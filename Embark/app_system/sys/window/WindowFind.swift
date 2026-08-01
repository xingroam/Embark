import SwiftUI
import AppKit

class WindowFind {
  private static let windowListOptions: CGWindowListOption = [.optionOnScreenOnly, .excludeDesktopElements]
  private static let allWindowListOptions: CGWindowListOption = [.optionAll, .excludeDesktopElements]
  private static var tolerance: CGFloat {
    let scale = NSScreen.main?.backingScaleFactor ?? 1.0
    return max(3.0, 8.0 / scale)
  }

  static func FindWindowUnderMouse() -> WindowData? {
    guard let windowList = CGWindowListCopyWindowInfo(windowListOptions, kCGNullWindowID) as? [[String: Any]] else {
      return nil
    }
    let mouseLocation = NSEvent.mouseLocation
    let screenHeight = NSScreen.screens.first?.frame.height ?? 0
    for windowInfo in windowList {
      if let windowData = findTargetWindow(from: windowInfo, mouseLocation: mouseLocation, screenHeight: screenHeight) {
        return windowData
      }
    }
    return nil
  }

  static func FindWindowAtPoint(_ point: CGPoint) -> WindowData? {
    guard let windowList = CGWindowListCopyWindowInfo(windowListOptions, kCGNullWindowID) as? [[String: Any]] else {
      return nil
    }
    for windowInfo in windowList {
      if let windowData = findTargetWindowAtPoint(from: windowInfo, point: point) {
        return windowData
      }
    }
    return nil
  }

  static func FindWindowByPidWid(pid: pid_t, wid: CGWindowID) -> Bool {
    guard let windowList = CGWindowListCopyWindowInfo(allWindowListOptions, kCGNullWindowID) as? [[String: Any]] else {
      return false
    }
    return windowList.contains { windowInfo in
      let windowPid = windowInfo["kCGWindowOwnerPID"] as? pid_t
      let windowWid = windowInfo["kCGWindowNumber"] as? CGWindowID
      return windowPid == pid && windowWid == wid
    }
  }

  static func FindWindowElement(wi: WindowData) -> AXUIElement? {
    if let element = wi.element {
      return element
    }
    return findWindowElementByPosition(windowData: wi)
  }

  static func GetWindowBounds(windowData: WindowData) -> CGRect? {
    guard let windowList = CGWindowListCopyWindowInfo(windowListOptions, kCGNullWindowID) as? [[String: Any]] else { return nil }
    for windowInfo in windowList {
      let windowPid = windowInfo["kCGWindowOwnerPID"] as? pid_t
      let windowWid = windowInfo["kCGWindowNumber"] as? CGWindowID
      if windowPid == windowData.pid && windowWid == windowData.wid {
        guard let boundsDict = windowInfo["kCGWindowBounds"] as? [String: CGFloat] else { return nil }
        let bounds = CGRect(
          x: boundsDict["X"] ?? 0,
          y: boundsDict["Y"] ?? 0,
          width: boundsDict["Width"] ?? 0,
          height: boundsDict["Height"] ?? 0
        )
        return bounds
      }
    }
    return nil
  }

  static func shouldSkipWindow(pid: pid_t?, wid: CGWindowID?, appName: String, title: String?, alpha: Double, skipFinder: Bool = false) -> Bool {
    if appName == "Window Server" || alpha == 0 { return true }
    if appName == "DockHelper" { return true }
    if let pid = pid, let app = NSRunningApplication(processIdentifier: pid) {
      let bundleId = app.bundleIdentifier?.lowercased()
      if bundleId == "com.apple.dock" { return true }
      if bundleId == "com.apple.screencapture" { return true }
      if bundleId == "com.apple.notificationcenterui" { return true }
      if bundleId == "com.apple.usernotificationcenter" { return true }
      if bundleId == "com.apple.controlcenter" { return true }
      if bundleId == "com.apple.spotlight" { return true }
      if bundleId == "com.apple.textinputmenuagent" { return true }
      if bundleId == "com.apple.wallpaper.agent" { return true }
      if bundleId == "com.apple.passwordmanagerbrowserextensionhelper" { return true }
      if skipFinder && bundleId == "com.apple.finder" { return true }
      if bundleId == EmbarkInfo.bundleIdentifierLowercased && wid != nil {
        if ToastWin.s.IsWindow(wid!) { return true }
        if Tooltip.s.IsWindow(wid!) { return true }
        if FocusOverlayWin.s.IsWindow(wid!, title: title) { return true }
        if SwiftMouseOverlayWin.s.IsWindow(wid!, title: title) { return true }
        if LauncherWin.s.IsWindow(wid!, title: title) { return true }
        if SwitcherWin.s.IsWindow(wid!, title: title) { return true }
        if SpaceLoaderWin.s.IsWindow(wid!, title: title) { return true }
      }
      if let executablePath = app.executableURL?.path {
        if executablePath.hasPrefix("/System/") || executablePath.hasPrefix("/usr/sbin/") {
          if executablePath.contains("screencapture") { return true }
        }
      }
    }
    return false
  }

  static func GetWindowTitle(element: AXUIElement) -> String? {
    var titleValue: AnyObject?
    let result = AXUIElementCopyAttributeValue(element, kAXTitleAttribute as CFString, &titleValue)
    if result == .success, let title = titleValue as? String {
      return title
    }
    return nil
  }

  static func IsWindowMinimized(element: AXUIElement) -> Bool {
    var minimizedValue: AnyObject?
    let result = AXUIElementCopyAttributeValue(element, kAXMinimizedAttribute as CFString, &minimizedValue)
    if result == .success, let minimized = minimizedValue as? Bool {
      return minimized
    }
    return false
  }

  private static func findTargetWindow(from windowInfo: [String: Any], mouseLocation: CGPoint, screenHeight: CGFloat) -> WindowData? {
    let pid = windowInfo["kCGWindowOwnerPID"] as? pid_t
    let appName = windowInfo["kCGWindowOwnerName"] as? String ?? ""
    let alpha = windowInfo["kCGWindowAlpha"] as? Double ?? 1.0
    let windowId = windowInfo["kCGWindowNumber"] as? CGWindowID ?? 0
    let windowName = windowInfo["kCGWindowName"] as? String ?? ""
    let currentPID = NSRunningApplication.current.processIdentifier
    if pid == currentPID && windowName.hasPrefix("Item-") {
      return nil
    }
    if shouldSkipWindow(pid: pid, wid: windowId, appName: appName, title: windowName, alpha: alpha) {
      return nil
    }
    guard let boundsDict = windowInfo["kCGWindowBounds"] as? [String: CGFloat] else {
      return nil
    }
    let bounds = CGRect(
      x: boundsDict["X"] ?? 0,
      y: boundsDict["Y"] ?? 0,
      width: boundsDict["Width"] ?? 0,
      height: boundsDict["Height"] ?? 0
    )
    let convertedMouseLocation = CGPoint(x: mouseLocation.x, y: screenHeight - mouseLocation.y)
    if bounds.contains(convertedMouseLocation) {
      let app = NSRunningApplication(processIdentifier: pid ?? 0)
      return WindowData(pid: pid ?? 0, wid: windowId, app: appName, bundleIdentifier: app?.bundleIdentifier, bounds: bounds)
    }
    return nil
  }

  private static func findTargetWindowAtPoint(from windowInfo: [String: Any], point: CGPoint) -> WindowData? {
    let pid = windowInfo["kCGWindowOwnerPID"] as? pid_t
    let appName = windowInfo["kCGWindowOwnerName"] as? String ?? ""
    let alpha = windowInfo["kCGWindowAlpha"] as? Double ?? 1.0
    let windowId = windowInfo["kCGWindowNumber"] as? CGWindowID ?? 0
    let windowName = windowInfo["kCGWindowName"] as? String ?? ""
    let currentPID = NSRunningApplication.current.processIdentifier
    if pid == currentPID && windowName.hasPrefix("Item-") {
      return nil
    }
    if shouldSkipWindow(pid: pid, wid: windowId, appName: appName, title: windowName, alpha: alpha) {
      return nil
    }
    guard let boundsDict = windowInfo["kCGWindowBounds"] as? [String: CGFloat] else {
      return nil
    }
    let bounds = CGRect(
      x: boundsDict["X"] ?? 0,
      y: boundsDict["Y"] ?? 0,
      width: boundsDict["Width"] ?? 0,
      height: boundsDict["Height"] ?? 0
    )
    if bounds.contains(point) {
      let app = NSRunningApplication(processIdentifier: pid ?? 0)
      return WindowData(pid: pid ?? 0, wid: windowId, app: appName, bundleIdentifier: app?.bundleIdentifier, bounds: bounds)
    }
    return nil
  }

  private static func findWindowElementByPosition(windowData: WindowData) -> AXUIElement? {
    return autoreleasepool {
      let appElement = AXUIElementCreateApplication(windowData.pid)
      var windowsValue: AnyObject?
      let result = AXUIElementCopyAttributeValue(appElement, kAXWindowsAttribute as CFString, &windowsValue)
      guard result == .success, let windowElements = windowsValue as? [AXUIElement] else {
        return nil
      }
      for windowElement in windowElements {
        if isWindowElementMatchingBounds(windowElement: windowElement, targetBounds: windowData.bounds) {
          return windowElement
        }
      }
      return nil
    }
  }

  private static func isWindowElementMatchingBounds(windowElement: AXUIElement, targetBounds: CGRect) -> Bool {
    var positionValue: AnyObject?
    var sizeValue: AnyObject?
    let positionResult = AXUIElementCopyAttributeValue(windowElement, kAXPositionAttribute as CFString, &positionValue)
    let sizeResult = AXUIElementCopyAttributeValue(windowElement, kAXSizeAttribute as CFString, &sizeValue)
    guard positionResult == .success && sizeResult == .success, let position = positionValue, let size = sizeValue else {
      return false
    }
    var windowPosition = CGPoint.zero
    var windowSize = CGSize.zero
    AXValueGetValue(position as! AXValue, .cgPoint, &windowPosition)
    AXValueGetValue(size as! AXValue, .cgSize, &windowSize)
    let windowBounds = CGRect(origin: windowPosition, size: windowSize)
    return abs(windowBounds.origin.x - targetBounds.origin.x) < tolerance &&
           abs(windowBounds.origin.y - targetBounds.origin.y) < tolerance &&
           abs(windowBounds.size.width - targetBounds.size.width) < tolerance &&
           abs(windowBounds.size.height - targetBounds.size.height) < tolerance
  }

  static func GetAllWindows(includeMinimized: Bool = false, sortByZOrder: Bool = true, timeout: TimeInterval? = nil) -> [WindowData] {
    let onScreenOptions: CGWindowListOption = [.optionOnScreenOnly, .excludeDesktopElements]
    let onScreenList = CGWindowListCopyWindowInfo(onScreenOptions, kCGNullWindowID) as? [[String: Any]] ?? []
    let allOptions: CGWindowListOption = [.optionAll, .excludeDesktopElements]
    let allList = CGWindowListCopyWindowInfo(allOptions, kCGNullWindowID) as? [[String: Any]] ?? []
    var windowOrder: [CGWindowID: Int] = [:]
    for (index, info) in onScreenList.enumerated() {
      if let wid = info[kCGWindowNumber as String] as? CGWindowID {
        windowOrder[wid] = index
      }
    }
    var cgWindowsByPID: [pid_t: [[String: Any]]] = [:]
    for info in allList {
      guard let pid = info[kCGWindowOwnerPID as String] as? Int32 else { continue }
      cgWindowsByPID[pid, default: []].append(info)
    }
    var result: [WindowData] = []
    let apps = NSWorkspace.shared.runningApplications.filter {
      ($0.activationPolicy == .regular || $0.activationPolicy == .accessory) && cgWindowsByPID[$0.processIdentifier] != nil
    }
    for app in apps {
      if let timeout = timeout {
        let semaphore = DispatchSemaphore(value: 0)
        var appWindows: [WindowData]? = nil
        DispatchQueue.global().async {
          appWindows = getWindowsForApp(app: app, cgWindowsByPID: cgWindowsByPID, windowOrder: windowOrder, includeMinimized: includeMinimized)
          semaphore.signal()
        }
        let waitResult = semaphore.wait(timeout: .now() + timeout)
        if waitResult == .timedOut {
           if let candidates = cgWindowsByPID[app.processIdentifier] {
             for cand in candidates {
               if let wd = createWindowDataFromCGInfo(app: app, info: cand, windowOrder: windowOrder) {
                 result.append(wd)
               }
             }
           }
        } else if let windows = appWindows {
          result.append(contentsOf: windows)
        }
      } else {
        let windows = getWindowsForApp(app: app, cgWindowsByPID: cgWindowsByPID, windowOrder: windowOrder, includeMinimized: includeMinimized)
        result.append(contentsOf: windows)
      }
    }
    if sortByZOrder {
      result.sort { (w1, w2) -> Bool in
        let idx1 = windowOrder[w1.wid] ?? Int.max
        let idx2 = windowOrder[w2.wid] ?? Int.max
        return idx1 < idx2
      }
    }
    return result
  }

  private static func getWindowsForApp(app: NSRunningApplication, cgWindowsByPID: [pid_t: [[String: Any]]], windowOrder: [CGWindowID: Int], includeMinimized: Bool) -> [WindowData] {
      var result: [WindowData] = []
      let pid = app.processIdentifier
      let appRef = AXUIElementCreateApplication(pid)
      var windowsRef: CFTypeRef?
      let err = AXUIElementCopyAttributeValue(appRef, kAXWindowsAttribute as CFString, &windowsRef)
      if err == .success, let windows = windowsRef as? [AXUIElement] {
        for windowRef in windows {
          var roleRef: CFTypeRef?
          AXUIElementCopyAttributeValue(windowRef, kAXRoleAttribute as CFString, &roleRef)
          if let role = roleRef as? String, role != kAXWindowRole { continue }
          let isMinimized = IsWindowMinimized(element: windowRef)
          if !includeMinimized && isMinimized { continue }
          let title = GetWindowTitle(element: windowRef)
          var positionRef: CFTypeRef?
          var sizeRef: CFTypeRef?
          var frame = CGRect.zero
          if AXUIElementCopyAttributeValue(windowRef, kAXPositionAttribute as CFString, &positionRef) == .success, AXUIElementCopyAttributeValue(windowRef, kAXSizeAttribute as CFString, &sizeRef) == .success {
            var pos = CGPoint.zero
            var size = CGSize.zero
            AXValueGetValue(positionRef as! AXValue, .cgPoint, &pos)
            AXValueGetValue(sizeRef as! AXValue, .cgSize, &size)
            frame = CGRect(origin: pos, size: size)
          }
          if frame.width < 5 || frame.height < 5 {
            continue
          }
          var wid: CGWindowID = 0
          var layer: Int = 0
          var alpha: Double = 1.0
          if let candidates = cgWindowsByPID[pid] {
            if let match = findBestMatch(candidates: candidates, frame: frame, windowOrder: windowOrder) {
              wid = match[kCGWindowNumber as String] as? CGWindowID ?? 0
              layer = match[kCGWindowLayer as String] as? Int ?? 0
              alpha = match[kCGWindowAlpha as String] as? Double ?? 1.0
            }
          }
          if !isMinimized && (wid == 0 || windowOrder[wid] == nil) {
            continue
          }
          if shouldSkipWindow(pid: pid, wid: wid, appName: app.localizedName ?? "", title: title, alpha: isMinimized ? 1.0 : alpha) {
            continue
          }
          let wd = WindowData(
            pid: pid,
            wid: wid,
            app: app.localizedName ?? "",
            bundleIdentifier: app.bundleIdentifier,
            bounds: frame,
            element: windowRef,
            layer: layer,
            title: title,
            isMinimized: isMinimized
          )
          result.append(wd)
        }
      }
      return result
  }

  private static func createWindowDataFromCGInfo(app: NSRunningApplication, info: [String: Any], windowOrder: [CGWindowID: Int]) -> WindowData? {
    let pid = app.processIdentifier
    let wid = info[kCGWindowNumber as String] as? CGWindowID ?? 0
    let alpha = info[kCGWindowAlpha as String] as? Double ?? 1.0
    let layer = info[kCGWindowLayer as String] as? Int ?? 0
    let boundsDict = info[kCGWindowBounds as String] as? [String: CGFloat]
    let bounds = CGRect(
      x: boundsDict?["X"] ?? 0,
      y: boundsDict?["Y"] ?? 0,
      width: boundsDict?["Width"] ?? 0,
      height: boundsDict?["Height"] ?? 0
    )
    let windowName = info["kCGWindowName"] as? String
    if bounds.width < 5 || bounds.height < 5 { return nil }
    if alpha == 0 { return nil }
    let isOnScreen = windowOrder[wid] != nil
    if !isOnScreen {
      if layer != 0 { return nil }
      if windowName == nil || windowName!.isEmpty { return nil }
    }
    let isMinimized = !isOnScreen
    if shouldSkipWindow(pid: pid, wid: wid, appName: app.localizedName ?? "", title: windowName, alpha: alpha) {
      return nil
    }
    return WindowData(
      pid: pid,
      wid: wid,
      app: app.localizedName ?? "",
      bundleIdentifier: app.bundleIdentifier,
      bounds: bounds,
      element: nil,
      layer: layer,
      title: windowName,
      isMinimized: isMinimized,
      isTimeout: true
    )
  }

  private static func findBestMatch(candidates: [[String: Any]], frame: CGRect, windowOrder: [CGWindowID: Int]) -> [String: Any]? {
    var bestMatch: [String: Any]?
    var maxScore: CGFloat = 0
    for cand in candidates {
      if let boundsDict = cand[kCGWindowBounds as String] as? [String: Any], let bounds = CGRect(dictionaryRepresentation: boundsDict as CFDictionary) {
        let intersection = frame.intersection(bounds)
        if intersection.isNull { continue }
        let intersectionArea = intersection.width * intersection.height
        let frameArea = frame.width * frame.height
        if frameArea == 0 { continue }
        var score = intersectionArea / frameArea
        if let wid = cand[kCGWindowNumber as String] as? CGWindowID, windowOrder[wid] != nil {
          score += 1.0
        }
        if score > 0.8 && score > maxScore {
          maxScore = score
          bestMatch = cand
        }
      }
    }
    return bestMatch
  }
}
