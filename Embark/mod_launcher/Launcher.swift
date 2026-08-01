import SwiftUI

class Launcher {
  static let s = Launcher()
  private var isRunning: Bool = false

  func Boot() {
    if UserDefaults.standard.object(forKey: LauncherConfig.launcherKey) == nil {
      LauncherConfig.launcher = LauncherDefine.launcher
    }
    if UserDefaults.standard.object(forKey: LauncherConfig.launcherTextSizeKey) == nil {
      LauncherConfig.launcherTextSize = LauncherDefine.launcherTextSize
    }
    if UserDefaults.standard.object(forKey: LauncherConfig.launcherTabKeyKey) == nil {
      LauncherConfig.launcherTabKey = LauncherDefine.launcherTabKey
    }
    if UserDefaults.standard.object(forKey: LauncherConfig.launcherSearchScopeKey) == nil {
      LauncherConfig.launcherSearchScope = LauncherDefine.launcherSearchScope
    }

    // Background
    if UserDefaults.standard.object(forKey: LauncherConfig.launcherBackgroundColorKey) == nil {
      LauncherConfig.launcherBackgroundColor = LauncherDefine.launcherBackgroundColor
    }
    if UserDefaults.standard.double(forKey: LauncherConfig.launcherBackgroundColorOpacityKey) == 0.0 {
      LauncherConfig.launcherBackgroundColorOpacity = LauncherDefine.launcherBackgroundColorOpacity
    }
    if UserDefaults.standard.double(forKey: LauncherConfig.launcherBackgroundImageOpacityKey) == 0.0 {
      LauncherConfig.launcherBackgroundImageOpacity = LauncherDefine.launcherBackgroundImageOpacity
    }
    if UserDefaults.standard.double(forKey: LauncherConfig.launcherBackgroundImageBlurKey) == 0.0 {
      LauncherConfig.launcherBackgroundImageBlur = LauncherDefine.launcherBackgroundImageBlur
    }
    if UserDefaults.standard.double(forKey: LauncherConfig.launcherBackgroundBlurKey) == 0.0 {
      LauncherConfig.launcherBackgroundBlur = LauncherDefine.launcherBackgroundBlur
    }

    // Link
    if UserDefaults.standard.object(forKey: LauncherConfig.launcherLinkTextColorKey) == nil {
      LauncherConfig.launcherLinkTextColor = LauncherDefine.launcherLinkTextColor
    }
    if UserDefaults.standard.object(forKey: LauncherConfig.launcherLinkBackgroundColorKey) == nil {
      LauncherConfig.launcherLinkBackgroundColor = LauncherDefine.launcherLinkBackgroundColor
    }
    if UserDefaults.standard.double(forKey: LauncherConfig.launcherLinkOpacityKey) == 0.0 {
      LauncherConfig.launcherLinkOpacity = LauncherDefine.launcherLinkOpacity
    }
    if UserDefaults.standard.double(forKey: LauncherConfig.launcherLinkIconSizeKey) == 0.0 {
      LauncherConfig.launcherLinkIconSize = LauncherDefine.launcherLinkIconSize
    }
    if UserDefaults.standard.object(forKey: LauncherConfig.launcherLinkThumbnailsKey) == nil {
      LauncherConfig.launcherLinkThumbnails = LauncherDefine.launcherLinkThumbnails
    }
    if UserDefaults.standard.object(forKey: LauncherConfig.launcherLinkMultiLineKey) == nil {
      LauncherConfig.launcherLinkMultiLine = LauncherDefine.launcherLinkMultiLine
    }

    // Panel
    if UserDefaults.standard.object(forKey: LauncherConfig.launcherPanelTextColorKey) == nil {
      LauncherConfig.launcherPanelTextColor = LauncherDefine.launcherPanelTextColor
    }
    if UserDefaults.standard.object(forKey: LauncherConfig.launcherPanelBackgroundColorKey) == nil {
      LauncherConfig.launcherPanelBackgroundColor = LauncherDefine.launcherPanelBackgroundColor
    }
    if UserDefaults.standard.double(forKey: LauncherConfig.launcherPanelOpacityKey) == 0.0 {
      LauncherConfig.launcherPanelOpacity = LauncherDefine.launcherPanelOpacity
    }
    if UserDefaults.standard.double(forKey: LauncherConfig.launcherPanelWidthKey) == 0.0 {
      LauncherConfig.launcherPanelWidth = LauncherDefine.launcherPanelWidth
    }
    if UserDefaults.standard.object(forKey: LauncherConfig.launcherPanelStretchKey) == nil {
      LauncherConfig.launcherPanelStretch = LauncherDefine.launcherPanelStretch
    }
    if UserDefaults.standard.object(forKey: LauncherConfig.launcherPanelTextBoldKey) == nil {
      LauncherConfig.launcherPanelTextBold = LauncherDefine.launcherPanelTextBold
    }

    // Auto
    if UserDefaults.standard.object(forKey: LauncherConfig.launcherAutoLinkTextColorKey) == nil {
      LauncherConfig.launcherAutoLinkTextColor = LauncherDefine.launcherAutoLinkTextColor
    }
    if UserDefaults.standard.object(forKey: LauncherConfig.launcherAutoLinkBackgroundColorKey) == nil {
      LauncherConfig.launcherAutoLinkBackgroundColor = LauncherDefine.launcherAutoLinkBackgroundColor
    }
    if UserDefaults.standard.object(forKey: LauncherConfig.launcherAutoPanelTextColorKey) == nil {
      LauncherConfig.launcherAutoPanelTextColor = LauncherDefine.launcherAutoPanelTextColor
    }
    if UserDefaults.standard.object(forKey: LauncherConfig.launcherAutoPanelBackgroundColorKey) == nil {
      LauncherConfig.launcherAutoPanelBackgroundColor = LauncherDefine.launcherAutoPanelBackgroundColor
    }

    // Proxy
    if UserDefaults.standard.object(forKey: LauncherConfig.launcherProxyTypeKey) == nil {
      LauncherConfig.launcherProxyType = LauncherDefine.launcherProxyType
    }

    _ = LauncherThemeManager.s
    NotificationCenter.default.addObserver(forName: NSNotification.Name("LinkShortcutsChanged"), object: nil, queue: .main) { [weak self] _ in
      guard let self = self else { return }
      if isRunning {
        LauncherMonitor.s.Start()
      }
    }
    NotificationCenter.default.addObserver(forName: NSNotification.Name("LauncherConfigChanged"), object: nil, queue: .main) { [weak self] _ in
      guard let self = self else { return }
      if Start() {
        return
      }
      if Stop() {
        return
      }
    }
    _ = Start()
  }

  func Start() -> Bool {
    if LauncherConfig.launcher {
      if !isRunning {
        isRunning = true
        DataManager.s.updateMainLinks {
          DataManager.s.updateOtherLinks()
        }
        LauncherMonitor.s.Start()
        return true
      }
    }
    return false
  }

  func Stop() -> Bool {
    if !LauncherConfig.launcher {
      if isRunning {
        isRunning = false
        LauncherMonitor.s.Stop()
        LauncherWin.s.Close()
        DataManager.s.Clean()
        return true
      }
    }
    return false
  }

  func ResetToFree(_ msg: Bool = true) {
    if ImageBackground.imageExists() {
      try? ImageBackground.removeImage()
    }
    if LauncherConfig.launcherBackgroundBlur == LauncherFree.launcherBackgroundBlur {
      return
    }
    LauncherConfig.launcherBackgroundBlur = LauncherFree.launcherBackgroundBlur
    if msg {
      NotificationCenter.default.post(name: NSNotification.Name("LauncherThemeChanged"), object: nil)
    }
  }
}
