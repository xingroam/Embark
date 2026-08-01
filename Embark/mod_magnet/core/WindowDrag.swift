import SwiftUI
import ApplicationServices

class WindowDrag {
  static let s = WindowDrag()
  private var isDraggingWindow: Bool = false
  private var draggedWindow: WindowData?
  private var dragStartPosition: CGPoint = .zero
  private var windowStartPosition: CGPoint = .zero
  private var hasAttemptedDrag: Bool = false
  private var isMouseMoveListening: Bool = false
  private var mouseMoveEventTap: CFMachPort?
  private var mouseMoveRunLoopSource: CFRunLoopSource?
  private var lastProcessTime: TimeInterval = 0
  private var reusableWindowData: WindowData?

  private init() {}

  deinit {
    cleanupEventTap()
  }

  func startMagnetDrag() -> Bool {
    resetState()
    return startInternal()
  }

  func stop() {
    guard isMouseMoveListening else { return }
    cleanupEventTap()
    if isDraggingWindow {
      stopInternal()
    }
    reusableWindowData = nil
    Debug.print("Stopping drag")
    Toast.hide()
    MagnetMonitor.s.notifyControlCompleted()
  }

  func resetState() {
    isDraggingWindow = false
    hasAttemptedDrag = false
    draggedWindow = nil
    dragStartPosition = .zero
    windowStartPosition = .zero
    lastProcessTime = 0
  }

  private func startInternal() -> Bool {
    return autoreleasepool {
      guard WindowFind.FindWindowUnderMouse() != nil else {
        return false
      }
      guard !isMouseMoveListening else { return false }
      let mouseMoveMask = (1 << CGEventType.mouseMoved.rawValue)
      let mouseMoveEventTap = CGEvent.tapCreate(tap: .cgSessionEventTap, place: .headInsertEventTap, options: .defaultTap, eventsOfInterest: CGEventMask(mouseMoveMask), callback: { (p, t, e, rc) -> Unmanaged<CGEvent>? in
        return Unmanaged<WindowDrag>.fromOpaque(rc!).takeUnretainedValue().handleMouseMove(e: e)
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

  private func handleMouseMove(e: CGEvent) -> Unmanaged<CGEvent>? {
    return autoreleasepool {
      if MagnetInfo.intervalDrag {
        let currentTime = CACurrentMediaTime()
        if currentTime - lastProcessTime < MagnetInfo.dragSplit {
          return Unmanaged.passUnretained(e)
        }
        lastProcessTime = currentTime
      }
      if !isDraggingWindow && !hasAttemptedDrag {
        startWindowDragInternal()
      } else if isDraggingWindow {
        _ = continueWindowDrag(e: e)
      }
      return Unmanaged.passUnretained(e)
    }
  }

  private func startWindowDragInternal() {
    return autoreleasepool {
      guard let wi = WindowFind.FindWindowUnderMouse(), let element = WindowFind.FindWindowElement(wi: wi) else {
        hasAttemptedDrag = true
        return
      }
      var positionValue: AnyObject?
      let positionResult = AXUIElementCopyAttributeValue(element, kAXPositionAttribute as CFString, &positionValue)
      if positionResult != .success {
        hasAttemptedDrag = true
        return
      }
      if reusableWindowData != nil {
        reusableWindowData = WindowData(pid: wi.pid, wid: wi.wid, app: wi.app, bounds: wi.bounds, element: element)
        draggedWindow = reusableWindowData
      } else {
        draggedWindow = WindowData(pid: wi.pid, wid: wi.wid, app: wi.app, bounds: wi.bounds, element: element)
        reusableWindowData = draggedWindow
      }
      dragStartPosition = NSEvent.mouseLocation
      windowStartPosition = wi.bounds.origin
      isDraggingWindow = true
      hasAttemptedDrag = false
      SwiftManager.s.activateWindow(fast: false, wi: wi, element: element) {}
      Debug.print("Starting drag window: [\(wi.app), \(wi.pid), \(wi.wid)]")
      if MagnetConfig.magnetTip {
        Toast.showPersistent(message: String(format: NSLocalizedString("magnet.settings.magnet_drag.message", comment: ""), wi.app))
      }
    }
  }

  private func continueWindowDrag(e: CGEvent) -> Unmanaged<CGEvent>? {
    return autoreleasepool {
      guard let window = draggedWindow else { return Unmanaged.passUnretained(e) }
      let currentMousePosition = NSEvent.mouseLocation
      let deltaX = currentMousePosition.x - dragStartPosition.x
      let deltaY = currentMousePosition.y - dragStartPosition.y
      let newPosition = CGPoint(x: windowStartPosition.x + deltaX, y: windowStartPosition.y - deltaY)
      let finalPosition = handleWindowDragPosition(newPosition, for: window)
      SwiftManager.s.moveWindow(wi: window, to: finalPosition)
      return Unmanaged.passUnretained(e)
    }
  }

  private func stopInternal() {
    isDraggingWindow = false
    hasAttemptedDrag = false
    draggedWindow = nil
  }

  func handleWindowDragPosition(_ newPosition: CGPoint, for window: WindowData) -> CGPoint {
    return autoreleasepool {
      let targetScreen = findScreenForWindow(window)
      guard let screen = targetScreen else { return newPosition }
      let windowSize = window.bounds.size
      if WindowMagnet.s.isMagnetEnabled {
        let tempWindow = WindowData(pid: window.pid, wid: window.wid, app: window.app, bounds: CGRect(origin: newPosition, size: windowSize), element: window.element)
        let magnetResult = WindowMagnet.s.dragMagnet(for: tempWindow, targetScreen: screen)
        if magnetResult.shouldSnap {
          WindowMagnet.s.applyDragMagnetResult(magnetResult, to: tempWindow)
          return magnetResult.targetPosition
        }
        return newPosition
      }
      return newPosition
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
