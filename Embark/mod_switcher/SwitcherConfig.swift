import SwiftUI
import ApplicationServices

struct SwitcherInfo {
  static let gestureStarted = false
  static let timeout: TimeInterval = 0.1
}

struct SwitcherDefine {
  static let switcher = true
  static let switcherShortcutKey: CGKeyCode = Keyboard.fullNameToKeyCode("Tab")!
  static let switcherShortcutFlags: CGEventFlags = .maskAlternate
  static let switcherMode: SwitcherMode = .switchMode
  static let switcherSize: SwitcherSize = .medium
  static let switcherWidth: Double = 300.0
  static let switcherMaxItemsPerColumn: Double = 8.0
}

struct SwitcherConfig {
  static let switcherKey = "switcher"
  static let switcherShortcutKeyKey = "switcherShortcutKey"
  static let switcherShortcutFlagsKey = "switcherShortcutFlags"
  static let switcherModeKey = "switcherMode"
  static let switcherSizeKey = "switcherSize"
  static let switcherWidthKey = "switcherWidth"
  static let switcherMaxItemsPerColumnKey = "switcherMaxItemsPerColumn"

  static var switcher: Bool {
    get {
      UserDefaults.standard.object(forKey: switcherKey) as? Bool ?? SwitcherDefine.switcher
    }
    set {
      UserDefaults.standard.set(newValue, forKey: switcherKey)
    }
  }

  static var switcherShortcutKey: CGKeyCode {
    get {
      let value = UserDefaults.standard.object(forKey: switcherShortcutKeyKey) as? CGKeyCode
      return value ?? SwitcherDefine.switcherShortcutKey
    }
    set {
      UserDefaults.standard.set(newValue, forKey: switcherShortcutKeyKey)
    }
  }

  static var switcherShortcutFlags: CGEventFlags {
    get {
      if let rawValue = UserDefaults.standard.object(forKey: switcherShortcutFlagsKey) as? UInt64 {
        return CGEventFlags(rawValue: rawValue)
      }
      return SwitcherDefine.switcherShortcutFlags
    }
    set {
      UserDefaults.standard.set(newValue.rawValue, forKey: switcherShortcutFlagsKey)
    }
  }

  static var switcherMode: SwitcherMode {
    get {
      if let str = UserDefaults.standard.string(forKey: switcherModeKey), let val = SwitcherMode(rawValue: str) {
        return val
      }
      return SwitcherDefine.switcherMode
    }
    set {
      UserDefaults.standard.set(newValue.rawValue, forKey: switcherModeKey)
    }
  }

  static var switcherSize: SwitcherSize {
    get {
      if let str = UserDefaults.standard.string(forKey: switcherSizeKey), let val = SwitcherSize(rawValue: str) {
        return val
      }
      return SwitcherDefine.switcherSize
    }
    set {
      UserDefaults.standard.set(newValue.rawValue, forKey: switcherSizeKey)
    }
  }

  static var switcherWidth: Double {
    get {
      UserDefaults.standard.object(forKey: switcherWidthKey) as? Double ?? SwitcherDefine.switcherWidth
    }
    set {
      UserDefaults.standard.set(newValue, forKey: switcherWidthKey)
    }
  }

  static var switcherMaxItemsPerColumn: Double {
    get {
      UserDefaults.standard.object(forKey: switcherMaxItemsPerColumnKey) as? Double ?? SwitcherDefine.switcherMaxItemsPerColumn
    }
    set {
      UserDefaults.standard.set(newValue, forKey: switcherMaxItemsPerColumnKey)
    }
  }
}
