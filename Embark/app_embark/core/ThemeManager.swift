import SwiftUI

class ThemeManager {
  static let s = ThemeManager()

  private init() {
    NotificationCenter.default.addObserver(self, selector: #selector(themeChanged), name: NSNotification.Name("AppThemeChanged"), object: nil)
  }

  deinit {
    NotificationCenter.default.removeObserver(self)
  }

  @objc private func themeChanged() {
    applyTheme()
    ensureStatusBarFollowsSystemTheme()
  }

  func applyTheme() {
    let theme = EmbarkConfig.appTheme
    switch theme {
    case .system:
      NSApp.appearance = nil
    case .light:
      NSApp.appearance = NSAppearance(named: .aqua)
    case .dark:
      NSApp.appearance = NSAppearance(named: .darkAqua)
    }
    for window in NSApp.windows {
      if window.className != "NSStatusBarWindow" && !(window is NSPanel && window.level == .statusBar) {
        window.appearance = NSApp.appearance
        window.contentView?.needsDisplay = true
      }
    }
  }

  func getCurrentColorScheme() -> ColorScheme? {
    return EmbarkConfig.appTheme.colorScheme
  }

  private func ensureStatusBarFollowsSystemTheme() {
    for window in NSApp.windows {
      if window.className == "NSStatusBarWindow" || (window is NSPanel && window.level == .statusBar) {
        window.appearance = nil
        if let statusItem = window.contentView?.subviews.first as? NSButton {
          statusItem.appearance = nil
        }
      }
    }
  }
}
