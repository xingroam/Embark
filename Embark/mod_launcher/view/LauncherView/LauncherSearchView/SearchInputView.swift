import SwiftUI

struct SearchInputView: View {
  @Binding var text: String
  @Binding var isSearchFocused: Bool
  let onUpArrow: () -> Void
  let onDownArrow: () -> Void
  let onLeftArrow: () -> Void
  let onRightArrow: () -> Void
  let onTab: () -> Void
  let onSubmit: () -> Void
  let fontSize: CGFloat
  let theme: LauncherTheme
  let height: CGFloat
  let opacityAdd: Double
  let cornerRadius: CGFloat
  var showBorder: Bool = false
  @State private var showCursor: Bool = false
  private let cursorTimer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()

  var body: some View {
    HStack(spacing: 2) {
      Image(systemName: "magnifyingglass")
        .foregroundColor(theme.panelTextColor.opacity(0.8))
        .font(.system(size: fontSize - 2, weight: .medium))
      ZStack(alignment: .leading) {
        HStack(spacing: 0) {
          Text(text.isEmpty ? " " : text)
            .font(.system(size: fontSize, weight: .medium))
            .foregroundColor(theme.panelTextColor)
            .lineLimit(1)
            .opacity(text.isEmpty ? 0 : 1)
          if isSearchFocused {
            Rectangle()
              .fill(theme.panelTextColor)
              .frame(width: 2, height: fontSize)
              .opacity(showCursor ? 1 : 0)
          }
          Spacer(minLength: 0)
        }
        SharedInvisibleTextField(
          text: $text,
          isFocused: $isSearchFocused,
          onUpArrow: onUpArrow,
          onDownArrow: onDownArrow,
          onLeftArrow: onLeftArrow,
          onRightArrow: onRightArrow,
          onTab: onTab,
          onSubmit: onSubmit
        )
        .opacity(0.05)
      }
    }
    .contentShape(Rectangle())
    .padding(.horizontal, 10)
    .frame(height: height)
    .font(.system(size: fontSize))
    .foregroundColor(theme.panelTextColor)
    .background(
      RoundedRectangle(cornerRadius: cornerRadius)
        .fill(theme.panelBackgroundColor.opacity(theme.panelBackgroundOpacity + opacityAdd))
    )
    .overlay(
      showBorder ?
        RoundedRectangle(cornerRadius: cornerRadius)
          .stroke(theme.panelBackgroundColor.opacity(theme.panelBackgroundOpacity + opacityAdd), lineWidth: 1) : nil
    )
    .onReceive(cursorTimer) { _ in
      if isSearchFocused {
        showCursor.toggle()
      } else {
        showCursor = false
      }
    }
    .onChange(of: isSearchFocused) { focused in
      if focused { showCursor = true }
    }
    .onAppear {
      if isSearchFocused { showCursor = true }
    }
    .onTapGesture {
      isSearchFocused = true
    }
  }
}
