import SwiftUI

struct SpaceSettingsMenuItem: View {
  let text: String
  @ObservedObject var theme: LauncherThemeManager
  let action: () -> Void
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
