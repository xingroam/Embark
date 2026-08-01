import SwiftUI

class CustomNSTextField: NSTextField {
  override func becomeFirstResponder() -> Bool {
    let result = super.becomeFirstResponder()
    if result, let textView = currentEditor() as? NSTextView {
      textView.isAutomaticQuoteSubstitutionEnabled = false
      textView.isAutomaticDashSubstitutionEnabled = false
      textView.isAutomaticTextReplacementEnabled = false
      textView.isAutomaticSpellingCorrectionEnabled = false
      textView.isAutomaticLinkDetectionEnabled = false
      textView.isAutomaticDataDetectionEnabled = false
      textView.isAutomaticTextCompletionEnabled = false
      textView.isContinuousSpellCheckingEnabled = false
      textView.isGrammarCheckingEnabled = false
      textView.isRichText = false
      textView.usesRuler = false
      textView.usesInspectorBar = false
      textView.smartInsertDeleteEnabled = false
      textView.insertionPointColor = .clear
      textView.drawsBackground = false
      textView.backgroundColor = .clear
      textView.textColor = .clear
    }
    return result
  }
  override func complete(_ sender: Any?) {}
}
