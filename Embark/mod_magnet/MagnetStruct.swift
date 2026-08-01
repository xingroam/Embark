import SwiftUI

struct DragMagnetResult {
  let targetPosition: CGPoint
  let shouldSnap: Bool
}

struct ResizeMagnetResult {
  let targetSize: CGSize
  let shouldSnapX: Bool
  let shouldSnapY: Bool
  let shouldSnap: Bool
}

struct ReferencePoints {
  let x: [CGFloat]
  let y: [CGFloat]
}

enum MagnetShortcut: String, CaseIterable {
  case controlOption = "ControlOption"
  case optionShift = "OptionShift"
  case controlShift = "ControlShift"

  var displayName: String {
    switch self {
    case .controlOption:
      return "Control+Option"
    case .optionShift:
      return "Option+Shift"
    case .controlShift:
      return "Control+Shift"
    }
  }
  var flags: CGEventFlags {
    switch self {
    case .controlOption:
      return CGEventFlags(rawValue: CGEventFlags.maskControl.rawValue | CGEventFlags.maskAlternate.rawValue)
    case .optionShift:
      return CGEventFlags(rawValue: CGEventFlags.maskAlternate.rawValue | CGEventFlags.maskShift.rawValue)
    case .controlShift:
      return CGEventFlags(rawValue: CGEventFlags.maskControl.rawValue | CGEventFlags.maskShift.rawValue)
    }
  }
}

enum GridType {
  case x2
  case x3x2
  case x3
  case x4x2
  case x4
  case x6
  case x8
  case x10
  case x12
}
