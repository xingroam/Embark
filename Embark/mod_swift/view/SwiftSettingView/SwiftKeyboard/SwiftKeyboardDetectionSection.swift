import SwiftUI

struct SwiftKeyboardDetectionSection: View {
  let color: Color
  let fz: CGFloat
  @Binding var detection: Double

  var body: some View {
    VStack(spacing: 10) {
      HStack(spacing: 5) {
        Text(NSLocalizedString("swift.keyboard.settings.detection", comment: ""))
          .font(.system(size: fz + 1, weight: .medium))
        Spacer()
        Text("\(NSLocalizedString("system.message.delay.seconds", comment: "").replacingOccurrences(of: "%@", with: String(format: "%.1f", detection)))")
          .font(.system(size: fz))
          .foregroundColor(color)
      }
      VStack(spacing: 5) {
        Slider(value: $detection, in: 0.3...1.0, step: 0.1)
          .accentColor(color)
          .onChange(of: detection) { newValue in
            SwiftKeyboardConfig.swiftKeyboardDetection = newValue
            NotificationCenter.default.post(name: NSNotification.Name("SwiftKeyboardConfigChanged"), object: nil)
          }
      }
      .cardStyle()
    }
  }
}
