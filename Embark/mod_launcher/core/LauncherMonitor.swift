import SwiftUI
import ApplicationServices

class LauncherMonitor {
  static let s = LauncherMonitor()
  private var keyDownListener: KeyboardListener?
  private var linkShortcuts: [String: LinkShortcut] = [:]

  private init() {}

  func Start() {
    linkShortcuts = DatabaseManager.s.getLinkShortcuts()
    setupKeyboardHandling()
  }

  func Stop() {
    if let listener = keyDownListener {
      InputEventManager.s.unregisterListener(listener)
      keyDownListener = nil
    }
  }

  private func setupKeyboardHandling() {
    Stop()
    keyDownListener = InputEventManager.s.createKeyDownListener { [weak self] type, event in
      guard let self = self else { return Unmanaged.passUnretained(event) }
      let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
      let flags = event.flags
      if let linkPath = self.findMatchingLinkShortcut(keyCode: CGKeyCode(keyCode), flags: flags) {
        SwiftKeyboardMonitor.s.markOtherKeyPressed()
        DispatchQueue.main.async {
          if LauncherWin.s.IsShow() {
            LauncherWin.s.Hide()
          }
          Task {
            let linkName = DataManager.s.linkData[linkPath]?.name ?? (linkPath as NSString).lastPathComponent
            _ = await DataManager.s.launchLinkWithValidation(path: linkPath, linkName: linkName)
          }
        }
        return nil
      }
      return Unmanaged.passUnretained(event)
    }
  }

  private func findMatchingLinkShortcut(keyCode: CGKeyCode, flags: CGEventFlags) -> String? {
    let normalizedFlags = LinkShortcut.normalizeFlags(flags)
    for (linkPath, shortcut) in linkShortcuts {
      if shortcut.keyCode == keyCode && shortcut.flags == normalizedFlags {
        return linkPath
      }
    }
    return nil
  }
}
