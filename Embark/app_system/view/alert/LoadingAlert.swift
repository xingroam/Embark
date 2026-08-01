import AppKit

class LoadingAlert {
  static let s = LoadingAlert()
  private var loadingAlert: NSAlert?
  private var loadingParentWindow: NSWindow?

  private init() {}

  func On() -> Bool {
    return loadingAlert != nil
  }

  func Show(_ message: String) {
    DispatchQueue.main.async { [weak self] in
      guard let self = self else { return }
      if loadingAlert != nil {
        return
      }
      show(message: message)
    }
  }

  func Close(completion: (() -> Void)? = nil) {
    DispatchQueue.main.async { [weak self] in
      guard let self = self else { return }
      if let alert = loadingAlert {
        if let parentWindow = loadingParentWindow {
          parentWindow.endSheet(alert.window)
          loadingAlert = nil
          loadingParentWindow = nil
          DispatchQueue.main.async {
            completion?()
          }
        } else {
          alert.window.orderOut(nil)
          loadingAlert = nil
          loadingParentWindow = nil
          DispatchQueue.main.async {
            completion?()
          }
        }
      }
    }
  }

  private func show(message: String) {
    let alert = NSAlert()
    alert.informativeText = message
    alert.alertStyle = .informational
    let btn = alert.addButton(withTitle: LanguageManager.s.localizedString("system.message.cancel"))
    btn.isEnabled = false
    alert.window.level = .popUpMenu
    alert.messageText = ""
    alert.showsHelp = false
    alert.showsSuppressionButton = false
    alert.window.title = ""
    alert.window.titleVisibility = .hidden
    alert.window.titlebarAppearsTransparent = true
    alert.window.styleMask.remove(.titled)
    alert.window.styleMask.remove(.closable)
    alert.window.standardWindowButton(.closeButton)?.isHidden = true
    alert.window.standardWindowButton(.miniaturizeButton)?.isHidden = true
    alert.window.standardWindowButton(.zoomButton)?.isHidden = true
    ScreenManager.s.Center(alert.window, winCenter: true)
    self.loadingAlert = alert
    self.loadingParentWindow = getValidParentWindow()
    if let parentWindow = self.loadingParentWindow {
      parentWindow.level = .popUpMenu
      alert.beginSheetModal(for: parentWindow, completionHandler: nil)
    }
  }

  private func getValidParentWindow() -> NSWindow? {
    if let keyWindow = NSApp.keyWindow, keyWindow.isVisible {
      return keyWindow
    }
    if let mainWindow = NSApp.mainWindow, mainWindow.isVisible {
      return mainWindow
    }
    for window in NSApp.windows {
      if window.isVisible && window.level == .normal {
        return window
      }
    }
    let screenFrame = NSScreen.main?.frame ?? NSRect.zero
    let dummyWindow = NSWindow(contentRect: NSRect(x: screenFrame.midX, y: screenFrame.midY, width: 1, height: 1), styleMask: [], backing: .buffered, defer: false)
    dummyWindow.isReleasedWhenClosed = false
    dummyWindow.alphaValue = 0.0
    dummyWindow.orderOut(nil)
    return dummyWindow
  }
}
