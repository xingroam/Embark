import Cocoa
import ApplicationServices

class SwitcherWindowUtil {
  static func getAllWindows(sortByZOrder: Bool = true) -> [SwitcherWindowInfo] {
    var windows = WindowFind.GetAllWindows(includeMinimized: true, sortByZOrder: sortByZOrder, timeout: SwitcherInfo.timeout)
    let currentPID = NSRunningApplication.current.processIdentifier
    windows.removeAll { $0.pid == currentPID }
    var seenIDs = Set<CGWindowID>()
    var syntheticID: UInt32 = 3000000000
    var result = windows.map { wd -> SwitcherWindowInfo in
      var finalID = wd.wid
      if finalID == 0 || seenIDs.contains(finalID) {
        finalID = syntheticID
        syntheticID += 1
      }
      seenIDs.insert(finalID)
      return SwitcherWindowInfo(
        id: finalID,
        ownerName: wd.app,
        name: wd.title ?? "",
        ownerPID: wd.pid,
        frame: wd.bounds,
        icon: NSRunningApplication(processIdentifier: wd.pid)?.icon,
        isMinimized: wd.isMinimized,
        element: wd.element,
        isTimeout: wd.isTimeout
      )
    }
    let ownWindows = getOwnWindows()
    for w in ownWindows {
      if !seenIDs.contains(w.id) {
        result.append(w)
        seenIDs.insert(w.id)
      }
    }
    return result
  }

  private static func getOwnWindows() -> [SwitcherWindowInfo] {
    if Thread.isMainThread {
      return _getOwnWindows()
    } else {
      return DispatchQueue.main.sync {
        return _getOwnWindows()
      }
    }
  }

  private static func _getOwnWindows() -> [SwitcherWindowInfo] {
    var ownWindows: [SwitcherWindowInfo] = []
    let app = NSRunningApplication.current
    let pid = app.processIdentifier
    let icon = app.icon
    let screenHeight = NSScreen.screens.first?.frame.height ?? NSScreen.main?.frame.height ?? 0
    for window in NSApp.windows {
      if (!window.isVisible && !window.isMiniaturized) || window.alphaValue == 0 { continue }
      let isBrowserWindow = LauncherBrowserWin.s.IsWindow(window.windowNumber)
      if !window.styleMask.contains(.titled) && !isBrowserWindow { continue }
      if SwitcherWin.s.IsWindow(CGWindowID(window.windowNumber)) { continue }
      let frame = window.frame
      let cgFrame = CGRect(
        x: frame.origin.x,
        y: screenHeight - frame.maxY,
        width: frame.width,
        height: frame.height
      )
      let info = SwitcherWindowInfo(
        id: CGWindowID(window.windowNumber),
        ownerName: app.localizedName ?? EmbarkInfo.name,
        name: window.title,
        ownerPID: pid,
        frame: cgFrame,
        icon: icon,
        isMinimized: window.isMiniaturized,
        element: nil
      )
      ownWindows.append(info)
    }
    return ownWindows
  }
}
