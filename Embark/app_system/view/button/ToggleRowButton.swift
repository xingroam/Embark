import SwiftUI

struct ToggleRowButton: View {
  let text: String
  let fz: CGFloat
  @Binding var isEnabled: Bool
  let onToggle: (Bool) -> Void
  @State private var isHovered = false

  var body: some View {
    HStack(spacing: 10) {
      Text(text)
        .font(.system(size: fz))
        .foregroundColor(isEnabled ? Color.accentColor : .secondary)
        .frame(maxWidth: .infinity, alignment: .leading)
      Toggle("", isOn: $isEnabled)
        .toggleStyle(SquareToggleStyle())
        .labelsHidden()
        .offset(x: 10)
        .onChange(of: isEnabled) { newValue in
          onToggle(newValue)
        }
    }
    .padding(.horizontal, 12)
    .padding(.vertical, 8)
    .background(
      RoundedRectangle(cornerRadius: 6)
        .fill(isEnabled ? (isHovered ? Color.accentColor.opacity(0.2) : Color.accentColor.opacity(0.1)) : (isHovered ? Color.secondary.opacity(0.2) : Color.secondary.opacity(0.1)))
    )
    .overlay(
      RoundedRectangle(cornerRadius: 6)
        .stroke(isEnabled ? (isHovered ? Color.accentColor.opacity(0.6) : Color.accentColor.opacity(0.4)) : (isHovered ? Color.secondary.opacity(0.6) : Color.secondary.opacity(0.4)), lineWidth: 1)
    )
    .contentShape(Rectangle())
    .onHover { hovering in
      isHovered = hovering
    }
    .onTapGesture {
      isEnabled.toggle()
      onToggle(isEnabled)
    }
  }
}
