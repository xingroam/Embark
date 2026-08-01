import SwiftUI

enum SelectAddButtonStyle {
  case button
  case icon
}

struct SelectAddButton: View {
  let color: Color
  let fz: CGFloat
  var style: SelectAddButtonStyle = .button
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      switch style {
      case .button:
        Image(systemName: "plus")
          .font(.system(size: fz - 1, weight: .bold))
          .foregroundColor(.primary)
          .frame(width: 28, height: 16)
          .background(color)
          .cornerRadius(5)
      case .icon:
        Image(systemName: "plus.circle.fill")
          .font(.system(size: fz + 4))
          .foregroundColor(color)
      }
    }
    .buttonStyle(PlainButtonStyle())
  }
}
