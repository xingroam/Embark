import SwiftUI

class SwiftKeyboard {
  static let s = SwiftKeyboard()
  private var isRunning: Bool = false

  func Boot() {
    if UserDefaults.standard.string(forKey: SwiftKeyboardConfig.swiftKeyboardKey) == nil {
      SwiftKeyboardConfig.swiftKeyboard = SwiftKeyboardDefine.swiftKeyboard
    }
    if UserDefaults.standard.string(forKey: SwiftKeyboardConfig.swiftKeyboardDetectionKey) == nil {
      SwiftKeyboardConfig.swiftKeyboardDetection = SwiftKeyboardDefine.swiftKeyboardDetection
    }
    checkAndSetDefault(key: SwiftKeyboardConfig.swiftKeyboardMinimizeKey, defaultValue: SwiftKeyboardDefine.swiftKeyboardMinimize)
    checkAndSetDefault(key: SwiftKeyboardConfig.swiftKeyboardRestoreKey, defaultValue: SwiftKeyboardDefine.swiftKeyboardRestore)
    checkAndSetDefault(key: SwiftKeyboardConfig.swiftKeyboardMaximizeKey, defaultValue: SwiftKeyboardDefine.swiftKeyboardMaximize)
    checkAndSetDefault(key: SwiftKeyboardConfig.swiftKeyboardCloseKey, defaultValue: SwiftKeyboardDefine.swiftKeyboardClose)
    checkAndSetDefault(key: SwiftKeyboardConfig.swiftKeyboardLauncherKey, defaultValue: SwiftKeyboardDefine.swiftKeyboardLauncher)
    checkAndSetDefault(key: SwiftKeyboardConfig.swiftKeyboardSpaceKey, defaultValue: SwiftKeyboardDefine.swiftKeyboardSpace)
    checkAndSetDefault(key: SwiftKeyboardConfig.swiftKeyboardSlideKey, defaultValue: SwiftKeyboardDefine.swiftKeyboardSlide)
    checkAndSetDefault(key: SwiftKeyboardConfig.swiftKeyboardFocusKey, defaultValue: SwiftKeyboardDefine.swiftKeyboardFocus)
    checkAndSetDefault(key: SwiftKeyboardConfig.swiftKeyboardSwitcherKey, defaultValue: SwiftKeyboardDefine.swiftKeyboardSwitcher)
    if UserDefaults.standard.string(forKey: SwiftKeyboardConfig.swiftKeyboardMaximizeModeKey) == nil {
      SwiftKeyboardConfig.swiftKeyboardMaximizeMode = SwiftKeyboardDefine.swiftKeyboardMaximizeMode
    }
    if UserDefaults.standard.string(forKey: SwiftKeyboardConfig.swiftKeyboardCloseModeKey) == nil {
      SwiftKeyboardConfig.swiftKeyboardCloseMode = SwiftKeyboardDefine.swiftKeyboardCloseMode
    }
    NotificationCenter.default.addObserver(forName: NSNotification.Name("SwiftKeyboardConfigChanged"), object: nil, queue: .main) { [weak self] _ in
      guard let self = self else { return }
      if Start() {
        return
      }
      if Stop() {
        return
      }
    }
    _ = Start()
  }

  func Start() -> Bool {
    if SwiftKeyboardConfig.swiftKeyboard {
      if !isRunning {
        isRunning = true
        SwiftKeyboardMonitor.s.Start()
        return true
      }
    }
    return false
  }

  func Stop(end: Bool = false) -> Bool {
    if !SwiftKeyboardConfig.swiftKeyboard || end {
      if isRunning {
        isRunning = false
        SwiftKeyboardMonitor.s.Stop()
        return true
      }
    }
    return false
  }

  private func checkAndSetDefault(key: String, defaultValue: SwiftShortcut) {
    if UserDefaults.standard.string(forKey: key) != nil {
      return
    }
    if defaultValue == .disabled {
      UserDefaults.standard.set(defaultValue.rawValue, forKey: key)
      return
    }
    var isConflict = false
    let configMap: [String: SwiftShortcut?] = [
      SwiftKeyboardConfig.swiftKeyboardMinimizeKey: SwiftKeyboardConfig.swiftKeyboardMinimize,
      SwiftKeyboardConfig.swiftKeyboardRestoreKey: SwiftKeyboardConfig.swiftKeyboardRestore,
      SwiftKeyboardConfig.swiftKeyboardMaximizeKey: SwiftKeyboardConfig.swiftKeyboardMaximize,
      SwiftKeyboardConfig.swiftKeyboardCloseKey: SwiftKeyboardConfig.swiftKeyboardClose,
      SwiftKeyboardConfig.swiftKeyboardLauncherKey: SwiftKeyboardConfig.swiftKeyboardLauncher,
      SwiftKeyboardConfig.swiftKeyboardSpaceKey: SwiftKeyboardConfig.swiftKeyboardSpace,
      SwiftKeyboardConfig.swiftKeyboardFocusKey: SwiftKeyboardConfig.swiftKeyboardFocus,
      SwiftKeyboardConfig.swiftKeyboardSlideKey: SwiftKeyboardConfig.swiftKeyboardSlide,
      SwiftKeyboardConfig.swiftKeyboardSwitcherKey: SwiftKeyboardConfig.swiftKeyboardSwitcher
    ]
    for (k, v) in configMap {
      if k == key { continue }
      if let val = v, val == defaultValue {
        isConflict = true
        break
      }
    }
    if !isConflict {
      let dbShortcuts = DatabaseManager.s.loadSwiftKeyboardLinks()
      if dbShortcuts.values.contains(defaultValue.rawValue) {
        isConflict = true
      }
    }
    if isConflict {
      UserDefaults.standard.set(SwiftShortcut.disabled.rawValue, forKey: key)
    } else {
      UserDefaults.standard.set(defaultValue.rawValue, forKey: key)
    }
  }
}
