import SwiftUI
import ApplicationServices

class SlideWindow {
  static let s = SlideWindow()

  private init() {}

  private func getQuartzScreenBounds(screen: NSScreen?) -> CGRect {
    guard let screen = screen ?? NSScreen.main else { return .zero }
    let cocoaFrame = screen.frame
    let mainScreenHeight = NSScreen.screens.first?.frame.height ?? 0
    return CGRect(
      x: cocoaFrame.minX,
      y: mainScreenHeight - cocoaFrame.maxY,
      width: cocoaFrame.width,
      height: cocoaFrame.height
    )
  }

  func getWindowDockInfo(windowData: WindowData, screen: NSScreen?) -> DockInfo? {
    let windowBounds = windowData.bounds
    let quartzScreenBounds = getQuartzScreenBounds(screen: screen)
    let leftEdge = windowBounds.minX <= quartzScreenBounds.minX + SlideConfig.slideDistance
    let rightEdge = windowBounds.maxX >= quartzScreenBounds.maxX - SlideConfig.slideDistance
    let bottomEdge = windowBounds.maxY >= quartzScreenBounds.maxY - SlideConfig.slideDistance
    if leftEdge && rightEdge {
      return DockInfo(mainDockArea: .leftAndRight, startPoint: CGPoint(x: windowBounds.minX, y: windowBounds.minY), endPoint: CGPoint(x: windowBounds.maxX, y: windowBounds.maxY))
    }
    var dockAreas: [DockArea] = []
    if leftEdge {
      dockAreas.append(DockArea(type: .left, size: windowBounds.height, startPoint: CGPoint(x: windowBounds.minX, y: windowBounds.minY), endPoint: CGPoint(x: windowBounds.minX, y: windowBounds.maxY)))
    }
    if rightEdge {
      dockAreas.append(DockArea(type: .right, size: windowBounds.height, startPoint: CGPoint(x: windowBounds.maxX, y: windowBounds.minY), endPoint: CGPoint(x: windowBounds.maxX, y: windowBounds.maxY)))
    }
    if bottomEdge {
      dockAreas.append(DockArea(type: .bottom, size: windowBounds.width, startPoint: CGPoint(x: windowBounds.minX, y: windowBounds.maxY), endPoint: CGPoint(x: windowBounds.maxX, y: windowBounds.maxY)))
    }
    guard !dockAreas.isEmpty else { return nil }
    let mainDockArea = dockAreas.max { $0.size < $1.size }!
    return DockInfo(mainDockArea: mainDockArea.type, startPoint: mainDockArea.startPoint, endPoint: mainDockArea.endPoint)
  }

  func shouldShowWindow(hiddenWindow: HiddenWindow, mouseX: CGFloat, mouseScreen: NSScreen?, lastMousePosition: CGPoint) -> Bool {
    let showBounds = hiddenWindow.showBounds
    let windowScreen = hiddenWindow.screen ?? NSScreen.main
    let quartzScreenBounds = getQuartzScreenBounds(screen: windowScreen)
    let mouseY = lastMousePosition.y
    switch hiddenWindow.dockInfo.mainDockArea {
    case .left:
      let isInYRange = mouseY >= showBounds.minY && mouseY <= showBounds.maxY
      let isAtEdge = mouseX <= quartzScreenBounds.minX + SlideConfig.slideDistance
      return isAtEdge && isInYRange
    case .right:
      let isInYRange = mouseY >= showBounds.minY && mouseY <= showBounds.maxY
      let isAtEdge = mouseX >= quartzScreenBounds.maxX - SlideConfig.slideDistance
      return isAtEdge && isInYRange
    case .bottom:
      let isInXRange = mouseX >= showBounds.minX && mouseX <= showBounds.maxX
      let isAtEdge = mouseY >= quartzScreenBounds.maxY - SlideConfig.slideDistance
      return isAtEdge && isInXRange
    default:
      return false
    }
  }

  func mouseInWindow(hiddenWindow: HiddenWindow, lastMousePosition: CGPoint) -> Bool {
    return hiddenWindow.currentBounds.contains(lastMousePosition)
  }

  func windowAtBothEdges(bounds: CGRect, screen: NSScreen?) -> Bool {
    let quartzScreenBounds = getQuartzScreenBounds(screen: screen)
    let leftEdge = bounds.minX <= quartzScreenBounds.minX + SlideConfig.slideDistance
    let rightEdge = bounds.maxX >= quartzScreenBounds.maxX - SlideConfig.slideDistance
    return leftEdge && rightEdge
  }

  func windowOnMinimize(windowData: WindowData) -> Bool {
    guard let element = windowData.element else { return false }
    var minimizedValue: AnyObject?
    let minimizedResult = AXUIElementCopyAttributeValue(element, kAXMinimizedAttribute as CFString, &minimizedValue)
    return (minimizedResult == .success) ? ((minimizedValue as? NSNumber)?.boolValue ?? false) : false
  }

  func elementValid(_ element: AXUIElement) -> Bool {
    var positionValue: AnyObject?
    let result = AXUIElementCopyAttributeValue(element, kAXPositionAttribute as CFString, &positionValue)
    return result == .success
  }

  func getWindowArea(windowData: WindowData, screen: NSScreen?) -> DockAreaType {
    let windowBounds = windowData.bounds
    let quartzScreenBounds = getQuartzScreenBounds(screen: screen)
    let leftEdge = windowBounds.minX <= quartzScreenBounds.minX + SlideConfig.slideDistance
    let rightEdge = windowBounds.maxX >= quartzScreenBounds.maxX - SlideConfig.slideDistance
    let bottomEdge = windowBounds.maxY >= quartzScreenBounds.maxY - SlideConfig.slideDistance
    if leftEdge && rightEdge {
      return .leftAndRight
    }
    if leftEdge {
      return .left
    }
    if rightEdge {
      return .right
    }
    if bottomEdge {
      return .bottom
    }
    return .none
  }

  // MARK: - Bounds

  func calcShowBounds(bounds: CGRect, screen: NSScreen?) -> CGRect {
    let quartzScreenBounds = getQuartzScreenBounds(screen: screen)
    var showBounds = bounds
    if showBounds.minX < quartzScreenBounds.minX {
      showBounds.origin.x = quartzScreenBounds.minX
    }
    if showBounds.maxX > quartzScreenBounds.maxX {
      showBounds.origin.x = quartzScreenBounds.maxX - showBounds.width
    }
    if showBounds.minY < quartzScreenBounds.minY {
      showBounds.origin.y = quartzScreenBounds.minY
    }
    if showBounds.maxY > quartzScreenBounds.maxY {
      showBounds.origin.y = quartzScreenBounds.maxY - showBounds.height
    }
    return showBounds
  }

  func calcHideBounds(showBounds: CGRect, dockInfo: DockInfo, screenFrame: CGRect) -> CGRect {
    let mainScreenHeight = NSScreen.screens.first?.frame.height ?? 0
    let quartzScreenBounds = CGRect(x: screenFrame.minX, y: mainScreenHeight - screenFrame.maxY, width: screenFrame.width, height: screenFrame.height)
    switch dockInfo.mainDockArea {
    case .left:
      let hiddenX = quartzScreenBounds.minX - showBounds.width + SlideConfig.slideMargin
      return CGRect(x: hiddenX, y: showBounds.origin.y, width: showBounds.width, height: showBounds.height)
    case .right:
      let hiddenX = quartzScreenBounds.maxX - SlideConfig.slideMargin
      return CGRect(x: hiddenX, y: showBounds.origin.y, width: showBounds.width, height: showBounds.height)
    case .bottom:
      let titleBarHeight: CGFloat = 28
      let visibleHeight = max(SlideConfig.slideMargin, titleBarHeight)
      let hiddenY = quartzScreenBounds.maxY - visibleHeight
      return CGRect(x: showBounds.origin.x, y: hiddenY, width: showBounds.width, height: showBounds.height)
    default:
      return showBounds
    }
  }

  func boundsEqual(_ bounds1: CGRect, _ bounds2: CGRect) -> Bool {
    let tolerance: CGFloat = 3.0
    return abs(bounds1.origin.x - bounds2.origin.x) < tolerance &&
           abs(bounds1.origin.y - bounds2.origin.y) < tolerance &&
           abs(bounds1.size.width - bounds2.size.width) < tolerance &&
           abs(bounds1.size.height - bounds2.size.height) < tolerance
  }

  // MARK: - Show & Hide

  func showOfWindow(hiddenWindow: HiddenWindow, activate: Bool = false) {
    guard let element = hiddenWindow.windowData.element else { return }
    guard elementValid(element) else { return }
    if activate {
      SwiftManager.s.activateWindow(fast: false, wi: hiddenWindow.windowData, element: element) {
        hiddenWindow.LockOperation {
          Debug.print("Showing window: [\(hiddenWindow.windowData.app), \(hiddenWindow.windowData.pid), \(hiddenWindow.windowData.wid)]")
          var newSize = hiddenWindow.showBounds.size
          AXUIElementSetAttributeValue(element, kAXSizeAttribute as CFString, AXValueCreate(.cgSize, &newSize)!)
          var newPosition = hiddenWindow.showBounds.origin
          AXUIElementSetAttributeValue(element, kAXPositionAttribute as CFString, AXValueCreate(.cgPoint, &newPosition)!)
        }
      }
    } else {
      Debug.print("Showing window: [\(hiddenWindow.windowData.app), \(hiddenWindow.windowData.pid), \(hiddenWindow.windowData.wid)]")
      var newSize = hiddenWindow.showBounds.size
      AXUIElementSetAttributeValue(element, kAXSizeAttribute as CFString, AXValueCreate(.cgSize, &newSize)!)
      var newPosition = hiddenWindow.showBounds.origin
      AXUIElementSetAttributeValue(element, kAXPositionAttribute as CFString, AXValueCreate(.cgPoint, &newPosition)!)
    }
  }

  func hideOfWindow(hiddenWindow: HiddenWindow) {
    guard let element = hiddenWindow.windowData.element else { return }
    guard elementValid(element) else { return }
    if hiddenWindow.dockInfo.mainDockArea == .bottom && hiddenWindow.hideBounds == .zero {
      hiddenWindow.LockOperation { [weak self] in
        guard let self = self else { return }
        Debug.print("Hiding window: [\(hiddenWindow.windowData.app), \(hiddenWindow.windowData.pid), \(hiddenWindow.windowData.wid)]")
        let screenFrame = hiddenWindow.screen?.frame ?? NSScreen.main?.frame ?? CGRect.zero
        let calculatedHideBounds = calcHideBounds(showBounds: hiddenWindow.showBounds, dockInfo: hiddenWindow.dockInfo, screenFrame: screenFrame)
        var newSize = calculatedHideBounds.size
        AXUIElementSetAttributeValue(element, kAXSizeAttribute as CFString, AXValueCreate(.cgSize, &newSize)!)
        var newPosition = calculatedHideBounds.origin
        AXUIElementSetAttributeValue(element, kAXPositionAttribute as CFString, AXValueCreate(.cgPoint, &newPosition)!)
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
          guard let self = self else { return }
          while true {
            usleep(50000)
            if !WindowFind.FindWindowByPidWid(pid: hiddenWindow.windowData.pid, wid: hiddenWindow.windowData.wid) {
              DispatchQueue.main.async {
                if let index = SlideMonitor.s.hiddenWindows.firstIndex(of: hiddenWindow) {
                  SlideMonitor.s.hiddenWindows.remove(at: index)
                }
              }
              break
            }
            if let currentBounds = WindowFind.GetWindowBounds(windowData: hiddenWindow.windowData) {
              if !self.boundsEqual(currentBounds, hiddenWindow.showBounds) {
                DispatchQueue.main.async {
                  hiddenWindow.hideBounds = currentBounds
                }
                break
              }
            }
          }
        }
      }
    } else if hiddenWindow.hideBounds != .zero {
      hiddenWindow.LockOperation {
        Debug.print("Hiding window: [\(hiddenWindow.windowData.app), \(hiddenWindow.windowData.pid), \(hiddenWindow.windowData.wid)]")
        var newSize = hiddenWindow.hideBounds.size
        AXUIElementSetAttributeValue(element, kAXSizeAttribute as CFString, AXValueCreate(.cgSize, &newSize)!)
        var newPosition = hiddenWindow.hideBounds.origin
        AXUIElementSetAttributeValue(element, kAXPositionAttribute as CFString, AXValueCreate(.cgPoint, &newPosition)!)
      }
    }
  }
}
