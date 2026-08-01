import SwiftUI

class WindowList {
  private static var lastWindowList: [[String: Any]]?
  private static var lastWindowListTime: TimeInterval = 0
  private static let cacheTimeout: TimeInterval = 0.1
  private static let windowListOptions: CGWindowListOption = [.optionOnScreenOnly, .excludeDesktopElements]
  private static let positionTolerance: CGFloat = 10.0
  private static let sizeTolerance: CGFloat = 10.0

  static func GetList(hasWindowless: Bool = false) -> ([WindowData], [WindowData], [NSRunningApplication]) {
    return autoreleasepool {
      var desktopWindows: [WindowData] = []
      var minimizedWindows: [WindowData] = []
      var windowlessApps: [NSRunningApplication] = []
      let windowList = getCachedWindowList()
      let runningApps = getFilteredRunningApps()
      let windowIDMap = createWindowIDMap(from: windowList)
      for app in runningApps {
        let (appWindows, hasWindows) = processAppWindows(app: app, windowIDMap: windowIDMap)
        desktopWindows.append(contentsOf: appWindows.desktop)
        minimizedWindows.append(contentsOf: appWindows.minimized)
        if hasWindowless && !hasWindows && shouldIncludeWindowlessApp(app: app) {
          windowlessApps.append(app)
        }
      }
      return (desktopWindows, minimizedWindows, windowlessApps)
    }
  }

  private static func getCachedWindowList() -> [[String: Any]] {
    let currentTime = Date().timeIntervalSince1970
    if let cached = lastWindowList, (currentTime - lastWindowListTime) < cacheTimeout {
      return cached
    }
    if let windowList = CGWindowListCopyWindowInfo(windowListOptions, kCGNullWindowID) as? [[String: Any]] {
      lastWindowList = windowList
      lastWindowListTime = currentTime
      return windowList
    }
    return []
  }

  private static func getFilteredRunningApps() -> [NSRunningApplication] {
    return NSWorkspace.shared.runningApplications.filter { app in
      app.bundleIdentifier != "com.apple.dock" && app.bundleIdentifier != EmbarkInfo.bundleIdentifier
    }
  }

  private static func createWindowIDMap(from windowList: [[String: Any]]) -> [pid_t: [(CGWindowID, CGRect)]] {
    var windowIDMap: [pid_t: [(CGWindowID, CGRect)]] = [:]
    for windowInfo in windowList {
      guard let windowPID = windowInfo["kCGWindowOwnerPID"] as? pid_t,
            let windowID = windowInfo["kCGWindowNumber"] as? CGWindowID,
            let windowBounds = windowInfo["kCGWindowBounds"] as? [String: CGFloat] else {
        continue
      }
      let bounds = CGRect(
        x: windowBounds["X"] ?? 0,
        y: windowBounds["Y"] ?? 0,
        width: windowBounds["Width"] ?? 0,
        height: windowBounds["Height"] ?? 0
      )
      if windowIDMap[windowPID] == nil {
        windowIDMap[windowPID] = []
      }
      windowIDMap[windowPID]?.append((windowID, bounds))
    }
    return windowIDMap
  }

  private static func processAppWindows(app: NSRunningApplication, windowIDMap: [pid_t: [(CGWindowID, CGRect)]]) -> (windows: (desktop: [WindowData], minimized: [WindowData]), hasWindows: Bool) {
    var desktopWindows: [WindowData] = []
    var minimizedWindows: [WindowData] = []
    var hasWindows = false
    let appElement = AXUIElementCreateApplication(app.processIdentifier)
    var windowsValue: AnyObject?
    let result = AXUIElementCopyAttributeValue(appElement, kAXWindowsAttribute as CFString, &windowsValue)
    guard result == .success, let windows = windowsValue as? [AXUIElement] else {
      return ((desktopWindows, minimizedWindows), hasWindows)
    }
    for windowElement in windows {
      let windowProperties = getWindowProperties(windowElement)
      guard let bounds = windowProperties.bounds else { continue }
      hasWindows = true
      let windowID = findWindowID(for: app, bounds: bounds, windowIDMap: windowIDMap)
      let windowData = WindowData(
        pid: app.processIdentifier,
        wid: windowID,
        app: app.localizedName ?? "",
        bounds: bounds,
        element: windowElement
      )
      if windowProperties.isMinimized {
        minimizedWindows.append(windowData)
      } else {
        if !(app.bundleIdentifier == "com.apple.finder" && bounds.origin == .zero) {
          desktopWindows.append(windowData)
        }
      }
    }
    return ((desktopWindows, minimizedWindows), hasWindows)
  }

  private static func getWindowProperties(_ windowElement: AXUIElement) -> (bounds: CGRect?, isMinimized: Bool) {
    var minimizedValue: AnyObject?
    var positionValue: AnyObject?
    var sizeValue: AnyObject?
    let minimizedResult = AXUIElementCopyAttributeValue(windowElement, kAXMinimizedAttribute as CFString, &minimizedValue)
    let positionResult = AXUIElementCopyAttributeValue(windowElement, kAXPositionAttribute as CFString, &positionValue)
    let sizeResult = AXUIElementCopyAttributeValue(windowElement, kAXSizeAttribute as CFString, &sizeValue)
    let isMinimized = (minimizedResult == .success) ? ((minimizedValue as? NSNumber)?.boolValue ?? false) : false
    guard positionResult == .success && sizeResult == .success, let position = positionValue, let size = sizeValue else {
      return (nil, isMinimized)
    }
    var windowPosition = CGPoint.zero
    var windowSize = CGSize.zero
    AXValueGetValue(position as! AXValue, .cgPoint, &windowPosition)
    AXValueGetValue(size as! AXValue, .cgSize, &windowSize)
    return (CGRect(origin: windowPosition, size: windowSize), isMinimized)
  }

  private static func findWindowID(for app: NSRunningApplication, bounds: CGRect, windowIDMap: [pid_t: [(CGWindowID, CGRect)]]) -> CGWindowID {
    guard let appWindows = windowIDMap[app.processIdentifier] else { return 0 }
    for (windowID, windowBounds) in appWindows {
      if isWindowMatchingBounds(windowBounds: windowBounds, targetBounds: bounds) {
        return windowID
      }
    }
    return appWindows.first?.0 ?? 0
  }

  private static func isWindowMatchingBounds(windowBounds: CGRect, targetBounds: CGRect) -> Bool {
    let positionMatch = abs(windowBounds.origin.x - targetBounds.origin.x) < positionTolerance && abs(windowBounds.origin.y - targetBounds.origin.y) < positionTolerance
    let sizeMatch = abs(windowBounds.size.width - targetBounds.size.width) < sizeTolerance && abs(windowBounds.size.height - targetBounds.size.height) < sizeTolerance
    return positionMatch && sizeMatch
  }

  private static func shouldIncludeWindowlessApp(app: NSRunningApplication) -> Bool {
    return app.activationPolicy != .prohibited && hasDockRunningIndicator(app: app)
  }

  private static func hasDockRunningIndicator(app: NSRunningApplication) -> Bool {
    guard app.activationPolicy == .regular else { return false }
    let appElement = AXUIElementCreateApplication(app.processIdentifier)
    var windows: AnyObject?
    let result = AXUIElementCopyAttributeValue(appElement, kAXWindowsAttribute as CFString, &windows)
    guard result == .success, let windowArray = windows as? [AXUIElement], !windowArray.isEmpty else {
      return app.isActive || app.activationPolicy == .regular
    }
    for windowElement in windowArray {
      if isWindowHiddenOrMinimized(windowElement: windowElement) {
        return true
      }
    }
    return app.isActive || app.activationPolicy == .regular
  }

  private static func isWindowHiddenOrMinimized(windowElement: AXUIElement) -> Bool {
    var isHidden: AnyObject?
    var isMinimized: AnyObject?
    let hiddenResult = AXUIElementCopyAttributeValue(windowElement, kAXHiddenAttribute as CFString, &isHidden)
    let minimizedResult = AXUIElementCopyAttributeValue(windowElement, kAXMinimizedAttribute as CFString, &isMinimized)
    let hidden = (hiddenResult == .success) ? ((isHidden as? NSNumber)?.boolValue ?? false) : false
    let minimized = (minimizedResult == .success) ? ((isMinimized as? NSNumber)?.boolValue ?? false) : false
    return hidden || minimized
  }
}
