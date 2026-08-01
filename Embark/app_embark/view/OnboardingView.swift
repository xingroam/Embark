import SwiftUI

struct OnboardingView: View {
  let showWelcome: Bool
  let onComplete: () -> Void
  @State private var currentPage: Int

  init(showWelcome: Bool, onComplete: @escaping () -> Void) {
    self.showWelcome = showWelcome
    self.onComplete = onComplete
    _currentPage = State(initialValue: showWelcome ? 0 : 1)
  }

  var body: some View {
    ZStack {
      WelcomePage {
        withAnimation(.easeInOut(duration: 0.3)) {
          currentPage = 1
        }
      }
      .opacity(currentPage == 0 ? 1 : 0)
      ConfigPage(onComplete: onComplete)
        .opacity(currentPage == 1 ? 1 : 0)
    }
    .frame(width: 800, height: 600)
    .background(SwiftBlurBackground(opacity: 1.0))
    .clipShape(RoundedRectangle(cornerRadius: 12))
    .edgesIgnoringSafeArea(.all)
  }
}
