import SwiftUI

struct LauncherSpaceView: View {
  @EnvironmentObject private var dm: DataManager
  @EnvironmentObject private var tm: LauncherThemeManager
  @StateObject private var languageManager = LanguageManager.s
  @ObservedObject private var spaceManager = SpaceManager.s
  @Binding var showSnapshotAlert: Bool
  @Binding var newSpaceName: String
  @Binding var focus: SpaceFocusMode
  @Binding var spaceScreen: SpaceScreen
  private let controlSize: CGFloat = 34
  private let fontSize: CGFloat = 16
  private let hideOpacity: Double = 0.4
  @State private var showActionMenu = false

  var body: some View {
    VStack(spacing: 15) {
      headerView
      spaceAreaView
    }
  }

  private var headerView: some View {
    HStack(spacing: 15) {
      spaceSortingButton
      Spacer()
      addButton
      actionButton
      spaceButton
    }
  }

  private var spaceAreaView: some View {
    HStack(spacing: 0) {
      if spaceManager.spaces.isEmpty {
        Text(NSLocalizedString("space.settings.snapshots.empty", comment: ""))
          .font(.system(size: tm.currentTheme.textSize))
          .foregroundColor(tm.currentTheme.linkTextColor.opacity(0.7))
          .padding(20)
      } else {
        ScrollView {
          LazyVStack(spacing: 0) {
            ForEach(spaceManager.spaces) { space in
              SnapshotButton(space: space, isSorting: dm.launcherMode == .spaceSorting)
                .onDrag {
                  if dm.launcherMode == .spaceSorting {
                    return NSItemProvider(object: String(space.id) as NSString)
                  } else {
                    return NSItemProvider()
                  }
                }
                .onDrop(of: [.text], delegate: SpaceDropDelegate(item: space, items: $spaceManager.spaces, isSorting: dm.launcherMode == .spaceSorting))
            }
          }
        }
      }
    }
    .frame(width: 500)
    .frame(height: LauncherWin.s.maxHeight)
  }

  private var spaceSortingButton: some View {
    Button(action: {
      dm.changeMode(dm.launcherMode == .space ? .spaceSorting : .space)
    }) {
      ZStack {
        RoundedRectangle(cornerRadius: 8)
          .fill(dm.launcherMode == .spaceSorting ? tm.currentTheme.panelBackgroundColor.opacity(tm.currentTheme.panelBackgroundOpacity + 0.1) : tm.currentTheme.panelBackgroundColor.opacity(tm.currentTheme.panelBackgroundOpacity))
        Image(systemName: dm.launcherMode == .spaceSorting ? "checkmark" : "list.number")
          .foregroundColor(tm.currentTheme.panelTextColor)
          .font(.system(size: fontSize, weight: .medium))
      }
      .frame(width: controlSize, height: controlSize)
      .contentShape(Rectangle())
    }
    .buttonStyle(PlainButtonStyle())
  }

  private var addButton: some View {
    Button(action: {
      PermissionManager.s.checkAutomationPermission(onGranted: {
        newSpaceName = ""
        spaceScreen = .all
        focus = .keep
        showSnapshotAlert = true
      }, onOpenSettings: {
        LauncherWin.s.Hide()
      })
    }) {
      ZStack {
        RoundedRectangle(cornerRadius: 8)
          .fill(tm.currentTheme.panelBackgroundColor.opacity(tm.currentTheme.panelBackgroundOpacity))
        Image(systemName: "plus")
          .foregroundColor(tm.currentTheme.panelTextColor)
          .font(.system(size: fontSize - 2, weight: .medium))
      }
      .contentShape(Rectangle())
      .frame(width: controlSize, height: controlSize)
    }
    .buttonStyle(PlainButtonStyle())
    .opacity(dm.launcherMode == .spaceSorting ? hideOpacity : 1.0)
    .disabled(dm.launcherMode == .spaceSorting)
  }

  private var actionButton: some View {
    Button(action: {
      showActionMenu.toggle()
    }) {
      ZStack {
        RoundedRectangle(cornerRadius: 8)
          .fill(tm.currentTheme.panelBackgroundColor.opacity(tm.currentTheme.panelBackgroundOpacity))
        Image(systemName: "square.stack.3d.up")
          .foregroundColor(tm.currentTheme.panelTextColor)
          .font(.system(size: fontSize - 2, weight: .medium))
      }
      .frame(width: controlSize, height: controlSize)
      .contentShape(Rectangle())
    }
    .buttonStyle(PlainButtonStyle())
    .popover(isPresented: $showActionMenu, arrowEdge: .bottom) {
      VStack(alignment: .leading, spacing: 5) {
        Text(NSLocalizedString("system.systemui.title", comment: ""))
          .font(.caption)
          .foregroundColor(.secondary)
        ForEach(SystemUI.allCases) { option in
          SpaceSettingsMenuItem(text: option.displayName, theme: tm) {
            SystemUIManager.s.Apply(option)
            showActionMenu = false
          }
        }
      }
      .padding(12)
    }
    .opacity(dm.launcherMode == .spaceSorting ? hideOpacity : 1.0)
    .disabled(dm.launcherMode == .spaceSorting)
  }

  private var spaceButton: some View {
    let isDisabled = !LauncherConfig.launcher || dm.launcherMode == .spaceSorting
    return Button(action: {
      dm.changeMode(dm.launcherMode == .space ? .launcher : .space)
    }) {
      ZStack {
        RoundedRectangle(cornerRadius: 8)
          .fill(dm.launcherMode == .space ? tm.currentTheme.panelBackgroundColor.opacity(tm.currentTheme.panelBackgroundOpacity + 0.1) : tm.currentTheme.panelBackgroundColor.opacity(tm.currentTheme.panelBackgroundOpacity))
        Image(systemName: FeatureType.space.icon)
          .foregroundColor(tm.currentTheme.panelTextColor)
          .font(.system(size: fontSize - 2, weight: .medium))
      }
      .contentShape(Rectangle())
      .frame(width: controlSize, height: controlSize)
    }
    .buttonStyle(PlainButtonStyle())
    .opacity(isDisabled ? hideOpacity : 1.0)
    .disabled(isDisabled)
  }
}
