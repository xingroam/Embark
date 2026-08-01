import SwiftUI

struct BlurredBackground: NSViewRepresentable {
  let material: NSVisualEffectView.Material
  let blendingMode: NSVisualEffectView.BlendingMode
  let blur: Double

  init(material: NSVisualEffectView.Material = .hudWindow, blendingMode: NSVisualEffectView.BlendingMode = .behindWindow, blur: Double = 1.0) {
    self.material = material
    self.blendingMode = blendingMode
    self.blur = blur
  }

  func makeNSView(context: Context) -> NSVisualEffectView {
    let view = NSVisualEffectView()
    view.material = material
    view.blendingMode = blendingMode
    view.state = .active
    view.alphaValue = blur
    view.wantsLayer = true
    view.layer?.backgroundColor = NSColor.clear.cgColor
    return view
  }

  func updateNSView(_ view: NSVisualEffectView, context: Context) {
    view.material = material
    view.blendingMode = blendingMode
    view.alphaValue = blur
    view.wantsLayer = true
    view.layer?.backgroundColor = NSColor.clear.cgColor
  }
}
