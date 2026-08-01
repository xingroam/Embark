import SwiftUI

class Slide {
  static let s = Slide()
  private var isRunning: Bool = false

  func Boot() {
    if UserDefaults.standard.object(forKey: SlideConfig.slideKey) == nil {
      SlideConfig.slide = SlideDefine.slide
    }
    if UserDefaults.standard.object(forKey: SlideConfig.slideShortcutKeyKey) == nil {
      SlideConfig.slideShortcutKey = SlideDefine.slideShortcutKey
    }
    if UserDefaults.standard.object(forKey: SlideConfig.slideShortcutFlagsKey) == nil {
      SlideConfig.slideShortcutFlags = SlideDefine.slideShortcutFlags
    }
    if UserDefaults.standard.object(forKey: SlideConfig.slideDelayKey) == nil {
      SlideConfig.slideDelay = SlideDefine.slideDelay
    }
    if UserDefaults.standard.object(forKey: SlideConfig.slideDistanceKey) == nil {
      SlideConfig.slideDistance = SlideDefine.slideDistance
    }
    if UserDefaults.standard.object(forKey: SlideConfig.slideMarginKey) == nil {
      SlideConfig.slideMargin = SlideDefine.slideMargin
    }
    if UserDefaults.standard.object(forKey: SlideConfig.slideAutoUndockKey) == nil {
      SlideConfig.slideAutoUndock = SlideDefine.slideAutoUndock
    }
    if UserDefaults.standard.object(forKey: SlideConfig.slideTipKey) == nil {
      SlideConfig.slideTip = SlideDefine.slideTip
    }
    NotificationCenter.default.addObserver(forName: NSNotification.Name("SlideConfigChanged"), object: nil, queue: .main) { [weak self] _ in
      guard let self = self else { return }
      if Start() {
        return
      }
      if Stop() {
        return
      }
      if isRunning {
        SlideMonitor.s.UpdateConfig()
      }
    }
    _ = Start()
  }

  func Start() -> Bool {
    if SlideConfig.slide {
      if !isRunning {
        isRunning = true
        SlideMonitor.s.Start()
        return true
      }
    }
    return false
  }

  func Stop(end: Bool = false) -> Bool {
    if !SlideConfig.slide || end {
      if isRunning {
        isRunning = false
        SlideMonitor.s.Stop()
        return true
      }
    }
    return false
  }

  func ResetToFree(_ msg: Bool = true) {
    if SlideConfig.slideDelay == SlideFree.slideDelay &&
       SlideConfig.slideDistance == SlideFree.slideDistance &&
       SlideConfig.slideMargin == SlideFree.slideMargin &&
       SlideConfig.slideAutoUndock == SlideFree.slideAutoUndock &&
       SlideConfig.slideTip == SlideFree.slideTip {
      return
    }
    SlideConfig.slideDelay = SlideFree.slideDelay
    SlideConfig.slideDistance = SlideFree.slideDistance
    SlideConfig.slideMargin = SlideFree.slideMargin
    SlideConfig.slideAutoUndock = SlideFree.slideAutoUndock
    SlideConfig.slideTip = SlideFree.slideTip
    if msg {
      NotificationCenter.default.post(name: NSNotification.Name("SlideConfigChanged"), object: nil)
    }
  }
}
