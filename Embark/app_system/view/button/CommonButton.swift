import SwiftUI

struct CommonButton: View {
  let title: String
  let style: ButtonStyle
  let size: ButtonSize
  let isDisabled: Bool
  let action: () -> Void

  init(title: String, style: ButtonStyle = .primary, size: ButtonSize = .normal, isDisabled: Bool = false, action: @escaping () -> Void) {
    self.title = title
    self.style = style
    self.size = size
    self.isDisabled = isDisabled
    self.action = action
  }

  var body: some View {
    Button(action: action) {
      Text(title)
        .font(.system(size: size.fontSize, weight: .medium))
        .foregroundColor(isDisabled ? .secondary : style.foregroundColor)
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .background(
          RoundedRectangle(cornerRadius: 100)
            .fill(isDisabled ? Color.secondary.opacity(0.1) : style.backgroundColor)
        )
        .overlay(
          RoundedRectangle(cornerRadius: 100)
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
