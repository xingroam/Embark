import AppKit

class CancelAlert {
  static func Show(title: String = "", message: String, ok: String, cancel: String, quit: Bool = false, restart: Bool = false, cancel_quit: Bool = false, callback: (() -> Void)? = nil) {
    DispatchQueue.main.async {
      if LoadingAlert.s.On() {
        LoadingAlert.s.Close {
          show(title: title, message: message, ok: ok, cancel: cancel, quit: quit, restart: restart, cancel_quit: cancel_quit, callback: callback)
        }
      } else {
        show(title: title, message: message, ok: ok, cancel: cancel, quit: quit, restart: restart, cancel_quit: cancel_quit, callback: callback)
      }
    }
  }

  private static func show(title: String = "", message: String, ok: String, cancel: String, quit: Bool = false, restart: Bool = false, cancel_quit: Bool = false, callback: (() -> Void)? = nil) {
    let alert = NSAlert()
    if title != "" {
      alert.messageText = title
    }
    alert.informativeText = message
    alert.addButton(withTitle: ok)
    alert.addButton(withTitle: cancel)
    alert.alertStyle = .informational
    alert.window.titleVisibility = .hidden
    alert.window.titlebarAppearsTransparent = true
    alert.window.styleMask = [.titled, .closable, .miniaturizable]
    alert.window.standardWindowButton(.closeButton)?.isHidden = true
    alert.window.standardWindowButton(.miniaturizeButton)?.isHidden = true
    alert.window.standardWindowButton(.zoomButton)?.isHidden = true
    let parentWindow = getValidParentWindow()
    if parentWindow != nil {
      alert.beginSheetModal(for: parentWindow!) { response in
        if response == .alertFirstButtonReturn {
          callback?()
          if quit {
            AppManager.Terminate()
          } else if restart {
            AppManager.Restart()
          }
        } else if response == .alertSecondButtonReturn && cancel_quit {
          AppManager.Terminate()
        }
      }
    } else {
      DispatchQueue.main.async {
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
          callback?()
          if quit {
            AppManager.Terminate()
          } else if restart {
            AppManager.Restart()
          }
        } else if response == .alertSecondButtonReturn && cancel_quit {
          AppManager.Terminate()
        }
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
