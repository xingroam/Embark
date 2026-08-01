import AppKit

class BorderlessKeyWindow: NSWindow {
  override var canBecomeKey: Bool {
    return true
  }
  override var canBecomeMain: Bool {
    return true
  }
}

