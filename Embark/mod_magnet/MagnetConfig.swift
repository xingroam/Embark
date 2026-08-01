import SwiftUI

struct MagnetInfo {
  static let intervalDrag = false
  static let intervalResize = false
  static let dragSplit: Double = 1.0 / 100.0
  static let resizeSplit: Double = 1.0 / 250.0
  static let magnetThreshold: CGFloat = 0.0225
}

struct MagnetDefine {
  static let magnet = true
  static let magnetDragShortcut: MagnetShortcut = .controlOption
  static let magnetResizeShortcut: MagnetShortcut = .optionShift
  static let magnet2x2 = false
  static let magnet3x2 = false
  static let magnet3x3 = false
  static let magnet4x2 = false
  static let magnet4x4 = false
  static let magnet6x6 = false
  static let magnet8x8 = true
  static let magnet10x10 = true
  static let magnet12x12 = true
  static let magnetTip = true
}

struct MagnetFree {
  static let magnet2x2 = false
  static let magnet3x2 = true
  static let magnet3x3 = false
  static let magnet4x2 = false
  static let magnet4x4 = false
  static let magnet6x6 = false
  static let magnet8x8 = false
  static let magnet10x10 = false
  static let magnet12x12 = false
  static let magnetTip = true
}

struct MagnetConfig {
  static let magnetKey = "magnet"
  static let magnetDragShortcutKey = "magnetDragShortcut"
  static let magnetResizeShortcutKey = "magnetResizeShortcut"
  static let magnet2x2Key = "magnet2x2"
  static let magnet3x2Key = "magnet3x2"
  static let magnet3x3Key = "magnet3x3"
  static let magnet4x2Key = "magnet4x2"
  static let magnet4x4Key = "magnet4x4"
  static let magnet6x6Key = "magnet6x6"
  static let magnet8x8Key = "magnet8x8"
  static let magnet10x10Key = "magnet10x10"
  static let magnet12x12Key = "magnet12x12"
  static let magnetTipKey = "magnetTip"

  static var magnet: Bool {
    get {
      if UserDefaults.standard.object(forKey: magnetKey) != nil {
        return UserDefaults.standard.bool(forKey: magnetKey)
      }
      return MagnetDefine.magnet
    }
    set {
      UserDefaults.standard.set(newValue, forKey: magnetKey)
    }
  }

  static var magnetDragShortcut: MagnetShortcut {
    get {
      if let raw = UserDefaults.standard.string(forKey: magnetDragShortcutKey), let magnetDragShortcut = MagnetShortcut(rawValue: raw) {
        return magnetDragShortcut
      }
      return MagnetDefine.magnetDragShortcut
    }
    set {
      UserDefaults.standard.set(newValue.rawValue, forKey: magnetDragShortcutKey)
    }
  }

  static var magnetResizeShortcut: MagnetShortcut {
    get {
      if let raw = UserDefaults.standard.string(forKey: magnetResizeShortcutKey), let magnetResizeShortcut = MagnetShortcut(rawValue: raw) {
        return magnetResizeShortcut
      }
      return MagnetDefine.magnetResizeShortcut
    }
    set {
      UserDefaults.standard.set(newValue.rawValue, forKey: magnetResizeShortcutKey)
    }
  }

  static var magnet2x2: Bool {
    get {
      UserDefaults.standard.object(forKey: magnet2x2Key) as? Bool ?? MagnetDefine.magnet2x2
    }
    set {
      UserDefaults.standard.set(newValue, forKey: magnet2x2Key)
    }
  }

  static var magnet3x2: Bool {
    get {
      UserDefaults.standard.object(forKey: magnet3x2Key) as? Bool ?? MagnetDefine.magnet3x2
    }
    set {
      UserDefaults.standard.set(newValue, forKey: magnet3x2Key)
    }
  }

  static var magnet3x3: Bool {
    get {
      UserDefaults.standard.object(forKey: magnet3x3Key) as? Bool ?? MagnetDefine.magnet3x3
    }
    set {
      UserDefaults.standard.set(newValue, forKey: magnet3x3Key)
    }
  }

  static var magnet4x2: Bool {
    get {
      UserDefaults.standard.object(forKey: magnet4x2Key) as? Bool ?? MagnetDefine.magnet4x2
    }
    set {
      UserDefaults.standard.set(newValue, forKey: magnet4x2Key)
    }
  }

  static var magnet4x4: Bool {
    get {
      UserDefaults.standard.object(forKey: magnet4x4Key) as? Bool ?? MagnetDefine.magnet4x4
    }
    set {
      UserDefaults.standard.set(newValue, forKey: magnet4x4Key)
    }
  }

  static var magnet6x6: Bool {
    get {
      UserDefaults.standard.object(forKey: magnet6x6Key) as? Bool ?? MagnetDefine.magnet6x6
    }
    set {
      UserDefaults.standard.set(newValue, forKey: magnet6x6Key)
    }
  }

  static var magnet8x8: Bool {
    get {
      UserDefaults.standard.object(forKey: magnet8x8Key) as? Bool ?? MagnetDefine.magnet8x8
    }
    set {
      UserDefaults.standard.set(newValue, forKey: magnet8x8Key)
    }
  }

  static var magnet10x10: Bool {
    get {
      UserDefaults.standard.object(forKey: magnet10x10Key) as? Bool ?? MagnetDefine.magnet10x10
    }
    set {
      UserDefaults.standard.set(newValue, forKey: magnet10x10Key)
    }
  }

  static var magnet12x12: Bool {
    get {
      UserDefaults.standard.object(forKey: magnet12x12Key) as? Bool ?? MagnetDefine.magnet12x12
    }
    set {
      UserDefaults.standard.set(newValue, forKey: magnet12x12Key)
    }
  }

  static var magnetTip: Bool {
    get {
      UserDefaults.standard.object(forKey: magnetTipKey) as? Bool ?? MagnetDefine.magnetTip
    }
    set {
      UserDefaults.standard.set(newValue, forKey: magnetTipKey)
    }
  }
}
