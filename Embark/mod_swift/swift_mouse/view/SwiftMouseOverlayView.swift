import SwiftUI

class SwiftMouseOverlayView: NSView {
  private var pathLayer: CAShapeLayer?

  override var isFlipped: Bool {
    return true
  }

  override init(frame frameRect: NSRect) {
    super.init(frame: frameRect)
    setupView()
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
    setupView()
  }

  private func setupView() {
    wantsLayer = true
    layer?.backgroundColor = NSColor.clear.cgColor
  }

  func clear() {
    pathLayer?.removeFromSuperlayer()
    pathLayer = nil
  }

  func drawPath(_ points: [CGPoint]) {
    if SwiftMouseConfig.swiftMousePathOpacity <= 0 {
      return
    }
    guard points.count > 1 else { return }
    if pathLayer == nil {
      let layer = CAShapeLayer()
      layer.strokeColor = NSColor.controlAccentColor.withAlphaComponent(SwiftMouseConfig.swiftMousePathOpacity).cgColor
      layer.lineWidth = 4.0
      layer.fillColor = NSColor.clear.cgColor
      layer.lineCap = .round
      layer.lineJoin = .round
      self.layer?.addSublayer(layer)
      self.pathLayer = layer
    }
    let path = CGMutablePath()
    path.move(to: points[0])
    for i in 1..<points.count {
      path.addLine(to: points[i])
    }
    pathLayer?.path = path
  }
}
