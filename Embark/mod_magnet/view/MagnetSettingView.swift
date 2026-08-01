import SwiftUI

struct MagnetSettingView: View {
  @State private var magnet: Bool = MagnetConfig.magnet
  @State private var magnetDragShortcut: MagnetShortcut = MagnetConfig.magnetDragShortcut
  @State private var magnetResizeShortcut: MagnetShortcut = MagnetConfig.magnetResizeShortcut
  @State private var isMagnet3x2: Bool = MagnetConfig.magnet3x2
  @State private var isMagnet6x6: Bool = MagnetConfig.magnet6x6
  @State private var isMagnet8x8: Bool = MagnetConfig.magnet8x8
  @State private var isMagnet10x10: Bool = MagnetConfig.magnet10x10
  @State private var isMagnet12x12: Bool = MagnetConfig.magnet12x12
  @State private var magnetTip: Bool = MagnetConfig.magnetTip
  private let color1: Color = .blue
  private let color2: Color = .green
  private let color3: Color = .orange
  private let color4: Color = .purple
  private let color5: Color = .indigo
  private let color6: Color = .red
  private let fz: CGFloat = 12

  var body: some View {
    VStack(spacing: 10) {
      HStack(spacing: 5) {
        Text(FeatureType.magnet.title)
          .font(.system(size: fz + 1, weight: .medium))
        Spacer()
        Toggle("", isOn: $magnet)
          .toggleStyle(SwitchToggleStyle())
          .scaleEffect(0.8)
          .offset(x: 5)
          .onChange(of: magnet) { newValue in
            MagnetConfig.magnet = newValue
            NotificationCenter.default.post(name: NSNotification.Name("MagnetConfigChanged"), object: nil)
          }
      }
      VStack(spacing: 10) {
        GridSection(
          color: color1,
          fz: fz,
          isMagnet3x2: $isMagnet3x2,
          isMagnet6x6: $isMagnet6x6,
          isMagnet8x8: $isMagnet8x8,
          isMagnet10x10: $isMagnet10x10,
          isMagnet12x12: $isMagnet12x12
        )
        MagnetDragSection(
          color: color2,
          fz: fz,
          magnetDragShortcut: $magnetDragShortcut,
          magnetResizeShortcut: $magnetResizeShortcut
        )
        MagnetResizeSection(
          color: color3,
          fz: fz,
          magnetDragShortcut: $magnetDragShortcut,
          magnetResizeShortcut: $magnetResizeShortcut
        )
        ToggleRowButton(
          text: NSLocalizedString("system.message.tip", comment: ""),
          fz: fz,
          isEnabled: $magnetTip,
          onToggle: { newValue in
            MagnetConfig.magnetTip = newValue
          }
        )
      }
      .disabledOverlay(isDisabled: !magnet)
    }
    .padding(15)
    .frame(width: 490)
    .background(BlurredBackground(material: .underWindowBackground, blendingMode: .behindWindow, blur: 1.0))
    .onAppear {
      magnet = MagnetConfig.magnet
      magnetDragShortcut = MagnetConfig.magnetDragShortcut
      magnetResizeShortcut = MagnetConfig.magnetResizeShortcut
      isMagnet3x2 = MagnetConfig.magnet3x2
      isMagnet6x6 = MagnetConfig.magnet6x6
      isMagnet8x8 = MagnetConfig.magnet8x8
      isMagnet10x10 = MagnetConfig.magnet10x10
      isMagnet12x12 = MagnetConfig.magnet12x12
      magnetTip = MagnetConfig.magnetTip
    }
  }
}
