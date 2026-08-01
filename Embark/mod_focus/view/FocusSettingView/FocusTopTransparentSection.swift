import SwiftUI

struct FocusTopTransparentSection: View {
  let color: Color
  let fz: CGFloat
  @Binding var focusTopTransparent: Bool
  @State private var focusTopTransparentDistance: CGFloat = FocusConfig.focusTopTransparentDistance

  var body: some View {
    VStack(spacing: 10) {
      HStack(spacing: 5) {
        Text(NSLocalizedString("focus.settings.top_transparent.title", comment: ""))
          .font(.system(size: fz, weight: .regular))
        Spacer()
        Toggle("", isOn: $focusTopTransparent)
          .sectionToggle()
          .onChange(of: focusTopTransparent) { newValue in
            FocusConfig.focusTopTransparent = newValue
            NotificationCenter.default.post(name: NSNotification.Name("FocusConfigChanged"), object: nil)
          }
      }
      if focusTopTransparent {
        HStack(spacing: 5) {
          Text(NSLocalizedString("focus.settings.top_transparent.distance", comment: "") + ": " + String(format: "%.0f%%", focusTopTransparentDistance))
            .font(.system(size: fz, weight: .regular))
            .frame(maxWidth: .infinity, alignment: .leading)
          CustomSlider(value: Binding<Double>(get: { Double(focusTopTransparentDistance) }, set: { focusTopTransparentDistance = CGFloat($0) }), in: 10...100, step: 1, valueFormatter: { _ in "" })
            .frame(maxWidth: .infinity)
            .onChange(of: focusTopTransparentDistance) { newValue in
              FocusConfig.focusTopTransparentDistance = newValue
              NotificationCenter.default.post(name: NSNotification.Name("FocusConfigChanged"), object: nil)
            }
        }
      }
    }
    .cardStyle()
    .onAppear {
      focusTopTransparentDistance = FocusConfig.focusTopTransparentDistance
    }
    .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("FocusConfigChanged"))) { _ in
      focusTopTransparentDistance = FocusConfig.focusTopTransparentDistance
    }
  }
}
