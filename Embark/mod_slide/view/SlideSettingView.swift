import SwiftUI
import ApplicationServices

struct SlideSettingView: View {
  @State private var slide: Bool = SlideConfig.slide
  @State private var slideShortcutKey: CGKeyCode = SlideConfig.slideShortcutKey
  @State private var slideShortcutFlags: CGEventFlags = SlideConfig.slideShortcutFlags
  @State private var slideDelay: TimeInterval = SlideConfig.slideDelay
  @State private var slideDistance: CGFloat = SlideConfig.slideDistance
  @State private var slideMargin: CGFloat = SlideConfig.slideMargin
  @State private var slideAutoUndock: Bool = SlideConfig.slideAutoUndock
  @State private var slideTip: Bool = SlideConfig.slideTip
  @State private var showShortcutDialog = false
  private let color1: Color = .blue
  private let color2: Color = .green
  private let color3: Color = .orange
  private let color4: Color = .purple
  private let color5: Color = .indigo
  private let color6: Color = .red
  private let fz: CGFloat = 12

  private var shortcutDisplayText: String {
    Keyboard.fullNameShortcut(keyCode: slideShortcutKey, flags: slideShortcutFlags)
  }

  var body: some View {
    VStack(spacing: 10) {
      HStack(spacing: 5) {
        Text(FeatureType.slide.title)
          .font(.system(size: fz + 1, weight: .medium))
        Spacer()
        Toggle("", isOn: $slide)
          .toggleStyle(SwitchToggleStyle())
          .scaleEffect(0.8)
          .offset(x: 5)
          .onChange(of: slide) { newValue in
            SlideConfig.slide = newValue
            NotificationCenter.default.post(name: NSNotification.Name("SlideConfigChanged"), object: nil)
          }
      }
      VStack(spacing: 10) {
        VStack(spacing: 10) {
          VStack(spacing: 10) {
            ShortcutButton(
              keyCode: slideShortcutKey,
              flags: slideShortcutFlags,
              onTap: {
                showShortcutDialog = true
              }
            )
            Text(NSLocalizedString("slide.settings.shortcut.description", comment: ""))
              .font(.system(size: fz - 1))
              .foregroundColor(.secondary)
              .lineLimit(nil)
              .multilineTextAlignment(.center)
              .fixedSize(horizontal: false, vertical: true)
          }
          .sheet(isPresented: $showShortcutDialog) {
            ShortcutDialog(
              title: NSLocalizedString("system.shortcut.dialog.title", comment: ""),
              isPresented: $showShortcutDialog,
              shortcutKey: $slideShortcutKey,
              shortcutFlags: $slideShortcutFlags
            )
          }
          VStack(spacing: 10) {
            VStack(spacing: 10) {
              HStack(spacing: 5) {
                Text(NSLocalizedString("slide.settings.delay.title", comment: ""))
                  .font(.system(size: fz, weight: .regular))
                Spacer()
                Text(NSLocalizedString("system.message.delay.seconds", comment: "").replacingOccurrences(of: "%@", with: String(format: "%.1f", slideDelay)))
                  .font(.system(size: fz, weight: .regular))
                  .foregroundColor(color1)
              }
              Slider(value: $slideDelay, in: 0.1...0.5, step: 0.1)
                .accentColor(color1)
                .onChange(of: slideDelay) { newValue in
                  SlideConfig.slideDelay = newValue
                  NotificationCenter.default.post(name: NSNotification.Name("SlideConfigChanged"), object: nil)
                }
            }
            VStack(spacing: 10) {
              HStack(spacing: 5) {
                Text(NSLocalizedString("slide.settings.tolerance.title", comment: ""))
                  .font(.system(size: fz, weight: .regular))
                Spacer()
                Text("\(Int(slideDistance))")
                  .font(.system(size: fz, weight: .regular))
                  .foregroundColor(color1)
              }
              Slider(value: $slideDistance, in: 5...20, step: 1)
                .accentColor(color1)
                .onChange(of: slideDistance) { newValue in
                  SlideConfig.slideDistance = newValue
                  NotificationCenter.default.post(name: NSNotification.Name("SlideConfigChanged"), object: nil)
                }
            }
            VStack(spacing: 10) {
              HStack(spacing: 5) {
                Text(NSLocalizedString("slide.settings.margin.title", comment: ""))
                  .font(.system(size: fz, weight: .regular))
                Spacer()
                Text("\(Int(slideMargin))")
                  .font(.system(size: fz, weight: .regular))
                  .foregroundColor(color1)
              }
              Slider(value: $slideMargin, in: 1...20, step: 1)
                .accentColor(color1)
                .onChange(of: slideMargin) { newValue in
                  SlideConfig.slideMargin = newValue
                  NotificationCenter.default.post(name: NSNotification.Name("SlideConfigChanged"), object: nil)
                }
            }
            HStack(spacing: 5) {
              Text(NSLocalizedString("slide.settings.auto_undock.title", comment: ""))
                .font(.system(size: fz))
              Spacer()
              Toggle("", isOn: $slideAutoUndock)
                .sectionToggle()
                .onChange(of: slideAutoUndock) { newValue in
                  SlideConfig.slideAutoUndock = newValue
                  NotificationCenter.default.post(name: NSNotification.Name("SlideConfigChanged"), object: nil)
                }
            }
          }
        }
        .cardStyle()
        ToggleRowButton(
          text: NSLocalizedString("system.message.tip", comment: ""),
          fz: fz,
          isEnabled: $slideTip,
          onToggle: { newValue in
            SlideConfig.slideTip = newValue
          }
        )
      }
      .disabledOverlay(isDisabled: !slide)
    }
    .padding(15)
    .frame(width: 460)
    .background(BlurredBackground(material: .underWindowBackground, blendingMode: .behindWindow, blur: 1.0))
    .onAppear {
      slide = SlideConfig.slide
      slideShortcutKey = SlideConfig.slideShortcutKey
      slideShortcutFlags = SlideConfig.slideShortcutFlags
      slideDelay = SlideConfig.slideDelay
      slideDistance = SlideConfig.slideDistance
      slideMargin = SlideConfig.slideMargin
      slideAutoUndock = SlideConfig.slideAutoUndock
      slideTip = SlideConfig.slideTip
    }
    .onChange(of: slideShortcutKey) { newValue in
      SlideConfig.slideShortcutKey = newValue
    }
    .onChange(of: slideShortcutFlags) { newValue in
      SlideConfig.slideShortcutFlags = newValue
    }
  }
}
