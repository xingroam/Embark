import SwiftUI
import Lottie

struct SpaceLoaderView: View {
  @ObservedObject var state: SpaceLoaderState

  var body: some View {
    ZStack {
      LottieView {
        try await DotLottieFile.named("SpaceLoader")
      }
      .playbackMode(state.isAnimating ? .playing(.fromProgress(0, toProgress: 1, loopMode: .loop)) : .paused)
      .resizable()
      .frame(width: 180, height: 180)
    }
  }
}
