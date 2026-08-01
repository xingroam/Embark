import SwiftUI

struct SwiftBlurBackground: View {
  let material: Material
  let opacity: Double

  init(material: Material = .ultraThinMaterial, opacity: Double = 1.0) {
    self.material = material
    self.opacity = opacity
  }

  var body: some View {
    Color.clear
      .background(material)
      .opacity(opacity)
  }
}
