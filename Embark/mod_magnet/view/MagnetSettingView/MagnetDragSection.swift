import SwiftUI

struct MagnetDragSection: View {
  let color: Color
  let fz: CGFloat
  @Binding var magnetDragShortcut: MagnetShortcut
  @Binding var magnetResizeShortcut: MagnetShortcut

  var body: some View {
    VStack(spacing: 10) {
      HStack(spacing: 5) {
        Text(NSLocalizedString("magnet.settings.magnet_drag.title", comment: ""))
          .font(.system(size: fz + 1, weight: .medium))
        Spacer()
      }
      VStack(spacing: 10) {
        ShortcutSelectorView(
          shortcut: $magnetDragShortcut,
          color: color,
          fz: fz - 1,
          onShortcutChanged: { oldShortcut, newShortcut in
            MagnetConfig.magnetDragShortcut = newShortcut
            if magnetResizeShortcut.rawValue == newShortcut.rawValue {
              magnetResizeShortcut = oldShortcut
              MagnetConfig.magnetResizeShortcut = oldShortcut
            }
            NotificationCenter.default.post(name: NSNotification.Name("MagnetConfigChanged"), object: nil)
          }
        )
        ShortcutInfoView(
          shortcut: magnetDragShortcut.displayName,
          description: NSLocalizedString("magnet.settings.magnet_drag.description", comment: ""),
          color: color,
          fz: fz - 1,
        )
      }
      .cardStyle()
    }
  }
}
