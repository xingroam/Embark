import SwiftUI

struct FocusAnimationSection: View {
  let color: Color
  let fz: CGFloat
  @Binding var focusAnimation: Bool
  @State private var focusDuration: TimeInterval = FocusConfig.focusDuration

  var body: some View {
    VStack(spacing: 10) {
      HStack(spacing: 5) {
        Text(NSLocalizedString("focus.settings.animation.title", comment: ""))
          .font(.system(size: fz, weight: .regular))
        Spacer()
        Toggle("", isOn: $focusAnimation)
          .sectionToggle()
          .onChange(of: focusAnimation) { newValue in
            FocusConfig.focusAnimation = newValue
            NotificationCenter.default.post(name: NSNotification.Name("FocusConfigChanged"), object: nil)
          }
      }
      if focusAnimation {
        HStack(spacing: 5) {
          Text(NSLocalizedString("focus.settings.animation.duration", comment: "") + ": " + NSLocalizedString("system.message.delay.seconds", comment: "").replacingOccurrences(of: "%@", with: String(format: "%.1f", focusDuration)))
            .font(.system(size: fz, weight: .regular))
            .frame(maxWidth: .infinity, alignment: .leading)
          CustomSlider(value: Binding<Double>(get: { focusDuration }, set: { focusDuration = $0 }), in: 0.3...0.9, step: 0.1, valueFormatter: { _ in "" })
            .frame(maxWidth: .infinity)
            .onChange(of: focusDuration) { newValue in
              FocusConfig.focusDuration = newValue
              NotificationCenter.default.post(name: NSNotification.Name("FocusConfigChanged"), object: nil)
            }
        }
      }
    }
    .cardStyle()
    .onAppear {
      focusDuration = FocusConfig.focusDuration
    }
    .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("FocusConfigChanged"))) { _ in
      focusDuration = FocusConfig.focusDuration
    }
  }
}
