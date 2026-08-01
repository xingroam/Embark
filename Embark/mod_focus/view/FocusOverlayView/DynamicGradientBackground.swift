import AppKit
import QuartzCore

class DynamicGradientBackground: NSView {
  let colors: [NSColor]
  let opacityRange: ClosedRange<CGFloat>
  let startPoint: CGPoint
  let endPoint: CGPoint
  let animationDuration: TimeInterval

  private var gradientLayer: CAGradientLayer!
  private var timer: DispatchSourceTimer?
  private var phase: CGFloat = 0.0

  init(
    colors: [NSColor] = [.systemPurple, .systemBlue, .systemPink],
    opacityRange: ClosedRange<CGFloat> = 0.1...0.3,
    startPoint: CGPoint = CGPoint(x: 0, y: 0),
    endPoint: CGPoint = CGPoint(x: 1, y: 1),
    animationDuration: TimeInterval = 3.0
  ) {
    self.colors = colors
    self.opacityRange = opacityRange
    self.startPoint = startPoint
    self.endPoint = endPoint
    self.animationDuration = animationDuration
    super.init(frame: .zero)
    setupGradient()
    startAnimation()
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private func setupGradient() {
    gradientLayer = CAGradientLayer()
    gradientLayer.frame = bounds
    gradientLayer.startPoint = startPoint
    gradientLayer.endPoint = endPoint
    gradientLayer.needsDisplayOnBoundsChange = false
    layer = gradientLayer
    wantsLayer = true
    updateGradient()
  }

  private func updateGradient() {
    let baseOpacity = (opacityRange.lowerBound + opacityRange.upperBound) / 2
    let amplitude = (opacityRange.upperBound - opacityRange.lowerBound) / 2
    let animatedColors = colors.enumerated().map { index, color in
      let phaseOffset = sin(phase + CGFloat(index) * .pi / CGFloat(colors.count)) * amplitude
      let dynamicOpacity = baseOpacity + phaseOffset
      return color.withAlphaComponent(dynamicOpacity).cgColor
    }
    gradientLayer.colors = animatedColors
  }

  private func startAnimation() {
    timer = DispatchSource.makeTimerSource()
    timer?.schedule(deadline: .now(), repeating: 0.1)
    timer?.setEventHandler { [weak self] in
      guard let self = self else { return }
      if !FocusConfig.focus {
        self.stopAnimation()
        return
      }
      DispatchQueue.main.async {
        self.phase += 0.1
        self.updateGradient()
      }
    }
    timer?.resume()
  }

  func stopAnimation() {
    timer?.cancel()
    timer = nil
  }

  override func layout() {
    super.layout()
    gradientLayer.frame = bounds
  }

  deinit {
    timer?.cancel()
  }
}
