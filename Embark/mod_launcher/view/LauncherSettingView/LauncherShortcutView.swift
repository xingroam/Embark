import SwiftUI

struct LauncherShortcutView: View {
  let color: Color
  let fz: CGFloat

  var body: some View {
    VStack(spacing: 5) {
      HStack(spacing: 5) {
        Image(systemName: "keyboard")
          .foregroundColor(color)
          .font(.system(size: fz))
        Text(NSLocalizedString("launcher.settings.general.shortcut.title", comment: ""))
          .font(.system(size: fz, weight: .medium))
        Spacer()
      }
      HStack(spacing: 5) {
        Text(String(format: NSLocalizedString("launcher.settings.general.shortcut.description", comment: ""), NSLocalizedString("swift.keyboard.title", comment: "")))
          .font(.system(size: fz - 1))
          .foregroundColor(.secondary)
          .frame(maxWidth: .infinity, alignment: .leading)
        Button(action: {
          SwiftSettingWin.s.Show(tab: "keyboard", subTab: EmbarkInfo.name)
        }) {
          Text(NSLocalizedString("launcher.settings.general.shortcut.go_to_settings", comment: ""))
            .font(.system(size: fz - 1, weight: .medium))
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .background(color)
            .cornerRadius(5)
        }
        .buttonStyle(PlainButtonStyle())
      }
    }
    .padding(10)
    .background(color.opacity(0.1))
    .cornerRadius(5)
    .overlay(
      RoundedRectangle(cornerRadius: 5)
        .stroke(color.opacity(0.3), lineWidth: 1)
    )
  }
}
