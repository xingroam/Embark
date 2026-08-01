import SwiftUI

struct ShortcutButtonLabel: View {
  let text: String
  let selected: Bool
  let color: Color
  let fz: CGFloat

  var body: some View {
    Text(text)
      .font(.system(size: fz, weight: .medium))
      .padding(.horizontal, 8)
      .padding(.vertical, 4)
      .background(selected ? color.opacity(0.9) : Color.secondary.opacity(0.1))
      .foregroundColor(selected ? .white : .primary)
      .cornerRadius(5)
  }
}
