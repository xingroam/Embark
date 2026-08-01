import SwiftUI

// 主面板视图
struct MainPanelView: View {
  let panel: PanelTable
  @EnvironmentObject private var dm: DataManager
  @EnvironmentObject private var dbm: DatabaseManager
  @Environment(\.launcherTheme) private var theme
  @State private var showSubPanelDialog = false
  @State private var newSubPanelName = ""
  @State private var showEditNameDialog = false
  @State private var showDeleteConfirmation = false
  @State private var showWebDialog = false
  @State private var isDragHovered = false
  @State private var isDragging = false
  @State private var showDragHint = false
  @State private var showFileFolderDialog = false
  @State private var fileFolderDialogMode: FileFolderDialogMode = .file
  @State private var showPanelWidthDialog = false
  @State private var newName = ""
  private let hideOpacity: Double = 0.4

  var body: some View {
    VStack(spacing: LauncherConfig.linkPadding()) {
      HStack(spacing: 5) {
        Text(panel.name)
          .font(.system(size: theme.textSize, weight: theme.panelTextBold ? .bold : .medium))
          .foregroundColor(theme.panelTextColor)
          .padding(.horizontal, theme.panelStretch ? 0 : 8)
          .padding(.vertical, theme.panelStretch ? 0 : 6)
          .background(theme.panelStretch ? Color.clear : theme.panelBackgroundColor.opacity(theme.panelBackgroundOpacity))
          .cornerRadius(theme.panelStretch ? 0 : 8)
          .opacity(panel.isVisible ? 1.0 : hideOpacity)
        Spacer()
        if dm.launcherMode == .settings {
          Button(action: {
            showSubPanelDialog = true
          }) {
            Image(systemName: "plus.rectangle.on.rectangle")
              .foregroundColor(theme.panelTextColor)
              .font(.caption2)
              .padding(3)
              .contentShape(Rectangle())
          }
          .buttonStyle(PlainButtonStyle())
          .settingsIconAnimation(dm.launcherMode == .settings, duration: LauncherInfo.animationDuration)
        }
        if dm.launcherMode == .settings {
          Menu {
            Button(NSLocalizedString("launcher.panel.settings.add_folder", comment: "")) {
              fileFolderDialogMode = .folder
              showFileFolderDialog = true
            }
            Button(NSLocalizedString("launcher.panel.settings.add_file", comment: "")) {
              fileFolderDialogMode = .file
              showFileFolderDialog = true
            }
            Button(NSLocalizedString("launcher.panel.settings.add_web", comment: "")) {
              showWebDialog = true
            }
            Divider()
            Button(panel.isVisible ? NSLocalizedString("launcher.panel.settings.invisible", comment: "") : NSLocalizedString("launcher.panel.settings.visible", comment: "")) {
              dm.updatePanelVisible(panelId: panel.id, isVisible: !panel.isVisible)
            }
            Button(NSLocalizedString("launcher.panel.settings.edit_name", comment: "")) {
              newName = panel.name
              showEditNameDialog = true
            }
            Button(NSLocalizedString("launcher.panel.settings.custom_width", comment: "")) {
              showPanelWidthDialog = true
            }
            Divider()
            Button(NSLocalizedString("launcher.panel.settings.remove_panel", comment: ""), role: .destructive) {
              showDeleteConfirmation = true
            }
          } label: {
            Image(systemName: "gear")
              .foregroundColor(theme.panelTextColor)
              .font(.caption2)
              .padding(3)
              .contentShape(Rectangle())
          }
          .id("panel-menu-\(panel.name)")
          .buttonStyle(PlainButtonStyle())
          .settingsIconAnimation(dm.launcherMode == .settings, duration: LauncherInfo.animationDuration)
          Image(systemName: "line.3.horizontal")
            .foregroundColor(theme.panelTextColor)
            .font(.caption2)
            .padding(3)
            .allowsHitTesting(false)
            .settingsIconAnimation(dm.launcherMode == .settings, duration: LauncherInfo.animationDuration)
        }
      }
      .padding(.horizontal, theme.panelStretch ? 8 : 0)
      .padding(.vertical, theme.panelStretch ? 6 : 0)
      .background(theme.panelStretch ? theme.panelBackgroundColor.opacity(theme.panelBackgroundOpacity) : Color.clear)
      .cornerRadius(8)
      .contentShape(Rectangle())
      .onDrag {
        if dm.launcherMode == .settings {
          isDragging = true
          let provider = NSItemProvider(object: "PANEL:\(panel.id)" as NSString)
          provider.suggestedName = NSLocalizedString("launcher.panel.settings.drag_panel", comment: "")
          isDragging = false
          return provider
        }
        return NSItemProvider()
      }
      .onDrop(of: [.text, .fileURL], delegate: DropDelegateWithHover(
        originalDelegate: MainPanelDropDelegate(panelId: panel.id),
        onHoverChanged: { hovering in
          isDragHovered = hovering
        },
        onDragEnded: {
          isDragging = false
          isDragHovered = false
        }
      ))
      .allowsHitTesting(dm.launcherMode == .settings)
      .backgroundTransitionAnimation(dm.launcherMode == .settings, duration: LauncherInfo.animationDuration)
      VStack(spacing: 0) {
        let panelLinks = dm.getLinks(for: panel.id)
        if panelLinks.isEmpty {
          Text(LanguageManager.s.localizedString("launcher.panel.drag.app_hint"))
            .font(.caption2)
            .foregroundColor(LauncherConfig.launcherLinkTextColor.opacity(LauncherConfig.getPanelOpacity(baseDepth: 0.1, offset: 0.2)))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onDrop(of: [.text, .fileURL], delegate: MainPanelDropDelegate(panelId: panel.id))
        } else {
          LazyVStack(spacing: 0) {
            ForEach(Array(panelLinks.enumerated()), id: \.element.path) { index, app in
              if dm.launcherMode == .settings || app.isVisible {
                LinkButton(app: app, isShowMode: false, isMiniMode: false, isSelected: false, canHide: true)
                  .onDrop(of: [.text, .fileURL], delegate: LinkDropDelegate(
                    targetPanelId: panel.id,
                    targetIndex: index,
                    targetOrderIndex: app.orderIndex,
                    onReorder: { fromIndex, toIndex in
                      dm.reorderLinks(in: panel.id, from: fromIndex, to: toIndex)
                    },
                    onMoveToPanel: { appPath, targetOrderIndex in
                      dm.moveLink(path: appPath, to: panel.id, at: targetOrderIndex + 1)
                      LauncherWin.s.Center()
                    }
                  ))
              }
            }
          }
        }
        let subPanels = dm.getSubPanels(for: panel.id)
        if !subPanels.isEmpty {
          ForEach(subPanels, id: \.id) { subPanel in
            if dm.launcherMode == .settings || subPanel.isVisible {
              SubPanelView(subPanel: subPanel, parentVisible: panel.isVisible)
            }
          }
        }
      }
    }
    .frame(width: getPanelWidth())
    .frame(minHeight: 50)
    .background(
      GeometryReader { geometry in
        Color.clear
          .preference(key: PanelHeightPreferenceKey.self, value: [panel.id: geometry.size.height])
      }
    )
    .background(
      RoundedRectangle(cornerRadius: 5)
        .fill(Color.clear)
        .overlay(
          RoundedRectangle(cornerRadius: 5)
            .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [16, 8]))
            .foregroundColor(isDragHovered ? theme.panelBackgroundColor.opacity(theme.panelBackgroundOpacity * 2) : Color.clear)
            .animation(.easeInOut(duration: 0.2), value: isDragHovered)
        )
    )
    .animation(.easeInOut(duration: 0.2), value: isDragHovered)
    .opacity(isDragging ? 0.7 : 1.0)
    .animation(.easeInOut(duration: 0.2), value: isDragging)
    .onHover { hovering in
      withAnimation(.easeInOut(duration: 0.3)) {
        showDragHint = hovering
      }
    }
    .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("LauncherPanelWidthChanged"))) { _ in
      LauncherWin.s.Center(wait: true)
    }
    .sheet(isPresented: $showFileFolderDialog) {
      FileFolderDialog(
        mode: fileFolderDialogMode,
        isPresented: $showFileFolderDialog,
        onAdd: { path in
          if fileFolderDialogMode == .file {
            dm.addFileLink(path: path, panelId: panel.id)
          } else {
            dm.addFolderLink(path: path, panelId: panel.id)
          }
        }
      )
    }
    .sheet(isPresented: $showPanelWidthDialog) {
      PanelWidthDialog(
        panelId: panel.id,
        panelName: panel.name,
        currentWidth: dm.getMainPanels().first(where: { $0.id == panel.id })?.panelWidth ?? dm.getSubPanels(for: panel.id).first?.panelWidth,
        isPresented: $showPanelWidthDialog
      )
    }
    .sheet(isPresented: $showWebDialog) {
      WebDialog(panelId: panel.id, isPresented: $showWebDialog)
    }
    .sheet(isPresented: $showSubPanelDialog) {
      AddEditDialog(
        mode: .addSubPanel,
        name: $newSubPanelName,
        isPresented: $showSubPanelDialog,
        onConfirm: { name in
          _ = dm.addSubPanel(name: name, to: panel.id)
          newSubPanelName = ""
        }
      )
    }
    .sheet(isPresented: $showEditNameDialog) {
      AddEditDialog(
        mode: .editPanel,
        name: $newName,
        isPresented: $showEditNameDialog,
        onConfirm: { name in
          if !name.isEmpty {
            dbm.updatePanelName(panelId: panel.id, newName: name)
            dbm.loadPanelsAsync { panels in
              dbm.updatePanels(panels)
            }
          }
        }
      )
    }
    .alert(String(format: LanguageManager.s.localizedString("launcher.panel.dialog.remove.title"), panel.name), isPresented: $showDeleteConfirmation) {
      Button(LanguageManager.s.localizedString("system.message.confirm"), role: .destructive) {
        dm.removePanel(panelId: panel.id)
      }
      Button(LanguageManager.s.localizedString("system.message.cancel"), role: .cancel) { }
    }
  }

  private func getPanelWidth() -> CGFloat {
    if let panel = dm.getMainPanels().first(where: { $0.id == panel.id }) ?? dm.getSubPanels(for: panel.id).first(where: { $0.id == panel.id }), let customWidth = panel.panelWidth {
      return customWidth
    }
    if dm.launcherMode == .settings {
      return theme.panelWidth + LauncherInfo.settingModeAddWidth
    }
    return theme.panelWidth
  }
}
