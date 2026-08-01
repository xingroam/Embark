import SwiftUI

struct SwiftMouseGeneralSection: View {
  let color: Color
  let fz: CGFloat
  @Binding var swiftMouseDistance: Double
  @Binding var swiftMousePathOpacity: Double

  var body: some View {
    VStack(spacing: 10) {
      HStack(spacing: 5) {
        Text(NSLocalizedString("swift.mouse.settings.distance", comment: "") + ": " + String(format: "%.0f", swiftMouseDistance))
          .font(.system(size: fz, weight: .regular))
          .frame(maxWidth: .infinity, alignment: .leading)
        CustomSlider(value: $swiftMouseDistance, in: 10.0...200.0, step: 10.0, valueFormatter: { _ in "" })
          .frame(maxWidth: .infinity)
          .onChange(of: swiftMouseDistance) { newValue in
            SwiftMouseConfig.swiftMouseDistance = newValue
            NotificationCenter.default.post(name: NSNotification.Name("SwiftMouseConfigChanged"), object: nil)
          }
      }
      HStack(spacing: 5) {
        Text(NSLocalizedString("swift.mouse.settings.path_transparency", comment: "") + ": " + String(format: "%.0f%%", swiftMousePathOpacity * 100))
          .font(.system(size: fz, weight: .regular))
          .frame(maxWidth: .infinity, alignment: .leading)
        CustomSlider(value: $swiftMousePathOpacity, in: 0.0...1.0, step: 0.05, valueFormatter: { _ in "" })
          .frame(maxWidth: .infinity)
          .onChange(of: swiftMousePathOpacity) { newValue in
            SwiftMouseConfig.swiftMousePathOpacity = newValue
            NotificationCenter.default.post(name: NSNotification.Name("SwiftMouseConfigChanged"), object: nil)
          }
      }
    }
    .cardStyle()
  }
}
