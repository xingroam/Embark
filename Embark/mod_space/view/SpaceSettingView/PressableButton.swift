import SwiftUI

struct PressableButton<Content: View>: View {
  let action: () -> Void
  let content: () -> Content
  @State private var isPressed = false

  init(action: @escaping () -> Void, @ViewBuilder content: @escaping () -> Content) {
    self.action = action
    self.content = content
  }

  var body: some View {
    content()
      .opacity(isPressed ? 0.5 : 1.0)
      .onTapGesture {
        action()
      }
      .simultaneousGesture(
        DragGesture(minimumDistance: 0)
          .onChanged { _ in isPressed = true }
          .onEnded { _ in isPressed = false }
      )
  }
}
