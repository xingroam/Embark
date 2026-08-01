import Foundation
import Carbon
import AppKit

struct SpaceDefine {
  static let space = true
  static let spaceShortcutKey: CGKeyCode = .disabled
  static let spaceShortcutFlags: CGEventFlags = .disabled
  static let spaceRestoreMode = SpaceRestoreMode.minimize
  static let spaceSkipMinimized = true
}

struct SpaceConfig {
  static let spaceKey = "space"
  static let spaceShortcutKeyKey = "spaceShortcutKey"
  static let spaceShortcutFlagsKey = "spaceShortcutFlags"
  static let spaceRestoreModeKey = "spaceRestoreMode"
  static let spaceSkipMinimizedKey = "spaceSkipMinimized"

  static var space: Bool {
    get {
      if UserDefaults.standard.object(forKey: spaceKey) != nil {
        return UserDefaults.standard.bool(forKey: spaceKey)
      }
      return true
    }
    set {
      UserDefaults.standard.set(newValue, forKey: spaceKey)
    }
  }

  static var spaceShortcutKey: CGKeyCode {
    get {
      let value = UserDefaults.standard.object(forKey: spaceShortcutKeyKey) as? CGKeyCode
      return value ?? SpaceDefine.spaceShortcutKey
    }
    set {
      UserDefaults.standard.set(newValue, forKey: spaceShortcutKeyKey)
    }
  }

  static var spaceShortcutFlags: CGEventFlags {
    get {
      if let rawValue = UserDefaults.standard.object(forKey: spaceShortcutFlagsKey) as? UInt64 {
        return CGEventFlags(rawValue: rawValue)
      }
      return SpaceDefine.spaceShortcutFlags
    }
    set {
      UserDefaults.standard.set(newValue.rawValue, forKey: spaceShortcutFlagsKey)
    }
  }

  static var spaceRestoreMode: SpaceRestoreMode {
    get {
      if let raw = UserDefaults.standard.string(forKey: spaceRestoreModeKey), let mode = SpaceRestoreMode(rawValue: raw) {
        return mode
      }
      return SpaceDefine.spaceRestoreMode
    }
    set {
      UserDefaults.standard.set(newValue.rawValue, forKey: spaceRestoreModeKey)
    }
  }

  static var spaceSkipMinimized: Bool {
    get {
      if UserDefaults.standard.object(forKey: spaceSkipMinimizedKey) != nil {
        return UserDefaults.standard.bool(forKey: spaceSkipMinimizedKey)
      }
      return SpaceDefine.spaceSkipMinimized
    }
    set {
      UserDefaults.standard.set(newValue, forKey: spaceSkipMinimizedKey)
    }
  }
}
