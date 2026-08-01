import SwiftUI
import ApplicationServices

struct SlideInfo {
  static let slideCleanTime: TimeInterval = 60
}

struct SlideDefine {
  static let slide = true
  static let slideShortcutKey: CGKeyCode = Keyboard.fullNameToKeyCode("Space")!
  static let slideShortcutFlags: CGEventFlags = .maskShift
  static let slideDelay: TimeInterval = 0.1
  static let slideDistance: CGFloat = 15
  static let slideMargin: CGFloat = 10
  static let slideAutoUndock = true
  static let slideTip = true
}

struct SlideFree {
  static let slideDelay: TimeInterval = 0.4
  static let slideDistance: CGFloat = 15
  static let slideMargin: CGFloat = 10
  static let slideAutoUndock = true
  static let slideTip = true
}

struct SlideConfig {
  static let slideKey = "slide"
  static let slideShortcutKeyKey = "slideShortcutKey"
  static let slideShortcutFlagsKey = "slideShortcutFlags"
  static let slideDelayKey = "slideDelay"
  static let slideDistanceKey = "slideDistance"
  static let slideMarginKey = "slideMargin"
  static let slideAutoUndockKey = "slideAutoUndock"
  static let slideTipKey = "slideTip"

  static var slide: Bool {
    get {
      UserDefaults.standard.object(forKey: slideKey) as? Bool ?? SlideDefine.slide
    }
    set {
      UserDefaults.standard.set(newValue, forKey: slideKey)
    }
  }

  static var slideShortcutKey: CGKeyCode {
    get {
      let value = UserDefaults.standard.object(forKey: slideShortcutKeyKey) as? CGKeyCode
      return value ?? SlideDefine.slideShortcutKey
    }
    set {
      UserDefaults.standard.set(newValue, forKey: slideShortcutKeyKey)
    }
  }

  static var slideShortcutFlags: CGEventFlags {
    get {
      if let rawValue = UserDefaults.standard.object(forKey: slideShortcutFlagsKey) as? UInt64 {
        return CGEventFlags(rawValue: rawValue)
      }
      return SlideDefine.slideShortcutFlags
    }
    set {
      UserDefaults.standard.set(newValue.rawValue, forKey: slideShortcutFlagsKey)
    }
  }

  static var slideDelay: TimeInterval {
    get {
      UserDefaults.standard.object(forKey: slideDelayKey) as? TimeInterval ?? SlideDefine.slideDelay
    }
    set {
      UserDefaults.standard.set(newValue, forKey: slideDelayKey)
    }
  }

  static var slideDistance: CGFloat {
    get {
      UserDefaults.standard.object(forKey: slideDistanceKey) as? CGFloat ?? SlideDefine.slideDistance
    }
    set {
      UserDefaults.standard.set(newValue, forKey: slideDistanceKey)
    }
  }

  static var slideMargin: CGFloat {
    get {
      UserDefaults.standard.object(forKey: slideMarginKey) as? CGFloat ?? SlideDefine.slideMargin
    }
    set {
      UserDefaults.standard.set(newValue, forKey: slideMarginKey)
    }
  }

  static var slideAutoUndock: Bool {
    get {
      UserDefaults.standard.object(forKey: slideAutoUndockKey) as? Bool ?? SlideDefine.slideAutoUndock
    }
    set {
      UserDefaults.standard.set(newValue, forKey: slideAutoUndockKey)
    }
  }

  static var slideTip: Bool {
    get {
      UserDefaults.standard.object(forKey: slideTipKey) as? Bool ?? SlideDefine.slideTip
    }
    set {
      UserDefaults.standard.set(newValue, forKey: slideTipKey)
    }
  }
}
