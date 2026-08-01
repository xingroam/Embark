import SwiftUI

struct DotGridView: NSViewRepresentable {
  let spacing: CGFloat
  let dotSize: CGFloat
  let color: Color
  let opacity: Double
  let size: CGSize

  func makeNSView(context: Context) -> DotGridNSView {
    let view = DotGridNSView()
    return view
  }

  func updateNSView(_ nsView: DotGridNSView, context: Context) {
    nsView.updateParameters(spacing: spacing, dotSize: dotSize, color: color, opacity: opacity, size: size)
  }

  func makeCoordinator() -> Coordinator {
    Coordinator()
  }

  class Coordinator: NSObject {}
}

class DotGridNSView: NSView {
  private var spacing: CGFloat = 20.0
  private var dotSize: CGFloat = 2.0
  private var dotColor: NSColor = NSColor.secondaryLabelColor
  private var dotOpacity: Double = 0.15

  override var isOpaque: Bool {
    return false
  }

  override init(frame frameRect: NSRect) {
    super.init(frame: frameRect)
    wantsLayer = true
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func updateParameters(spacing: CGFloat, dotSize: CGFloat, color: Color, opacity: Double, size: CGSize) {
    self.spacing = spacing
    self.dotSize = dotSize
    self.dotColor = NSColor(color)
    self.dotOpacity = opacity
    needsDisplay = true
  }

  override func draw(_ dirtyRect: NSRect) {
    super.draw(dirtyRect)
    guard let context = NSGraphicsContext.current?.cgContext else { return }
    context.setFillColor(dotColor.withAlphaComponent(dotOpacity).cgColor)
    let minX = Int(floor(dirtyRect.minX / spacing)) * Int(spacing)
    let maxX = Int(ceil(dirtyRect.maxX / spacing)) * Int(spacing)
    let minY = Int(floor(dirtyRect.minY / spacing)) * Int(spacing)
    let maxY = Int(ceil(dirtyRect.maxY / spacing)) * Int(spacing)
    var x = CGFloat(minX)
    while x <= CGFloat(maxX) {
      var y = CGFloat(minY)
      while y <= CGFloat(maxY) {
        let rect = CGRect(
          x: x - dotSize / 2,
          y: y - dotSize / 2,
          width: dotSize,
          height: dotSize
        )
        context.fillEllipse(in: rect)
        y += spacing
      }
      x += spacing
    }
  }
}
