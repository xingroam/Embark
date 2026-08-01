import SwiftUI
import AppKit

class SharedSearchTextField {
  static let shared = SharedSearchTextField()

  private(set) var textField: CustomNSTextField?

  private init() {}

  func getOrCreateTextField() -> CustomNSTextField {
    if let existing = textField {
      return existing
    }
    let newTextField = CustomNSTextField()
    newTextField.isBordered = false
    newTextField.drawsBackground = false
    newTextField.backgroundColor = .clear
    newTextField.focusRingType = .none
    newTextField.font = NSFont.systemFont(ofSize: 1)
    newTextField.textColor = .clear
    if let cell = newTextField.cell as? NSTextFieldCell {
      cell.usesSingleLineMode = true
      cell.wraps = false
      cell.isScrollable = true
    }
    textField = newTextField
    return newTextField
  }

  func clearTextField() {
    textField = nil
  }
}
