import SwiftUI

struct FocusSettingView: View {
  @State private var focus: Bool = FocusConfig.focus
  @State private var focusShortcutKey: CGKeyCode = FocusConfig.focusShortcutKey
  @State private var focusShortcutFlags: CGEventFlags = FocusConfig.focusShortcutFlags
  @State private var focusStyle: FocusStyle = FocusConfig.focusStyle
  @State private var focusColor: FocusColor = FocusConfig.focusColor
  @State private var focusOpacity: Double = FocusConfig.focusOpacity
  @State private var focusBlur: CGFloat = FocusConfig.focusBlur
  @State private var focusAnimation: Bool = FocusConfig.focusAnimation
  @State private var focusDuration: TimeInterval = FocusConfig.focusDuration
  @State private var focusTopTransparent: Bool = FocusConfig.focusTopTransparent
  @State private var showShortcutDialog = false
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
        Text(FeatureType.focus.title)
          .font(.system(size: fz + 1, weight: .medium))
        Spacer()
        Toggle("", isOn: $focus)
          .toggleStyle(SwitchToggleStyle())
          .scaleEffect(0.8)
          .offset(x: 5)
          .onChange(of: focus) { newValue in
            FocusConfig.focus = newValue
            NotificationCenter.default.post(name: NSNotification.Name("FocusConfigChanged"), object: nil)
          }
      }
      VStack(spacing: 10) {
        FocusGeneralSection(
          color: color1,
          fz: fz,
          focusShortcutKey: $focusShortcutKey,
          focusShortcutFlags: $focusShortcutFlags,
          focusStyle: $focusStyle,
          focusColor: $focusColor,
          focusOpacity: $focusOpacity,
          focusBlur: $focusBlur,
          showShortcutDialog: $showShortcutDialog
        )
        FocusAnimationSection(
          color: color1,
          fz: fz,
          focusAnimation: $focusAnimation
        )
        FocusTopTransparentSection(
          color: color1,
          fz: fz,
          focusTopTransparent: $focusTopTransparent
        )
        FocusExcludeSection(
          color: color6,
          fz: fz
        )
      }
      .disabledOverlay(isDisabled: !focus)
    }
    .padding(15)
    .frame(width: 460)
    .background(BlurredBackground(material: .underWindowBackground, blendingMode: .behindWindow, blur: 1.0))
    .onAppear {
      updateState()
    }
    .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("FocusConfigChanged"))) { _ in
      updateState()
    }
    .sheet(isPresented: $showShortcutDialog) {
      ShortcutDialog(
        title: NSLocalizedString("system.shortcut.dialog.title", comment: ""),
        isPresented: $showShortcutDialog,
        shortcutKey: $focusShortcutKey,
        shortcutFlags: $focusShortcutFlags
      )
    }
  }

  private func updateState() {
    focus = FocusConfig.focus
    focusShortcutKey = FocusConfig.focusShortcutKey
    focusShortcutFlags = FocusConfig.focusShortcutFlags
    focusStyle = FocusConfig.focusStyle
    focusColor = FocusConfig.focusColor
    focusOpacity = FocusConfig.focusOpacity
    focusBlur = FocusConfig.focusBlur
    focusAnimation = FocusConfig.focusAnimation
    focusDuration = FocusConfig.focusDuration
    focusTopTransparent = FocusConfig.focusTopTransparent
  }
}
