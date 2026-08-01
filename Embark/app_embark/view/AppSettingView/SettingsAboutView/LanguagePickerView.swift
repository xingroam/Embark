import SwiftUI

struct LanguagePickerView: View {
  @Binding var appLanguage: String
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    VStack(spacing: 0) {
      ScrollView {
        LazyVStack(spacing: 0) {
          ForEach(LanguageManager.s.supportedLanguages) { language in
            LanguageRowView(
              language: language,
              isSelected: language.code == appLanguage
            ) {
              appLanguage = language.code
            }
          }
        }
      }
    }
    .background(Color(NSColor.controlBackgroundColor))
  }
}
