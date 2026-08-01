import SwiftUI
import AppKit

struct InvisibleTextField: NSViewRepresentable {
  @Binding var text: String
  @Binding var isFocused: Bool
  let onUpArrow: () -> Void
  let onDownArrow: () -> Void
  let onLeftArrow: () -> Void
  let onRightArrow: () -> Void
  let onTab: () -> Void
  let onSubmit: () -> Void

  func makeNSView(context: Context) -> CustomNSTextField {
    let textField = CustomNSTextField()
    textField.delegate = context.coordinator
    textField.isBordered = false
    textField.drawsBackground = false
    textField.backgroundColor = .clear
    textField.focusRingType = .none
    textField.font = NSFont.systemFont(ofSize: 1)
    textField.textColor = .clear
    if let cell = textField.cell as? NSTextFieldCell {
      cell.usesSingleLineMode = true
      cell.wraps = false
      cell.isScrollable = true
    }
    return textField
  }

  func updateNSView(_ nsView: CustomNSTextField, context: Context) {
    context.coordinator.parent = self
    if nsView.stringValue != text {
      nsView.stringValue = text
      if let editor = nsView.currentEditor() as? NSTextView {
        editor.selectedRange = NSRange(location: text.count, length: 0)
      }
    }
    if isFocused {
      if nsView.window?.firstResponder != nsView.currentEditor() {
        DispatchQueue.main.async {
          nsView.window?.makeFirstResponder(nsView)
          if let editor = nsView.currentEditor() as? NSTextView {
            editor.selectedRange = NSRange(location: nsView.stringValue.count, length: 0)
          }
        }
      }
    }
  }

  func makeCoordinator() -> Coordinator {
    Coordinator(self)
  }

  class Coordinator: NSObject, NSTextFieldDelegate {
    var parent: InvisibleTextField

    init(_ parent: InvisibleTextField) {
      self.parent = parent
    }

    func controlTextDidChange(_ obj: Notification) {
      guard let textField = obj.object as? NSTextField else { return }
      DispatchQueue.main.async {
        self.parent.text = textField.stringValue
      }
    }

    func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
      if commandSelector == #selector(NSResponder.moveUp(_:)) {
        parent.onUpArrow()
        return true
      } else if commandSelector == #selector(NSResponder.moveDown(_:)) {
        parent.onDownArrow()
        return true
      } else if commandSelector == #selector(NSResponder.moveLeft(_:)) {
        parent.onLeftArrow()
        return true
      } else if commandSelector == #selector(NSResponder.moveRight(_:)) {
        parent.onRightArrow()
        return true
      } else if commandSelector == #selector(NSResponder.insertTab(_:)) {
        parent.onTab()
        return true
      } else if commandSelector == #selector(NSResponder.insertNewline(_:)) {
        parent.onSubmit()
        return true
      } else if commandSelector == #selector(NSResponder.cancelOperation(_:)) {
        return true
      }
      return false
    }
  }
}
