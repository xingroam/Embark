import SwiftUI

struct ShortcutInfoView: View {
  let shortcut: String
  let description: String
  let color: Color
  let fz: CGFloat

  var body: some View {
    HStack(spacing: 5) {
      ShortcutKeyLabel(text: shortcut, color: color, ph: 6, pv: 2, fz: fz)
      Text(NSLocalizedString("magnet.settings.shortcut_info", comment: "") + description)
        .font(.system(size: fz))
        .foregroundColor(.secondary)
    }
  }
}
