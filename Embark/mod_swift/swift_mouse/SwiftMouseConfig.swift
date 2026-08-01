import SwiftUI

struct SwiftMouseInfo {
  static let gestureIgnoreThreshold: Double = 0.4
  static let minSegmentLength: CGFloat = 20.0
}

struct SwiftMouseDefine {
  static let swiftMouse: Bool = true
  static let swiftMouseDistance: Double = 20.0
  static let swiftMousePathOpacity: Double = 0.75
  static let swiftMouseMinimize: SwiftMouseGesture = .down
  static let swiftMouseRestore: SwiftMouseGesture = .none
  static let swiftMouseMaximize: SwiftMouseGesture = .right
  static let swiftMouseClose: SwiftMouseGesture = .rightDown
  static let swiftMouseLauncher: SwiftMouseGesture = .left
  static let swiftMouseSpace: SwiftMouseGesture = .leftDown
  static let swiftMouseFocus: SwiftMouseGesture = .none
  static let swiftMouseSlide: SwiftMouseGesture = .none
  static let swiftMouseSwitcher: SwiftMouseGesture = .up
  static let swiftMouseMaximizeMode: SwiftMaximizeMode = .max
  static let swiftMouseCloseMode: SwiftCloseMode = .standard
}

struct SwiftMouseConfig {
  static let swiftMouseKey = "swiftMouse"
  static let swiftMouseDistanceKey = "swiftMouseDistance"
  static let swiftMousePathOpacityKey = "swiftMousePathOpacity"
  static let swiftMouseMinimizeKey = "swiftMouseMinimize"
  static let swiftMouseRestoreKey = "swiftMouseRestore"
  static let swiftMouseMaximizeKey = "swiftMouseMaximize"
  static let swiftMouseCloseKey = "swiftMouseClose"
  static let swiftMouseLauncherKey = "swiftMouseLauncher"
  static let swiftMouseSpaceKey = "swiftMouseSpace"
  static let swiftMouseFocusKey = "swiftMouseFocus"
  static let swiftMouseSlideKey = "swiftMouseSlide"
  static let swiftMouseSwitcherKey = "swiftMouseSwitcher"
  static let swiftMouseMaximizeModeKey = "swiftMouseMaximizeMode"
  static let swiftMouseCloseModeKey = "swiftMouseCloseMode"

  static var swiftMouse: Bool {
    get {
      return UserDefaults.standard.bool(forKey: swiftMouseKey)
    }
    set {
      UserDefaults.standard.set(newValue, forKey: swiftMouseKey)
    }
  }

  static var swiftMouseDistance: Double {
    get {
      UserDefaults.standard.double(forKey: swiftMouseDistanceKey) - 0.1
    }
    set {
      UserDefaults.standard.set(newValue + 0.1, forKey: swiftMouseDistanceKey)
    }
  }

  static var swiftMousePathOpacity: Double {
    get {
      UserDefaults.standard.double(forKey: swiftMousePathOpacityKey) - 0.1
    }
    set {
      UserDefaults.standard.set(newValue + 0.1, forKey: swiftMousePathOpacityKey)
    }
  }

  static var swiftMouseMinimize: SwiftMouseGesture {
    get {
      if let str = UserDefaults.standard.string(forKey: swiftMouseMinimizeKey), let val = SwiftMouseGesture(rawValue: str) {
        return val
      }
      return SwiftMouseDefine.swiftMouseMinimize
    }
    set { UserDefaults.standard.set(newValue.rawValue, forKey: swiftMouseMinimizeKey) }
  }

  static var swiftMouseRestore: SwiftMouseGesture {
    get {
      if let str = UserDefaults.standard.string(forKey: swiftMouseRestoreKey), let val = SwiftMouseGesture(rawValue: str) {
        return val
      }
      return SwiftMouseDefine.swiftMouseRestore
    }
    set { UserDefaults.standard.set(newValue.rawValue, forKey: swiftMouseRestoreKey) }
  }

  static var swiftMouseMaximize: SwiftMouseGesture {
    get {
      if let str = UserDefaults.standard.string(forKey: swiftMouseMaximizeKey), let val = SwiftMouseGesture(rawValue: str) {
        return val
      }
      return SwiftMouseDefine.swiftMouseMaximize
    }
    set { UserDefaults.standard.set(newValue.rawValue, forKey: swiftMouseMaximizeKey) }
  }

  static var swiftMouseClose: SwiftMouseGesture {
    get {
      if let str = UserDefaults.standard.string(forKey: swiftMouseCloseKey), let val = SwiftMouseGesture(rawValue: str) {
        return val
      }
      return SwiftMouseDefine.swiftMouseClose
    }
    set { UserDefaults.standard.set(newValue.rawValue, forKey: swiftMouseCloseKey) }
  }

  static var swiftMouseLauncher: SwiftMouseGesture {
    get {
      if let str = UserDefaults.standard.string(forKey: swiftMouseLauncherKey), let val = SwiftMouseGesture(rawValue: str) {
        return val
      }
      return SwiftMouseDefine.swiftMouseLauncher
    }
    set { UserDefaults.standard.set(newValue.rawValue, forKey: swiftMouseLauncherKey) }
  }

  static var swiftMouseSpace: SwiftMouseGesture {
    get {
      if let str = UserDefaults.standard.string(forKey: swiftMouseSpaceKey), let val = SwiftMouseGesture(rawValue: str) {
        return val
      }
      return SwiftMouseDefine.swiftMouseSpace
    }
    set { UserDefaults.standard.set(newValue.rawValue, forKey: swiftMouseSpaceKey) }
  }

  static var swiftMouseFocus: SwiftMouseGesture {
    get {
      if let str = UserDefaults.standard.string(forKey: swiftMouseFocusKey), let val = SwiftMouseGesture(rawValue: str) {
        return val
      }
      return SwiftMouseDefine.swiftMouseFocus
    }
    set { UserDefaults.standard.set(newValue.rawValue, forKey: swiftMouseFocusKey) }
  }

  static var swiftMouseSlide: SwiftMouseGesture {
    get {
      if let str = UserDefaults.standard.string(forKey: swiftMouseSlideKey), let val = SwiftMouseGesture(rawValue: str) {
        return val
      }
      return SwiftMouseDefine.swiftMouseSlide
    }
    set { UserDefaults.standard.set(newValue.rawValue, forKey: swiftMouseSlideKey) }
  }

  static var swiftMouseSwitcher: SwiftMouseGesture {
    get {
      if let str = UserDefaults.standard.string(forKey: swiftMouseSwitcherKey), let val = SwiftMouseGesture(rawValue: str) {
        return val
      }
      return SwiftMouseDefine.swiftMouseSwitcher
    }
    set { UserDefaults.standard.set(newValue.rawValue, forKey: swiftMouseSwitcherKey) }
  }

  static var swiftMouseMaximizeMode: SwiftMaximizeMode {
    get {
      if let raw = UserDefaults.standard.string(forKey: swiftMouseMaximizeModeKey), let m = SwiftMaximizeMode(rawValue: raw) {
        return m
      }
      return SwiftMouseDefine.swiftMouseMaximizeMode
    }
    set {
      UserDefaults.standard.set(newValue.rawValue, forKey: swiftMouseMaximizeModeKey)
    }
  }

  static var swiftMouseCloseMode: SwiftCloseMode {
    get {
      if let raw = UserDefaults.standard.string(forKey: swiftMouseCloseModeKey), let m = SwiftCloseMode(rawValue: raw) {
        return m
      }
      return SwiftMouseDefine.swiftMouseCloseMode
    }
    set {
      UserDefaults.standard.set(newValue.rawValue, forKey: swiftMouseCloseModeKey)
    }
  }
}
