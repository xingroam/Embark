import SwiftUI

struct LauncherTheme {
  let textSize: CGFloat
  let linkTextColor: Color
  let linkBackgroundColor: Color
  let linkBackgroundOpacity: Double
  let linkIconSize: CGFloat
  let panelTextColor: Color
  let panelBackgroundColor: Color
  let panelBackgroundOpacity: Double
  let panelWidth: CGFloat
  let panelStretch: Bool
  let panelTextBold: Bool
  let backgroundColor: Color
  let backgroundColorOpacity: Double
  let backgroundBlur: Double

  static var current: LauncherTheme {
    LauncherTheme(
      textSize: LauncherConfig.launcherTextSize,
      linkTextColor: LauncherConfig.currentLinkTextColor,
      linkBackgroundColor: LauncherConfig.currentLinkBackgroundColor,
      linkBackgroundOpacity: LauncherConfig.launcherLinkOpacity,
      linkIconSize: LauncherConfig.launcherLinkIconSize,
      panelTextColor: LauncherConfig.currentPanelTextColor,
      panelBackgroundColor: LauncherConfig.currentPanelBackgroundColor,
      panelBackgroundOpacity: LauncherConfig.getPanelOpacity(),
      panelWidth: LauncherConfig.launcherPanelWidth,
      panelStretch: LauncherConfig.launcherPanelStretch,
      panelTextBold: LauncherConfig.launcherPanelTextBold,
      backgroundColor: LauncherConfig.launcherBackgroundColor,
      backgroundColorOpacity: LauncherConfig.launcherBackgroundColorOpacity,
      backgroundBlur: LauncherConfig.launcherBackgroundBlur
    )
  }
}

struct LauncherThemeKey: EnvironmentKey {
  static let defaultValue: LauncherTheme = LauncherTheme.current
}

extension EnvironmentValues {
  var launcherTheme: LauncherTheme {
    get { self[LauncherThemeKey.self] }
    set { self[LauncherThemeKey.self] = newValue }
  }
}

class LauncherThemeManager: ObservableObject {
  static let s = LauncherThemeManager()
  @Published var currentTheme: LauncherTheme = LauncherTheme.current

  private init() {
    NotificationCenter.default.addObserver(forName: NSNotification.Name("LauncherThemeChanged"), object: nil, queue: .main) { [weak self] _ in
      guard let self = self else { return }
      updateTheme()
    }
  }

  private func updateTheme() {
    DispatchQueue.main.async { [weak self] in
      self?.currentTheme = LauncherTheme.current
    }
  }
}
