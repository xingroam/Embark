import SwiftUI

struct ToastView: View {
  let message: String
  let icon: Image?
  weak var panel: NSPanel?

  var body: some View {
    HStack(spacing: 12) {
      if let icon = icon {
        icon
          .renderingMode(.template)
          .resizable()
          .scaledToFit()
          .frame(width: 16, height: 16)
          .foregroundColor(.primary)
      }
      Text(message)
        .frame(maxWidth: .infinity, alignment: .leading)
        .multilineTextAlignment(.leading)
        .lineLimit(nil)
    }
    .onTapGesture {
      guard let panel = panel else { return }
      NSAnimationContext.runAnimationGroup({ context in
        context.duration = 0.3
        context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        panel.animator().alphaValue = 0
      }, completionHandler: {
        panel.orderOut(nil)
      })
    }
    .padding(.horizontal, 20)
    .padding(.vertical, 10)
    .background(.ultraThickMaterial)
    .cornerRadius(20)
    .overlay(
      RoundedRectangle(cornerRadius: 20)
        .stroke(Color.primary.opacity(0.25), lineWidth: 1.5)
    )
  }
}
