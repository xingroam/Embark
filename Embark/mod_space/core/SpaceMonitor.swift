import SwiftUI
import ApplicationServices

class SpaceMonitor {
  static let s = SpaceMonitor()
  private var keyboardListener: KeyboardListener?

  private init() {}

  func Start() {
    setupKeyboardHandling()
  }

  func Stop() {
    cleanupKeyboardHandling()
  }

  private func setupKeyboardHandling() {
    cleanupKeyboardHandling()
    keyboardListener = InputEventManager.s.createKeyDownListener { type, event in
      let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
      let flags = event.flags
      if SpaceConfig.space && SpaceConfig.spaceShortcutKey != .disabled && keyCode == SpaceConfig.spaceShortcutKey && flags.contains(SpaceConfig.spaceShortcutFlags) {
        DispatchQueue.main.async {
          LauncherWin.s.ShowOrHide(mode: .space)
        }
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
