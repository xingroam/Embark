import SwiftUI

struct ResizeHandle: NSViewRepresentable {
  func makeNSView(context: Context) -> NSView {
    return ResizeHandleView()
  }

  func updateNSView(_ nsView: NSView, context: Context) {}

  class ResizeHandleView: NSView {
    override func resetCursorRects() {
      let cursor = NSCursor(image: NSImage(systemSymbolName: "arrow.up.left.and.arrow.down.right", accessibilityDescription: nil) ?? NSImage(), hotSpot: NSPoint(x: 8, y: 8))
      addCursorRect(bounds, cursor: cursor)
    }

    override func mouseDown(with event: NSEvent) {
      guard let window = self.window else { return }
      let initialFrame = window.frame
      let initialMouseLocation = NSEvent.mouseLocation
      var shouldContinue = true
      while shouldContinue {
        guard let nextEvent = window.nextEvent(matching: [.leftMouseUp, .leftMouseDragged]) else { continue }
        switch nextEvent.type {
        case .leftMouseDragged:
          let currentMouseLocation = NSEvent.mouseLocation
          let deltaX = currentMouseLocation.x - initialMouseLocation.x
          let deltaY = currentMouseLocation.y - initialMouseLocation.y
          let newWidth = max(400, initialFrame.width + deltaX)
          let newHeight = max(300, initialFrame.height - deltaY)
          let newOriginY = initialFrame.origin.y + (initialFrame.height - newHeight)
          window.setFrame(NSRect(x: initialFrame.origin.x, y: newOriginY, width: newWidth, height: newHeight), display: true, animate: false)
        case .leftMouseUp:
          shouldContinue = false
        default:
          break
        }
      }
    }
  }
}
