import SwiftUI

class MagnetSettingWin: NSObject, NSWindowDelegate {
  static let s = MagnetSettingWin()
  private var window: NSWindow?
  private var hostingController: NSHostingController<MagnetSettingView>?

  private override init() {
    super.init()
  }

  func IsShow() -> Bool {
    return window != nil
  }

  func Show() {
    NotificationCenter.default.post(name: NSNotification.Name("FunctionExecuted"), object: nil, userInfo: ["source": FeatureType.magnet.title + "Setting"])
    if let existingWindow = window, existingWindow.isVisible {
      existingWindow.makeKeyAndOrderFront(nil)
      NSApp.activate(ignoringOtherApps: true)
      return
    }
    let view = MagnetSettingView()
    hostingController = NSHostingController(rootView: view)
    guard let host = hostingController else { return }
    window = NSWindow(contentViewController: host)
    guard let w = window else { return }
    w.title = EmbarkInfo.name + " " + FeatureType.magnet.title
    w.styleMask = [.titled, .closable, .miniaturizable]
    w.standardWindowButton(.zoomButton)?.isHidden = true
    w.standardWindowButton(.miniaturizeButton)?.isHidden = false
    w.level = .normal
    w.delegate = self
    let size = host.view.intrinsicContentSize
    if size.width > 0, size.height > 0 {
      w.setContentSize(size)
    }
    ScreenManager.s.Center(w, winCenter: true)
    w.makeKeyAndOrderFront(nil)
    NSApp.activate(ignoringOtherApps: true)
  }

  func Close() {
    window?.close()
  }

  func windowWillClose(_ notification: Notification) {
    guard let closingWindow = notification.object as? NSWindow, closingWindow === window else { return }
    window?.delegate = nil
    window?.contentViewController = nil
    window = nil
    hostingController = nil
  }
}
