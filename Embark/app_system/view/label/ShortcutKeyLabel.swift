import SwiftUI

struct ShortcutKeyLabel: View {
  let text: String
  let color: Color
  let ph: CGFloat
  let pv: CGFloat
  let fz: CGFloat

  var body: some View {
    Text(text)
      .font(.system(size: fz, weight: .medium))
      .foregroundColor(color)
      .padding(.horizontal, ph)
      .padding(.vertical, pv)
      .background(color.opacity(0.1))
      .cornerRadius(5)
      .overlay(
        RoundedRectangle(cornerRadius: 5)
          .stroke(color.opacity(0.2), lineWidth: 1)
      )
      .lineLimit(nil)
      .multilineTextAlignment(.center)
  }
}
