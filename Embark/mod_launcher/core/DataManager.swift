import SwiftUI

class DataManager : ObservableObject {
  static let s = DataManager()
  let APPS_PANEL_ID: Int64 = -1
  @Published private(set) var linkData: [String: LinkData] = [:]
  @Published private(set) var launcherMode: LauncherMode = .launcher
  @Published private(set) var isDialogShowing: Bool = false
  @Published private(set) var isInitializing: Bool = false
  @Published private(set) var updateAppsListCompleted: Bool = false
  @Published private(set) var iconCacheInvalidated: Bool = false
  @Published private(set) var newlyAddedLinks: Set<String> = []
  @Published private(set) var recentlyMovedLinks: Set<String> = []
  @Published var contentOpacity: Double = 1.0
  var iconSizeChanged: Bool = false
  private var isDragging: Bool = false
  private var pendingUIUpdate: Bool = false
  private var iconLoadingCancelled: Bool = false
  private var folderIconLoadingPaths: Set<String> = []

  private init() {
    NotificationCenter.default.addObserver(self, selector: #selector(thumbnailsConfigChanged), name: NSNotification.Name("LauncherThumbnailsChanged"), object: nil)
  }

  deinit {
    NotificationCenter.default.removeObserver(self)
  }

  @objc private func thumbnailsConfigChanged() {
    DispatchQueue.main.async { [weak self] in
      guard let self = self else { return }
      for (key, linkData) in self.linkData {
        if linkData.linkType == .file {
          self.linkData[key]?.icon = nil
        }
      }
      self.objectWillChange.send()
    }
  }

  func Clean(){
    autoreleasepool {
      linkData = [:]
      launcherMode = .launcher
      isInitializing = false
      updateAppsListCompleted = false
      isDragging = false
      pendingUIUpdate = false
      folderIconLoadingPaths = []
      contentOpacity = 1.0
    }
  }

  func setDraggingState(_ dragging: Bool) {
    isDragging = dragging
    if !dragging && pendingUIUpdate {
      pendingUIUpdate = false
      DispatchQueue.main.async { [weak self] in
        self?.objectWillChange.send()
      }
    }
  }

  func changeMode(_ mode: LauncherMode) {
    if launcherMode == mode { return }
    let oldMode = launcherMode
    launcherMode = mode
    if mode == .settings {
      updateOtherLinks()
    } else if oldMode == .settings {
      clearAppsListIconCache()
    }
  }

  func updateMainLinks(completion: (() -> Void)? = nil) {
    DispatchQueue.main.async { [weak self] in
      guard let self = self else { return }
      isInitializing = true
    }
    DatabaseManager.s.loadLinksAsync { [weak self] links in
      guard let self = self else { return }
      let panelsSnapshot = DatabaseManager.s.panels
      DispatchQueue.global(qos: .userInitiated).async { [weak self] in
        guard let self = self else { return }
        autoreleasepool {
          let validLinks = self.cleanOrphanedLinks(links: links, panelsSnapshot: panelsSnapshot)
          self.cleanOrphanedPanels()
          self.cleanOrphanedLinkShortcuts(links: validLinks)
          self.cleanOrphanedLinkIcons(links: validLinks)
          self.cleanOrphanedSwiftMouseLinks(links: validLinks)
          self.cleanOrphanedSwiftKeyboardLinks(links: validLinks)
          var mm: [String: LinkData] = self.linkData
          for link in validLinks {
            var date: Date? = nil
            if link.linkType == .file {
              date = self.getFileModificationDate(for: link.path)
            }
            var icon: NSImage?
            if link.linkType != .web {
              DispatchQueue.main.sync {
                icon = LaunchManager.s.getIcon(path: link.path, linkType: link.linkType)
              }
            }
            mm[link.path] = LinkData(
              id: link.id,
              path: link.path,
              panelId: link.panelId,
              orderIndex: link.orderIndex,
              name: self.getLinkName(linkPath: link.path, linkType: link.linkType),
              icon: icon,
              shortcut: self.getLinkShortcut(linkPath: link.path),
              linkType: link.linkType,
              fileModificationDate: date,
              title: link.title,
              iconData: link.linkType == .web ? DatabaseManager.s.getLinkIcon(id: link.id) : nil,
              windowState: link.windowState,
              keepAlive: link.keepAlive,
              isMobileMode: link.isMobileMode,
              showInMenuBar: link.showInMenuBar,
              isPinned: link.isPinned,
              useProxy: link.useProxy,
              zoom: link.zoom,
              isVisible: link.isVisible
            )
          }
          let allShortcuts = DatabaseManager.s.getLinkShortcuts()
          for (path, shortcut) in allShortcuts {
            if mm[path] == nil {
              if FileManager.default.fileExists(atPath: path) && shortcut.linkType == .application {
                let appName = LaunchManager.s.getAppName(appPath: path)
                var appIcon: NSImage?
                DispatchQueue.main.sync {
                  appIcon = LaunchManager.s.getIcon(path: path, linkType: .application)
                }
                let appData = LinkData(
                  id: -1,
                  path: path,
                  panelId: -1,
                  orderIndex: -1,
                  name: appName,
                  icon: appIcon,
                  shortcut: shortcut,
                  linkType: .application,
                  fileModificationDate: nil,
                  title: nil,
                  iconData: nil,
                  windowState: nil,
                  keepAlive: false,
                  isMobileMode: false,
                  showInMenuBar: false,
                  isPinned: false,
                  useProxy: false,
                  zoom: 1.0,
                  isVisible: true
                )
                mm[path] = appData
              }
            }
          }
          DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            isInitializing = false
            for (path, link) in mm {
              if link.linkType == .web, let iconData = link.iconData {
                mm[path]?.icon = NSImage(data: iconData)
              }
            }
            linkData = mm
            MenuBarLinkManager.s.syncWithLinks(mm)
            objectWillChange.send()
            for (path, link) in mm {
              if link.linkType == .folder {
                self.loadFolderCustomIcon(path: path)
              }
            }
            completion?()
          }
        }
      }
    }
  }

  private func cleanOrphanedLinks(links: [LinkTable], panelsSnapshot: [PanelTable]) -> [LinkTable] {
    let validLinks = links.filter { link in
      return panelsSnapshot.contains { $0.id == link.panelId }
    }
    let validLinkPaths = Set(validLinks.map { $0.path })
    let invalidLinks = links.filter { !validLinkPaths.contains($0.path) }
    for invalidLink in invalidLinks {
      DatabaseManager.s.removeLink(path: invalidLink.path)
    }
    return validLinks
  }

  private func cleanOrphanedPanels() {
    let panels = DatabaseManager.s.panels
    let mainPanelIds = Set(panels.filter { $0.parentId == 0 || $0.parentId == nil }.map { $0.id })
    let invalidSubPanels = panels.filter { ($0.parentId != 0 && $0.parentId != nil) && !mainPanelIds.contains($0.parentId!) }
    for panel in invalidSubPanels {
      self.removePanel(panelId: panel.id)
    }
  }

  private func cleanOrphanedLinkShortcuts(links: [LinkTable]) {
    let shortcuts = DatabaseManager.s.getAllRawShortcuts()
    let linkIds = Set(links.map { $0.id })
    for shortcut in shortcuts {
      if shortcut.linkType == .web {
        if let linkId = shortcut.linkId {
          if !linkIds.contains(linkId) {
            DatabaseManager.s.deleteLinkShortcut(id: shortcut.id)
          }
        } else {
           DatabaseManager.s.deleteLinkShortcut(id: shortcut.id)
        }
      } else {
        if !FileManager.default.fileExists(atPath: shortcut.linkPath) {
          DatabaseManager.s.deleteLinkShortcut(id: shortcut.id)
        }
      }
    }
  }

  private func cleanOrphanedLinkIcons(links: [LinkTable]) {
    let icons = DatabaseManager.s.getAllLinkIconMetadata()
    let linkIds = Set(links.map { $0.id })
    for icon in icons {
      if !linkIds.contains(icon.linkId) {
        DatabaseManager.s.deleteLinkIcon(id: icon.id)
      }
    }
  }

  private func cleanOrphanedSwiftMouseLinks(links: [LinkTable]) {
    let mouseLinks = DatabaseManager.s.loadSwiftMouseLinks()
    let linkIds = Set(links.map { $0.id })
    for (linkId, _) in mouseLinks {
      if !linkIds.contains(linkId) {
        DatabaseManager.s.deleteSwiftMouseLink(linkId: linkId)
      }
    }
  }

  private func cleanOrphanedSwiftKeyboardLinks(links: [LinkTable]) {
    let keyboardLinks = DatabaseManager.s.loadSwiftKeyboardLinks()
    let linkIds = Set(links.map { $0.id })
    for (linkId, _) in keyboardLinks {
      if !linkIds.contains(linkId) {
        DatabaseManager.s.deleteSwiftKeyboardLink(linkId: linkId)
      }
    }
  }

  func updateOtherLinks(completion: (() -> Void)? = nil) {
    updateAppsListCompleted = false
    iconLoadingCancelled = false
    LaunchManager.s.fetchApps { [weak self] r in
      guard let self = self else { return }
      DatabaseManager.s.loadLinksAsync { [weak self] dbLinksSnapshot in
        guard let self = self else { return }
        let currentLinkData = self.linkData
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
          guard let self = self else { return }
          autoreleasepool {
            var mm: [String: LinkData] = [:]
            for (path, existingLink) in currentLinkData {
              if dbLinksSnapshot.first(where: { $0.path == path }) != nil {
                mm[path] = existingLink
              }
            }
            let newAppList = r.filter { mm[$0] == nil }
            let existingAppsWithoutIcon = mm.values.filter { app in
              app.panelId == self.APPS_PANEL_ID && app.linkType == .application && app.icon == nil
            }.map { $0.path }
            var appsNeedingIcons: [String] = []
            if !newAppList.isEmpty {
              for appPath in newAppList {
                let appName = LaunchManager.s.getAppName(appPath: appPath)
                let existingIcon = currentLinkData[appPath]?.icon
                let appData = LinkData(
                  id: -1,
                  path: appPath,
                  panelId: -1,
                  orderIndex: -1,
                  name: appName,
                  icon: existingIcon,
                  shortcut: DatabaseManager.s.getLinkShortcut(linkPath: appPath),
                  linkType: .application,
                  fileModificationDate: nil,
                  title: nil,
                  iconData: nil,
                  windowState: nil,
                  keepAlive: false,
                  isMobileMode: false,
                  showInMenuBar: false,
                  isPinned: false,
                  useProxy: false,
                  zoom: 1.0,
                  isVisible: true
                )
                mm[appPath] = appData
              }
              appsNeedingIcons.append(contentsOf: newAppList)
            }
            if !existingAppsWithoutIcon.isEmpty {
              appsNeedingIcons.append(contentsOf: existingAppsWithoutIcon)
            }
            DispatchQueue.main.async { [weak self] in
              guard let self = self else { return }
              linkData = mm
              objectWillChange.send()
              updateAppsListCompleted = true
              completion?()
              if !appsNeedingIcons.isEmpty {
                DispatchQueue.main.async { [weak self] in
                  guard let self = self else { return }
                  self.loadIconsAsync(for: appsNeedingIcons)
                }
              }
            }
          }
        }
      }
    }
  }

  // 重置图标加载取消标志
  func resetIconLoadingCancelled() {
    iconLoadingCancelled = false
  }

  func resetIconCacheInvalidatedFlag() {
    iconCacheInvalidated = false
  }

  // 异步加载图标（每加载一个就更新一个）
  func loadIconsAsync(for appPaths: [String]) {
    DispatchQueue.global(qos: .utility).async { [weak self] in
      guard let self = self else { return }
      var successCount = 0
      var failCount = 0
      var loadedIcons: [(path: String, icon: NSImage)] = []
      var failedApps: [String] = []
      for appPath in appPaths {
        if self.iconLoadingCancelled {
          return
        }
        autoreleasepool {
          var icon: NSImage?
          DispatchQueue.main.sync {
            icon = LaunchManager.s.getIcon(path: appPath, linkType: .application)
          }
          if let icon = icon {
            loadedIcons.append((path: appPath, icon: icon))
            successCount += 1
            if loadedIcons.count >= 10 {
              let batch = loadedIcons
              loadedIcons.removeAll()
              DispatchQueue.main.sync { [weak self] in
                guard let self = self else { return }
                if self.iconLoadingCancelled {
                  return
                }
                var updatedCount = 0
                var notFoundCount = 0
                for item in batch {
                  if self.linkData[item.path] != nil {
                    self.linkData[item.path]?.icon = item.icon
                    updatedCount += 1
                  } else {
                    notFoundCount += 1
                  }
                }
                self.objectWillChange.send()
              }
            }
          } else {
            failCount += 1
            failedApps.append(appPath)
          }
        }
      }
      if !loadedIcons.isEmpty && !self.iconLoadingCancelled {
        let batch = loadedIcons
        DispatchQueue.main.sync { [weak self] in
          guard let self = self else { return }
          if self.iconLoadingCancelled {
            return
          }
          var updatedCount = 0
          var notFoundCount = 0
          for item in batch {
            if self.linkData[item.path] != nil {
              self.linkData[item.path]?.icon = item.icon
              updatedCount += 1
            } else {
              notFoundCount += 1
            }
          }
          self.objectWillChange.send()
        }
      }
    }
  }

  func moveLink(path: String, to panelId: Int64) {
    moveLink(path: path, to: panelId, at: nil)
  }

  func moveLink(path: String, to panelId: Int64, at orderIndex: Int?) {
    guard let existingLink = linkData[path] else {
      return
    }
    if panelId == APPS_PANEL_ID {
      DatabaseManager.s.removeLink(path: path)
      DispatchQueue.main.async { [weak self] in
        guard let self = self else { return }
        linkData[path]?.panelId = panelId
        linkData[path]?.orderIndex = 0
        objectWillChange.send()
      }
    } else {
      let fromAppsPanel = existingLink.panelId == APPS_PANEL_ID
      let sourcePanelId = existingLink.panelId
      if let specifiedIndex = orderIndex {
        DispatchQueue.main.async { [weak self] in
          guard let self = self else { return }
          for (key, link) in linkData where link.panelId == panelId && key != path {
            if link.orderIndex >= specifiedIndex {
              linkData[key]?.orderIndex += 1
            }
          }
          linkData[path]?.panelId = panelId
          linkData[path]?.orderIndex = specifiedIndex
          objectWillChange.send()
          if fromAppsPanel {
            self.markAsNewlyAdded(path: path)
          } else if sourcePanelId != panelId {
            self.markAsRecentlyMoved(path: path)
          }
        }
        DispatchQueue.global(qos: .userInitiated).async {
          let existingLinks = DatabaseManager.s.links.filter { $0.panelId == panelId && $0.path != path }
          for link in existingLinks {
            if link.orderIndex >= specifiedIndex {
              DatabaseManager.s.updateLinkOrder(path: link.path, panelId: panelId, orderIndex: link.orderIndex + 1)
            }
          }
          if sourcePanelId == panelId {
            DatabaseManager.s.updateLinkOrder(path: path, panelId: panelId, orderIndex: specifiedIndex)
          } else {
            DatabaseManager.s.moveLinkWithOrder(path: path, to: panelId)
            DatabaseManager.s.updateLinkOrder(path: path, panelId: panelId, orderIndex: specifiedIndex)
          }
          DatabaseManager.s.loadLinksAsync { [weak self] links in
            guard let self = self else { return }
            DispatchQueue.main.async { [weak self] in
              guard let self = self else { return }
              if let updatedLink = links.first(where: { $0.path == path }) {
                self.linkData[path]?.id = updatedLink.id
              }
            }
          }
        }
      } else {
        DatabaseManager.s.moveLinkWithOrder(path: path, to: panelId)
        DatabaseManager.s.loadLinksAsync { [weak self] links in
          guard let self = self else { return }
          DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            for updatedLink in links.filter({ $0.panelId == panelId }) {
              linkData[updatedLink.path]?.panelId = updatedLink.panelId
              linkData[updatedLink.path]?.orderIndex = updatedLink.orderIndex
              linkData[updatedLink.path]?.id = updatedLink.id
            }
            objectWillChange.send()
            if fromAppsPanel {
              self.markAsNewlyAdded(path: path)
            } else {
              self.markAsRecentlyMoved(path: path)
            }
          }
        }
      }
    }
  }

  // 重新排序面板中的链接（仅用于自定义面板, 应用列表不允许拖动排序）
  func reorderLinks(in panelId: Int64, from sourceIndex: Int, to destinationIndex: Int) {
    if panelId == APPS_PANEL_ID {
      return
    }
    autoreleasepool {
      let panelLinks = getLinks(for: panelId)
      guard sourceIndex < panelLinks.count && destinationIndex < panelLinks.count else {
        return
      }
      var updatedLinks = panelLinks
      let movedLink = updatedLinks.remove(at: sourceIndex)
      updatedLinks.insert(movedLink, at: destinationIndex)
      for (index, link) in updatedLinks.enumerated() {
        DatabaseManager.s.updateLinkOrder(path: link.path, panelId: panelId, orderIndex: index)
      }
      let movedPath = movedLink.path
      DispatchQueue.main.async { [weak self] in
        guard let self = self else { return }
        for (index, link) in updatedLinks.enumerated() {
          linkData[link.path]?.orderIndex = index
        }
        objectWillChange.send()
        markAsRecentlyMoved(path: movedPath)
      }
    }
  }

  // 移除无效链接
  func removeInvalidLink(path: String) {
    if let linkData = linkData[path] {
      if linkData.linkType != .application {
        removeLinkShortcut(linkPath: path, linkId: linkData.id, linkType: linkData.linkType)
      }
      DatabaseManager.s.removeLink(path: path)
      DatabaseManager.s.loadLinksAsync { links in
        DatabaseManager.s.updateLinks(links)
      }
      DispatchQueue.main.async { [weak self] in
        guard let self = self else { return }
        self.linkData.removeValue(forKey: path)
        objectWillChange.send()
      }
    }
  }

  // 从面板中移除链接（应用或文件夹）
  func removeLink(path: String) {
    guard let linkData = linkData[path] else { return }
    var shouldRemove = false
    let fileManager = FileManager.default
    var isDirectory: ObjCBool = false
    let exists = fileManager.fileExists(atPath: path, isDirectory: &isDirectory)
    switch linkData.linkType {
    case .application:
      if launcherMode == .settings && LaunchManager.s.isAppExists(appPath: path) {
        DatabaseManager.s.removeLink(path: path)
        DispatchQueue.main.async { [weak self] in
          guard let self = self else { return }
          self.linkData[path]?.panelId = self.APPS_PANEL_ID
          self.linkData[path]?.orderIndex = 0
          self.objectWillChange.send()
        }
        return
      }
      shouldRemove = true
    case .folder:
      if exists && isDirectory.boolValue {
        shouldRemove = true
      } else {
        removeInvalidLink(path: path)
        return
      }
    case .file:
      if exists && !isDirectory.boolValue {
        shouldRemove = true
      } else {
        removeInvalidLink(path: path)
        return
      }
    case .web:
      if linkData.showInMenuBar {
        MenuBarLinkManager.s.removeLink(path: path)
      }
      shouldRemove = true
    }
    if shouldRemove {
      removeLinkShortcut(linkPath: path, linkId: linkData.id, linkType: linkData.linkType)
      if linkData.linkType == .web && linkData.id > 0 {
        DatabaseManager.s.removeLink(id: linkData.id)
      } else {
        DatabaseManager.s.removeLink(path: path)
      }
      DatabaseManager.s.loadLinksAsync { links in
        DatabaseManager.s.updateLinks(links)
      }
      DispatchQueue.main.async { [weak self] in
        guard let self = self else { return }
        self.linkData.removeValue(forKey: path)
        self.objectWillChange.send()
      }
    }
  }

  // 启动链接并处理失败情况
  func launchLinkWithValidation(path: String, linkName: String) async -> Bool {
    if let linkData = linkData[path] {
      let result = await launchLink(path: path, linkType: linkData.linkType)
      if !result.success {
        switch linkData.linkType {
        case .application:
          if !LaunchManager.s.isAppExists(appPath: path) {
            removeInvalidLink(path: path)
            return false
          }
        case .folder:
          let fileManager = FileManager.default
          var isDirectory: ObjCBool = false
          if !fileManager.fileExists(atPath: path, isDirectory: &isDirectory) || !isDirectory.boolValue {
            removeInvalidLink(path: path)
            return false
          }
        case .file:
          let fileManager = FileManager.default
          var isDirectory: ObjCBool = false
          if !fileManager.fileExists(atPath: path, isDirectory: &isDirectory) || isDirectory.boolValue {
            removeInvalidLink(path: path)
            return false
          }
        case .web:
          break
        }
      }
      return result.success
    }
    return false
  }

  // 获取指定面板中的链接
  func getLinks(for panelId: Int64) -> [LinkData] {
    let filteredLinks = linkData.values.filter { $0.panelId == panelId }
    if panelId == APPS_PANEL_ID {
      return filteredLinks.sorted { link1, link2 in
        if link1.linkType != link2.linkType {
          return link1.linkType == .application
        }
        return link1.name.localizedCaseInsensitiveCompare(link2.name) == .orderedAscending
      }
    } else {
      return filteredLinks.sorted { $0.orderIndex < $1.orderIndex }
    }
  }

  // 获取应用列表中的链接（panel_id = -1）
  func getAppsListLinks() -> [LinkData] {
    return getLinks(for: APPS_PANEL_ID)
  }

  // 获取所有应用（包括应用列表和主面板中的应用）
  func getAllApps() -> [LinkData] {
    return linkData.values.filter { $0.linkType == .application }.sorted { link1, link2 in
      link1.name.localizedCaseInsensitiveCompare(link2.name) == .orderedAscending
    }
  }

  // 获取搜索结果
  func getSearchApps(scope: SearchScope) -> [LinkData] {
    let links = linkData.values
    switch scope {
    case .all:
      return links.sorted { link1, link2 in
        link1.name.localizedCaseInsensitiveCompare(link2.name) == .orderedAscending
      }
    case .allApps:
      return links.filter { $0.linkType == .application }.sorted { link1, link2 in
        link1.name.localizedCaseInsensitiveCompare(link2.name) == .orderedAscending
      }
    case .otherApps:
      return getAppsListLinks()
    }
  }

  // 获取链接图标（带缓存）
  func getLinkIcon(linkPath: String) -> NSImage? {
    if let linkData = linkData[linkPath] {
      var icon: NSImage? = nil
      if linkData.linkType == .application {
        return linkData.icon
      }
      if linkData.linkType == .folder {
        if let cachedIcon = linkData.icon {
          return cachedIcon
        }
        icon = LaunchManager.s.getIcon(path: linkPath, linkType: .folder)
        loadFolderCustomIcon(path: linkPath)
      }
      if linkData.linkType == .file {
        if let currentModDate = getFileModificationDate(for: linkPath), let storedModDate = linkData.fileModificationDate, currentModDate == storedModDate, let cachedIcon = linkData.icon {
          return cachedIcon
        }
        if linkData.icon == nil {
          DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self = self else { return }
            if let loadedIcon = LaunchManager.s.getIcon(path: linkPath, linkType: .file) {
              DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                if self.linkData[linkPath] != nil {
                  self.linkData[linkPath]?.icon = loadedIcon
                  self.linkData[linkPath]?.fileModificationDate = self.getFileModificationDate(for: linkPath)
                  self.objectWillChange.send()
                }
              }
            }
          }
          return nil
        }
        icon = LaunchManager.s.getIcon(path: linkPath, linkType: .file)
      }
      if linkData.linkType == .web {
        return linkData.icon
      }
      if let icon = icon {
        DispatchQueue.main.async { [weak self] in
          guard let self = self else { return }
          if self.linkData[linkPath] != nil {
            self.linkData[linkPath]?.icon = icon
            if self.linkData[linkPath]?.linkType == .file {
              self.linkData[linkPath]?.fileModificationDate = self.getFileModificationDate(for: linkPath)
            }
          }
        }
      }
      return icon
    }
    return nil
  }

  // 添加主面板
  func addMainPanel(name: String) -> Int64 {
    let panelId = DatabaseManager.s.addMainPanel(name: name)
    DatabaseManager.s.loadPanelsAsync { [weak self] panels in
      guard let self = self else { return }
      DatabaseManager.s.updatePanels(panels)
      self.objectWillChange.send()
    }
    LauncherWin.s.Center(wait: true)
    return panelId
  }

  // 添加子面板
  func addSubPanel(name: String, to parentId: Int64) -> Int64 {
    let panelId = DatabaseManager.s.addSubPanel(name: name, parentId: parentId)
    DatabaseManager.s.loadPanelsAsync { [weak self] panels in
      guard let self = self else { return }
      DatabaseManager.s.updatePanels(panels)
      self.objectWillChange.send()
    }
    LauncherWin.s.Center(wait: true)
    return panelId
  }

  // 删除面板
  func removePanel(panelId: Int64) {
    var appsToMoveToList: [LinkData] = []
    var linksToRemove: [LinkData] = []
    func collectLinksRecursively(for panelId: Int64) {
      let panelLinks = getLinks(for: panelId)
      for link in panelLinks {
        if link.linkType == .application {
          appsToMoveToList.append(link)
        } else {
          linksToRemove.append(link)
        }
      }
      let childPanels = getSubPanels(for: panelId)
      for childPanel in childPanels {
        collectLinksRecursively(for: childPanel.id)
      }
    }
    collectLinksRecursively(for: panelId)
    DatabaseManager.s.removePanelWithAppMove(panelId: panelId)
    DispatchQueue.main.async { [weak self] in
      guard let self = self else { return }
      for app in appsToMoveToList {
        if LaunchManager.s.isAppExists(appPath: app.path) {
          self.linkData[app.path]?.panelId = self.APPS_PANEL_ID
          self.linkData[app.path]?.orderIndex = 0
        } else {
          self.linkData.removeValue(forKey: app.path)
        }
      }
      for link in linksToRemove {
        self.linkData.removeValue(forKey: link.path)
      }
      self.objectWillChange.send()
      DatabaseManager.s.loadPanelsAsync { [weak self] panels in
        DatabaseManager.s.updatePanels(panels)
        DatabaseManager.s.loadLinksAsync { [weak self] links in
          DatabaseManager.s.updateLinks(links)
          self?.updateOtherLinks {
            DispatchQueue.main.async { [weak self] in
              guard let self = self else { return }
              self.objectWillChange.send()
            }
          }
        }
      }
    }
    LauncherWin.s.Center(wait: true)
  }

  // 交换两个面板的顺序
  func swapPanelOrder(panel1Id: Int64, panel2Id: Int64) {
    DatabaseManager.s.swapPanelOrderWithValidation(panel1Id: panel1Id, panel2Id: panel2Id, panels: DatabaseManager.s.panels)
    DatabaseManager.s.loadPanelsAsync { [weak self] panels in
      guard let self = self else { return }
      DatabaseManager.s.updatePanels(panels)
      self.objectWillChange.send()
    }
  }

  // 移动主面板到另一个主面板下面
  func movePanelToBelow(panelId: Int64, targetPanelId: Int64) {
    DatabaseManager.s.movePanelToBelow(panelId: panelId, targetPanelId: targetPanelId)
    DatabaseManager.s.loadPanelsAsync { [weak self] panels in
      guard let self = self else { return }
      DatabaseManager.s.updatePanels(panels)
      self.objectWillChange.send()
    }
  }

  // 移动子面板到不同的主面板
  func moveSubPanel(subPanelId: Int64, to newParentId: Int64) {
    DatabaseManager.s.moveSubPanelWithValidation(subPanelId: subPanelId, to: newParentId, panels: DatabaseManager.s.panels)
    DatabaseManager.s.loadPanelsAsync { [weak self] panels in
      guard let self = self else { return }
      DatabaseManager.s.updatePanels(panels)
      self.objectWillChange.send()
    }
  }

  // 移动子面板到另一个主面板的子面板下面
  func moveSubPanelToSubPanelBelow(subPanelId: Int64, targetSubPanelId: Int64) {
    DatabaseManager.s.moveSubPanelToSubPanelBelow(subPanelId: subPanelId, targetSubPanelId: targetSubPanelId)
    DatabaseManager.s.loadPanelsAsync { [weak self] panels in
      guard let self = self else { return }
      DatabaseManager.s.updatePanels(panels)
      self.objectWillChange.send()
    }
  }

  // 自定义面板宽度
  func updatePanelWidth(panelId: Int64, width: Double?) {
    DatabaseManager.s.updatePanelWidth(panelId: panelId, width: width)
    DatabaseManager.s.loadPanelsAsync { [weak self] panels in
      guard let self = self else { return }
      DatabaseManager.s.updatePanels(panels)
      self.objectWillChange.send()
    }
  }

  // 获取主面板列表
  func getMainPanels() -> [PanelTable] {
    return DatabaseManager.s.getMainPanels(panels: DatabaseManager.s.panels)
  }

  // 获取指定面板的子面板
  func getSubPanels(for panelId: Int64) -> [PanelTable] {
    return DatabaseManager.s.getSubPanels(for: panelId, panels: DatabaseManager.s.panels)
  }

  func clearAppsListIconCache() {
    if launcherMode == .settings {
      return
    }
    iconLoadingCancelled = true
    DispatchQueue.main.async { [weak self] in
      autoreleasepool {
        guard let self = self else { return }
        var removedCount = 0
        for d in self.linkData.values.filter({ $0.panelId == self.APPS_PANEL_ID }) {
          if d.icon != nil {
            var ud = d
            ud.icon = nil
            self.linkData[ud.path] = ud
            removedCount += 1
          }
        }
        if removedCount > 0 {
          let linksWithIconAfter = self.linkData.values.filter { $0.icon != nil }.count
          self.iconCacheInvalidated = true
          Debug.print("Cleared \(removedCount) icons, Remaining: \(linksWithIconAfter)")
        }
      }
    }
  }

  func reloadApplicationIconsAfterSizeChange() {
    iconSizeChanged = false
    for key in linkData.keys {
      if var d = linkData[key], d.linkType == .application, d.icon != nil {
        d.icon = nil
        linkData[key] = d
      }
    }
    iconLoadingCancelled = false
    let paths = linkData.values.filter { $0.linkType == .application }.map { $0.path }
    if !paths.isEmpty {
      loadIconsAsync(for: paths)
    }
  }

  func getLinkShortcut(linkPath: String) -> LinkShortcut? {
    return DatabaseManager.s.getLinkShortcut(linkPath: linkPath)
  }

  func getAllLinkShortcuts() -> [(linkPath: String, shortcut: LinkShortcut)] {
    let shortcutsDict = DatabaseManager.s.getLinkShortcuts()
    return shortcutsDict.map { (linkPath: $0.key, shortcut: $0.value) }
  }

  func setLinkShortcut(linkPath: String, linkId: Int64? = nil, keyCode: CGKeyCode?, flags: CGEventFlags?, linkType: LinkType = .application) {
    DatabaseManager.s.setLinkShortcut(linkPath: linkPath, linkId: linkId, keyCode: keyCode, flags: flags, linkType: linkType)
    if let existingLinkData = linkData[linkPath] {
      var updatedLinkData = existingLinkData
      if let keyCode = keyCode, let flags = flags {
        updatedLinkData.shortcut = LinkShortcut(keyCode: keyCode, flags: flags, linkType: linkType)
      } else {
        updatedLinkData.shortcut = nil
      }
      DispatchQueue.main.async { [weak self] in
        self?.linkData[linkPath] = updatedLinkData
      }
    }
  }

  func removeLinkShortcut(linkPath: String, linkId: Int64? = nil, linkType: LinkType = .application) {
    setLinkShortcut(linkPath: linkPath, linkId: linkId, keyCode: nil, flags: nil, linkType: linkType)
  }

  private func _addLink(path: String, panelId: Int64, orderIndex: Int, title: String?, linkType: LinkType) {
    let updateIdCompletion: (Int64) -> Void = { [weak self] id in
      DispatchQueue.main.async {
        guard let self = self else { return }
        if var link = self.linkData[path] {
          link.id = id
          self.linkData[path] = link
          self.objectWillChange.send()
        }
      }
    }
    switch linkType {
    case .folder:
      DatabaseManager.s.addFolderLink(path: path, panelId: panelId, orderIndex: orderIndex, title: title, completion: updateIdCompletion)
    case .file:
      DatabaseManager.s.addFileLink(path: path, panelId: panelId, orderIndex: orderIndex, title: title, completion: updateIdCompletion)
    case .application:
      DatabaseManager.s.addAppLink(path: path, panelId: panelId, orderIndex: orderIndex, title: title, completion: updateIdCompletion)
    case .web:
      return
    }
    let name = getLinkName(linkPath: path, linkType: linkType)
    let icon = LaunchManager.s.getIcon(path: path, linkType: linkType)
    let newLinkData = LinkData(
      id: -1,
      path: path,
      panelId: panelId,
      orderIndex: orderIndex,
      name: name,
      icon: icon,
      shortcut: nil,
      linkType: linkType,
      fileModificationDate: nil,
      title: title,
      iconData: nil,
      windowState: nil,
      keepAlive: false,
      isMobileMode: false,
      showInMenuBar: false,
      isPinned: false,
      useProxy: false,
      zoom: 1.0,
      isVisible: true
    )
    DispatchQueue.main.async { [weak self] in
      guard let self = self else { return }
      self.linkData[path] = newLinkData
      self.objectWillChange.send()
      self.markAsNewlyAdded(path: path)
      if linkType == .folder {
        self.loadFolderCustomIcon(path: path)
      }
    }
  }

  func addFolderLink(path: String, panelId: Int64, title: String? = nil) {
    let orderIndex = DatabaseManager.s.getNextLinkOrderIndex(panelId: panelId)
    _addLink(path: path, panelId: panelId, orderIndex: orderIndex, title: title, linkType: .folder)
  }

  func addFolderLink(path: String, panelId: Int64, orderIndex: Int, title: String? = nil) {
    _addLink(path: path, panelId: panelId, orderIndex: orderIndex, title: title, linkType: .folder)
  }

  func addFileLink(path: String, panelId: Int64, title: String? = nil) {
    let orderIndex = DatabaseManager.s.getNextLinkOrderIndex(panelId: panelId)
    _addLink(path: path, panelId: panelId, orderIndex: orderIndex, title: title, linkType: .file)
  }

  func addFileLink(path: String, panelId: Int64, orderIndex: Int, title: String? = nil) {
    _addLink(path: path, panelId: panelId, orderIndex: orderIndex, title: title, linkType: .file)
  }

  func addAppLink(path: String, panelId: Int64, title: String? = nil) {
    let orderIndex = DatabaseManager.s.getNextLinkOrderIndex(panelId: panelId)
    _addLink(path: path, panelId: panelId, orderIndex: orderIndex, title: title, linkType: .application)
  }

  func addAppLink(path: String, panelId: Int64, orderIndex: Int, title: String? = nil) {
    _addLink(path: path, panelId: panelId, orderIndex: orderIndex, title: title, linkType: .application)
  }

  func addWebLink(path: String, panelId: Int64, title: String, iconData: Data? = nil, useProxy: Bool = false, showInMenuBar: Bool = false, completion: (() -> Void)? = nil) {
    let orderIndex = DatabaseManager.s.getNextLinkOrderIndex(panelId: panelId)
    if let providedIconData = iconData {
      DatabaseManager.s.addWebLink(path: path, panelId: panelId, orderIndex: orderIndex, title: title, icon: providedIconData, useProxy: useProxy, showInMenuBar: showInMenuBar) { [weak self] linkId in
        guard let self = self else { return }
        if var link = self.linkData[path] {
          link.id = linkId
          self.linkData[path] = link
          self.objectWillChange.send()
          MenuBarLinkManager.s.syncWithLinks(self.linkData)
        }
      }
      DispatchQueue.main.async { [weak self] in
        guard let self = self else { return }
        let icon = NSImage(data: providedIconData)
        let newWebData = LinkData(
          id: -1,
          path: path,
          panelId: panelId,
          orderIndex: orderIndex,
          name: title,
          icon: icon,
          shortcut: nil,
          linkType: .web,
          fileModificationDate: nil,
          title: title,
          iconData: providedIconData,
          windowState: nil,
          keepAlive: false,
          isMobileMode: false,
          showInMenuBar: showInMenuBar,
          isPinned: false,
          useProxy: useProxy,
          zoom: 1.0,
          isVisible: true
        )
        self.linkData[path] = newWebData
        self.objectWillChange.send()
        self.markAsNewlyAdded(path: path)
        completion?()
      }
    } else {
      DispatchQueue.global(qos: .userInitiated).async { [weak self] in
        guard let self = self else { return }
        let fetchedIconData = self.fetchWebIcon(url: path, useProxy: useProxy)
        DatabaseManager.s.addWebLink(path: path, panelId: panelId, orderIndex: orderIndex, title: title, icon: fetchedIconData, useProxy: useProxy, showInMenuBar: showInMenuBar) { [weak self] linkId in
          guard let self = self else { return }
          if var link = self.linkData[path] {
            link.id = linkId
            self.linkData[path] = link
            self.objectWillChange.send()
            MenuBarLinkManager.s.syncWithLinks(self.linkData)
          }
        }
        DispatchQueue.main.async { [weak self] in
          guard let self = self else { return }
          let icon = fetchedIconData != nil ? NSImage(data: fetchedIconData!) : nil
          let newWebData = LinkData(
            id: -1,
            path: path,
            panelId: panelId,
            orderIndex: orderIndex,
            name: title,
            icon: icon,
            shortcut: nil,
            linkType: .web,
            fileModificationDate: nil,
            title: title,
            iconData: fetchedIconData,
            windowState: nil,
            keepAlive: false,
            isMobileMode: false,
            showInMenuBar: showInMenuBar,
            isPinned: false,
            useProxy: useProxy,
            zoom: 1.0,
            isVisible: true
          )
          self.linkData[path] = newWebData
          self.objectWillChange.send()
          self.markAsNewlyAdded(path: path)
          completion?()
        }
      }
    }
  }

  func editWebLink(oldPath: String, newPath: String, title: String, iconData: Data?, useProxy: Bool, showInMenuBar: Bool, fetchIcon: Bool = false, completion: (() -> Void)? = nil) {
    if fetchIcon {
      DispatchQueue.global(qos: .userInitiated).async { [weak self] in
        guard let self = self else { return }
        var fetchedIconData = self.fetchWebIcon(url: newPath, useProxy: useProxy)
        if fetchedIconData == nil {
            fetchedIconData = iconData
        }
        DatabaseManager.s.updateWebLink(oldPath: oldPath, newPath: newPath, title: title, icon: fetchedIconData, useProxy: useProxy, showInMenuBar: showInMenuBar)
        DispatchQueue.main.async {
          self.updateMemoryAfterEdit(oldPath: oldPath, newPath: newPath, title: title, iconData: fetchedIconData, useProxy: useProxy, showInMenuBar: showInMenuBar)
          completion?()
        }
      }
    } else {
      DatabaseManager.s.updateWebLink(oldPath: oldPath, newPath: newPath, title: title, icon: iconData, useProxy: useProxy, showInMenuBar: showInMenuBar)
      DispatchQueue.main.async { [weak self] in
        guard let self = self else { return }
        self.updateMemoryAfterEdit(oldPath: oldPath, newPath: newPath, title: title, iconData: iconData, useProxy: useProxy, showInMenuBar: showInMenuBar)
        completion?()
      }
    }
  }

  private func updateMemoryAfterEdit(oldPath: String, newPath: String, title: String, iconData: Data?, useProxy: Bool, showInMenuBar: Bool) {
    if var link = self.linkData[oldPath] {
      if oldPath != newPath {
        self.linkData.removeValue(forKey: oldPath)
        LauncherBrowserWin.s.updateWindowKey(oldKey: oldPath, newKey: newPath)
      }
      link.path = newPath
      link.name = title
      link.title = title
      link.iconData = iconData
      link.useProxy = useProxy
      link.showInMenuBar = showInMenuBar
      if let data = iconData {
        link.icon = NSImage(data: data)
      } else {
        link.icon = nil
      }
      self.linkData[newPath] = link
      self.objectWillChange.send()
      MenuBarLinkManager.s.syncWithLinks(self.linkData)
    }
  }

  private func fetchWebIcon(url: String, useProxy: Bool) -> Data? {
    guard let urlObj = URL(string: url), let _ = urlObj.host else { return nil }
    var iconData: Data? = nil
    let semaphore = DispatchSemaphore(value: 0)
    var request = URLRequest(url: urlObj)
    request.timeoutInterval = 5
    request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15", forHTTPHeaderField: "User-Agent")
    let config = URLSessionConfiguration.default
    if useProxy {
      let host = LauncherConfig.launcherProxyHost
      let port = Int(LauncherConfig.launcherProxyPort) ?? 0
      let type = LauncherConfig.launcherProxyType
      if !host.isEmpty && port > 0 {
        if type == 0 {
          config.connectionProxyDictionary = [
            kCFStreamPropertySOCKSProxyHost: host,
            kCFStreamPropertySOCKSProxyPort: port
          ]
        } else {
          config.connectionProxyDictionary = [
            kCFNetworkProxiesHTTPEnable: 1,
            kCFNetworkProxiesHTTPProxy: host,
            kCFNetworkProxiesHTTPPort: port,
            kCFNetworkProxiesHTTPSEnable: 1,
            kCFNetworkProxiesHTTPSProxy: host,
            kCFNetworkProxiesHTTPSPort: port
          ]
        }
      }
    }
    let session = URLSession(configuration: config)
    let task2 = session.dataTask(with: request) { [weak self] data, response, error in
      defer { semaphore.signal() }
      guard let self = self, let data = data, let htmlString = String(data: data, encoding: .utf8) else { return }
      if let iconUrl = self.findIconUrlInHtml(html: htmlString, baseUrl: urlObj) {
        let semaphore2 = DispatchSemaphore(value: 0)
        let iconTask = session.dataTask(with: iconUrl) { d, r, e in
          if let d = d, !d.isEmpty {
            iconData = d
          }
          semaphore2.signal()
        }
        iconTask.resume()
        _ = semaphore2.wait(timeout: .now() + 5)
      }
    }
    task2.resume()
    _ = semaphore.wait(timeout: .now() + 10)
    if let data = iconData {
      return data
    }
    if let host = urlObj.host {
      let googleFaviconUrl = "https://www.google.com/s2/favicons?domain=\(host)&sz=128"
      if let url = URL(string: googleFaviconUrl) {
        let semaphore3 = DispatchSemaphore(value: 0)
        let task3 = session.dataTask(with: url) { d, r, e in
          if let d = d, let image = NSImage(data: d), image.isValid {
            iconData = d
          }
          semaphore3.signal()
        }
        task3.resume()
        _ = semaphore3.wait(timeout: .now() + 5)
        if let data = iconData {
          return data
        }
      }
    }
    return nil
  }

  private func findIconUrlInHtml(html: String, baseUrl: URL) -> URL? {
    let patterns = [
      "<link[^>]*rel=[\"']apple-touch-icon(?:-precomposed)?[\"'][^>]*href=[\"']([^\"']+)[\"']", // apple-touch-icon在前
      "<link[^>]*href=[\"']([^\"']+)[\"'][^>]*rel=[\"']apple-touch-icon(?:-precomposed)?[\"']", // href在前
      "<link[^>]*rel=[\"'](?:shortcut )?icon[\"'][^>]*href=[\"']([^\"']+)[\"']", // 普通icon
      "<link[^>]*href=[\"']([^\"']+)[\"'][^>]*rel=[\"'](?:shortcut )?icon[\"']"  // href在前
    ]
    for pattern in patterns {
      do {
        let regex = try NSRegularExpression(pattern: pattern, options: .caseInsensitive)
        let nsString = html as NSString
        let results = regex.matches(in: html, options: [], range: NSRange(location: 0, length: nsString.length))
        if let first = results.first {
          let hrefRange = first.range(at: 1)
          let href = nsString.substring(with: hrefRange)
          return URL(string: href, relativeTo: baseUrl)
        }
      } catch {
        continue
      }
    }
    return nil
  }

  private func launchLink(path: String, linkType: LinkType) async -> (success: Bool, error: String?) {
    switch linkType {
    case .application:
      return await LaunchManager.s.launchApp(appPath: path)
    case .folder:
      if NSWorkspace.shared.open(URL(fileURLWithPath: path)) {
        return (true, nil)
      } else {
        return (false, "Unable to open folder")
      }
    case .file:
      if NSWorkspace.shared.open(URL(fileURLWithPath: path)) {
        return (true, nil)
      } else {
        return (false, "Unable to open file")
      }
    case .web:
      let title = self.linkData[path]?.title ?? "Browser"
      DispatchQueue.main.async {
        LauncherBrowserWin.s.ToggleOrOpen(url: path, title: title)
      }
      return (true, nil)
    }
  }

  private func getLinkName(linkPath: String, linkType: LinkType) -> String {
    switch linkType {
    case .application:
      return LaunchManager.s.getAppName(appPath: linkPath)
    case .folder:
      return (linkPath as NSString).lastPathComponent
    case .file:
      return ((linkPath as NSString).lastPathComponent as NSString).deletingPathExtension
    case .web:
      return linkPath
    }
  }

  func updateLinkTitle(linkPath: String, title: String?) {
    DatabaseManager.s.updateLinkTitle(linkPath: linkPath, title: title)
    if var linkDataItem = linkData[linkPath] {
      linkDataItem.title = title
      linkData[linkPath] = linkDataItem
      objectWillChange.send()
    }
  }

  func updateLinkWindowState(linkPath: String, state: String) {
    DatabaseManager.s.updateLinkWindowState(linkPath: linkPath, state: state)
    DispatchQueue.main.async { [weak self] in
      guard let self = self else { return }
      if var link = self.linkData[linkPath] {
        link.windowState = state
        self.linkData[linkPath] = link
      }
    }
  }

  func updateLinkKeepAlive(linkPath: String, keepAlive: Bool) {
    DatabaseManager.s.updateLinkKeepAlive(linkPath: linkPath, keepAlive: keepAlive)
    DispatchQueue.main.async { [weak self] in
      guard let self = self else { return }
      if var link = self.linkData[linkPath] {
        link.keepAlive = keepAlive
        self.linkData[linkPath] = link
        self.objectWillChange.send()
      }
      LauncherBrowserWin.s.setKeepAlive(linkPath, keepAlive: keepAlive)
    }
  }

  func updateLinkMobileMode(linkPath: String, isMobileMode: Bool) {
    DatabaseManager.s.updateLinkMobileMode(linkPath: linkPath, isMobileMode: isMobileMode)
    DispatchQueue.main.async { [weak self] in
      guard let self = self else { return }
      if var link = self.linkData[linkPath] {
        link.isMobileMode = isMobileMode
        self.linkData[linkPath] = link
        self.objectWillChange.send()
      }
    }
  }

  func updateLinkShowInMenuBar(linkPath: String, showInMenuBar: Bool) {
    DatabaseManager.s.updateLinkShowInMenuBar(linkPath: linkPath, showInMenuBar: showInMenuBar)
    if var link = linkData[linkPath] {
      link.showInMenuBar = showInMenuBar
      linkData[linkPath] = link
      objectWillChange.send()
      MenuBarLinkManager.s.syncWithLinks(linkData)
    } else {
      updateMainLinks()
    }
  }

  func updateLinkPinned(linkPath: String, isPinned: Bool) {
    DatabaseManager.s.updateLinkPinned(linkPath: linkPath, isPinned: isPinned)
    if var link = linkData[linkPath] {
      link.isPinned = isPinned
      linkData[linkPath] = link
    }
  }

  func updateLinkZoom(path: String, zoom: Double) {
    if var link = linkData[path] {
      link.zoom = zoom
      linkData[path] = link
      DatabaseManager.s.updateLinkZoom(path: path, zoom: zoom)
    }
  }

  func updateLinkVisible(linkPath: String, isVisible: Bool) {
    DatabaseManager.s.updateLinkVisible(linkPath: linkPath, isVisible: isVisible)
    if var data = linkData[linkPath] {
      data.isVisible = isVisible
      linkData[linkPath] = data
      objectWillChange.send()
    }
  }

  func updatePanelVisible(panelId: Int64, isVisible: Bool) {
    DatabaseManager.s.updatePanelVisible(panelId: panelId, isVisible: isVisible)
    DatabaseManager.s.loadPanels()
  }

  func isNewlyAdded(path: String) -> Bool {
    return newlyAddedLinks.contains(path)
  }

  func isRecentlyMoved(path: String) -> Bool {
    return recentlyMovedLinks.contains(path)
  }

  func setDialogShowing(_ showing: Bool) {
    isDialogShowing = showing
  }

  private func getFileModificationDate(for path: String) -> Date? {
    do {
      let attributes = try FileManager.default.attributesOfItem(atPath: path)
      return attributes[.modificationDate] as? Date
    } catch {
      return nil
    }
  }

  private func markAsNewlyAdded(path: String) {
    if !LauncherInfo.addLinkTip {
      return
    }
    DispatchQueue.main.async { [weak self] in
      guard let self = self else { return }
      self.newlyAddedLinks.insert(path)
      self.objectWillChange.send()
      DispatchQueue.main.asyncAfter(deadline: .now() + LauncherInfo.addLinkDuration) { [weak self] in
        guard let self = self else { return }
        self.newlyAddedLinks.remove(path)
        self.objectWillChange.send()
      }
    }
  }

  func markAsRecentlyMoved(path: String) {
    if !LauncherInfo.addLinkTip {
      return
    }
    DispatchQueue.main.async { [weak self] in
      guard let self = self else { return }
      self.recentlyMovedLinks.insert(path)
      self.objectWillChange.send()
      DispatchQueue.main.asyncAfter(deadline: .now() + LauncherInfo.addLinkDuration) { [weak self] in
        guard let self = self else { return }
        self.recentlyMovedLinks.remove(path)
        self.objectWillChange.send()
      }
    }
  }

  private func loadFolderCustomIcon(path: String) {
    guard #available(macOS 14.0, *) else { return }
    guard !folderIconLoadingPaths.contains(path) else { return }
    folderIconLoadingPaths.insert(path)
    LaunchManager.s.getFolderIconWithCustomization(path: path) { [weak self] customIcon in
      guard let self = self else { return }
      self.folderIconLoadingPaths.remove(path)
      guard let customIcon = customIcon else { return }
      if self.linkData[path] != nil {
        self.linkData[path]?.icon = customIcon
        self.objectWillChange.send()
      }
    }
  }
}
