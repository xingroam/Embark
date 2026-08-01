import SwiftUI

struct DraggableArea: NSViewRepresentable {
  func makeNSView(context: Context) -> NSView {
    return DraggableView()
  }

  func updateNSView(_ nsView: NSView, context: Context) {}

  class DraggableView: NSView {
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
      return true
    }
    override func mouseDown(with event: NSEvent) {
      self.window?.performDrag(with: event)
    }
  }
}
