import SwiftUI

extension ShapeStyle where Self == AnyShapeStyle {
  static func grainGradient(strength: Float = 0.1) -> Self {
    if #available(macOS 14.0, *) {
      return AnyShapeStyle(ShaderLibrary.default.grainGradient(.boundingRect, .float(strength)))
    } else {
      return AnyShapeStyle(Color.clear)
    }
  }
}
