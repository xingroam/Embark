import SwiftUI

class SwiftSettingWin: NSObject, NSWindowDelegate {
  static let s = SwiftSettingWin()
  private var window: NSWindow?
  private var hostingController: NSHostingController<SwiftSettingView>?

  private override init() {
    super.init()
  }

  func IsShow() -> Bool {
    return window != nil
  }

  func Show(tab: String = "mouse", subTab: String? = nil) {
    NotificationCenter.default.post(name: NSNotification.Name("FunctionExecuted"), object: nil, userInfo: ["source": FeatureType.swift.title + "Setting"])
    if let existingWindow = window, existingWindow.isVisible {
      if let host = hostingController {
        host.rootView = SwiftSettingView(selectedTab: tab, selectedSubTab: subTab)
      }
      existingWindow.makeKeyAndOrderFront(nil)
      NSApp.activate(ignoringOtherApps: true)
      return
    }
    let view = SwiftSettingView(selectedTab: tab, selectedSubTab: subTab)
    hostingController = NSHostingController(rootView: view)
    guard let host = hostingController else { return }
    window = NSWindow(contentViewController: host)
    guard let w = window else { return }
    w.title = EmbarkInfo.name + " " + NSLocalizedString("embark.struct.feature.swift.title", comment: "")
    w.styleMask = [.titled, .closable, .miniaturizable]
    w.standardWindowButton(.zoomButton)?.isHidden = true
    w.standardWindowButton(.miniaturizeButton)?.isHidden = false
    w.level = .popUpMenu
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

  func getWindowFrame() -> NSRect? {
    guard let window = window else { return nil }
    let contentRect = window.contentLayoutRect
    let screenOrigin = NSPoint(x: window.frame.origin.x + contentRect.origin.x, y: window.frame.origin.y + contentRect.origin.y)
    return NSRect(origin: screenOrigin, size: contentRect.size)
  }

  func windowWillClose(_ notification: Notification) {
    guard let closingWindow = notification.object as? NSWindow, closingWindow === window else { return }
    window?.delegate = nil
    window?.contentViewController = nil
    window = nil
    hostingController = nil
  }
}
