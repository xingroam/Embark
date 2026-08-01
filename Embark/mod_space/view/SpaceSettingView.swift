import SwiftUI

struct SpaceSettingView: View {
  @StateObject private var manager = SpaceManager.s
  @State private var spaceEnabled: Bool = SpaceConfig.space
  @State private var spaceShortcutKey: CGKeyCode = SpaceConfig.spaceShortcutKey
  @State private var spaceShortcutFlags: CGEventFlags = SpaceConfig.spaceShortcutFlags
  @State private var restoreMode: SpaceRestoreMode = SpaceConfig.spaceRestoreMode
  @State private var spaceSkipMinimized: Bool = SpaceConfig.spaceSkipMinimized
  @State private var showShortcutDialog = false
  @State private var spaceScreen: SpaceScreen = .all
  @State private var deletingSnap: SpaceTable?
  @State private var showingNameAlert = false
  @State private var newSpaceName = ""
  @State private var focus: SpaceFocusMode = .keep
  @State private var showDeleteAlert = false
  private let fz: CGFloat = 12

  var body: some View {
    VStack(spacing: 10) {
      HStack(spacing: 5) {
        Text(FeatureType.space.title)
          .font(.system(size: fz + 1, weight: .medium))
        Spacer()
        Toggle("", isOn: $spaceEnabled)
          .toggleStyle(SwitchToggleStyle())
          .scaleEffect(0.8)
          .offset(x: 5)
          .onChange(of: spaceEnabled) { newValue in
            SpaceConfig.space = newValue
            NotificationCenter.default.post(name: NSNotification.Name("SpaceConfigChanged"), object: nil)
          }
      }
      VStack(spacing: 10) {
        SpaceGeneralSection(
          fz: fz,
          restoreMode: $restoreMode,
          spaceSkipMinimized: $spaceSkipMinimized,
          shortcutKey: spaceShortcutKey,
          shortcutFlags: spaceShortcutFlags,
          onShortcutTap: { showShortcutDialog = true }
        )
        SpaceTablesSection(
          fz: fz,
          sm: manager,
          spaceScreen: $spaceScreen,
          focus: $focus,
          deletingSnap: $deletingSnap,
          newSpaceName: $newSpaceName,
          showingNameAlert: $showingNameAlert,
          showDeleteAlert: $showDeleteAlert
        )
      }
      .disabledOverlay(isDisabled: !spaceEnabled, isLocked: false)
    }
    .padding(15)
    .frame(width: 460)
    .background(BlurredBackground(material: .underWindowBackground, blendingMode: .behindWindow, blur: 1.0))
    .sheet(isPresented: $showingNameAlert) {
      SnapshotDialog(mode: .new, name: $newSpaceName, spaceScreen: $spaceScreen, focus: $focus, isPresented: $showingNameAlert) { windows in
        manager.saveSpace(name: newSpaceName, scope: spaceScreen, focus: focus, windows: windows)
      }
    }
    .sheet(isPresented: $showShortcutDialog) {
      ShortcutDialog(
        title: NSLocalizedString("system.shortcut.dialog.title", comment: ""),
        isPresented: $showShortcutDialog,
        shortcutKey: $spaceShortcutKey,
        shortcutFlags: $spaceShortcutFlags
      )
    }
    .onChange(of: spaceShortcutKey) { newValue in
      SpaceConfig.spaceShortcutKey = newValue
      NotificationCenter.default.post(name: NSNotification.Name("SpaceConfigChanged"), object: nil)
    }
    .onChange(of: spaceShortcutFlags) { newValue in
      SpaceConfig.spaceShortcutFlags = newValue
      NotificationCenter.default.post(name: NSNotification.Name("SpaceConfigChanged"), object: nil)
    }
    .alert(String(format: LanguageManager.s.localizedString("space.dialog.remove.title"), deletingSnap?.name ?? ""), isPresented: $showDeleteAlert) {
      Button(LanguageManager.s.localizedString("system.message.confirm"), role: .destructive) {
        if let space = deletingSnap {
          manager.deleteSpace(id: space.id)
        }
        deletingSnap = nil
      }
      Button(LanguageManager.s.localizedString("system.message.cancel"), role: .cancel) { }
    }
  }
}
