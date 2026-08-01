import ApplicationServices

extension CGEventFlags {
  static let disabled: CGEventFlags = CGEventFlags(rawValue: 0xFFFFFFFFFFFFFFFF)

  var isDisabled: Bool {
    return self.rawValue == 0xFFFFFFFFFFFFFFFF
  }

  /// 只保留标准修饰键标志位，去除设备特定（左/右区分）和系统临时标志位
  /// 避免因左右修饰键不同或 maskNonCoalesced 等瞬态标志导致比较失败
  var modifierOnly: CGEventFlags {
    let mask: UInt64 =
      CGEventFlags.maskAlphaShift.rawValue |
      CGEventFlags.maskShift.rawValue |
      CGEventFlags.maskControl.rawValue |
      CGEventFlags.maskAlternate.rawValue |
      CGEventFlags.maskCommand.rawValue |
      CGEventFlags.maskSecondaryFn.rawValue
    return CGEventFlags(rawValue: self.rawValue & mask)
  }

  /// 检查是否包含指定的标准修饰键（忽略设备特定标志位）
  func containsModifier(_ other: CGEventFlags) -> Bool {
    return self.modifierOnly.contains(other.modifierOnly)
  }
}
