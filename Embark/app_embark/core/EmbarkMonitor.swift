import SwiftUI
import AppKit
import ApplicationServices

class EmbarkMonitor {
  static let s = EmbarkMonitor()
  private var keyboardListener: KeyboardListener?
  private var isRunning: Bool = false

  private init() {}

  func Boot(){
    Start()
  }

  func Start() {
    if !isRunning {
      isRunning = true
      setupKeyboardHandling()
    }
  }

  func Stop() {
    if isRunning {
      isRunning = false
      cleanupKeyboardHandling()
    }
  }

  private func setupKeyboardHandling() {
    cleanupKeyboardHandling()
    keyboardListener = InputEventManager.s.createKeyDownListener { type, event in
      let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
      let flags = event.flags
      if FocusConfig.focusShortcutKey != .disabled && FocusConfig.focusShortcutFlags != .disabled && keyCode == FocusConfig.focusShortcutKey && flags.contains(FocusConfig.focusShortcutFlags) {
        FocusConfig.focus = !FocusConfig.focus
        NotificationCenter.default.post(name: NSNotification.Name("FocusConfigChanged"), object: nil)
        return nil
      }
      return Unmanaged.passUnretained(event)
    }
  }

  private func cleanupKeyboardHandling() {
    if let listener = keyboardListener {
      InputEventManager.s.unregisterListener(listener)
      keyboardListener = nil
    }
  }
}
