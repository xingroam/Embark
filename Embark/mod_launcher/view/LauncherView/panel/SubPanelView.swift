import SwiftUI

// 子面板视图
struct SubPanelView: View {
  let subPanel: PanelTable
  let parentVisible: Bool
  @EnvironmentObject private var dm: DataManager
  @EnvironmentObject private var dbm: DatabaseManager
  @Environment(\.launcherTheme) private var theme
  @State private var isDragHovered = false
  @State private var showEditNameDialog = false
  @State private var showDeleteConfirmation = false
  @State private var showFileFolderDialog = false
  @State private var fileFolderDialogMode: FileFolderDialogMode = .file
  @State private var showWebDialog = false
  @State private var newName = ""
  private let hideOpacity: Double = 0.4

  var body: some View {
    let headerView = HStack(spacing: 5) {
      Text(subPanel.name)
        .font(.system(size: theme.textSize, weight: theme.panelTextBold ? .bold : .medium))
        .foregroundColor(theme.panelTextColor)
        .padding(.horizontal, theme.panelStretch ? 0 : 8)
        .padding(.vertical, theme.panelStretch ? 0 : 6)
        .background(theme.panelStretch ? Color.clear : theme.panelBackgroundColor.opacity(theme.panelBackgroundOpacity))
        .cornerRadius(theme.panelStretch ? 0 : 8)
        .opacity((subPanel.isVisible && parentVisible) ? 1.0 : hideOpacity)
      Spacer()
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
          Button(subPanel.isVisible ? NSLocalizedString("launcher.panel.settings.invisible", comment: "") : NSLocalizedString("launcher.panel.settings.visible", comment: "")) {
            dm.updatePanelVisible(panelId: subPanel.id, isVisible: !subPanel.isVisible)
          }
          Button(LanguageManager.s.localizedString("launcher.panel.settings.edit_name")) {
            newName = subPanel.name
            showEditNameDialog = true
          }
          Divider()
          Button(LanguageManager.s.localizedString("launcher.panel.settings.remove_panel"), role: .destructive) {
            showDeleteConfirmation = true
          }
        } label: {
          Image(systemName: "gear")
            .foregroundColor(theme.panelTextColor)
            .font(.caption2)
            .padding(3)
            .contentShape(Rectangle())
        }
        .id("subpanel-menu-\(subPanel.id)")
        .buttonStyle(PlainButtonStyle())
        .settingsIconAnimation(dm.launcherMode == .settings, duration: LauncherInfo.animationDuration)
        Image(systemName: "line.3.horizontal")
          .foregroundColor(theme.panelTextColor)
          .font(.caption2)
          .allowsHitTesting(false)
          .settingsIconAnimation(dm.launcherMode == .settings, duration: LauncherInfo.animationDuration)
      }
    }
    .padding(.horizontal, theme.panelStretch ? 8 : 0)
    .padding(.vertical, theme.panelStretch ? 6 : 0)
    .background(theme.panelStretch ? theme.panelBackgroundColor.opacity(theme.panelBackgroundOpacity) : Color.clear)
    .cornerRadius(8)
    .contentShape(Rectangle())
    .backgroundTransitionAnimation(dm.launcherMode == .settings, duration: LauncherInfo.animationDuration)
    let subPanelLinks = dm.getLinks(for: subPanel.id)
    let contentView: some View = {
      if subPanelLinks.isEmpty {
        return AnyView(
          Text(LanguageManager.s.localizedString("launcher.panel.drag.app_hint"))
            .foregroundColor(theme.linkTextColor.opacity(theme.panelBackgroundOpacity + 0.1))
            .font(.system(size: theme.textSize - 2))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onDrop(of: [.text, .fileURL], delegate: SubPanelDropDelegate(
              targetSubPanelId: subPanel.id,
              onHoverChanged: { hovering in
                isDragHovered = hovering
              }
            ))
        )
      } else {
        return AnyView(
          LazyVStack(spacing: 0) {
            ForEach(Array(subPanelLinks.enumerated()), id: \.element.path) { index, app in
              if dm.launcherMode == .settings || app.isVisible {
                LinkButton(app: app, isShowMode: false, isMiniMode: false, isSelected: false, canHide: true)
                  .onDrop(of: [.text, .fileURL], delegate: LinkDropDelegate(
                    targetPanelId: subPanel.id,
                    targetIndex: index,
                    targetOrderIndex: app.orderIndex,
                    onReorder: { fromIndex, toIndex in
                      dm.reorderLinks(in: subPanel.id, from: fromIndex, to: toIndex)
                    },
                    onMoveToPanel: { appPath, targetOrderIndex in
                      dm.moveLink(path: appPath, to: subPanel.id, at: targetOrderIndex + 1)
                      LauncherWin.s.Center()
                    }
                  ))
              }
            }
          }
        )
      }
    }()
    let mainView = VStack(spacing: LauncherConfig.linkPadding()) {
      headerView
        .contentShape(Rectangle())
        .onDrag {
          if dm.launcherMode == .settings {
            let provider = NSItemProvider(object: "SUBPANEL:\(subPanel.id)" as NSString)
            provider.suggestedName = NSLocalizedString("launcher.panel.settings.drag_panel", comment: "")
            return provider
          }
          return NSItemProvider()
        }
        .onDrop(of: [.text, .fileURL], delegate: DropDelegateWithHover(
          originalDelegate: SubPanelDropDelegate(
            targetSubPanelId: subPanel.id,
            onHoverChanged: { hovering in
              isDragHovered = hovering
            }
          ),
          onHoverChanged: { hovering in
            isDragHovered = hovering
          },
          onDragEnded: {
            isDragHovered = false
          }
        ))
      contentView
    }
    .overlay(
      RoundedRectangle(cornerRadius: 5)
        .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [16, 8]))
        .foregroundColor(isDragHovered ? theme.panelBackgroundColor.opacity(theme.panelBackgroundOpacity * 2) : Color.clear)
        .animation(.easeInOut(duration: 0.2), value: isDragHovered)
    )
    .padding(.top, LauncherConfig.linkPadding())
    .sheet(isPresented: $showFileFolderDialog) {
      FileFolderDialog(
        mode: fileFolderDialogMode,
        isPresented: $showFileFolderDialog,
        onAdd: { path in
          if fileFolderDialogMode == .file {
            dm.addFileLink(path: path, panelId: subPanel.id)
          } else {
            dm.addFolderLink(path: path, panelId: subPanel.id)
          }
        }
      )
    }
    .sheet(isPresented: $showWebDialog) {
      WebDialog(panelId: subPanel.id, isPresented: $showWebDialog)
    }
    .sheet(isPresented: $showEditNameDialog) {
      AddEditDialog(
        mode: .editPanel,
        name: $newName,
        isPresented: $showEditNameDialog,
        onConfirm: { name in
          if !name.isEmpty {
            dbm.updatePanelName(panelId: subPanel.id, newName: name)
            dbm.loadPanelsAsync { panels in
              dbm.updatePanels(panels)
            }
          }
        }
      )
    }
    .alert(String(format: LanguageManager.s.localizedString("launcher.panel.dialog.remove.title"), subPanel.name), isPresented: $showDeleteConfirmation) {
      Button(LanguageManager.s.localizedString("system.message.confirm"), role: .destructive) {
        dm.removePanel(panelId: subPanel.id)
      }
      Button(LanguageManager.s.localizedString("system.message.cancel"), role: .cancel) { }
    }
    return mainView
  }
}
