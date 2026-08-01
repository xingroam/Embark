import SwiftUI

class SwiftMouse {
  static let s = SwiftMouse()
  private var isRunning: Bool = false

  func Boot() {
    if UserDefaults.standard.string(forKey: SwiftMouseConfig.swiftMouseKey) == nil {
      SwiftMouseConfig.swiftMouse = SwiftMouseDefine.swiftMouse
    }
    if UserDefaults.standard.string(forKey: SwiftMouseConfig.swiftMouseDistanceKey) == nil {
      SwiftMouseConfig.swiftMouseDistance = SwiftMouseDefine.swiftMouseDistance
    }
    if UserDefaults.standard.string(forKey: SwiftMouseConfig.swiftMousePathOpacityKey) == nil {
      SwiftMouseConfig.swiftMousePathOpacity = SwiftMouseDefine.swiftMousePathOpacity
    }
    checkAndSetDefault(key: SwiftMouseConfig.swiftMouseMinimizeKey, defaultValue: SwiftMouseDefine.swiftMouseMinimize)
    checkAndSetDefault(key: SwiftMouseConfig.swiftMouseRestoreKey, defaultValue: SwiftMouseDefine.swiftMouseRestore)
    checkAndSetDefault(key: SwiftMouseConfig.swiftMouseMaximizeKey, defaultValue: SwiftMouseDefine.swiftMouseMaximize)
    checkAndSetDefault(key: SwiftMouseConfig.swiftMouseCloseKey, defaultValue: SwiftMouseDefine.swiftMouseClose)
    checkAndSetDefault(key: SwiftMouseConfig.swiftMouseLauncherKey, defaultValue: SwiftMouseDefine.swiftMouseLauncher)
    checkAndSetDefault(key: SwiftMouseConfig.swiftMouseSpaceKey, defaultValue: SwiftMouseDefine.swiftMouseSpace)
    checkAndSetDefault(key: SwiftMouseConfig.swiftMouseFocusKey, defaultValue: SwiftMouseDefine.swiftMouseFocus)
    checkAndSetDefault(key: SwiftMouseConfig.swiftMouseSlideKey, defaultValue: SwiftMouseDefine.swiftMouseSlide)
    checkAndSetDefault(key: SwiftMouseConfig.swiftMouseSwitcherKey, defaultValue: SwiftMouseDefine.swiftMouseSwitcher)
    if UserDefaults.standard.string(forKey: SwiftMouseConfig.swiftMouseMaximizeModeKey) == nil {
      SwiftMouseConfig.swiftMouseMaximizeMode = SwiftMouseDefine.swiftMouseMaximizeMode
    }
    if UserDefaults.standard.string(forKey: SwiftMouseConfig.swiftMouseCloseModeKey) == nil {
      SwiftMouseConfig.swiftMouseCloseMode = SwiftMouseDefine.swiftMouseCloseMode
    }
    NotificationCenter.default.addObserver(forName: NSNotification.Name("SwiftMouseConfigChanged"), object: nil, queue: .main) { [weak self] _ in
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
    if SwiftMouseConfig.swiftMouse {
      if !isRunning {
        isRunning = true
        SwiftMouseMonitor.s.Start()
        return true
      }
    }
    return false
  }

  func Stop(end: Bool = false) -> Bool {
    if !SwiftMouseConfig.swiftMouse || end {
      if isRunning {
        isRunning = false
        SwiftMouseMonitor.s.Stop()
        return true
      }
    }
    return false
  }

  private func checkAndSetDefault(key: String, defaultValue: SwiftMouseGesture) {
    if UserDefaults.standard.string(forKey: key) != nil {
      return
    }
    if defaultValue == .none {
      UserDefaults.standard.set(defaultValue.rawValue, forKey: key)
      return
    }
    var isConflict = false
    let configMap: [String: SwiftMouseGesture] = [
      SwiftMouseConfig.swiftMouseMinimizeKey: SwiftMouseConfig.swiftMouseMinimize,
      SwiftMouseConfig.swiftMouseRestoreKey: SwiftMouseConfig.swiftMouseRestore,
      SwiftMouseConfig.swiftMouseMaximizeKey: SwiftMouseConfig.swiftMouseMaximize,
      SwiftMouseConfig.swiftMouseCloseKey: SwiftMouseConfig.swiftMouseClose,
      SwiftMouseConfig.swiftMouseLauncherKey: SwiftMouseConfig.swiftMouseLauncher,
      SwiftMouseConfig.swiftMouseSpaceKey: SwiftMouseConfig.swiftMouseSpace,
      SwiftMouseConfig.swiftMouseFocusKey: SwiftMouseConfig.swiftMouseFocus,
      SwiftMouseConfig.swiftMouseSlideKey: SwiftMouseConfig.swiftMouseSlide,
      SwiftMouseConfig.swiftMouseSwitcherKey: SwiftMouseConfig.swiftMouseSwitcher
    ]
    for (k, v) in configMap {
      if k == key { continue }
      if v == defaultValue {
        isConflict = true
        break
      }
    }
    if !isConflict {
      let dbGestures = DatabaseManager.s.loadSwiftMouseLinks()
      if dbGestures.values.contains(defaultValue.rawValue) {
        isConflict = true
      }
    }
    if isConflict {
      UserDefaults.standard.set(SwiftMouseGesture.none.rawValue, forKey: key)
    } else {
      UserDefaults.standard.set(defaultValue.rawValue, forKey: key)
    }
  }
}
