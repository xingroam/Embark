import SwiftUI

struct LinkButton: View {
  let app: LinkData
  let isShowMode: Bool
  let isMiniMode: Bool
  let isSelected: Bool
  let canHide: Bool
  @EnvironmentObject private var dm: DataManager
  @State private var isHovered = false
  @State private var showShortcutDialog = false
  @State private var showCustomNameDialog = false
  @State private var showEditWebLinkDialog = false
  @State private var newCustomName = ""
  @State private var shortcutKey: CGKeyCode = .disabled
  @State private var shortcutFlags: CGEventFlags = .disabled
  @Environment(\.launcherTheme) private var theme
  private let hideOpacity: Double = 0.4

  private var isNewlyAdded: Bool {
    dm.isNewlyAdded(path: app.path)
  }

  private var isRecentlyMoved: Bool {
    dm.isRecentlyMoved(path: app.path)
  }

  init(app: LinkData, isShowMode: Bool, isMiniMode: Bool, isSelected: Bool, canHide: Bool = false) {
    self.app = app
    self.isShowMode = isShowMode
    self.isMiniMode = isMiniMode
    self.isSelected = isSelected
    self.canHide = canHide
  }

  var body: some View {
    let contentView = HStack(spacing: 5) {
      if let icon = dm.getLinkIcon(linkPath: app.path) {
        Image(nsImage: icon)
          .resizable()
          .aspectRatio(contentMode: .fit)
          .frame(width: isMiniMode ? LauncherInfo.iconMinSize : theme.linkIconSize, height: isMiniMode ? LauncherInfo.iconMinSize : theme.linkIconSize)
          .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 0)
          .scaleEffect(app.linkType == .application ? 1.0 : (app.linkType == .web ? 0.8 : 0.86))
      } else if app.linkType == .web, let iconData = app.iconData, let nsImage = NSImage(data: iconData) {
        Image(nsImage: nsImage)
          .resizable()
          .aspectRatio(contentMode: .fit)
          .frame(width: isMiniMode ? LauncherInfo.iconMinSize : theme.linkIconSize, height: isMiniMode ? LauncherInfo.iconMinSize : theme.linkIconSize)
          .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 0)
          .scaleEffect(0.8)
      } else {
        ZStack {
          Image(systemName: app.linkType.iconName)
            .foregroundColor(.secondary.opacity(app.linkType == .web ? 1.0 : 0.1))
            .font(.system(size: (isMiniMode ? LauncherInfo.iconMinSize : theme.linkIconSize) * (app.linkType == .web ? 0.86 : 0.9)))
        }
        .frame(width: isMiniMode ? LauncherInfo.iconMinSize : theme.linkIconSize, height: isMiniMode ? LauncherInfo.iconMinSize : theme.linkIconSize)
      }
      LinkTextContent(app: app, theme: theme)
      Spacer()
      if dm.launcherMode == .settings {
        Image(systemName: "line.3.horizontal")
          .foregroundColor(theme.linkTextColor)
          .font(.caption2)
          .allowsHitTesting(false)
      }
    }
    .padding(LauncherConfig.linkPadding())
    .background(
      ZStack {
        if isSelected {
          RoundedRectangle(cornerRadius: 8)
            .fill(theme.linkBackgroundColor.opacity(theme.linkBackgroundOpacity / 2))
          RoundedRectangle(cornerRadius: 8)
            .strokeBorder(style: StrokeStyle(lineWidth: 4, dash: [16, 8]))
            .foregroundColor(theme.linkBackgroundColor.opacity(theme.linkBackgroundOpacity * 2))
        } else if isNewlyAdded || isRecentlyMoved {
          RoundedRectangle(cornerRadius: 8)
            .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [16, 8]))
            .foregroundColor(theme.linkBackgroundColor.opacity(theme.linkBackgroundOpacity * 2))
            .opacity((isNewlyAdded || isRecentlyMoved) ? 1.0 : 0.0)
            .animation(.easeInOut(duration: LauncherInfo.addLinkDuration), value: isNewlyAdded)
            .animation(.easeInOut(duration: LauncherInfo.addLinkDuration), value: isRecentlyMoved)
        } else {
          RoundedRectangle(cornerRadius: 8)
            .fill(isHovered && dm.launcherMode != .settings ? theme.linkBackgroundColor.opacity(theme.linkBackgroundOpacity) : Color.clear)
        }
      }
    )
    Group {
      if dm.launcherMode == .settings {
        contentView
          .contentShape(Rectangle())
          .opacity(app.isVisible ? 1.0 : hideOpacity)
          .onDrag {
            dm.setDraggingState(true)
            let dragData = "APP:\(app.panelId):\(app.path)"
            let provider = NSItemProvider(object: dragData as NSString)
            return provider
          }
      } else {
        contentView
          .contentShape(Rectangle())
          .opacity(app.isVisible ? 1.0 : hideOpacity)
          .onTapGesture {
            LauncherWin.s.Hide()
            Task {
              _ = await dm.launchLinkWithValidation(path: app.path, linkName: app.name)
            }
          }
      }
    }
    .onHover { hovering in
      if dm.launcherMode != .settings {
        isHovered = hovering
      }
    }
    .contextMenu {
      Button(NSLocalizedString("launcher.link.context.open_directory", comment: "")) {
        openDirectory()
      }
      Button(NSLocalizedString("launcher.link.context.bind_shortcut", comment: "")) {
        showShortcutDialog = true
      }
      if isShowMode {
        if app.panelId == dm.APPS_PANEL_ID {
          Divider()
          Menu(NSLocalizedString("launcher.link.context.add_to_panel", comment: "")) {
            ForEach(getAllPanelsForMenu(), id: \.panel.id) { item in
              Button(item.displayName) {
                dm.moveLink(path: app.path, to: item.panel.id)
              }
            }
          }
        }
      } else {
        if app.linkType != .web {
          Button(NSLocalizedString("launcher.link.context.custom_name", comment: "")) {
            newCustomName = app.title ?? ""
            showCustomNameDialog = true
          }
        }
        if canHide {
          Button(app.isVisible ? NSLocalizedString("launcher.link.context.invisible", comment: "") : NSLocalizedString("launcher.link.context.visible", comment: "")) {
            dm.updateLinkVisible(linkPath: app.path, isVisible: !app.isVisible)
          }
        }
        if app.linkType == .web {
          Button(NSLocalizedString("launcher.link.context.settings", comment: "")) {
            showEditWebLinkDialog = true
          }
        }
        Divider()
        Button(NSLocalizedString("launcher.link.context.remove", comment: ""), role: .destructive) {
          removeLink()
        }
      }
    }
    .id("contextMenu-\(app.path)")
    .sheet(isPresented: $showShortcutDialog) {
      ShortcutDialog(
        title: NSLocalizedString("launcher.shortcut.dialog.title", comment: ""),
        description: String(format: NSLocalizedString("launcher.shortcut.dialog.description", comment: ""), app.name),
        isPresented: $showShortcutDialog,
        shortcutKey: $shortcutKey,
        shortcutFlags: $shortcutFlags
      )
    }
    .sheet(isPresented: $showCustomNameDialog) {
      AddEditDialog(
        mode: .editLink,
        name: $newCustomName,
        isPresented: $showCustomNameDialog,
        onConfirm: { name in
          let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
          dm.updateLinkTitle(linkPath: app.path, title: trimmedName.isEmpty ? nil : trimmedName)
        }
      )
    }
    .sheet(isPresented: $showEditWebLinkDialog) {
      WebDialog(panelId: app.panelId, isPresented: $showEditWebLinkDialog, editingLink: app)
    }
    .onAppear {
      loadShortcut()
    }
    .onChange(of: shortcutKey) { _ in
      saveShortcutToDatabase()
    }
    .onChange(of: shortcutFlags) { _ in
      saveShortcutToDatabase()
    }
  }

  private func loadShortcut() {
    if let shortcut = app.shortcut {
      shortcutKey = shortcut.keyCode
      shortcutFlags = shortcut.flags
    } else {
      shortcutKey = .disabled
      shortcutFlags = .disabled
    }
  }

  private func saveShortcutToDatabase() {
    let currentKeyCode = app.shortcut?.keyCode ?? .disabled
    let currentFlags = app.shortcut?.flags ?? .disabled
    if shortcutKey == currentKeyCode && shortcutFlags == currentFlags {
      return
    }
    if shortcutKey != .disabled {
      dm.setLinkShortcut(linkPath: app.path, keyCode: shortcutKey, flags: shortcutFlags, linkType: app.linkType)
    } else {
      dm.setLinkShortcut(linkPath: app.path, keyCode: nil, flags: nil, linkType: app.linkType)
    }
  }

  private func openDirectory() {
    LauncherWin.s.Hide()
    let appURL = URL(fileURLWithPath: app.path)
    let parentURL = appURL.deletingLastPathComponent()
    NSWorkspace.shared.open(parentURL)
  }

  private func removeLink() {
    switch app.linkType {
    case .application:
      if dm.launcherMode == .settings {
        if LaunchManager.s.isAppExists(appPath: app.path) {
          dm.moveLink(path: app.path, to: dm.APPS_PANEL_ID)
        } else {
          dm.removeLink(path: app.path)
        }
      } else {
        dm.removeLink(path: app.path)
      }
    case .folder:
      dm.removeLink(path: app.path)
    case .file:
      dm.removeLink(path: app.path)
    case .web:
      dm.removeLink(path: app.path)
    }
  }

  private struct PanelMenuItem {
    let panel: PanelTable
    let displayName: String
  }

  private func getAllPanelsForMenu() -> [PanelMenuItem] {
    let panels = DatabaseManager.s.panels
    let mainPanels = panels.filter { $0.parentId == nil || $0.parentId == 0 }.sorted { $0.orderIndex < $1.orderIndex }
    var result: [PanelMenuItem] = []
    for mainPanel in mainPanels {
      result.append(PanelMenuItem(panel: mainPanel, displayName: mainPanel.name))
      let subPanels = panels.filter { $0.parentId == mainPanel.id }.sorted { $0.orderIndex < $1.orderIndex }
      for subPanel in subPanels {
        result.append(PanelMenuItem(panel: subPanel, displayName: subPanel.name))
      }
    }
    return result
  }
}
