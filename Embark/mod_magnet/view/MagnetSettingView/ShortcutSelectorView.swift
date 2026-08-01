import SwiftUI

struct ShortcutSelectorView: View {
  @Binding var shortcut: MagnetShortcut
  let color: Color
  let fz: CGFloat
  let onShortcutChanged: ((MagnetShortcut, MagnetShortcut) -> Void)?

  var body: some View {
    HStack(spacing: 10) {
      ForEach(MagnetShortcut.allCases, id: \.self) { s in
        Button(action: {
          let oldShortcut = shortcut
          shortcut = s
          onShortcutChanged?(oldShortcut, s)
        }) {
          ShortcutButtonLabel(text: s.displayName, selected: shortcut == s, color: color, fz: fz)
        }
        .buttonStyle(PlainButtonStyle())
      }
    }
  }
}
