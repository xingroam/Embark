import SwiftUI
import ApplicationServices

class WindowResize {
  static let s = WindowResize()
  private var isResizingWindow: Bool = false
  private var resizedWindow: WindowData?
  private var resizeStartPosition: CGPoint = .zero
  private var windowStartBounds: CGRect = .zero
  private var hasAttemptedResize: Bool = false
  private var isMouseMoveListening: Bool = false
  private var mouseMoveEventTap: CFMachPort?
  private var mouseMoveRunLoopSource: CFRunLoopSource?
  private var lastProcessTime: TimeInterval = 0
  private var reusableWindowData: WindowData?
  private var cachedScreenFrame: CGRect = .zero
  private var lastScreenCacheTime: TimeInterval = 0

  private init() {}

  deinit {
    cleanupEventTap()
  }

  func startMagnetResize() -> Bool {
    return autoreleasepool {
      guard WindowFind.FindWindowUnderMouse() != nil else {
        return false
      }
      guard !isMouseMoveListening else { return false }
      hasAttemptedResize = false
      let mouseMoveMask = (1 << CGEventType.mouseMoved.rawValue)
      let mouseMoveEventTap = CGEvent.tapCreate(tap: .cgSessionEventTap, place: .headInsertEventTap, options: .defaultTap, eventsOfInterest: CGEventMask(mouseMoveMask), callback: { (p, t, e, rc) -> Unmanaged<CGEvent>? in
        return Unmanaged<WindowResize>.fromOpaque(rc!).takeUnretainedValue().handleMouseMove(e: e)
      }, userInfo: UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()))
      self.mouseMoveEventTap = mouseMoveEventTap
      if let mouseMoveEventTap = mouseMoveEventTap {
        let mouseMoveRunLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, mouseMoveEventTap, 0)
        self.mouseMoveRunLoopSource = mouseMoveRunLoopSource
        CFRunLoopAddSource(CFRunLoopGetCurrent(), mouseMoveRunLoopSource, .commonModes)
        CGEvent.tapEnable(tap: mouseMoveEventTap, enable: true)
        isMouseMoveListening = true
      }
      return true
    }
  }

  func stop() {
    guard isMouseMoveListening else { return }
    cleanupEventTap()
    if isResizingWindow {
      resetResizeState()
    } else {
      hasAttemptedResize = false
    }
    reusableWindowData = nil
    cachedScreenFrame = .zero
    Debug.print("Stopping resize")
    Toast.hide()
    MagnetMonitor.s.notifyControlCompleted()
  }

  func resetState() {
    resetResizeState()
    resizeStartPosition = .zero
    windowStartBounds = .zero
  }

  private func handleMouseMove(e: CGEvent) -> Unmanaged<CGEvent>? {
    return autoreleasepool {
      if MagnetInfo.intervalResize {
        let currentTime = CACurrentMediaTime()
        if currentTime - lastProcessTime < MagnetInfo.resizeSplit {
          return Unmanaged.passUnretained(e)
        }
        lastProcessTime = currentTime
      }
      if !isResizingWindow && !hasAttemptedResize {
        startWindowResizeInternal()
      } else if isResizingWindow {
        _ = continueWindowResize(e: e)
      }
      return Unmanaged.passUnretained(e)
    }
  }

  private func startWindowResizeInternal() {
    return autoreleasepool {
      guard let wi = WindowFind.FindWindowUnderMouse() else { return }
      if let currentWindow = resizedWindow, currentWindow.pid == wi.pid && currentWindow.wid == wi.wid {
        return
      }
      guard let element = WindowFind.FindWindowElement(wi: wi), canResizeWindow(element: element) else {
        hasAttemptedResize = true
        return
      }
      if reusableWindowData != nil {
        reusableWindowData = WindowData(pid: wi.pid, wid: wi.wid, app: wi.app, bounds: wi.bounds, element: element)
        resizedWindow = reusableWindowData
      } else {
        resizedWindow = WindowData(pid: wi.pid, wid: wi.wid, app: wi.app, bounds: wi.bounds, element: element)
        reusableWindowData = resizedWindow
      }
      setupResizeWithWindow(resizedWindow!)
    }
  }

  private func continueWindowResize(e: CGEvent) -> Unmanaged<CGEvent>? {
    return autoreleasepool {
      guard let window = resizedWindow else { return Unmanaged.passUnretained(e) }
      let currentMousePosition = NSEvent.mouseLocation
      guard isMouseInScreenBounds(currentMousePosition) else { return Unmanaged.passUnretained(e) }
      let newSize = calculateNewWindowSize(currentMousePosition: currentMousePosition)
      if shouldApplyMagnetResize(window: window, finalSize: newSize) {
        return Unmanaged.passUnretained(e)
      }
      let finalSize = handleWindowResizeSize(newSize, for: window)
      SwiftManager.s.resizeWindow(wi: window, to: finalSize)
      return Unmanaged.passUnretained(e)
    }
  }

  func handleWindowResizeSize(_ newSize: CGSize, for window: WindowData) -> CGSize {
    return autoreleasepool {
      let targetScreen = findScreenForWindow(window)
      guard let screen = targetScreen else { return newSize }
      let effectiveFrame = getEffectiveScreenFrame(for: screen)
      let minSize = CGSize(width: 100, height: 100)
      let maxSize = effectiveFrame.size
      return CGSize(
        width: max(minSize.width, min(maxSize.width, newSize.width)),
        height: max(minSize.height, min(maxSize.height, newSize.height))
      )
    }
  }

  private func cleanupEventTap() {
    if let mouseMoveEventTap = mouseMoveEventTap {
      CGEvent.tapEnable(tap: mouseMoveEventTap, enable: false)
      CFMachPortInvalidate(mouseMoveEventTap)
    }
    if let mouseMoveRunLoopSource = mouseMoveRunLoopSource {
      CFRunLoopRemoveSource(CFRunLoopGetCurrent(), mouseMoveRunLoopSource, .commonModes)
    }
    mouseMoveEventTap = nil
    mouseMoveRunLoopSource = nil
    isMouseMoveListening = false
  }

  private func setupResizeWithWindow(_ wi: WindowData) {
    resizedWindow = wi
    resizeStartPosition = NSEvent.mouseLocation
    windowStartBounds = wi.bounds
    isResizingWindow = true
    guard let element = WindowFind.FindWindowElement(wi: wi) else { return }
    SwiftManager.s.activateWindow(fast: false, wi: wi, element: element) {}
    Debug.print("Starting resize window: [\(wi.app), \(wi.pid), \(wi.wid)]")
    if MagnetConfig.magnetTip {
      Toast.showPersistent(message: String(format: NSLocalizedString("magnet.settings.magnet_resize.message", comment: ""), wi.app))
    }
  }

  private func canResizeWindow(element: AXUIElement) -> Bool {
    return autoreleasepool {
      var fullScreenValue: AnyObject?
      let fullScreenResult = AXUIElementCopyAttributeValue(element, "AXFullScreen" as CFString, &fullScreenValue)
      if fullScreenResult == .success, let isFullScreen = fullScreenValue as? NSNumber, isFullScreen.boolValue {
        return false
      }
      return true
    }
  }

  private func isMouseInScreenBounds(_ position: CGPoint) -> Bool {
    let currentTime = CACurrentMediaTime()
    if currentTime - lastScreenCacheTime > 1.0 || cachedScreenFrame == .zero {
      if let screen = NSScreen.screens.first(where: { $0.frame.contains(position) }) {
        cachedScreenFrame = screen.frame
      } else {
        cachedScreenFrame = NSScreen.main?.frame ?? CGRect.zero
      }
      lastScreenCacheTime = currentTime
    }
    return cachedScreenFrame.contains(position)
  }

  private func calculateNewWindowSize(currentMousePosition: CGPoint) -> CGSize {
    let newWidth = max(100, currentMousePosition.x - windowStartBounds.origin.x)
    let primaryScreenHeight = NSScreen.screens.first?.frame.height ?? NSScreen.main?.frame.height ?? 0
    let mouseYInWindowCoordinates = primaryScreenHeight - currentMousePosition.y
    let newHeight = max(100, mouseYInWindowCoordinates - windowStartBounds.origin.y)
    return CGSize(width: newWidth, height: newHeight)
  }

  private func shouldApplyMagnetResize(window: WindowData, finalSize: CGSize) -> Bool {
    return autoreleasepool {
      guard WindowMagnet.s.isMagnetEnabled else { return false }
      let targetScreen = findScreenForWindow(window)
      guard let screen = targetScreen else { return false }
      let tempBounds = CGRect(origin: window.bounds.origin, size: finalSize)
      let resizeDragMagnetResult = WindowMagnet.s.resizeMagnet(for: WindowData(pid: window.pid, wid: window.wid, app: window.app, bounds: tempBounds, element: window.element), targetScreen: screen)
      if resizeDragMagnetResult.shouldSnap {
        SwiftManager.s.resizeWindow(wi: window, to: resizeDragMagnetResult.targetSize)
        return true
      }
      return false
    }
  }

  private func resetResizeState() {
    isResizingWindow = false
    hasAttemptedResize = false
    resizedWindow = nil
  }

  private func findScreenForWindow(_ window: WindowData) -> NSScreen? {
    let windowCenter = CGPoint(
      x: window.bounds.origin.x + window.bounds.size.width / 2,
      y: window.bounds.origin.y + window.bounds.size.height / 2
    )
    if NSScreen.main?.frame.contains(windowCenter) == true {
      return NSScreen.main
    }
    for screen in NSScreen.screens {
      if screen != NSScreen.main && screen.frame.contains(windowCenter) {
        return screen
      }
    }
    return NSScreen.main
  }

  private func getEffectiveScreenFrame(for screen: NSScreen) -> CGRect {
    let visibleFrame = screen.visibleFrame
    let effectiveOrigin = CGPoint(x: visibleFrame.origin.x, y: screen.frame.maxY - visibleFrame.maxY)
    return CGRect(origin: effectiveOrigin, size: visibleFrame.size)
  }
}
