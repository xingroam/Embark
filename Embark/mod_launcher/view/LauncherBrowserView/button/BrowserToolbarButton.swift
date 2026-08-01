import SwiftUI

struct BrowserToolbarButton: View {
  let systemName: String
  var isActive: Bool = false
  var pressedColor: Color? = nil
  var iconColor: Color? = nil
  @ObservedObject var theme: LauncherThemeManager
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      Image(systemName: systemName)
        .font(.system(size: 12))
        .frame(width: 16, height: 16)
    }
    .buttonStyle(BrowserIconButtonStyle(theme: theme, isActive: isActive, pressedColor: pressedColor, iconColor: iconColor))
  }
}

struct BrowserIconButtonStyle: SwiftUI.ButtonStyle {
  @ObservedObject var theme: LauncherThemeManager
  var isActive: Bool = false
  var pressedColor: Color? = nil
  var iconColor: Color? = nil

  func makeBody(configuration: SwiftUI.ButtonStyleConfiguration) -> some View {
    configuration.label
      .modifier(BrowserIconStyleModifier(theme: theme, isActive: isActive, isPressed: configuration.isPressed, pressedColor: pressedColor, iconColor: iconColor))
  }
}

struct BrowserIconStyleModifier: ViewModifier {
  @ObservedObject var theme: LauncherThemeManager
  var isActive: Bool
  var isPressed: Bool
  var pressedColor: Color? = nil
  var iconColor: Color? = nil
  @Environment(\.isEnabled) private var isEnabled

  func body(content: Content) -> some View {
    content
      .foregroundColor(
        !isEnabled ? theme.currentTheme.panelTextColor.opacity(0.3) :
        (isActive || isPressed) ? .white : iconColor ?? theme.currentTheme.panelTextColor
      )
      .padding(5)
      .background(
        !isEnabled ? Color.black.opacity(0.05) :
        (isActive || isPressed) ? (pressedColor?.opacity(0.8) ?? Color.accentColor.opacity(0.8)) : Color.black.opacity(0.1)
      )
      .clipShape(Circle())
  }
}
