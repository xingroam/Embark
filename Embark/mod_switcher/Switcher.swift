import SwiftUI

class Switcher {
  static let s = Switcher()
  private var isRunning: Bool = false

  func Boot() {
    if UserDefaults.standard.object(forKey: SwitcherConfig.switcherKey) == nil {
      SwitcherConfig.switcher = SwitcherDefine.switcher
    }
    if UserDefaults.standard.object(forKey: SwitcherConfig.switcherShortcutKeyKey) == nil {
      SwitcherConfig.switcherShortcutKey = SwitcherDefine.switcherShortcutKey
    }
    if UserDefaults.standard.object(forKey: SwitcherConfig.switcherShortcutFlagsKey) == nil {
      SwitcherConfig.switcherShortcutFlags = SwitcherDefine.switcherShortcutFlags
    }
    if UserDefaults.standard.object(forKey: SwitcherConfig.switcherModeKey) == nil {
      SwitcherConfig.switcherMode = SwitcherDefine.switcherMode
    }
    if UserDefaults.standard.object(forKey: SwitcherConfig.switcherSizeKey) == nil {
      SwitcherConfig.switcherSize = SwitcherDefine.switcherSize
    }
    if UserDefaults.standard.object(forKey: SwitcherConfig.switcherWidthKey) == nil {
      SwitcherConfig.switcherWidth = SwitcherDefine.switcherWidth
    }
    if UserDefaults.standard.object(forKey: SwitcherConfig.switcherMaxItemsPerColumnKey) == nil {
      SwitcherConfig.switcherMaxItemsPerColumn = SwitcherDefine.switcherMaxItemsPerColumn
    }
    NotificationCenter.default.addObserver(forName: NSNotification.Name("SwitcherConfigChanged"), object: nil, queue: .main) { [weak self] _ in
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
    if SwitcherConfig.switcher {
      if !isRunning {
        isRunning = true
        SwitcherMonitor.s.Start()
        return true
      }
    }
    return false
  }

  func Stop(end: Bool = false) -> Bool {
    if !SwitcherConfig.switcher || end {
      if isRunning {
        isRunning = false
        SwitcherMonitor.s.Stop()
        return true
      }
    }
    return false
  }
}
