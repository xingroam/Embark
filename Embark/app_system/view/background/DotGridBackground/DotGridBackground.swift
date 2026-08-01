import SwiftUI

struct DotGridBackground: View {
  let dotSpacing: CGFloat
  let dotSize: CGFloat
  let dotColor: Color
  let dotOpacity: Double
  let size: CGSize

  init(
    spacing: CGFloat = 20.0,
    dotSize: CGFloat = 2.0,
    color: Color = Color.secondary,
    opacity: Double = 0.125,
    size: CGSize
  ) {
    self.dotSpacing = spacing
    self.dotSize = dotSize
    self.dotColor = color
    self.dotOpacity = opacity
    self.size = size
  }

  var body: some View {
    DotGridView(
      spacing: dotSpacing,
      dotSize: dotSize,
      color: dotColor,
      opacity: dotOpacity,
      size: size
    )
    .allowsHitTesting(false)
  }
}
