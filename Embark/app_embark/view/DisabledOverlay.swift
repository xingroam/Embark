import SwiftUI

struct DisabledOverlay: View {
  let cornerRadius: CGFloat

  var body: some View {
    ZStack {
      Color.clear
        .background(.ultraThickMaterial)
        .opacity(0.6)
        .cornerRadius(cornerRadius)
    }
    .allowsHitTesting(true)
  }
}

extension View {
  @ViewBuilder
  func disabledOverlay(isDisabled: Bool, isLocked: Bool = false, cornerRadius: CGFloat = 8) -> some View {
    ZStack {
      self
        .disabled(isDisabled)
      if isDisabled && !isLocked {
        DisabledOverlay(cornerRadius: cornerRadius)
      }
    }
  }
}
