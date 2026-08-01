import AppKit

class OkAlert {
  static func Show(title: String = "", _ message: String, exit: Bool = false, restart: Bool = false, callback: (() -> Void)? = nil) {
    DispatchQueue.main.async {
      if LoadingAlert.s.On() {
        LoadingAlert.s.Close {
          show(title: title, message: message, exit: exit, restart: restart, callback: callback)
        }
      } else {
        show(title: title, message: message, exit: exit, restart: restart, callback: callback)
      }
    }
  }

  private static func show(title: String = "", message: String, exit: Bool = false, restart: Bool = false, callback: (() -> Void)? = nil) {
    let alert = NSAlert()
    if title != "" {
      alert.messageText = title
    } else {
      alert.messageText = ""
    }
    alert.informativeText = message
    alert.alertStyle = .informational
    alert.addButton(withTitle: LanguageManager.s.localizedString("system.message.confirm"))
    alert.window.titleVisibility = .hidden
    alert.window.titlebarAppearsTransparent = true
    alert.window.styleMask = [.titled, .closable, .miniaturizable]
    alert.window.standardWindowButton(.closeButton)?.isHidden = true
    alert.window.standardWindowButton(.miniaturizeButton)?.isHidden = true
    alert.window.standardWindowButton(.zoomButton)?.isHidden = true
    let parentWindow = getValidParentWindow()
    if parentWindow != nil {
      alert.beginSheetModal(for: parentWindow!) { response in
        callback?()
        if exit {
          AppManager.Terminate()
        } else if restart {
          AppManager.Restart()
        }
      }
    } else {
      _ = alert.runModal()
      callback?()
      if exit {
        AppManager.Terminate()
      } else if restart {
        AppManager.Restart()
      }
    }
  }

  private static func getValidParentWindow() -> NSWindow? {
    if let keyWindow = NSApp.keyWindow, keyWindow.isVisible && !keyWindow.isSheet {
      return keyWindow
    }
    if let mainWindow = NSApp.mainWindow, mainWindow.isVisible && !mainWindow.isSheet {
      return mainWindow
    }
    for window in NSApp.windows {
      if window.isVisible && !window.isSheet && window.level == .normal {
        return window
      }
    }
    return nil
  }
}
