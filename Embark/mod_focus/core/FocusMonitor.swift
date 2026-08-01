import SwiftUI
import AppKit
import ApplicationServices

class FocusMonitor {
  static let s = FocusMonitor()
  private var timer: Timer?
  private var activateObserver: NSObjectProtocol?
  private var screenObserver: NSObjectProtocol?
  private var lastAboveWindow: WindowData?
  private var lastWindowList: [WindowData]?
  private var lastWids: [CGWindowID]?
  private var stop: Bool = false
  private let backgroundQueue = DispatchQueue(label: "embark.focus.monitor", qos: .userInteractive)
  private var bundleIdCache: [pid_t: String?] = [:]
  private var hiddenWindowsMap: [String: HiddenWindow] = [:]
  private var cachedUIWindowIds: Set<CGWindowID> = []
  private var lastFocusWid: CGWindowID = 0
  private var lastLauncherWid: CGWindowID = 0

  private init() {}

  func Start() {
    stop = false
    lastAboveWindow = nil
    lastWindowList = nil
    lastWids = nil
    lastFocusWid = 0
    lastLauncherWid = 0
    bundleIdCache.removeAll()
    hiddenWindowsMap.removeAll()
    cachedUIWindowIds.removeAll()
    updateHiddenWindowsMap()
    updateUIWindowIds()
    setupTimerMonitoring()
    setupObserversMonitoring()
  }

  func Stop() {
    cleanupTimerMonitoring()
    cleanupObserversMonitoring()
    lastAboveWindow = nil
    lastWindowList = nil
    lastWids = nil
    bundleIdCache.removeAll()
    hiddenWindowsMap.removeAll()
    cachedUIWindowIds.removeAll()
    stop = false
    DispatchQueue.main.async {
      FocusOverlayWin.s.Close()
    }
  }

  private func setupTimerMonitoring() {
    DispatchQueue.main.async { [weak self] in
      guard let self = self else { return }
      timer = Timer.scheduledTimer(withTimeInterval: FocusInfo.timerInterval, repeats: true) { [weak self] _ in
        guard let self = self else { return }
        if stop { return }
        updateUIWindowIds()
        backgroundQueue.async { [weak self] in
          guard let self = self else { return }
          guard let windowList = CGWindowListCopyWindowInfo([.optionOnScreenOnly], kCGNullWindowID) as? [[String: Any]] else { return }
          let currentWindowList = self.getWindow(from: windowList, skipFinder: false)
          let currentAboveWindow = currentWindowList.first
          DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if currentAboveWindow == nil {
              if lastAboveWindow != nil {
                lastAboveWindow = nil
                lastWindowList = nil
                lastWids = nil
                FocusOverlayWin.s.hideOverlay()
              }
              return
            }
            if FocusManager.s.isExcluded(bundleId: currentAboveWindow?.bundleIdentifier) {
              lastAboveWindow = nil
              lastWindowList = nil
              lastWids = nil
              FocusOverlayWin.s.hideOverlay()
              return
            }
            if lastAboveWindow == nil {
              if !stop {
                guard let element = WindowFind.FindWindowElement(wi: currentAboveWindow!) else { return }
                let attributes = [kAXRoleAttribute, kAXSubroleAttribute, kAXMinimizedAttribute] as CFArray
                var valuesRef: CFArray?
                if AXUIElementCopyMultipleAttributeValues(element, attributes, AXCopyMultipleAttributeOptions(rawValue: 0), &valuesRef) == .success,
                   let values = valuesRef as? [AnyObject],
                   values.count == 3,
                   let role = values[0] as? String, role == "AXWindow",
                   let subrole = values[1] as? String, subrole == "AXStandardWindow",
                   let minimized = values[2] as? Bool, !minimized {
                  if !stop {
                    lastAboveWindow = currentAboveWindow
                    lastWindowList = currentWindowList
                    lastWids = currentWindowList.map { $0.wid }
                    FocusOverlayWin.s.showOverlay()
                    SwiftManager.s.activateWindow(fast: false, wi: currentAboveWindow!, element: element) {}
                  }
                }
              }
              return
            }
            let currentWids = currentWindowList.map { $0.wid }
            if let cachedWids = lastWids, currentWids != cachedWids {
              if lastAboveWindow!.wid != currentAboveWindow!.wid {
                guard let element = WindowFind.FindWindowElement(wi: currentAboveWindow!) else { return }
                let attributes = [kAXRoleAttribute, kAXSubroleAttribute, kAXMinimizedAttribute] as CFArray
                var valuesRef: CFArray?
                if AXUIElementCopyMultipleAttributeValues(element, attributes, AXCopyMultipleAttributeOptions(rawValue: 0), &valuesRef) == .success,
                   let values = valuesRef as? [AnyObject],
                   values.count == 3,
                   let role = values[0] as? String, role == "AXWindow",
                   let subrole = values[1] as? String, subrole == "AXStandardWindow",
                   let minimized = values[2] as? Bool, !minimized {
                  if !stop {
                    lastAboveWindow = currentAboveWindow
                    FocusOverlayWin.s.showOverlay()
                    SwiftManager.s.activateWindow(fast: false, wi: currentAboveWindow!, element: element) {}
                  }
                }
              }
              lastWindowList = currentWindowList
              lastWids = currentWids
            }
          }
        }
      }
    }
  }

  private func cleanupTimerMonitoring() {
    DispatchQueue.main.async { [weak self] in
      guard let self = self else { return }
      timer?.invalidate()
      timer = nil
    }
  }

  private func setupObserversMonitoring() {
    activateObserver = NSWorkspace.shared.notificationCenter.addObserver(forName: NSWorkspace.didActivateApplicationNotification, object: nil, queue: nil) { [weak self] notification in
      guard let self = self else { return }
      if let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication {
        let bundleId = app.bundleIdentifier
        if FocusManager.s.isExcluded(bundleId: bundleId) {
          if !stop {
            stop = true
            lastAboveWindow = nil
            lastWindowList = nil
            lastWids = nil
            FocusOverlayWin.s.hideOverlay()
          }
        } else {
          if stop {
            stop = false
          }
        }
      }
    }
    screenObserver = NotificationCenter.default.addObserver(forName: NSApplication.didChangeScreenParametersNotification, object: nil, queue: nil) { _ in
      if FocusOverlayWin.s.isShowing && !SystemUIManager.s.onChange {
        FocusOverlayWin.s.hideOverlay()
        DispatchQueue.main.async {
          FocusOverlayWin.s.showOverlay()
        }
      }
    }
  }

  private func cleanupObserversMonitoring() {
    if let observer = activateObserver {
      NSWorkspace.shared.notificationCenter.removeObserver(observer)
      activateObserver = nil
    }
    if let observer = screenObserver {
      NotificationCenter.default.removeObserver(observer)
      screenObserver = nil
    }
  }

  private func getWindow(from windowList: [[String: Any]], skipFinder: Bool) -> [WindowData] {
    var result: [WindowData] = []
    let currentPID = NSRunningApplication.current.processIdentifier
    updateHiddenWindowsMap()
    for windowInfo in windowList {
      let pid = windowInfo["kCGWindowOwnerPID"] as? pid_t
      let appName = windowInfo["kCGWindowOwnerName"] as? String ?? ""
      let alpha = windowInfo["kCGWindowAlpha"] as? Double ?? 1.0
      let windowId = windowInfo["kCGWindowNumber"] as? CGWindowID ?? 0
      let windowName = windowInfo["kCGWindowName"] as? String ?? ""
      let layer = windowInfo["kCGWindowLayer"] as? Int ?? 0
      if pid == currentPID && windowName.hasPrefix("Item-") {
        continue
      }
      if cachedUIWindowIds.contains(windowId) {
        continue
      }
      if WindowFind.shouldSkipWindow(pid: pid, wid: windowId, appName: appName, title: windowName, alpha: alpha, skipFinder: skipFinder) {
        continue
      }
      if let pid = pid {
        let key = "\(pid)-\(windowId)"
        if let hiddenWindow = hiddenWindowsMap[key], SlideWindow.s.boundsEqual(hiddenWindow.currentBounds, hiddenWindow.hideBounds) {
          continue
        }
      }
      guard let boundsDict = windowInfo["kCGWindowBounds"] as? [String: CGFloat] else { continue }
      let bounds = makeBounds(from: boundsDict)
      let bundleId: String?
      if let pid = pid {
        if let cached = bundleIdCache[pid] {
          bundleId = cached
        } else {
          bundleId = NSRunningApplication(processIdentifier: pid)?.bundleIdentifier
          bundleIdCache[pid] = bundleId
        }
      } else {
        bundleId = nil
      }
      result.append(WindowData(pid: pid ?? 0, wid: windowId, app: appName, bundleIdentifier: bundleId, bounds: bounds, layer: layer, title: windowName))
    }
    return result
  }

  private func updateHiddenWindowsMap() {
    hiddenWindowsMap.removeAll(keepingCapacity: true)
    for hiddenWindow in SlideMonitor.s.hiddenWindows {
      let key = "\(hiddenWindow.windowData.pid)-\(hiddenWindow.windowData.wid)"
      hiddenWindowsMap[key] = hiddenWindow
    }
  }

  private func makeBounds(from dict: [String: CGFloat]) -> CGRect {
    return CGRect(
      x: dict["X"] ?? 0,
      y: dict["Y"] ?? 0,
      width: dict["Width"] ?? 0,
      height: dict["Height"] ?? 0
    )
  }

  private func updateUIWindowIds() {
    guard Thread.isMainThread else {
      DispatchQueue.main.async { [weak self] in
        self?.updateUIWindowIds()
      }
      return
    }
    var ids = Set<CGWindowID>()
    let focusWid = FocusOverlayWin.s.windowID()
    if focusWid != 0 {
      ids.insert(focusWid)
      lastFocusWid = focusWid
    } else if lastFocusWid != 0 {
      ids.insert(lastFocusWid)
    }
    cachedUIWindowIds = ids
  }
}
