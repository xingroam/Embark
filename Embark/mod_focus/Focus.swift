import SwiftUI

class Focus {
  static let s = Focus()
  private var isRunning: Bool = false

  func Boot() {
    if UserDefaults.standard.object(forKey: FocusConfig.focusKey) == nil {
      FocusConfig.focus = FocusDefine.focus
    }
    if UserDefaults.standard.object(forKey: FocusConfig.focusShortcutKeyKey) == nil {
      FocusConfig.focusShortcutKey = FocusDefine.focusShortcutKey
    }
    if UserDefaults.standard.object(forKey: FocusConfig.focusShortcutFlagsKey) == nil {
      FocusConfig.focusShortcutFlags = FocusDefine.focusShortcutFlags
    }
    if UserDefaults.standard.object(forKey: FocusConfig.focusStyleKey) == nil {
      if #available(macOS 14, *) {
        FocusConfig.focusStyle = FocusDefine.focusStyle
      } else {
        FocusConfig.focusStyle = FocusDefine.focusStyle13
      }
    }
    if UserDefaults.standard.object(forKey: FocusConfig.focusColorKey) == nil {
      FocusConfig.focusColor = FocusDefine.focusColor
    }
    if UserDefaults.standard.object(forKey: FocusConfig.focusOpacityKey) == nil {
      FocusConfig.focusOpacity = FocusDefine.focusOpacity
    }
    if UserDefaults.standard.object(forKey: FocusConfig.focusBlurKey) == nil {
      FocusConfig.focusBlur = FocusDefine.focusBlur
    }
    if UserDefaults.standard.object(forKey: FocusConfig.focusAnimationKey) == nil {
      FocusConfig.focusAnimation = FocusDefine.focusAnimation
    }
    if UserDefaults.standard.object(forKey: FocusConfig.focusDurationKey) == nil {
      FocusConfig.focusDuration = FocusDefine.focusDuration
    }
    if UserDefaults.standard.object(forKey: FocusConfig.focusTopTransparentKey) == nil {
      FocusConfig.focusTopTransparent = FocusDefine.focusTopTransparent
    }
    if UserDefaults.standard.object(forKey: FocusConfig.focusTopTransparentDistanceKey) == nil {
      FocusConfig.focusTopTransparentDistance = FocusDefine.focusTopTransparentDistance
    }
    NotificationCenter.default.addObserver(forName: NSNotification.Name("FocusConfigChanged"), object: nil, queue: .main) { [weak self] _ in
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
    if FocusConfig.focus {
      if !isRunning {
        isRunning = true
        FocusMonitor.s.Start()
        return true
      }
    }
    return false
  }

  func Stop(end: Bool = false) -> Bool {
    if !FocusConfig.focus || end {
      if isRunning {
        isRunning = false
        FocusMonitor.s.Stop()
        return true
      }
    }
    return false
  }

  func ResetToFree(_ msg: Bool = true) {
    if FocusConfig.focusStyle == FocusFree.focusStyle &&
       FocusConfig.focusColor == FocusFree.focusColor &&
       FocusConfig.focusOpacity == FocusFree.focusOpacity &&
       FocusConfig.focusBlur == FocusFree.focusBlur &&
       FocusConfig.focusAnimation == FocusFree.focusAnimation &&
       FocusConfig.focusTopTransparent == FocusFree.focusTopTransparent {
      return
    }
    FocusConfig.focusStyle = FocusFree.focusStyle
    FocusConfig.focusColor = FocusFree.focusColor
    FocusConfig.focusOpacity = FocusFree.focusOpacity
    FocusConfig.focusBlur = FocusFree.focusBlur
    FocusConfig.focusAnimation = FocusFree.focusAnimation
    FocusConfig.focusTopTransparent = FocusFree.focusTopTransparent
    if msg {
      NotificationCenter.default.post(name: NSNotification.Name("FocusConfigChanged"), object: nil)
    }
  }
}
