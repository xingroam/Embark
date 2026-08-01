import SwiftUI

struct MagnetResizeSection: View {
  let color: Color
  let fz: CGFloat
  @Binding var magnetDragShortcut: MagnetShortcut
  @Binding var magnetResizeShortcut: MagnetShortcut

  var body: some View {
    VStack(spacing: 10) {
      HStack(spacing: 5) {
        Text(NSLocalizedString("magnet.settings.magnet_resize.title", comment: ""))
          .font(.system(size: fz + 1, weight: .medium))
        Spacer()
      }
      VStack(spacing: 10) {
        ShortcutSelectorView(
          shortcut: $magnetResizeShortcut,
          color: color,
          fz: fz - 1,
          onShortcutChanged: { oldShortcut, newShortcut in
            MagnetConfig.magnetResizeShortcut = newShortcut
            if magnetDragShortcut.rawValue == newShortcut.rawValue {
              magnetDragShortcut = oldShortcut
              MagnetConfig.magnetDragShortcut = oldShortcut
            }
            NotificationCenter.default.post(name: NSNotification.Name("MagnetConfigChanged"), object: nil)
          }
        )
        ShortcutInfoView(
          shortcut: magnetResizeShortcut.displayName,
          description: NSLocalizedString("magnet.settings.magnet_resize.description", comment: ""),
          color: color,
          fz: fz - 1,
        )
      }
      .cardStyle()
    }
  }
}
