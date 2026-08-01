import SwiftUI

class Space {
  static let s = Space()
  private var isRunning: Bool = false

  func Boot() {
    if UserDefaults.standard.object(forKey: SpaceConfig.spaceKey) == nil {
      SpaceConfig.space = SpaceDefine.space
    }
    if UserDefaults.standard.object(forKey: SpaceConfig.spaceShortcutKeyKey) == nil {
      SpaceConfig.spaceShortcutKey = SpaceDefine.spaceShortcutKey
    }
    if UserDefaults.standard.object(forKey: SpaceConfig.spaceShortcutFlagsKey) == nil {
      SpaceConfig.spaceShortcutFlags = SpaceDefine.spaceShortcutFlags
    }
    if UserDefaults.standard.object(forKey: SpaceConfig.spaceRestoreModeKey) == nil {
      SpaceConfig.spaceRestoreMode = SpaceDefine.spaceRestoreMode
    }
    if UserDefaults.standard.object(forKey: SpaceConfig.spaceSkipMinimizedKey) == nil {
      SpaceConfig.spaceSkipMinimized = SpaceDefine.spaceSkipMinimized
    }
    NotificationCenter.default.addObserver(forName: NSNotification.Name("SpaceConfigChanged"), object: nil, queue: .main) { [weak self] _ in
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
    if SpaceConfig.space {
      if !isRunning {
        isRunning = true
        SpaceMonitor.s.Start()
        return true
      }
    }
    return false
  }

  func Stop(end: Bool = false) -> Bool {
    if !SpaceConfig.space || end {
      if isRunning {
        isRunning = false
        SpaceMonitor.s.Stop()
        return true
      }
    }
    return false
  }
}
