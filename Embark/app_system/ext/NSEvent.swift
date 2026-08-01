import SwiftUI

extension NSEvent {
  func toSelector() -> Selector? {
    switch keyCode {
    case 126: // Up arrow
      return #selector(NSResponder.moveUp(_:))
    case 125: // Down arrow
      return #selector(NSResponder.moveDown(_:))
    case 123: // Left arrow
      return #selector(NSResponder.moveLeft(_:))
    case 124: // Right arrow
      return #selector(NSResponder.moveRight(_:))
    case 48: // Tab
      return #selector(NSResponder.insertTab(_:))
    case 36: // Return/Enter
      return #selector(NSResponder.insertNewline(_:))
    case 53: // Escape
      return #selector(NSResponder.cancelOperation(_:))
    default:
      return nil
    }
  }
}
