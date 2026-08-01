import SwiftUI

enum FocusStyle: String, CaseIterable, Identifiable {
  case clean = "Clean"
  case dot = "Dot"
  case grain = "Grain"

  var id: String { self.rawValue }

  var displayName: String {
    switch self {
    case .clean:
      return NSLocalizedString("focus.settings.style.clean", comment: "")
    case .dot:
      return NSLocalizedString("focus.settings.style.dot", comment: "")
    case .grain:
      return NSLocalizedString("focus.settings.style.grain", comment: "")
    }
  }
}

enum FocusColor: String, CaseIterable, Identifiable {
  case solid = "Solid"
  case staticGradient = "StaticGradient"
  case dynamicGradient = "DynamicGradient"

  var id: String { self.rawValue }

  var displayName: String {
    switch self {
    case .solid:
      return NSLocalizedString("focus.settings.color.solid", comment: "")
    case .staticGradient:
      return NSLocalizedString("focus.settings.color.staticGradient", comment: "")
    case .dynamicGradient:
      return NSLocalizedString("focus.settings.color.dynamicGradient", comment: "")
    }
  }
}

struct FocusExcludeApp: Identifiable, Equatable {
  let id = UUID()
  let title: String
  let bundleId: String
  let enabled: Bool

  static func == (lhs: FocusExcludeApp, rhs: FocusExcludeApp) -> Bool {
    return lhs.bundleId == rhs.bundleId
  }
}

struct ComputedValues {
  let menuBarHeight: CGFloat = 28
  let transitionDistancePixels: CGFloat
  let menuBarRatio: CGFloat
  let transitionEndRatio: CGFloat
  let maskGradient: Gradient

  init(screenSize: CGSize) {
    transitionDistancePixels = (FocusConfig.focusTopTransparentDistance / 100.0) * screenSize.height
    menuBarRatio = menuBarHeight / screenSize.height
    transitionEndRatio = min(1.0, (menuBarHeight + transitionDistancePixels) / screenSize.height)
    maskGradient = Gradient(stops: [
      .init(color: .clear, location: 0.0),
      .init(color: .clear, location: menuBarRatio),
      .init(color: .white, location: transitionEndRatio),
      .init(color: .white, location: 1.0)
    ])
  }
}
