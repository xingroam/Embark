import SwiftUI
import ApplicationServices
import AppKit

class SwiftManager {
  static let s = SwiftManager()
  private var minList: [WindowData] = []
  private var maxList: [WindowData] = []
  private let positionTolerance: CGFloat = 1.0
  private var sizeChangeTimers: [SwiftMaxData: Timer] = [:]

  func cleanup() {
    autoreleasepool {
      if !minList.isEmpty {
        minList.removeAll { !WindowFind.FindWindowByPidWid(pid: $0.pid, wid: $0.wid) }
      }
      if !maxList.isEmpty {
        maxList.removeAll { !WindowFind.FindWindowByPidWid(pid: $0.pid, wid: $0.wid) }
      }
      if !sizeChangeTimers.isEmpty {
        let keysToRemove = sizeChangeTimers.keys.filter { windowMaxData in
          !WindowFind.FindWindowByPidWid(pid: windowMaxData.pid, wid: windowMaxData.wid)
        }
        for key in keysToRemove {
          if let timer = sizeChangeTimers[key] {
            timer.invalidate()
            sizeChangeTimers.removeValue(forKey: key)
          }
        }
      }
    }
  }

  func removeFromMaxList(element: AXUIElement) {
    autoreleasepool {
      var pidValue: pid_t = 0
      let pidResult = AXUIElementGetPid(element, &pidValue)
      guard pidResult == .success else { return }
      guard let app = NSRunningApplication(processIdentifier: pidValue), let bundleId = app.bundleIdentifier else { return }
      maxList.removeAll {
        guard let itemApp = NSRunningApplication(processIdentifier: $0.pid) else { return false }
        return itemApp.bundleIdentifier == bundleId
      }
    }
  }

  func MinWindow(targetWindow: WindowData? = nil) {
    autoreleasepool {
      var wi: WindowData? = targetWindow
      if wi == nil {
        wi = WindowFind.FindWindowUnderMouse()
      }
      guard var window = wi else { return }
      guard let element = WindowFind.FindWindowElement(wi: window) else { return }
      window = WindowData(pid: window.pid, wid: window.wid, app: window.app, bounds: window.bounds, element: element)
      minList.removeAll { $0.pid == window.pid && $0.wid == window.wid }
      minList.append(window)
      let result = AXUIElementSetAttributeValue(element, kAXMinimizedAttribute as CFString, kCFBooleanTrue as CFTypeRef)
      if result == .success {
        Debug.print("Minimize window: [\(window.app), \(window.pid), \(window.wid)]")
      }
    }
  }

  func ReWindow() {
    autoreleasepool {
      guard let wi = minList.popLast(), let element = wi.element else { return }
      var minimizedValue: AnyObject?
      let minimizedResult = AXUIElementCopyAttributeValue(element, kAXMinimizedAttribute as CFString, &minimizedValue)
      let isMinimized = (minimizedResult == .success) ? ((minimizedValue as? NSNumber)?.boolValue ?? false) : false
      if isMinimized {
        let result = AXUIElementSetAttributeValue(element, kAXMinimizedAttribute as CFString, kCFBooleanFalse as CFTypeRef)
        if result == .success {
          activateWindow(wi: wi, element: element) {
            Debug.print("Restore window: [\(wi.app), \(wi.pid), \(wi.wid)]")
          }
        }
      } else if minList.count > 0 {
        ReWindow()
      }
    }
  }

  func MaxWindow(targetWindow: WindowData? = nil, mode: SwiftMaximizeMode) {
    autoreleasepool {
      var wi: WindowData? = targetWindow
      if wi == nil {
        wi = WindowFind.FindWindowUnderMouse()
      }
      guard var window = wi else { return }
      guard let element = WindowFind.FindWindowElement(wi: window) else { return }
      let hiddenWindow = SlideMonitor.s.hiddenWindows.first { $0.windowData.pid == window.pid && $0.windowData.wid == window.wid }
      if let hiddenWindow = hiddenWindow {
        hiddenWindow.Lock()
        startSizeChangeTimer(for: hiddenWindow)
      }
      if mode == .max {
        if checkWindowFullScreen(element: element) {
          fullWindow(wi: WindowData(pid: window.pid, wid: window.wid, app: window.app, bounds: window.bounds, element: element))
          return
        }
        if let index = maxList.firstIndex(where: { $0.wid == window.wid && $0.pid == window.pid }) {
          reMaxWindow(maxList.remove(at: index))
        } else {
          window = WindowData(pid: window.pid, wid: window.wid, app: window.app, bounds: window.bounds, element: element)
          if checkWindowMaxScreen(wi: window) {
            return
          }
          maxList.removeAll { $0.pid == window.pid && $0.wid == window.wid }
          maxList.append(window)
          maxWindow(wi: window)
        }
      } else {
        fullWindow(wi: WindowData(pid: window.pid, wid: window.wid, app: window.app, bounds: window.bounds, element: element))
      }
    }
  }

  private func maxWindow(wi: WindowData) {
    guard let element = wi.element else { return }
    let targetScreen = getTargetScreenForWindow(wi: wi)
    var position = CGPoint(x: targetScreen.visibleFrame.origin.x, y: targetScreen.frame.maxY - targetScreen.visibleFrame.maxY)
    var size = targetScreen.visibleFrame.size
    let positionResult = AXUIElementSetAttributeValue(element, kAXPositionAttribute as CFString, AXValueCreate(.cgPoint, &position)!)
    let sizeResult = AXUIElementSetAttributeValue(element, kAXSizeAttribute as CFString, AXValueCreate(.cgSize, &size)!)
    if positionResult == .success && sizeResult == .success {
      activateWindow(fast: false, wi: wi, element: element) {
        Debug.print("Maximize window: [\(wi.app), \(wi.pid), \(wi.wid)] on screen: \(targetScreen.localizedName)")
      }
    }
  }

  private func reMaxWindow(_ wi: WindowData) {
    guard let element = wi.element else { return }
    if checkWindowMaxScreen(wi: wi) {
      return
    }
    var restorePosition = wi.bounds.origin
    var restoreSize = wi.bounds.size
    let positionResult = AXUIElementSetAttributeValue(element, kAXPositionAttribute as CFString, AXValueCreate(.cgPoint, &restorePosition)!)
    let sizeResult = AXUIElementSetAttributeValue(element, kAXSizeAttribute as CFString, AXValueCreate(.cgSize, &restoreSize)!)
    if positionResult == .success && sizeResult == .success {
      activateWindow(wi: wi, element: element) {
        Debug.print("Restore window: [\(wi.app), \(wi.pid), \(wi.wid)]")
      }
    }
  }

  private func fullWindow(wi: WindowData) {
    guard let element = wi.element else { return }
    var fullScreenValue: AnyObject?
    let fullScreenResult = AXUIElementCopyAttributeValue(element, "AXFullScreen" as CFString, &fullScreenValue)
    let isFullScreen = (fullScreenResult == .success) ? ((fullScreenValue as? NSNumber)?.boolValue ?? false) : false
    let value: CFTypeRef = isFullScreen ? kCFBooleanFalse! : kCFBooleanTrue!
    let result = AXUIElementSetAttributeValue(element, "AXFullScreen" as CFString, value)
    if result == .success {
      Debug.print("Fullscreen window: [\(wi.app), \(wi.pid), \(wi.wid)], new state: \(!isFullScreen)")
    }
  }

  func ActivateWindow(wi: WindowData) {
    autoreleasepool {
      if wi.isTimeout {
        if let app = NSRunningApplication(processIdentifier: wi.pid) {
          app.activate(options: .activateIgnoringOtherApps)
        }
        return
      }
      guard let element = wi.element ?? WindowFind.FindWindowElement(wi: wi) else { return }
      if wi.isMinimized {
        let result = AXUIElementSetAttributeValue(element, kAXMinimizedAttribute as CFString, kCFBooleanFalse as CFTypeRef)
        if result == .success {
           activateWindow(fast: false, wi: wi, element: element) {
             Debug.print("Restore window: [\(wi.app), \(wi.pid), \(wi.wid)]")
           }
        }
      } else {
        activateWindow(fast: false, wi: wi, element: element) {
           Debug.print("Activate window: [\(wi.app), \(wi.pid), \(wi.wid)]")
        }
      }
    }
  }

  func CloseWindow(targetWindow: WindowData? = nil, mode: SwiftCloseMode) {
    autoreleasepool {
      var wi: WindowData? = targetWindow
      if wi == nil {
        wi = WindowFind.FindWindowUnderMouse()
      }
      guard let window = wi else { return }
      guard let element = WindowFind.FindWindowElement(wi: window) else { return }
      switch mode {
      case .standard:
        commandClose(wi: window, element: element) { _ in
          Debug.print("Standard close window: [\(window.app), \(window.pid), \(window.wid)]")
        }
      case .direct:
        if buttonClose(element: element) {
          Debug.print("Direct close window: [\(window.app), \(window.pid), \(window.wid)]")
          return
        }
        commandClose(wi: window, element: element) { _ in
          Debug.print("Direct close window: [\(window.app), \(window.pid), \(window.wid)]")
        }
      case .force:
        if buttonClose(element: element) {
          return
        }
        commandClose(wi: window, element: element) { success in
          if !success {
            self.terminateApplication(pid: window.pid)
          }
        }
      }
    }
  }

  private func buttonClose(element: AXUIElement) -> Bool {
    var closeButtonValue: AnyObject?
    if AXUIElementCopyAttributeValue(element, kAXCloseButtonAttribute as CFString, &closeButtonValue) == .success, let closeButton = closeButtonValue, AXUIElementPerformAction(closeButton as! AXUIElement, kAXPressAction as CFString) == .success {
      return true
    }
    return false
  }

  private func commandClose(wi: WindowData, element: AXUIElement, callback: @escaping (Bool) -> Void) {
    activateWindow(fast: false, wi: wi, element: element) {
      if let frontApp = NSWorkspace.shared.frontmostApplication {
        if frontApp.processIdentifier != wi.pid {
          callback(false)
          return
        }
      }
      let source = CGEventSource(stateID: .hidSystemState)
      let commandDown = CGEvent(keyboardEventSource: source, virtualKey: 0x37, keyDown: true)
      let wDown = CGEvent(keyboardEventSource: source, virtualKey: 0x0D, keyDown: true)
      let wUp = CGEvent(keyboardEventSource: source, virtualKey: 0x0D, keyDown: false)
      let commandUp = CGEvent(keyboardEventSource: source, virtualKey: 0x37, keyDown: false)
      commandDown?.flags = .maskCommand
      wDown?.flags = .maskCommand
      commandDown?.post(tap: .cghidEventTap)
      wDown?.post(tap: .cghidEventTap)
      wUp?.post(tap: .cghidEventTap)
      commandUp?.post(tap: .cghidEventTap)
      callback(true)
    }
  }

  func activateWindow(fast: Bool = true, wi: WindowData, element: AXUIElement, callback: @escaping () -> Void) {
    if fast {
      if WindowActivator.activateWindow(wi.wid, pid: wi.pid) {
        callback()
        return
      }
    }
    if let app = NSRunningApplication(processIdentifier: wi.pid), app.activate(options: .activateIgnoringOtherApps) {
      if WindowActivator.activateWindow(element: element) {
        checkWindowActivationAndExecute(element: element){
          callback()
        }
      } else if WindowActivator.activateWindow(wi.wid, pid: wi.pid) {
        callback()
      }
    } else if WindowActivator.activateWindow(wi.wid, pid: wi.pid) {
      callback()
    }
  }

  func terminateApplication(pid: Int32) {
    if let app = NSRunningApplication(processIdentifier: pid) {
      DispatchQueue.main.async {
        app.terminate()
        Debug.print("Terminate application: [\(app.localizedName ?? ""), \(app.processIdentifier)]")
      }
    }
  }

  func moveWindow(wi: WindowData, to position: CGPoint) {
    autoreleasepool {
      guard let element = wi.element else { return }
      var newPosition = position
      AXUIElementSetAttributeValue(element, kAXPositionAttribute as CFString, AXValueCreate(.cgPoint, &newPosition)!)
    }
  }

  func resizeWindow(wi: WindowData, to size: CGSize) {
    autoreleasepool {
      guard let element = wi.element else { return }
      var newSize = size
      AXUIElementSetAttributeValue(element, kAXSizeAttribute as CFString, AXValueCreate(.cgSize, &newSize)!)
    }
  }

  func getAppWindowCount(pid: pid_t) -> Int {
    let appElement = AXUIElementCreateApplication(pid)
    var windowsValue: AnyObject?
    let result = AXUIElementCopyAttributeValue(appElement, kAXWindowsAttribute as CFString, &windowsValue)
    guard result == .success, let windows = windowsValue as? [AXUIElement] else {
      return 0
    }
    return windows.count
  }

  func isWindowActivated(element: AXUIElement) -> Bool {
    var mainValue: AnyObject?
    var focusedValue: AnyObject?
    let mainResult = AXUIElementCopyAttributeValue(element, kAXMainAttribute as CFString, &mainValue)
    let focusedResult = AXUIElementCopyAttributeValue(element, kAXFocusedAttribute as CFString, &focusedValue)
    if mainResult == .success, let main = mainValue as? NSNumber {
      return main.boolValue
    }
    if focusedResult == .success, let focused = focusedValue as? NSNumber {
      return focused.boolValue
    }
    return false
  }

  func isWindowExists(element: AXUIElement) -> Bool {
    var positionValue: AnyObject?
    let result = AXUIElementCopyAttributeValue(element, kAXPositionAttribute as CFString, &positionValue)
    return result == .success
  }

  private func checkWindowActivationAndExecute(element: AXUIElement, callback: @escaping () -> Void) {
    DispatchQueue.global(qos: .userInitiated).async { [weak self] in
      guard let self = self else { return }
      let startTime = Date()
      let timeout: TimeInterval = 5.0
      while true {
        if Date().timeIntervalSince(startTime) > timeout {
          return
        }
        if !isWindowExists(element: element) {
          return
        }
        if isWindowActivated(element: element) == true {
          DispatchQueue.main.async {
            callback()
          }
          return
        }
        Thread.sleep(forTimeInterval: 0.01)
      }
    }
  }

  private func checkWindowFullScreen(element: AXUIElement) -> Bool {
    var fullScreenValue: AnyObject?
    let fullScreenResult = AXUIElementCopyAttributeValue(element, "AXFullScreen" as CFString, &fullScreenValue)
    return (fullScreenResult == .success) ? ((fullScreenValue as? NSNumber)?.boolValue ?? false) : false
  }

  private func checkWindowMaxScreen(wi: WindowData) -> Bool {
    let targetScreen = getTargetScreenForWindow(wi: wi)
    let expectedOrigin = CGPoint(x: targetScreen.visibleFrame.origin.x, y: targetScreen.frame.maxY - targetScreen.visibleFrame.maxY)
    let expectedSize = targetScreen.visibleFrame.size
    let tolerance: CGFloat = 20.0
    let originMatch = abs(wi.bounds.origin.x - expectedOrigin.x) <= tolerance && abs(wi.bounds.origin.y - expectedOrigin.y) <= tolerance
    let sizeMatch = abs(wi.bounds.size.width - expectedSize.width) <= tolerance && abs(wi.bounds.size.height - expectedSize.height) <= tolerance
    return originMatch && sizeMatch
  }

  private func getTargetScreenForWindow(wi: WindowData) -> NSScreen {
    let windowCenter = CGPoint(
      x: wi.bounds.origin.x + wi.bounds.size.width / 2,
      y: wi.bounds.origin.y + wi.bounds.size.height / 2
    )
    if NSScreen.main?.frame.contains(windowCenter) == true {
      return NSScreen.main!
    }
    for screen in NSScreen.screens {
      if screen != NSScreen.main && screen.frame.contains(windowCenter) {
        return screen
      }
    }
    return NSScreen.screens.min(by: { screen1, screen2 in
      let distance1 = sqrt(pow(screen1.frame.midX - windowCenter.x, 2) + pow(screen1.frame.midY - windowCenter.y, 2))
      let distance2 = sqrt(pow(screen2.frame.midX - windowCenter.x, 2) + pow(screen2.frame.midY - windowCenter.y, 2))
      return distance1 < distance2
    }) ?? NSScreen.main!
  }

  private func startSizeChangeTimer(for hiddenWindow: HiddenWindow) {
    let windowMaxData = SwiftMaxData(windowData: hiddenWindow.windowData)
    stopSizeChangeTimer(for: windowMaxData)
    let initialBounds = hiddenWindow.windowData.bounds
    let timer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { [weak self] timer in
      guard let self = self else {
        timer.invalidate()
        return
      }
      if let currentBounds = WindowFind.GetWindowBounds(windowData: hiddenWindow.windowData) {
        if !self.boundsEqual(initialBounds, currentBounds) {
          hiddenWindow.UnLock()
          timer.invalidate()
          self.sizeChangeTimers.removeValue(forKey: windowMaxData)
        }
      } else {
        hiddenWindow.UnLock()
        timer.invalidate()
        self.sizeChangeTimers.removeValue(forKey: windowMaxData)
      }
    }
    sizeChangeTimers[windowMaxData] = timer
  }

  private func stopSizeChangeTimer(for windowMaxData: SwiftMaxData) {
    if let timer = sizeChangeTimers[windowMaxData] {
      timer.invalidate()
      sizeChangeTimers.removeValue(forKey: windowMaxData)
    }
  }

  private func boundsEqual(_ bounds1: CGRect, _ bounds2: CGRect) -> Bool {
    return abs(bounds1.origin.x - bounds2.origin.x) <= positionTolerance &&
           abs(bounds1.origin.y - bounds2.origin.y) <= positionTolerance &&
           abs(bounds1.size.width - bounds2.size.width) <= positionTolerance &&
           abs(bounds1.size.height - bounds2.size.height) <= positionTolerance
  }
}
