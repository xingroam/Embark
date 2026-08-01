import SwiftUI

struct CustomPicker: View {
  let fz: CGFloat
  @Binding var selection: Bool

  var body: some View {
    HStack(spacing: 0) {
      Button(action: { selection = true }) {
        Text(NSLocalizedString("system.info.auto", comment: ""))
          .font(.system(size: fz - 2))
          .padding(.vertical, 2)
          .padding(.horizontal, 6)
          .background(selection ? Color.accentColor.opacity(0.8) : Color.secondary.opacity(0.1))
          .foregroundColor(selection ? .primary : .secondary)
      }
      .buttonStyle(.plain)
      Button(action: { selection = false }) {
        Text(NSLocalizedString("system.info.custom", comment: ""))
          .font(.system(size: fz - 2))
          .padding(.vertical, 2)
          .padding(.horizontal, 6)
          .background(!selection ? Color.accentColor.opacity(0.8) : Color.secondary.opacity(0.1))
          .foregroundColor(!selection ? .primary : .secondary)
      }
      .buttonStyle(.plain)
    }
    .background(Color.secondary.opacity(0.05))
    .cornerRadius(6)
  }
}
