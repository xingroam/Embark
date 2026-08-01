import SwiftUI
import ApplicationServices

enum SwiftShortcut: String, CaseIterable {
  case command = "Command"
  case control = "Control"
  case option = "Option"
  case shift = "Shift"
  case escape = "Esc"
  case disabled = "Disabled"

  var flag: CGEventFlags {
    switch self {
    case .command: return .maskCommand
    case .control: return .maskControl
    case .option: return .maskAlternate
    case .shift: return .maskShift
    case .escape: return CGEventFlags(rawValue: 0)
    case .disabled: return CGEventFlags(rawValue: 0)
    }
  }
}
