import SwiftUI

struct BrowserMenuButton: View {
  let text: String
  let action: () -> Void
  @ObservedObject var theme: LauncherThemeManager
  @State private var isHovered = false

  var body: some View {
    Button(action: action) {
      Text(text)
        .foregroundColor(theme.currentTheme.panelTextColor)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 5)
        .padding(.horizontal, 10)
        .background(
          RoundedRectangle(cornerRadius: 5)
            .fill(isHovered ? theme.currentTheme.panelTextColor.opacity(0.1) : Color.clear)
        )
        .contentShape(Rectangle())
    }
    .buttonStyle(PlainButtonStyle())
    .onHover { isHovered = $0 }
  }
}
