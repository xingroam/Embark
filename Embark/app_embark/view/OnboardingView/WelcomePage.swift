import SwiftUI

struct WelcomePage: View {
  let onNext: () -> Void
  private let fz: CGFloat = 12
  @State private var isAnimating = false
  @State private var rotationAngle: Double = 0

  var body: some View {
    VStack(spacing: 0) {
      ZStack {
        Circle()
          .fill(
            AngularGradient(
              gradient: Gradient(colors: [
                Color.accentColor.opacity(0.4),
                Color.accentColor.opacity(0.2),
                Color.purple.opacity(0.3),
                Color.accentColor.opacity(0.2),
                Color.accentColor.opacity(0.4)
              ]),
              center: .center,
              startAngle: .degrees(rotationAngle),
              endAngle: .degrees(rotationAngle + 360)
            )
          )
          .frame(width: 220, height: 220)
          .blur(radius: 50)
        if let appIcon = NSImage(named: NSImage.applicationIconName) {
          Image(nsImage: appIcon)
            .resizable()
            .interpolation(.high)
            .frame(width: 160, height: 160)
        }
      }
      .onAppear {
        withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
          isAnimating = true
        }
        withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
          rotationAngle = 360
        }
      }
      Spacer().frame(height: 10)
      Text(String(format: LanguageManager.s.localizedString("embark.onboarding.welcome"), EmbarkInfo.name))
        .font(.system(size: fz + 22, weight: .semibold))
        .multilineTextAlignment(.center)
        .foregroundColor(.primary)
      Spacer().frame(height: 100)
      Button(action: onNext) {
        HStack(spacing: 5) {
          Text(LanguageManager.s.localizedString("embark.onboarding.start"))
            .font(.system(size: fz + 6, weight: .semibold))
        }
        .padding(.vertical, 5)
        .padding(.horizontal, 20)
      }
      .buttonStyle(.borderedProminent)
      .controlSize(.large)
      .keyboardShortcut(.return, modifiers: [])
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
}
