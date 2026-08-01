import SwiftUI

struct ModeButtonLabel: View {
  let text: String
  let selected: Bool
  let color: Color
  let fz: CGFloat

  var body: some View {
    HStack(spacing: 5) {
      ZStack {
        Circle()
          .stroke(selected ? Color.white : Color.primary, lineWidth: 1)
          .frame(width: 10, height: 10)
        if selected {
          Circle()
            .fill(Color.white)
            .frame(width: 6, height: 6)
        }
      }
      Text(text)
        .font(.system(size: fz - 1, weight: .medium))
        .foregroundColor(selected ? Color.white : Color.primary)
    }
    .padding(.horizontal, 8)
    .padding(.vertical, 4)
    .background(
      Capsule()
        .fill(selected ? color.opacity(0.8) : Color.clear)
    )
    .contentShape(Capsule())
  }
}
