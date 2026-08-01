import SwiftUI

struct SnapshotButton: View {
  let space: SpaceTable
  let isSorting: Bool
  @EnvironmentObject private var tm: LauncherThemeManager
  @ObservedObject private var spaceManager = SpaceManager.s
  @State private var isHovered = false
  @State private var buttonSize: CGSize = .zero
  @State private var showUpdateDialog = false
  @State private var showDeleteAlert = false
  @State private var showDuplicateDialog = false
  @State private var newName = ""
  @State private var focus: SpaceFocusMode = .keep
  @State private var updateSpaceScreen: SpaceScreen = .all

  var body: some View {
    HStack(spacing: 10) {
      VStack(alignment: .leading, spacing: 3) {
        Text(space.name)
          .font(.system(size: tm.currentTheme.textSize + 2, weight: .medium))
          .foregroundColor(tm.currentTheme.linkTextColor)
          .lineLimit(1)
        HStack(spacing: 5) {
          if space.isLegacyData {
            Text("? \(NSLocalizedString("space.button.screens", comment: ""))")
            Text("? \(NSLocalizedString("space.button.apps", comment: ""))")
          } else {
            Text("\(space.screens.count) \(NSLocalizedString("space.button.screens", comment: ""))")
            Text("\(Set(space.windows.map { $0.bundleIdentifier }).count) \(NSLocalizedString("space.button.apps", comment: ""))")
          }
        }
        .font(.system(size: tm.currentTheme.textSize - 1))
        .foregroundColor(tm.currentTheme.linkTextColor.opacity(0.6))
      }
      Spacer()
      if isSorting {
        Image(systemName: "line.3.horizontal")
          .foregroundColor(tm.currentTheme.linkTextColor.opacity(0.5))
          .font(.system(size: tm.currentTheme.textSize))
      }
    }
    .padding(LauncherConfig.spacePadding())
    .background(
      RoundedRectangle(cornerRadius: 8)
        .fill(isHovered ? tm.currentTheme.linkBackgroundColor.opacity(tm.currentTheme.linkBackgroundOpacity) : Color.clear)
    )
    .contentShape(Rectangle())
    .background(
      GeometryReader { geo in
        Color.clear.onAppear { buttonSize = geo.size }
      }
    )
    .onHover { hovering in
      isHovered = hovering
    }
    .gesture(
      isSorting ? nil : DragGesture(minimumDistance: 0)
        .onEnded { value in
          let inBounds = value.location.x >= 0 && value.location.x <= buttonSize.width && value.location.y >= 0 && value.location.y <= buttonSize.height
          guard inBounds else { return }
          LauncherWin.s.Hide(animation: false)
          DispatchQueue.main.async {
            SpaceManager.s.restoreSpace(space)
          }
        }
    )
    .contextMenu {
      Button(action: {
        newName = space.name
        focus = space.focus
        showUpdateDialog = true
      }) {
        Text(LanguageManager.s.localizedString("space.dialog.update"))
      }
      Button(action: {
        newName = space.name
        showDuplicateDialog = true
      }) {
        Text(NSLocalizedString("space.dialog.duplicate", comment: ""))
      }
      Divider()
      Button(action: {
        showDeleteAlert = true
      }) {
        Text(NSLocalizedString("system.info.delete", comment: ""))
      }
    }
    .sheet(isPresented: $showUpdateDialog) {
      SnapshotDialog(
        mode: .update(space),
        name: $newName,
        spaceScreen: $updateSpaceScreen,
        focus: $focus,
        isPresented: $showUpdateDialog,
        onSave: { windows in
          SpaceManager.s.updateSpace(id: space.id, name: newName, focus: focus, windows: windows)
        }
      )
    }
    .sheet(isPresented: $showDuplicateDialog) {
      AddEditDialog(
        mode: .duplicateSpace,
        name: $newName,
        isPresented: $showDuplicateDialog,
        onConfirm: { name in
          SpaceManager.s.duplicateSpace(sourceId: space.id, newName: name)
        }
      )
    }
    .alert(String(format: LanguageManager.s.localizedString("space.dialog.remove.title"), space.name), isPresented: $showDeleteAlert) {
      Button(LanguageManager.s.localizedString("system.message.confirm"), role: .destructive) {
        SpaceManager.s.deleteSpace(id: space.id)
      }
      Button(LanguageManager.s.localizedString("system.message.cancel"), role: .cancel) { }
    }
  }
}
