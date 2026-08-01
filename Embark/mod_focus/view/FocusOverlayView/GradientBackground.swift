import SwiftUI

struct GradientBackground: View {
  let colors: [Color]
  let opacityRange: ClosedRange<Double>
  let startPoint: UnitPoint
  let endPoint: UnitPoint

  @State private var animatedColors: [Color]

  init(
    colors: [Color] = [.purple, .blue, .pink],
    opacityRange: ClosedRange<Double> = 0.1...0.3,
    startPoint: UnitPoint = .topLeading,
    endPoint: UnitPoint = .bottomTrailing
  ) {
    self.colors = colors
    self.opacityRange = opacityRange
    self.startPoint = startPoint
    self.endPoint = endPoint
    self._animatedColors = State(initialValue: colors.enumerated().map { _, color in
      let randomOpacity = Double.random(in: opacityRange)
      return color.opacity(randomOpacity)
    })
  }

  var body: some View {
    LinearGradient(
      gradient: Gradient(colors: animatedColors),
      startPoint: startPoint,
      endPoint: endPoint
    )
  }
}
