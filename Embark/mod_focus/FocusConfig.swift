import SwiftUI
import QuartzCore

struct FocusInfo {
  static let animationTimingFunction = CAMediaTimingFunction(name: .easeIn) // .linear, .easeIn, .easeOut, .easeInEaseOut, .default
  static let timerInterval: TimeInterval = 0.15
}

struct FocusDefine {
  static let focus = false
  static let focusShortcutKey: CGKeyCode = .disabled
  static let focusShortcutFlags: CGEventFlags = .disabled
  static let focusStyle: FocusStyle = .dot
  static let focusStyle13: FocusStyle = .clean
  static let focusColor: FocusColor = .solid
  static let focusOpacity: Double = 0.0
  static let focusBlur: CGFloat = 1.0
  static let focusAnimation = true
  static let focusDuration: TimeInterval = 0.3
  static let focusTopTransparent = false
  static let focusTopTransparentDistance: CGFloat = 40.0
}

struct FocusFree {
  static let focusStyle: FocusStyle = .clean
  static let focusColor: FocusColor = .solid
  static let focusOpacity: Double = 0.5
  static let focusBlur: CGFloat = 0.0
  static let focusAnimation = false
  static let focusTopTransparent = false
}

struct FocusConfig {
  static let focusKey = "focus"
  static let focusShortcutKeyKey = "focusShortcutKey"
  static let focusShortcutFlagsKey = "focusShortcutFlags"
  static let focusStyleKey = "focusStyle"
  static let focusColorKey = "focusColor"
  static let focusOpacityKey = "focusOpacity"
  static let focusBlurKey = "focusBlur"
  static let focusAnimationKey = "focusAnimation"
  static let focusDurationKey = "focusDuration"
  static let focusTopTransparentKey = "focusTopTransparent"
  static let focusTopTransparentDistanceKey = "focusTopTransparentDistance"

  static var focus: Bool {
    get {
      UserDefaults.standard.object(forKey: focusKey) as? Bool ?? FocusDefine.focus
    }
    set {
      UserDefaults.standard.set(newValue, forKey: focusKey)
    }
  }

  static var focusShortcutKey: CGKeyCode {
    get {
      let value = UserDefaults.standard.object(forKey: focusShortcutKeyKey) as? CGKeyCode
      return value ?? FocusDefine.focusShortcutKey
    }
    set {
      UserDefaults.standard.set(newValue, forKey: focusShortcutKeyKey)
    }
  }

  static var focusShortcutFlags: CGEventFlags {
    get {
      if let rawValue = UserDefaults.standard.object(forKey: focusShortcutFlagsKey) as? UInt64 {
        return CGEventFlags(rawValue: rawValue)
      }
      return FocusDefine.focusShortcutFlags
    }
    set {
      UserDefaults.standard.set(newValue.rawValue, forKey: focusShortcutFlagsKey)
    }
  }

  static var focusStyle: FocusStyle {
    get {
      if let rawValue = UserDefaults.standard.string(forKey: focusStyleKey), let focusStyle = FocusStyle(rawValue: rawValue) {
        return focusStyle
      }
      return FocusDefine.focusStyle
    }
    set {
      UserDefaults.standard.set(newValue.rawValue, forKey: focusStyleKey)
    }
  }

  static var focusColor: FocusColor {
    get {
      if let rawValue = UserDefaults.standard.string(forKey: focusColorKey), let focusColor = FocusColor(rawValue: rawValue) {
        return focusColor
      }
      return FocusDefine.focusColor
    }
    set {
      UserDefaults.standard.set(newValue.rawValue, forKey: focusColorKey)
    }
  }

  static var focusOpacity: Double {
    get {
      let value = UserDefaults.standard.object(forKey: focusOpacityKey) as? Double
      return value ?? FocusDefine.focusOpacity
    }
    set {
      UserDefaults.standard.set(newValue, forKey: focusOpacityKey)
    }
  }

  static var focusBlur: CGFloat {
    get {
      let value = UserDefaults.standard.object(forKey: focusBlurKey) as? CGFloat
      return value ?? FocusDefine.focusBlur
    }
    set {
      UserDefaults.standard.set(newValue, forKey: focusBlurKey)
    }
  }

  static var focusAnimation: Bool {
    get {
      UserDefaults.standard.object(forKey: focusAnimationKey) as? Bool ?? FocusDefine.focusAnimation
    }
    set {
      UserDefaults.standard.set(newValue, forKey: focusAnimationKey)
    }
  }

  static var focusDuration: TimeInterval {
    get {
      let value = UserDefaults.standard.object(forKey: focusDurationKey) as? TimeInterval
      return value ?? FocusDefine.focusDuration
    }
    set {
      UserDefaults.standard.set(newValue, forKey: focusDurationKey)
    }
  }

  static var focusTopTransparent: Bool {
    get {
      UserDefaults.standard.object(forKey: focusTopTransparentKey) as? Bool ?? FocusDefine.focusTopTransparent
    }
    set {
      UserDefaults.standard.set(newValue, forKey: focusTopTransparentKey)
    }
  }

  static var focusTopTransparentDistance: CGFloat {
    get {
      let value = UserDefaults.standard.object(forKey: focusTopTransparentDistanceKey) as? CGFloat
      return value ?? FocusDefine.focusTopTransparentDistance
    }
    set {
      UserDefaults.standard.set(newValue, forKey: focusTopTransparentDistanceKey)
    }
  }
}
