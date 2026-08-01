import SwiftUI

struct SmallSwitchToggleStyle: ToggleStyle {
  func makeBody(configuration: Configuration) -> some View {
    HStack(spacing: 0) {
      configuration.label
      Spacer()
      RoundedRectangle(cornerRadius: 10)
        .fill(configuration.isOn ? Color.accentColor : Color.secondary.opacity(0.3))
        .frame(width: 30, height: 18)
        .overlay(
          Circle()
            .fill(Color.white)
            .frame(width: 14, height: 14)
            .offset(x: configuration.isOn ? 6 : -6)
            .animation(.easeInOut(duration: 0.2), value: configuration.isOn)
        )
        .onTapGesture {
          configuration.isOn.toggle()
        }
    }
  }
}
