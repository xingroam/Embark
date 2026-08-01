import SwiftUI

class OnboardingWin: NSObject, NSWindowDelegate {
  static let s = OnboardingWin()
  private var window: NSWindow?
  private var hostingController: NSHostingController<OnboardingView>?

  private override init() {
    super.init()
  }

  func IsShow() -> Bool {
    return window != nil && window!.isVisible
  }

  func Show(showWelcome: Bool = true) {
    if let existingWindow = window, existingWindow.isVisible {
      existingWindow.makeKeyAndOrderFront(nil)
      NSApp.activate(ignoringOtherApps: true)
      return
    }
    let view = OnboardingView(showWelcome: showWelcome) { [weak self] in
      self?.Close()
    }
    hostingController = NSHostingController(rootView: view)
    guard let host = hostingController else { return }
    window = NSWindow(contentViewController: host)
    guard let w = window else { return }
    w.title = EmbarkInfo.name
    w.styleMask = [.titled, .closable, .fullSizeContentView]
    w.titlebarAppearsTransparent = true
    w.titleVisibility = .hidden
    w.isOpaque = false
    w.backgroundColor = .clear
    w.standardWindowButton(.closeButton)?.isHidden = false
    w.standardWindowButton(.zoomButton)?.isHidden = true
    w.standardWindowButton(.miniaturizeButton)?.isHidden = true
    w.isMovableByWindowBackground = true
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
    if !Embark.s.isAppStarted() {
      NSApp.terminate(nil)
    }
  }
}
