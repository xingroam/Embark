import Cocoa
import ApplicationServices

class WindowActivator {
  private static let windowPositionTolerance: CGFloat = 1.0
  private static let windowListOptions: CGWindowListOption = [.optionOnScreenOnly, .excludeDesktopElements]

  @discardableResult
  static func activateWindow(_ windowId: CGWindowID) -> Bool {
    return activateWindow(windowId, pid: nil)
  }

  @discardableResult
  static func activateWindow(_ windowId: CGWindowID, pid: pid_t?) -> Bool {
    guard let runningApp = getRunningApplication(for: windowId, pid: pid) else {
      return false
    }
    if runningApp.bundleURL == Bundle.main.bundleURL {
      return activateOwnWindow(windowId)
    }
    if isWindowlessApp(runningApp) {
      return activateWindowlessApp(runningApp)
    }
    return activateWithAccessibility(windowId, runningApp: runningApp)
  }

  @discardableResult
  static func activateWindow(element: AXUIElement) -> Bool {
    DispatchQueue.main.async {
      AXUIElementPerformAction(element, kAXRaiseAction as CFString)
      AXUIElementSetAttributeValue(element, kAXMainAttribute as CFString, kCFBooleanTrue as CFTypeRef)
    }
    return true
  }

  @discardableResult
  static func activateWindow(element: AXUIElement, pid: pid_t?) -> Bool {
    if let pid = pid, let runningApp = NSRunningApplication(processIdentifier: pid) {
      DispatchQueue.main.async {
        runningApp.activate(options: .activateIgnoringOtherApps)
      }
    }
    return activateWindow(element: element)
  }

  private static func getRunningApplication(for windowId: CGWindowID, pid: pid_t?) -> NSRunningApplication? {
    if let pid = pid {
      return NSRunningApplication(processIdentifier: pid)
    }
    let windowList = getWindowList()
    return findRunningApplication(for: windowId, in: windowList)
  }

  private static func getWindowList() -> [[String: Any]] {
    return CGWindowListCopyWindowInfo(windowListOptions, kCGNullWindowID) as? [[String: Any]] ?? []
  }

  private static func findRunningApplication(for windowId: CGWindowID, in windowList: [[String: Any]]) -> NSRunningApplication? {
    for windowInfo in windowList {
      guard let windowID = windowInfo[kCGWindowNumber as String] as? CGWindowID, windowID == windowId, let ownerPID = windowInfo[kCGWindowOwnerPID as String] as? pid_t else {
        continue
      }
      return NSRunningApplication(processIdentifier: ownerPID)
    }
    return nil
  }

  private static func isWindowlessApp(_ app: NSRunningApplication) -> Bool {
    return app.activationPolicy != .regular
  }

  private static func activateOwnWindow(_ windowId: CGWindowID) -> Bool {
    DispatchQueue.main.async {
      NSApp.activate(ignoringOtherApps: true)
      if let window = NSApp.windows.first(where: { $0.windowNumber == Int(windowId) }) {
        window.makeKeyAndOrderFront(nil)
      }
    }
    return true
  }

  private static func activateWindowlessApp(_ runningApp: NSRunningApplication) -> Bool {
    DispatchQueue.main.async {
      guard let bundleURL = runningApp.bundleURL else {
        runningApp.activate(options: .activateIgnoringOtherApps)
        return
      }
      if #available(macOS 11.0, *) {
        let configuration = NSWorkspace.OpenConfiguration()
        NSWorkspace.shared.openApplication(at: bundleURL, configuration: configuration) { _, error in
          if error != nil {
            runningApp.activate(options: .activateIgnoringOtherApps)
          }
        }
      } else {
        if (try? NSWorkspace.shared.launchApplication(at: bundleURL, configuration: [:])) == nil {
          runningApp.activate(options: .activateIgnoringOtherApps)
        }
      }
    }
    return true
  }

  private static func activateWithAccessibility(_ windowId: CGWindowID, runningApp: NSRunningApplication) -> Bool {
    DispatchQueue.main.async {
      runningApp.activate(options: .activateIgnoringOtherApps)
      DispatchQueue.global(qos: .userInitiated).async {
        focusWindowWithAccessibility(windowId, pid: runningApp.processIdentifier)
      }
    }
    return true
  }

  private static func focusWindowWithAccessibility(_ windowId: CGWindowID, pid: pid_t) {
    let appElement = AXUIElementCreateApplication(pid)
    var windows: AnyObject?
    let result = AXUIElementCopyAttributeValue(appElement, kAXWindowsAttribute as CFString, &windows)
    guard result == .success, let windowArray = windows as? [AXUIElement] else {
      return
    }
    guard let targetWindowInfo = findTargetWindowInfo(windowId: windowId) else {
      return
    }
    let targetBounds = extractWindowBounds(from: targetWindowInfo)
    focusWindowByBounds(windowArray: windowArray, targetBounds: targetBounds)
  }

  private static func findTargetWindowInfo(windowId: CGWindowID) -> [String: Any]? {
    let windowList = getWindowList()
    return windowList.first { $0[kCGWindowNumber as String] as? CGWindowID == windowId }
  }

  private static func extractWindowBounds(from windowInfo: [String: Any]) -> CGRect {
    let bounds = windowInfo[kCGWindowBounds as String] as? [String: Any] ?? [:]
    let x = bounds["X"] as? CGFloat ?? 0
    let y = bounds["Y"] as? CGFloat ?? 0
    let width = bounds["Width"] as? CGFloat ?? 0
    let height = bounds["Height"] as? CGFloat ?? 0
    return CGRect(x: x, y: y, width: width, height: height)
  }

  private static func focusWindowByBounds(windowArray: [AXUIElement], targetBounds: CGRect) {
    for windowElement in windowArray {
      guard let windowPosition = getWindowPosition(windowElement), let windowSize = getWindowSize(windowElement) else {
        continue
      }
      if isWindowMatchingBounds(position: windowPosition, size: windowSize, targetBounds: targetBounds) {
        focusWindow(windowElement)
        break
      }
    }
  }

  private static func getWindowPosition(_ windowElement: AXUIElement) -> CGPoint? {
    var positionValue: AnyObject?
    let result = AXUIElementCopyAttributeValue(windowElement, kAXPositionAttribute as CFString, &positionValue)
    guard result == .success, let position = positionValue as? NSValue else { return nil }
    var windowPosition = CGPoint.zero
    position.getValue(&windowPosition)
    return windowPosition
  }

  private static func getWindowSize(_ windowElement: AXUIElement) -> CGSize? {
    var sizeValue: AnyObject?
    let result = AXUIElementCopyAttributeValue(windowElement, kAXSizeAttribute as CFString, &sizeValue)
    guard result == .success, let size = sizeValue as? NSValue else { return nil }
    var windowSize = CGSize.zero
    size.getValue(&windowSize)
    return windowSize
  }

  private static func isWindowMatchingBounds(position: CGPoint, size: CGSize, targetBounds: CGRect) -> Bool {
    return abs(position.x - targetBounds.origin.x) < windowPositionTolerance &&
           abs(position.y - targetBounds.origin.y) < windowPositionTolerance &&
           abs(size.width - targetBounds.size.width) < windowPositionTolerance &&
           abs(size.height - targetBounds.size.height) < windowPositionTolerance
  }

  private static func focusWindow(_ windowElement: AXUIElement) {
    AXUIElementPerformAction(windowElement, kAXRaiseAction as CFString)
    AXUIElementSetAttributeValue(windowElement, kAXMainAttribute as CFString, kCFBooleanTrue as CFTypeRef)
  }
}
