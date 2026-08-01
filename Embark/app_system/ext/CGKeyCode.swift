import ApplicationServices

extension CGKeyCode {
  static let disabled: CGKeyCode = 0xFFFF

  var isDisabled: Bool {
    return self == 0xFFFF
  }
}
