import SwiftUI

class LauncherBrowserWin: NSObject {
  static let s = LauncherBrowserWin()
  private var windows: [String: BrowserWindowController] = [:]
  private var lastCloseTimes: [String: TimeInterval] = [:]

  private override init() {
    super.init()
  }

  func removeWindow(url: String) {
    windows.removeValue(forKey: url)
  }

  func IsWindow(_ wid: Int) -> Bool {
    var result = false
    if Thread.isMainThread {
      result = windows.values.contains { $0.window?.windowNumber == wid }
    } else {
      DispatchQueue.main.sync {
        result = windows.values.contains { $0.window?.windowNumber == wid }
      }
    }
    return result
  }

  func IsShow(url: String) -> Bool {
    return windows[url]?.isShown ?? false
  }

  func IsAnyShow() -> Bool {
    return windows.values.contains { $0.isShown }
  }

  func ToggleOrOpen(url: String, title: String, animation: Bool = true, useProxy: Bool? = nil, isSecondaryWindow: Bool = false) {
    if let lastTime = lastCloseTimes[url], Date().timeIntervalSince1970 - lastTime < 0.2 {
      return
    }
    if let controller = windows[url] {
      if controller.isShown {
        if let win = controller.window, win.isMiniaturized {
          win.deminiaturize(nil)
          NSApp.activate(ignoringOtherApps: true)
          win.makeKeyAndOrderFront(nil)
        } else {
          controller.close(animation: animation)
        }
      } else {
        Open(url: url, title: title, animation: animation, useProxy: useProxy, isSecondaryWindow: isSecondaryWindow)
      }
    } else {
      Open(url: url, title: title, animation: animation, useProxy: useProxy, isSecondaryWindow: isSecondaryWindow)
    }
  }

  func Open(url: String, title: String, animation: Bool = true, useProxy: Bool? = nil, isSecondaryWindow: Bool = false) {
    if let controller = windows[url] {
      if controller.isShown {
        NSApp.activate(ignoringOtherApps: true)
        controller.window?.makeKeyAndOrderFront(nil)
      } else {
        controller.open(animation: animation)
      }
      return
    }
    let controller = BrowserWindowController(url: url, title: title, inheritedUseProxy: useProxy, isSecondaryWindow: isSecondaryWindow)
    windows[url] = controller
    controller.open(animation: animation)
  }

  func Close(url: String, animation: Bool = true) {
    if let controller = windows[url] {
      controller.close(animation: animation)
    }
  }

  func CloseAll(animation: Bool = true) {
    for (_, controller) in windows {
      controller.close(animation: animation)
    }
    windows.removeAll()
  }

  func setPinned(_ url: String, pinned: Bool) {
    windows[url]?.setPinned(pinned)
  }

  func dragWindow(_ url: String, delta: CGSize) {
    windows[url]?.dragWindow(delta: delta)
  }

  func setKeepAlive(_ url: String, keepAlive: Bool) {
    windows[url]?.setKeepAlive(keepAlive)
  }

  func updateWindowKey(oldKey: String, newKey: String) {
    if let controller = windows[oldKey] {
      windows.removeValue(forKey: oldKey)
      windows[newKey] = controller
      controller.updateUrl(newKey)
    }
  }

  func setDocked(wid: CGWindowID, docked: Bool) {
    if Thread.isMainThread {
      if let controller = windows.values.first(where: { $0.window?.windowNumber == Int(wid) }) {
        controller.setDocked(docked)
      }
    } else {
      DispatchQueue.main.async {
        if let controller = self.windows.values.first(where: { $0.window?.windowNumber == Int(wid) }) {
          controller.setDocked(docked)
        }
      }
    }
  }
  func recordCloseTime(url: String) {
    lastCloseTimes[url] = Date().timeIntervalSince1970
  }
}
