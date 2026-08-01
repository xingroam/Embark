import SwiftUI

class HiddenWindow: Equatable {
  var windowData: WindowData
  let dockInfo: DockInfo
  var currentBounds: CGRect
  var showBounds: CGRect
  var hideBounds: CGRect
  var screen: NSScreen?
  private let lock = NSLock()
  private var isOperating = false

  init(windowData: WindowData, dockInfo: DockInfo, showBounds: CGRect, hideBounds: CGRect, screen: NSScreen?) {
    self.windowData = windowData
    self.dockInfo = dockInfo
    self.currentBounds = showBounds
    self.showBounds = showBounds
    self.hideBounds = hideBounds
    self.screen = screen
  }

  static func == (lhs: HiddenWindow, rhs: HiddenWindow) -> Bool {
    return lhs.windowData.pid == rhs.windowData.pid && lhs.windowData.wid == rhs.windowData.wid
  }

  func LockOperation(after: TimeInterval = 0.05, _ operation: @escaping () -> Void) {
    guard !isOperating else { return }
    isOperating = true
    defer {
      DispatchQueue.global().asyncAfter(deadline: .now() + after) {
        self.lock.unlock()
        self.isOperating = false
      }
    }
    lock.lock()
    operation()
  }

  func Lock() {
    lock.lock()
    isOperating = true
  }

  func UnLock() {
    lock.unlock()
    isOperating = false
  }
}

enum DockAreaType {
  case none
  case left
  case right
  case bottom
  case leftAndRight
}

struct DockArea {
  let type: DockAreaType
  let size: CGFloat
  let startPoint: CGPoint
  let endPoint: CGPoint
}

struct DockInfo {
  let mainDockArea: DockAreaType
  let startPoint: CGPoint
  let endPoint: CGPoint
}
