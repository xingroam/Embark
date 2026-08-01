import SwiftUI

struct SquareToggleStyle: ToggleStyle {
  func makeBody(configuration: Configuration) -> some View {
    HStack {
      RoundedRectangle(cornerRadius: 4)
        .strokeBorder(configuration.isOn ? Color.accentColor.opacity(0.8) : Color.secondary.opacity(0.6), lineWidth: 1)
        .background(
          RoundedRectangle(cornerRadius: 2)
            .fill(configuration.isOn ? Color.accentColor : Color.clear)
            .padding(3.4)
        )
        .frame(width: 16, height: 16)
        .onTapGesture {
          configuration.isOn.toggle()
        }
      configuration.label
    }
  }
}
