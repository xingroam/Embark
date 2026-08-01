import SwiftUI

struct SwiftKeyboardDefine {
  static let swiftKeyboard: Bool = true
  static let swiftKeyboardDetection: TimeInterval = 0.4
  static let swiftKeyboardMinimize: SwiftShortcut = .disabled
  static let swiftKeyboardRestore: SwiftShortcut = .disabled
  static let swiftKeyboardMaximize: SwiftShortcut = .disabled
  static let swiftKeyboardClose: SwiftShortcut = .disabled
  static let swiftKeyboardLauncher: SwiftShortcut = .command
  static let swiftKeyboardSpace: SwiftShortcut = .control
  static let swiftKeyboardFocus: SwiftShortcut = .disabled
  static let swiftKeyboardSlide: SwiftShortcut = .disabled
  static let swiftKeyboardSwitcher: SwiftShortcut = .disabled
  static let swiftKeyboardMaximizeMode: SwiftMaximizeMode = .max
  static let swiftKeyboardCloseMode: SwiftCloseMode = .standard
}

struct SwiftKeyboardConfig {
  static let swiftKeyboardKey = "swiftKeyboard"
  static let swiftKeyboardDetectionKey = "swiftKeyboardDetection"
  static let swiftKeyboardMinimizeKey = "swiftKeyboardMinimize"
  static let swiftKeyboardRestoreKey = "swiftKeyboardRestore"
  static let swiftKeyboardMaximizeKey = "swiftKeyboardMaximize"
  static let swiftKeyboardCloseKey = "swiftKeyboardClose"
  static let swiftKeyboardLauncherKey = "swiftKeyboardLauncher"
  static let swiftKeyboardSpaceKey = "swiftKeyboardSpace"
  static let swiftKeyboardFocusKey = "swiftKeyboardFocus"
  static let swiftKeyboardSlideKey = "swiftKeyboardSlide"
  static let swiftKeyboardSwitcherKey = "swiftKeyboardSwitcher"
  static let swiftKeyboardMaximizeModeKey = "swiftKeyboardMaximizeMode"
  static let swiftKeyboardCloseModeKey = "swiftKeyboardCloseMode"

  static var swiftKeyboard: Bool {
    get {
      return UserDefaults.standard.bool(forKey: swiftKeyboardKey)
    }
    set {
      UserDefaults.standard.set(newValue, forKey: swiftKeyboardKey)
    }
  }

  static var swiftKeyboardDetection: TimeInterval {
    get {
      UserDefaults.standard.double(forKey: swiftKeyboardDetectionKey)
    }
    set {
      UserDefaults.standard.set(newValue, forKey: swiftKeyboardDetectionKey)
    }
  }

  static var swiftKeyboardMinimize: SwiftShortcut? {
    get {
      if let raw = UserDefaults.standard.string(forKey: swiftKeyboardMinimizeKey) {
        if let key = SwiftShortcut(rawValue: raw) {
          return key == .disabled ? nil : key
        }
      }
      return nil
    }
    set {
      if let v = newValue {
        UserDefaults.standard.set(v.rawValue, forKey: swiftKeyboardMinimizeKey)
      } else {
        UserDefaults.standard.set(SwiftShortcut.disabled.rawValue, forKey: swiftKeyboardMinimizeKey)
      }
    }
  }

  static var swiftKeyboardRestore: SwiftShortcut? {
    get {
      if let raw = UserDefaults.standard.string(forKey: swiftKeyboardRestoreKey) {
        if let key = SwiftShortcut(rawValue: raw) {
          return key == .disabled ? nil : key
        }
      }
      return nil
    }
    set {
      if let v = newValue {
        UserDefaults.standard.set(v.rawValue, forKey: swiftKeyboardRestoreKey)
      } else {
        UserDefaults.standard.set(SwiftShortcut.disabled.rawValue, forKey: swiftKeyboardRestoreKey)
      }
    }
  }

  static var swiftKeyboardMaximize: SwiftShortcut? {
    get {
      if let raw = UserDefaults.standard.string(forKey: swiftKeyboardMaximizeKey) {
        if let key = SwiftShortcut(rawValue: raw) {
          return key == .disabled ? nil : key
        }
      }
      return nil
    }
    set {
      if let v = newValue {
        UserDefaults.standard.set(v.rawValue, forKey: swiftKeyboardMaximizeKey)
      } else {
        UserDefaults.standard.set(SwiftShortcut.disabled.rawValue, forKey: swiftKeyboardMaximizeKey)
      }
    }
  }

  static var swiftKeyboardClose: SwiftShortcut? {
    get {
      if let raw = UserDefaults.standard.string(forKey: swiftKeyboardCloseKey) {
        if let key = SwiftShortcut(rawValue: raw) {
          return key == .disabled ? nil : key
        }
      }
      return nil
    }
    set {
      if let v = newValue {
        UserDefaults.standard.set(v.rawValue, forKey: swiftKeyboardCloseKey)
      } else {
        UserDefaults.standard.set(SwiftShortcut.disabled.rawValue, forKey: swiftKeyboardCloseKey)
      }
    }
  }

  static var swiftKeyboardLauncher: SwiftShortcut? {
    get {
      if let raw = UserDefaults.standard.string(forKey: swiftKeyboardLauncherKey) {
        if let key = SwiftShortcut(rawValue: raw) {
          return key == .disabled ? nil : key
        }
      }
      return nil
    }
    set {
      if let v = newValue {
        UserDefaults.standard.set(v.rawValue, forKey: swiftKeyboardLauncherKey)
      } else {
        UserDefaults.standard.set(SwiftShortcut.disabled.rawValue, forKey: swiftKeyboardLauncherKey)
      }
    }
  }

  static var swiftKeyboardSpace: SwiftShortcut? {
    get {
      if let raw = UserDefaults.standard.string(forKey: swiftKeyboardSpaceKey) {
        if let key = SwiftShortcut(rawValue: raw) {
          return key == .disabled ? nil : key
        }
      }
      return nil
    }
    set {
      if let v = newValue {
        UserDefaults.standard.set(v.rawValue, forKey: swiftKeyboardSpaceKey)
      } else {
        UserDefaults.standard.set(SwiftShortcut.disabled.rawValue, forKey: swiftKeyboardSpaceKey)
      }
    }
  }

  static var swiftKeyboardFocus: SwiftShortcut? {
    get {
      if let raw = UserDefaults.standard.string(forKey: swiftKeyboardFocusKey) {
        if let key = SwiftShortcut(rawValue: raw) {
          return key == .disabled ? nil : key
        }
      }
      return nil
    }
    set {
      if let v = newValue {
        UserDefaults.standard.set(v.rawValue, forKey: swiftKeyboardFocusKey)
      } else {
        UserDefaults.standard.set(SwiftShortcut.disabled.rawValue, forKey: swiftKeyboardFocusKey)
      }
    }
  }

  static var swiftKeyboardSlide: SwiftShortcut? {
    get {
      if let raw = UserDefaults.standard.string(forKey: swiftKeyboardSlideKey) {
        if let key = SwiftShortcut(rawValue: raw) {
          return key == .disabled ? nil : key
        }
      }
      return nil
    }
    set {
      if let v = newValue {
        UserDefaults.standard.set(v.rawValue, forKey: swiftKeyboardSlideKey)
      } else {
        UserDefaults.standard.set(SwiftShortcut.disabled.rawValue, forKey: swiftKeyboardSlideKey)
      }
    }
  }

  static var swiftKeyboardSwitcher: SwiftShortcut? {
    get {
      if let raw = UserDefaults.standard.string(forKey: swiftKeyboardSwitcherKey) {
        if let key = SwiftShortcut(rawValue: raw) {
          return key == .disabled ? nil : key
        }
      }
      return nil
    }
    set {
      if let v = newValue {
        UserDefaults.standard.set(v.rawValue, forKey: swiftKeyboardSwitcherKey)
      } else {
        UserDefaults.standard.set(SwiftShortcut.disabled.rawValue, forKey: swiftKeyboardSwitcherKey)
      }
    }
  }

  static var swiftKeyboardMaximizeMode: SwiftMaximizeMode {
    get {
      if let raw = UserDefaults.standard.string(forKey: swiftKeyboardMaximizeModeKey), let m = SwiftMaximizeMode(rawValue: raw) {
        return m
      }
      return SwiftKeyboardDefine.swiftKeyboardMaximizeMode
    }
    set {
      UserDefaults.standard.set(newValue.rawValue, forKey: swiftKeyboardMaximizeModeKey)
    }
  }

  static var swiftKeyboardCloseMode: SwiftCloseMode {
    get {
      if let raw = UserDefaults.standard.string(forKey: swiftKeyboardCloseModeKey), let m = SwiftCloseMode(rawValue: raw) {
        return m
      }
      return SwiftKeyboardDefine.swiftKeyboardCloseMode
    }
    set {
      UserDefaults.standard.set(newValue.rawValue, forKey: swiftKeyboardCloseModeKey)
    }
  }
}
