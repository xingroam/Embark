import SwiftUI

struct DynamicGradient: NSViewRepresentable {
  let colors: [Color]
  let opacityRange: ClosedRange<Double>
  let startPoint: UnitPoint
  let endPoint: UnitPoint

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
  }

  static func dismantleNSView(_ nsView: DynamicGradientBackground, coordinator: Coordinator) {
    coordinator.removeObserver()
    nsView.removeFromSuperview()
  }

  func makeCoordinator() -> Coordinator {
    Coordinator()
  }

  func makeNSView(context: Context) -> DynamicGradientBackground {
    let nsColors = colors.map { NSColor($0) }
    let nsView = DynamicGradientBackground(
      colors: nsColors,
      opacityRange: CGFloat(opacityRange.lowerBound)...CGFloat(opacityRange.upperBound),
      startPoint: CGPoint(x: startPoint.x, y: startPoint.y),
      endPoint: CGPoint(x: endPoint.x, y: endPoint.y)
    )
    context.coordinator.addObserver(for: nsView)
    return nsView
  }

  func updateNSView(_ nsView: DynamicGradientBackground, context: Context) {}

  class Coordinator {
    private var observer: NSObjectProtocol?

    func addObserver(for nsView: DynamicGradientBackground) {
      observer = NotificationCenter.default.addObserver(forName: NSNotification.Name("FocusConfigChanged"), object: nil, queue: .main) { [weak nsView] _ in
        guard let nsView = nsView else { return }
        if !FocusConfig.focus || FocusConfig.focusColor != .dynamicGradient {
          nsView.stopAnimation()
        }
      }
    }

    func removeObserver() {
      if let observer = observer {
        NotificationCenter.default.removeObserver(observer)
        self.observer = nil
      }
    }

    deinit {
      removeObserver()
    }
  }
}
