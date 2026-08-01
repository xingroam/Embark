import Cocoa
import ApplicationServices
import Combine

class SpaceManager: ObservableObject {
  static let s = SpaceManager()
  @Published var spaces: [SpaceTable] = []
  private var cancellables = Set<AnyCancellable>()

  private init() {
    DatabaseManager.s.$spaces
      .assign(to: \.spaces, on: self)
      .store(in: &cancellables)
  }

  func saveSpace(name: String, scope: SpaceScreen = .all, focus: SpaceFocusMode = .keep) {
    let snapshot = snapshotSpace(name: name, scope: scope, focus: focus)
    DatabaseManager.s.saveSpace(snapshot)
  }

  func saveSpace(name: String, scope: SpaceScreen, focus: SpaceFocusMode, windows: [WindowSnapshot]) {
    var snapshot = snapshotSpace(name: name, scope: scope, focus: focus)
    snapshot.windows = windows
    DatabaseManager.s.saveSpace(snapshot)
  }

  func deleteSpace(id: Int64) {
    DatabaseManager.s.deleteSpace(id: id)
  }

  func renameSpace(id: Int64, newName: String) {
    if var space = spaces.first(where: { $0.id == id }) {
      space.name = newName
      DatabaseManager.s.saveSpace(space)
    }
  }

  func duplicateSpace(sourceId: Int64, newName: String) {
    guard let sourceSpace = spaces.first(where: { $0.id == sourceId }) else { return }
    let newSpace = SpaceTable(
      id: 0,
      name: newName,
      orderIndex: spaces.count,
      focus: sourceSpace.focus,
      systemUI: sourceSpace.systemUI,
      screens: sourceSpace.screens,
      windows: sourceSpace.windows
    )
    DatabaseManager.s.saveSpace(newSpace)
  }

  func updateSpace(id: Int64, name: String, scope: SpaceScreen, focus: SpaceFocusMode) {
    var snapshot = snapshotSpace(name: name, scope: scope, focus: focus)
    snapshot.id = id
    if let oldSpace = spaces.first(where: { $0.id == id }) {
      snapshot.orderIndex = oldSpace.orderIndex
    }
    DatabaseManager.s.saveSpace(snapshot)
  }

  func updateSpace(id: Int64, name: String, focus: SpaceFocusMode, windows: [WindowSnapshot]) {
    guard var space = spaces.first(where: { $0.id == id }) else { return }
    space.name = name
    space.focus = focus
    space.windows = windows
    DatabaseManager.s.saveSpace(space)
  }

  func snapshotSpace(name: String, scope: SpaceScreen, focus: SpaceFocusMode) -> SpaceTable {
    var targetScreens = NSScreen.screens
    if scope == .current {
      let mouseLoc = NSEvent.mouseLocation
      if let currentScreen = NSScreen.screens.first(where: { NSMouseInRect(mouseLoc, $0.frame, false) }) {
        targetScreens = [currentScreen]
      } else if let main = NSScreen.main {
        targetScreens = [main]
      }
    }
    let sortedAllScreens = getSortedScreens()
    let targetScreenSet = Set(targetScreens.map { ObjectIdentifier($0) })
    let screens = sortedAllScreens.enumerated().compactMap { (index, screen) -> ScreenInfo? in
      guard targetScreenSet.contains(ObjectIdentifier(screen)) else { return nil }
      return ScreenInfo(screenIndex: index, frame: screen.frame, isPrimary: screen == NSScreen.main)
    }
    let targetScreenIndices = Set(screens.map { $0.screenIndex })
    let (desktopWindows, _, _) = WindowList.GetList()
    let windowSnapshots = desktopWindows.compactMap { wd -> WindowSnapshot? in
      var bundleID = wd.bundleIdentifier
      if bundleID == nil || bundleID?.isEmpty == true {
        if let app = NSRunningApplication(processIdentifier: wd.pid) {
          bundleID = app.bundleIdentifier
        }
      }
      guard let finalBundleID = bundleID, !finalBundleID.isEmpty else {
        return nil
      }
      let screenIndex = findScreenIndex(for: wd.bounds)
      if scope == .current {
        if !targetScreenIndices.contains(screenIndex) {
          return nil
        }
      }
      let relativeFrame = calculateRelativeFrame(absoluteFrame: wd.bounds, screenIndex: screenIndex)
      return WindowSnapshot(bundleIdentifier: finalBundleID, appName: wd.app, relativeFrame: relativeFrame, screenIndex: screenIndex, isMinimized: wd.isMinimized, title: wd.title)
    }
    let nextOrderIndex = spaces.count
    let currentSystemUI = SystemUIManager.s.getCurrentSystemUISync()
    return SpaceTable(id: 0, name: name, orderIndex: nextOrderIndex, focus: focus, systemUI: currentSystemUI, screens: screens, windows: windowSnapshots)
  }

  private func getSortedScreens() -> [NSScreen] {
    return NSScreen.screens.sorted { s1, s2 in
      if s1.frame.origin.x != s2.frame.origin.x {
        return s1.frame.origin.x < s2.frame.origin.x
      }
      return s1.frame.origin.y < s2.frame.origin.y
    }
  }

  func updateSpaceOrder(spaces: [SpaceTable]) {
    self.spaces = spaces
    DatabaseManager.s.reorderSpaces(spaces)
  }

  func restoreSpace(_ snapshot: SpaceTable) {
    if snapshot.isLegacyData {
      DispatchQueue.main.async {
        let alert = NSAlert()
        alert.messageText = NSLocalizedString("space.legacy.title", comment: "")
        alert.informativeText = NSLocalizedString("space.legacy.message", comment: "")
        alert.alertStyle = .warning
        alert.addButton(withTitle: NSLocalizedString("system.info.delete", comment: ""))
        alert.addButton(withTitle: NSLocalizedString("system.message.cancel", comment: ""))
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
          DatabaseManager.s.deleteSpace(id: snapshot.id)
        }
      }
      return
    }
    PermissionManager.s.checkAutomationPermission { [weak self] in
      self?.performRestoreSpace(snapshot)
    }
  }

  private func performRestoreSpace(_ snapshot: SpaceTable) {
    SpaceLoaderWin.s.Show()
    SystemUIManager.s.Apply(snapshot.systemUI)
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
      guard let self = self else { return }
      DispatchQueue.global(qos: .userInitiated).async { [weak self] in
        guard let self = self else { return }
        let context = RestorationContext()
        let sortedCurrentScreens = self.getSortedScreens()
        var screenIndexMapping: [Int: Int] = [:]
        var validScreenIndices = Set<Int>()
        var usedCurrentScreenIndices = Set<Int>()
        for screenInfo in snapshot.screens {
          let snapshotIndex = screenInfo.screenIndex
          if snapshotIndex < sortedCurrentScreens.count {
            let currentScreen = sortedCurrentScreens[snapshotIndex]
            if !usedCurrentScreenIndices.contains(snapshotIndex) &&
              currentScreen.frame.size == screenInfo.frame.size {
              validScreenIndices.insert(snapshotIndex)
              screenIndexMapping[snapshotIndex] = snapshotIndex
              usedCurrentScreenIndices.insert(snapshotIndex)
            }
          }
        }
        for screenInfo in snapshot.screens {
          if validScreenIndices.contains(screenInfo.screenIndex) { continue }
          for (currentIndex, currentScreen) in sortedCurrentScreens.enumerated() {
            if usedCurrentScreenIndices.contains(currentIndex) { continue }
            if currentScreen.frame.size == screenInfo.frame.size {
              validScreenIndices.insert(screenInfo.screenIndex)
              screenIndexMapping[screenInfo.screenIndex] = currentIndex
              usedCurrentScreenIndices.insert(currentIndex)
              break
            }
          }
        }
        context.validScreenIndices = validScreenIndices
        context.screenIndexMapping = screenIndexMapping
        context.sortedCurrentScreens = sortedCurrentScreens
        self.handleExistingWindows(mode: SpaceConfig.spaceRestoreMode, snapshot: snapshot, context: context)
        DispatchQueue.main.async { [weak self] in
          guard let self = self else { return }
          let validWindows = snapshot.windows.filter { validScreenIndices.contains($0.screenIndex) }
          let groupedWindows = Dictionary(grouping: validWindows) { $0.bundleIdentifier }
          let group = DispatchGroup()
          for (_, windows) in groupedWindows {
            group.enter()
            self.restoreWindowsSequentially(windows: windows, context: context) {
              group.leave()
            }
          }
          group.notify(queue: .main) {
            SpaceLoaderWin.s.Close()
          }
        }
      }
    }
  }

  private func restoreWindowsSequentially(windows: [WindowSnapshot], context: RestorationContext, completion: @escaping () -> Void) {
    var immediateWindows: [WindowSnapshot] = []
    var asyncWindows: [WindowSnapshot] = []
    let runningApps = NSWorkspace.shared.runningApplications
    for window in windows {
      guard context.validScreenIndices.contains(window.screenIndex) else { continue }
      if window.bundleIdentifier.lowercased() == "com.apple.finder" {
        asyncWindows.append(window)
        continue
      }
      if let app = runningApps.first(where: { $0.bundleIdentifier == window.bundleIdentifier }) {
        let appElement = AXUIElementCreateApplication(app.processIdentifier)
        var windowsValue: AnyObject?
        if AXUIElementCopyAttributeValue(appElement, kAXWindowsAttribute as CFString, &windowsValue) == .success,
           let axWindows = windowsValue as? [AXUIElement], !axWindows.isEmpty {
          immediateWindows.append(window)
        } else {
          asyncWindows.append(window)
        }
      } else {
        asyncWindows.append(window)
      }
    }
    for window in immediateWindows {
      if let app = runningApps.first(where: { $0.bundleIdentifier == window.bundleIdentifier }) {
        _ = moveWindowForApp(app, snapshot: window, context: context)
      }
    }
    var remainingWindows = asyncWindows
    func restoreNext() {
      guard !remainingWindows.isEmpty else {
        completion()
        return
      }
      let window = remainingWindows.removeFirst()
      self.restoreWindow(window, context: context) {
        restoreNext()
      }
    }
    restoreNext()
  }

  private func waitForWindow(app: NSRunningApplication, snapshot: WindowSnapshot, context: RestorationContext, timeout: TimeInterval = 60.0, completion: @escaping (Bool) -> Void) {
    let startTime = Date()
    func check() {
      if app.isTerminated {
        completion(false)
        return
      }
      if moveWindowForApp(app, snapshot: snapshot, context: context) {
        completion(true)
        return
      }
      if Date().timeIntervalSince(startTime) > timeout {
        completion(false)
        return
      }
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
        check()
      }
    }
    check()
  }

  private func restoreWindow(_ snapshot: WindowSnapshot, context: RestorationContext, completion: @escaping () -> Void) {
    guard context.validScreenIndices.contains(snapshot.screenIndex) else {
      completion()
      return
    }
    let runningApps = NSWorkspace.shared.runningApplications
    if let app = runningApps.first(where: { $0.bundleIdentifier == snapshot.bundleIdentifier }) {
      if app.bundleIdentifier?.lowercased() == "com.apple.finder" {
        if !checkAndMoveWindow(app: app, snapshot: snapshot, context: context) {
          let validPaths = snapshot.projectPaths.filter { FileManager.default.fileExists(atPath: $0) }
          if !validPaths.isEmpty {
            for path in validPaths {
              NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: path)
            }
            self.waitForWindow(app: app, snapshot: snapshot, context: context, timeout: 60.0) { success in
              if success {
                completion()
              } else {
                self.attemptWindowRestoration(app: app, snapshot: snapshot, context: context, completion: completion)
              }
            }
          } else {
            attemptWindowRestoration(app: app, snapshot: snapshot, context: context, completion: completion)
          }
        } else {
          completion()
        }
        return
      }
      let appElement = AXUIElementCreateApplication(app.processIdentifier)
      var windowsValue: AnyObject?
      let result = AXUIElementCopyAttributeValue(appElement, kAXWindowsAttribute as CFString, &windowsValue)
      if result == .success, let windows = windowsValue as? [AXUIElement], !windows.isEmpty {
        if !moveWindowForApp(app, snapshot: snapshot, context: context) {
          attemptWindowRestoration(app: app, snapshot: snapshot, context: context, completion: completion)
        } else {
          completion()
        }
      } else {
        let validPaths = snapshot.projectPaths.filter { FileManager.default.fileExists(atPath: $0) }
        if !validPaths.isEmpty, let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: snapshot.bundleIdentifier) {
          let fileURLs = validPaths.map { URL(fileURLWithPath: $0) }
          let config = NSWorkspace.OpenConfiguration()
          config.activates = true
          NSWorkspace.shared.open(fileURLs, withApplicationAt: appURL, configuration: config) { _, _ in
            DispatchQueue.main.async {
              self.waitForWindow(app: app, snapshot: snapshot, context: context, timeout: 60.0) { success in
                if success {
                  completion()
                } else {
                  self.attemptWindowRestoration(app: app, snapshot: snapshot, context: context, completion: completion)
                }
              }
            }
          }
        } else {
          attemptWindowRestoration(app: app, snapshot: snapshot, context: context, completion: completion)
        }
      }
    } else {
      launchApplication(snapshot: snapshot, context: context, completion: completion)
    }
  }

  private func launchApplication(snapshot: WindowSnapshot, context: RestorationContext, completion: @escaping () -> Void) {
    guard let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: snapshot.bundleIdentifier) else {
      completion()
      return
    }
    let config = NSWorkspace.OpenConfiguration()
    config.activates = true
    let validPaths = snapshot.projectPaths.filter { FileManager.default.fileExists(atPath: $0) }
    if !validPaths.isEmpty {
      let fileURLs = validPaths.map { URL(fileURLWithPath: $0) }
      NSWorkspace.shared.open(fileURLs, withApplicationAt: appURL, configuration: config) { app, error in
        if let app = app {
          DispatchQueue.main.async {
            self.waitForWindow(app: app, snapshot: snapshot, context: context, timeout: 60.0) { success in
              if success {
                completion()
              } else {
                self.attemptWindowRestoration(app: app, snapshot: snapshot, context: context, completion: completion)
              }
            }
          }
        } else {
          completion()
        }
      }
    } else {
      NSWorkspace.shared.openApplication(at: appURL, configuration: config) { app, error in
        if let app = app {
          DispatchQueue.main.async {
            self.waitForWindow(app: app, snapshot: snapshot, context: context, timeout: 60.0) { success in
              if success {
                completion()
              } else {
                self.attemptWindowRestoration(app: app, snapshot: snapshot, context: context, completion: completion)
              }
            }
          }
        } else {
          completion()
        }
      }
    }
  }

  @discardableResult
  private func moveWindowForApp(_ app: NSRunningApplication, snapshot: WindowSnapshot, context: RestorationContext) -> Bool {
    let appElement = AXUIElementCreateApplication(app.processIdentifier)
    var windowsValue: AnyObject?
    let result = AXUIElementCopyAttributeValue(appElement, kAXWindowsAttribute as CFString, &windowsValue)
    guard result == .success, let windows = windowsValue as? [AXUIElement] else {
      return false
    }
    var candidateWindows = windows
    if app.bundleIdentifier?.lowercased() == "com.apple.finder" {
      candidateWindows = windows.filter { window in
        var titleValue: AnyObject?
        _ = AXUIElementCopyAttributeValue(window, kAXTitleAttribute as CFString, &titleValue)
        if let title = titleValue as? String, !title.isEmpty {
          return true
        }
        return false
      }
    }
    candidateWindows = candidateWindows.filter { !context.isUsed($0) }
    if candidateWindows.isEmpty {
      return false
    }
    let (position, size) = calculateAbsoluteFrame(snapshot: snapshot, context: context)
    for window in candidateWindows {
      if let snapTitle = snapshot.title, !snapTitle.isEmpty {
        var titleValue: AnyObject?
        if AXUIElementCopyAttributeValue(window, kAXTitleAttribute as CFString, &titleValue) == .success, let title = titleValue as? String, title == snapTitle {
          restoreWindowState(window: window, app: app, snapshot: snapshot)
          applyWindowGeometry(window, position: position, size: size)
          context.markUsed(window)
          return true
        }
      }
    }
    if let firstWindow = candidateWindows.first {
      restoreWindowState(window: firstWindow, app: app, snapshot: snapshot)
      applyWindowGeometry(firstWindow, position: position, size: size)
      context.markUsed(firstWindow)
      return true
    } else {
      return false
    }
  }

  private func restoreWindowState(window: AXUIElement, app: NSRunningApplication, snapshot: WindowSnapshot) {
    if !snapshot.isMinimized {
      var minimizedValue: AnyObject?
      if AXUIElementCopyAttributeValue(window, kAXMinimizedAttribute as CFString, &minimizedValue) == .success, let minimized = minimizedValue as? Bool, minimized {
        let falseValue = false as CFTypeRef
        AXUIElementSetAttributeValue(window, kAXMinimizedAttribute as CFString, falseValue)
      }
      app.activate(options: .activateIgnoringOtherApps)
      AXUIElementPerformAction(window, kAXRaiseAction as CFString)
    }
  }

  private func applyWindowGeometry(_ window: AXUIElement, position: CGPoint, size: CGSize) {
    var currentPosValue: AnyObject?
    var currentSizeValue: AnyObject?
    if AXUIElementCopyAttributeValue(window, kAXPositionAttribute as CFString, &currentPosValue) == .success,
       AXUIElementCopyAttributeValue(window, kAXSizeAttribute as CFString, &currentSizeValue) == .success,
       let posValue = currentPosValue, let sizeValue = currentSizeValue {
      var currentPos = CGPoint.zero
      var currentSize = CGSize.zero
      AXValueGetValue(posValue as! AXValue, .cgPoint, &currentPos)
      AXValueGetValue(sizeValue as! AXValue, .cgSize, &currentSize)
      let tolerance: CGFloat = 5.0
      let positionMatch = abs(currentPos.x - position.x) <= tolerance && abs(currentPos.y - position.y) <= tolerance
      let sizeMatch = abs(currentSize.width - size.width) <= tolerance && abs(currentSize.height - size.height) <= tolerance
      if positionMatch && sizeMatch {
        return
      }
    }
    SwiftManager.s.removeFromMaxList(element: window)
    var pos = position
    var sz = size
    AXUIElementSetAttributeValue(window, kAXPositionAttribute as CFString, AXValueCreate(.cgPoint, &pos)!)
    AXUIElementSetAttributeValue(window, kAXSizeAttribute as CFString, AXValueCreate(.cgSize, &sz)!)
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
      var sz = size
      AXUIElementSetAttributeValue(window, kAXSizeAttribute as CFString, AXValueCreate(.cgSize, &sz)!)
    }
  }

  private func attemptWindowRestoration(app: NSRunningApplication, snapshot: WindowSnapshot, context: RestorationContext, completion: @escaping () -> Void) {
    let strategies: [(String, (NSRunningApplication) -> Void)] = [
      ("Activate", { app in
        app.activate(options: [.activateAllWindows, .activateIgnoringOtherApps])
      }),
      ("AppleScript Reopen", { app in
        guard let bid = app.bundleIdentifier else { return }
        self.runAppleScript(code: "tell application id \"\(bid)\" to reopen\n tell application id \"\(bid)\" to activate")
      }),
      ("CGEvent Cmd+N", { _ in
        self.simulateNewWindow()
      }),
      ("AppleScript Make New Window", { app in
        guard let bid = app.bundleIdentifier else { return }
        if bid.lowercased() == "com.apple.finder" {
          self.runAppleScript(code: "tell application id \"\(bid)\"\n activate\n make new Finder window\n end tell")
        } else {
          self.runAppleScript(code: "tell application id \"\(bid)\"\n activate\n make new window\n end tell")
        }
      }),
      ("System Events Cmd+N", { app in
        guard let bid = app.bundleIdentifier else { return }
        self.runAppleScript(code: """
          tell application id "\(bid)" to activate
          tell application "System Events" to keystroke "n" using command down
        """)
      })
    ]
    executeStrategy(app: app, snapshot: snapshot, strategies: strategies, index: 0, context: context, completion: completion)
  }

  private func executeStrategy(app: NSRunningApplication, snapshot: WindowSnapshot, strategies: [(String, (NSRunningApplication) -> Void)], index: Int, context: RestorationContext, completion: @escaping () -> Void) {
    guard index < strategies.count else {
      completion()
      return
    }
    let (_, action) = strategies[index]
    action(app)
    self.waitForWindow(app: app, snapshot: snapshot, context: context, timeout: 2.0) { [weak self] success in
      guard let self = self else {
        completion()
        return
      }
      if success {
        completion()
      } else {
        self.executeStrategy(app: app, snapshot: snapshot, strategies: strategies, index: index + 1, context: context, completion: completion)
      }
    }
  }

  private func runAppleScript(code: String) {
    var error: NSDictionary?
    if let scriptObject = NSAppleScript(source: code) {
      scriptObject.executeAndReturnError(&error)
    }
  }

  private func checkAndMoveWindow(app: NSRunningApplication, snapshot: WindowSnapshot, context: RestorationContext) -> Bool {
    return moveWindowForApp(app, snapshot: snapshot, context: context)
  }

  private func simulateNewWindow() {
    let source = CGEventSource(stateID: .hidSystemState)
    let cmdDown = CGEvent(keyboardEventSource: source, virtualKey: 0x37, keyDown: true)
    cmdDown?.flags = .maskCommand
    let nDown = CGEvent(keyboardEventSource: source, virtualKey: 0x2D, keyDown: true)
    nDown?.flags = .maskCommand
    let nUp = CGEvent(keyboardEventSource: source, virtualKey: 0x2D, keyDown: false)
    nUp?.flags = .maskCommand
    let cmdUp = CGEvent(keyboardEventSource: source, virtualKey: 0x37, keyDown: false)
    cmdDown?.post(tap: .cgSessionEventTap)
    nDown?.post(tap: .cgSessionEventTap)
    nUp?.post(tap: .cgSessionEventTap)
    cmdUp?.post(tap: .cgSessionEventTap)
  }

  private func calculateRelativeFrame(absoluteFrame: CGRect, screenIndex: Int) -> CGRect {
    let sortedScreens = getSortedScreens()
    guard screenIndex >= 0 && screenIndex < sortedScreens.count else {
      return absoluteFrame
    }
    let screen = sortedScreens[screenIndex]
    let primaryScreenHeight = NSScreen.screens.first?.frame.height ?? screen.frame.height
    let windowCocoaY = primaryScreenHeight - absoluteFrame.origin.y - absoluteFrame.size.height
    let screenFrame = screen.frame
    let relativeX = absoluteFrame.origin.x - screenFrame.origin.x
    let relativeY = windowCocoaY - screenFrame.origin.y
    return CGRect(x: relativeX, y: relativeY, width: absoluteFrame.size.width, height: absoluteFrame.size.height)
  }

  private func calculateAbsoluteFrame(snapshot: WindowSnapshot, context: RestorationContext) -> (position: CGPoint, size: CGSize) {
    guard let currentScreenIndex = context.screenIndexMapping[snapshot.screenIndex], currentScreenIndex >= 0 && currentScreenIndex < context.sortedCurrentScreens.count else {
      return (.zero, .zero)
    }
    let screen = context.sortedCurrentScreens[currentScreenIndex]
    let screenFrame = screen.frame
    let relativeFrame = snapshot.relativeFrame
    let primaryScreenHeight = NSScreen.screens.first?.frame.height ?? screen.frame.height
    let absoluteCocoaX = screenFrame.origin.x + relativeFrame.origin.x
    let absoluteCocoaY = screenFrame.origin.y + relativeFrame.origin.y
    let absoluteQuartzY = primaryScreenHeight - absoluteCocoaY - relativeFrame.size.height
    return (CGPoint(x: absoluteCocoaX, y: absoluteQuartzY), relativeFrame.size)
  }

  private func findScreenIndex(for rect: CGRect) -> Int {
    let sortedScreens = getSortedScreens()
    let primaryScreenHeight = NSScreen.screens.first?.frame.height ?? 0
    let cocoaY = primaryScreenHeight - rect.origin.y - rect.size.height
    let cocoaRect = CGRect(x: rect.origin.x, y: cocoaY, width: rect.size.width, height: rect.size.height)
    var maxArea: CGFloat = 0
    var bestScreenIndex: Int = 0
    for (index, screen) in sortedScreens.enumerated() {
      let intersection = screen.frame.intersection(cocoaRect)
      let area = intersection.width * intersection.height
      if area > maxArea {
        maxArea = area
        bestScreenIndex = index
      }
    }
    return bestScreenIndex
  }

  private func handleExistingWindows(mode: SpaceRestoreMode, snapshot: SpaceTable, context: RestorationContext) {
    DispatchQueue.main.async {
      switch snapshot.focus {
      case .keep:
        break
      case .enable:
        if !FocusConfig.focus {
          FocusConfig.focus = true
          NotificationCenter.default.post(name: NSNotification.Name("FocusConfigChanged"), object: nil)
        }
      case .disable:
        if FocusConfig.focus {
          FocusConfig.focus = false
          NotificationCenter.default.post(name: NSNotification.Name("FocusConfigChanged"), object: nil)
        }
      }
    }
    switch mode {
    case .keep:
      break
    case .minimize:
      minimizeOtherWindows(snapshot: snapshot, context: context)
    case .close:
      closeOtherWindows(snapshot: snapshot, context: context)
    }
  }

  private func minimizeOtherWindows(snapshot: SpaceTable, context: RestorationContext) {
    let snapshotBundleIDs = Set(snapshot.windows.map { $0.bundleIdentifier })
    let validCurrentScreenIndices = Set(context.screenIndexMapping.values)
    let (desktopWindows, _, _) = WindowList.GetList()
    for desktopWindow in desktopWindows {
      var bundleID = desktopWindow.bundleIdentifier
      if bundleID == nil {
        if let app = NSRunningApplication(processIdentifier: desktopWindow.pid) {
          bundleID = app.bundleIdentifier
        }
      }
      guard let bid = bundleID else { continue }
      if bid == Bundle.main.bundleIdentifier { continue }
      if snapshotBundleIDs.contains(bid) { continue }
      let windowScreenIndex = findScreenIndex(for: desktopWindow.bounds)
      if !validCurrentScreenIndices.contains(windowScreenIndex) { continue }
      if SpaceConfig.spaceSkipMinimized && desktopWindow.isMinimized { continue }
      guard let app = NSRunningApplication(processIdentifier: desktopWindow.pid) else { continue }
      let appElement = AXUIElementCreateApplication(app.processIdentifier)
      var windowsValue: AnyObject?
      if AXUIElementCopyAttributeValue(appElement, kAXWindowsAttribute as CFString, &windowsValue) == .success, let axWindows = windowsValue as? [AXUIElement] {
        for axWindow in axWindows {
          var posValue: AnyObject?
          if AXUIElementCopyAttributeValue(axWindow, kAXPositionAttribute as CFString, &posValue) == .success, let pos = posValue {
            var position = CGPoint.zero
            AXValueGetValue(pos as! AXValue, .cgPoint, &position)
            if abs(position.x - desktopWindow.bounds.origin.x) < 5 && abs(position.y - desktopWindow.bounds.origin.y) < 5 {
              AXUIElementSetAttributeValue(axWindow, kAXMinimizedAttribute as CFString, kCFBooleanTrue)
              break
            }
          }
        }
      }
    }
  }

  private func closeOtherWindows(snapshot: SpaceTable, context: RestorationContext) {
    let snapshotBundleIDs = Set(snapshot.windows.map { $0.bundleIdentifier })
    let validCurrentScreenIndices = Set(context.screenIndexMapping.values)
    let (desktopWindows, _, _) = WindowList.GetList()
    for window in desktopWindows {
      var bundleID = window.bundleIdentifier
      if bundleID == nil {
        if let app = NSRunningApplication(processIdentifier: window.pid) {
          bundleID = app.bundleIdentifier
        }
      }
      guard let bid = bundleID else { continue }
      if bid == Bundle.main.bundleIdentifier { continue }
      let windowScreenIndex = findScreenIndex(for: window.bounds)
      if !validCurrentScreenIndices.contains(windowScreenIndex) { continue }
      if !snapshotBundleIDs.contains(bid) {
        SwiftManager.s.CloseWindow(targetWindow: window, mode: .force)
      }
    }
  }
}
