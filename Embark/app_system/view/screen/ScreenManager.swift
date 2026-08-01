import AppKit
import Foundation

class ScreenManager {
  static let s = ScreenManager()

  private init() {}

  func Center(_ window: NSWindow, winCenter: Bool = false) {
    if !winCenter {
      window.center()
      return
    }
    guard let screen = GetScreen() else {
      window.center()
      return
    }
    if !centerWindowOnScreen(window, screen: screen) {
      window.center()
    }
  }

  func GetScreen() -> NSScreen? {
    let mouseLocation = NSEvent.mouseLocation
    return NSScreen.screens.first { screen in
      NSMouseInRect(mouseLocation, screen.frame, false)
    } ?? NSScreen.main
  }

  private func centerWindowOnScreen(_ window: NSWindow, screen: NSScreen) -> Bool {
    let screenFrame = screen.frame
    let windowSize = window.frame.size
    guard windowSize.width > 0 && windowSize.height > 0 else {
      return false
    }
    guard screenFrame.width > 0 && screenFrame.height > 0 else {
      return false
    }
    let visibleFrame = screen.visibleFrame
    let centerX = visibleFrame.midX - (windowSize.width / 2)
    let centerY = visibleFrame.midY - (windowSize.height / 2)
    window.setFrameOrigin(NSPoint(x: centerX, y: centerY))
    return true
  }
}
