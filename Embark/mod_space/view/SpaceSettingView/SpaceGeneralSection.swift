import SwiftUI

struct SpaceGeneralSection: View {
  let fz: CGFloat
  @Binding var restoreMode: SpaceRestoreMode
  @Binding var spaceSkipMinimized: Bool
  let shortcutKey: CGKeyCode
  let shortcutFlags: CGEventFlags
  let onShortcutTap: () -> Void

  var body: some View {
    VStack(spacing: 10) {
      ShortcutButton(
        keyCode: shortcutKey,
        flags: shortcutFlags,
        onTap: onShortcutTap
      )
      Text(NSLocalizedString("space.settings.shortcut.description", comment: ""))
        .font(.system(size: fz - 1))
        .foregroundColor(.secondary)
        .lineLimit(nil)
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)
      HStack(spacing: 5) {
        Text(NSLocalizedString("space.settings.restore.mode", comment: ""))
          .font(.system(size: fz, weight: .regular))
        Spacer()
        Picker("", selection: $restoreMode) {
          ForEach(SpaceRestoreMode.allCases) { mode in
            Text(mode.displayName).tag(mode)
          }
        }
        .pickerStyle(MenuPickerStyle())
        .fixedSize(horizontal: true, vertical: false)
        .onChange(of: restoreMode) { newValue in
          SpaceConfig.spaceRestoreMode = newValue
        }
      }
      HStack(spacing: 5) {
        Text(NSLocalizedString("space.settings.skip_minimized", comment: ""))
          .font(.system(size: fz))
        Spacer()
        Toggle("", isOn: $spaceSkipMinimized)
          .sectionToggle()
          .onChange(of: spaceSkipMinimized) { newValue in
            SpaceConfig.spaceSkipMinimized = newValue
          }
      }
    }
    .cardStyle()
  }
}
