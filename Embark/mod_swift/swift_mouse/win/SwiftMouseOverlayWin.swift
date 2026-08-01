import SwiftUI
import ApplicationServices

class SwiftMouseOverlayWin {
  static let s = SwiftMouseOverlayWin()
  private var overlayWindow: NSWindow?

  var overlayActive: Bool {
    return overlayWindow?.isVisible ?? false
  }

  func IsWindow(_ wid: CGWindowID, title: String? = nil) -> Bool {
    var result = false
    if Thread.isMainThread {
      result = overlayWindow != nil && (overlayWindow?.windowNumber == Int(wid) || (title != nil && overlayWindow?.title == title))
    } else {
      DispatchQueue.main.sync {
        result = overlayWindow != nil && (overlayWindow?.windowNumber == Int(wid) || (title != nil && overlayWindow?.title == title))
      }
    }
    return result
  }

  private init() {
    NotificationCenter.default.addObserver(self, selector: #selector(screenParametersChanged), name: NSApplication.didChangeScreenParametersNotification, object: nil)
  }

  deinit {
    NotificationCenter.default.removeObserver(self)
  }

  @objc private func screenParametersChanged() {
    if overlayWindow != nil {
      let wasVisible = overlayWindow?.isVisible ?? false
      overlayWindow?.orderOut(nil)
      overlayWindow = nil
      if wasVisible {
        createWindow()
        overlayWindow?.orderFrontRegardless()
      }
    }
  }

  func show(at point: CGPoint? = nil) {
    if overlayWindow == nil {
      createWindow()
    }
    guard let window = overlayWindow else { return }
    var targetScreen = ScreenManager.s.GetScreen()
    if let point = point {
      let primaryScreenHeight = NSScreen.screens.first?.frame.height ?? NSScreen.main?.frame.height ?? 0
      let cocoaPoint = CGPoint(x: point.x, y: primaryScreenHeight - point.y)
      targetScreen = NSScreen.screens.first(where: { $0.frame.contains(cocoaPoint) }) ?? ScreenManager.s.GetScreen()
    }
    guard let screen = targetScreen else { return }
    if window.frame != screen.frame {
      window.setFrame(screen.frame, display: true)
      (window.contentView as? SwiftMouseOverlayView)?.frame = CGRect(origin: .zero, size: screen.frame.size)
    }
    (window.contentView as? SwiftMouseOverlayView)?.clear()
    window.orderFrontRegardless()
  }

  func drawPath(_ points: [CGPoint]) {
    guard let window = overlayWindow else { return }
    let primaryScreenHeight = NSScreen.screens.first?.frame.height ?? NSScreen.main?.frame.height ?? 0
    let convertedPoints = points.map { point -> CGPoint in
      let cocoaGlobalPoint = CGPoint(x: point.x, y: primaryScreenHeight - point.y)
      let pointInWindow = window.convertPoint(fromScreen: cocoaGlobalPoint)
      return CGPoint(x: pointInWindow.x, y: window.frame.height - pointInWindow.y)
    }
    (window.contentView as? SwiftMouseOverlayView)?.drawPath(convertedPoints)
  }

  func hide() {
    overlayWindow?.orderOut(nil)
  }

  private func createWindow() {
    guard let screen = ScreenManager.s.GetScreen() else { return }
    overlayWindow = NSWindow(
      contentRect: screen.frame,
      styleMask: .borderless,
      backing: .buffered,
      defer: false
    )
    overlayWindow?.level = .screenSaver + 1
    overlayWindow?.backgroundColor = .clear
    overlayWindow?.isOpaque = false
    overlayWindow?.ignoresMouseEvents = true
    overlayWindow?.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
    overlayWindow?.contentView = SwiftMouseOverlayView(frame: screen.frame)
  }
}
