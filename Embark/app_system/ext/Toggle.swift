import SwiftUI

extension Toggle {
  func sectionToggle() -> some View {
    self
      .toggleStyle(SwitchToggleStyle())
      .scaleEffect(0.64)
      .offset(x: 9)
  }
}
