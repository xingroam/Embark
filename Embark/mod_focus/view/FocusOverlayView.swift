import SwiftUI

struct FocusOverlayView: View {
  let screenSize: CGSize
  @State private var configVersion = 0

  private var computedValues: ComputedValues {
    ComputedValues(screenSize: screenSize)
  }

  var body: some View {
    let view = backgroundView
      .ignoresSafeArea()
      .id(FocusConfig.focusColor)
    maskedView(view: view, maskGradient: computedValues.maskGradient)
      .id(configVersion)
      .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("FocusConfigChanged"))) { _ in
        configVersion += 1
      }
  }

  @ViewBuilder
  private var backgroundView: some View {
    let gradientColors: [Color] = [.purple, .blue, .pink]
    let opacityRange: ClosedRange<Double> = (FocusConfig.focusOpacity - 0.1)...(FocusConfig.focusOpacity + 0.1)

    ZStack {
      if FocusConfig.focusBlur > 0 {
        BlurredBackground(blur: FocusConfig.focusBlur)
      }
      switch FocusConfig.focusColor {
      case .solid:
        Color(red: 0, green: 0, blue: 0).opacity(FocusConfig.focusOpacity)
      case .staticGradient:
        GradientBackground(
          colors: gradientColors,
          opacityRange: opacityRange,
          startPoint: .topLeading,
          endPoint: .bottomTrailing
        )
      case .dynamicGradient:
        DynamicGradient(
          colors: gradientColors,
          opacityRange: opacityRange,
          startPoint: .topLeading,
          endPoint: .bottomTrailing
        )
      }
      if #available(macOS 14.0, *) {
        if FocusConfig.focusStyle == .grain {
          Color.clear
            .background(.grainGradient(strength: 0.33))
        } else {
          if FocusConfig.focusStyle == .dot {
            DotGridBackground(size: screenSize)
          }
        }
      } else {
        if FocusConfig.focusStyle == .dot {
          DotGridBackground(size: screenSize)
        }
      }
    }
  }

  @ViewBuilder
  private func maskedView(view: some View, maskGradient: Gradient) -> some View {
    if FocusConfig.focusTopTransparent {
      view.mask(LinearGradient(gradient: maskGradient, startPoint: .top, endPoint: .bottom))
    } else {
      view
    }
  }
}
