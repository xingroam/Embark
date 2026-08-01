import SwiftUI

struct CommonIconButton: View {
  let icon: String
  let title: String?
  let style: ButtonStyle
  let size: ButtonSize
  let isDisabled: Bool
  let action: () -> Void

  init(icon: String, title: String? = nil, style: ButtonStyle = .primary, size: ButtonSize = .medium, isDisabled: Bool = false, action: @escaping () -> Void) {
    self.icon = icon
    self.title = title
    self.style = style
    self.size = size
    self.isDisabled = isDisabled
    self.action = action
  }

  var body: some View {
    Button(action: action) {
      HStack(spacing: title != nil ? 5 : 0) {
        Image(systemName: icon)
          .font(.system(size: size.fontSize))
          .foregroundColor(isDisabled ? .secondary : style.foregroundColor)
        if let title = title {
          Text(title)
            .font(.system(size: size.fontSize, weight: .medium))
            .foregroundColor(isDisabled ? .secondary : style.foregroundColor)
        }
      }
      .padding(.horizontal, size.paddingHorizontal)
      .padding(.vertical, size.paddingVertical)
      .background(
        RoundedRectangle(cornerRadius: size.cornerRadius)
          .fill(isDisabled ? Color.secondary.opacity(0.1) : style.backgroundColor)
      )
      .overlay(
        RoundedRectangle(cornerRadius: size.cornerRadius)
          .stroke(
            isDisabled ? Color.secondary.opacity(0.2) : style.borderColor,
            lineWidth: 1
          )
      )
    }
    .buttonStyle(PlainButtonStyle())
    .disabled(isDisabled)
    .scaleEffect(isDisabled ? 0.95 : 1.0)
    .animation(.easeInOut(duration: 0.1), value: isDisabled)
  }
}
