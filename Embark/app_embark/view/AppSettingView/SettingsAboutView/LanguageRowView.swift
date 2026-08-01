import SwiftUI

struct LanguageRowView: View {
  let language: LanguageOption
  let isSelected: Bool
  let onTap: () -> Void

  var body: some View {
    Button(action: onTap) {
      HStack(spacing: 10) {
        ZStack {
          Circle()
            .fill(isSelected ? Color.accentColor : Color.clear)
            .frame(width: 14, height: 14)
          if isSelected {
            Image(systemName: "checkmark")
              .foregroundColor(.primary)
              .font(.system(size: 8, weight: .bold))
          } else {
            Text(String(language.name.prefix(1)))
              .foregroundColor(.secondary)
              .font(.system(size: 10, weight: .bold))
          }
        }
        VStack(alignment: .leading, spacing: 2) {
          Text(language.name)
            .foregroundColor(.primary)
            .font(.system(size: 12))
        }
        Spacer()
      }
      .padding(.horizontal, 10)
      .padding(.vertical, 10)
      .background(isSelected ? Color.accentColor.opacity(0.2) : Color.clear)
      .contentShape(Rectangle())
    }
    .buttonStyle(PlainButtonStyle())
    if language.code != LanguageManager.s.supportedLanguages.last?.code {
      Divider()
    }
  }
}
