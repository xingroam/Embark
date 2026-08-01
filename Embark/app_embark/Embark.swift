import SwiftUI
import Security

class Embark {
  static let s = Embark()
  private var statusBar: StatusBarView?
  private var secondTimer: Timer?
  private var dailyTimer: Timer?
  private var canUse = false

  init() {}

  deinit {
    secondTimer?.invalidate()
    dailyTimer?.invalidate()
  }

  func Boot() {
    NSApp.setActivationPolicy(.accessory)
    StartupManager.s.migrateIfNeeded()
    let needsInstall = InstallManager.s.needsInstall()
    DatabaseManager.s.boot()
    if needsInstall {
      InstallManager.s.installDefaultData()
    }
    DispatchQueue.main.async { [weak self] in
      guard let self = self else { return }
      if EmbarkConfig.appFirstRun {
        OnboardingWin.s.Show(showWelcome: true)
      } else if !PermissionManager.s.isAccessibilityGranted() {
        OnboardingWin.s.Show(showWelcome: false)
      } else {
        StartApp()
      }
    }
  }

  func StartApp() {
    canUse = true
    ThemeManager.s.applyTheme()
    IconManager.s.refreshCurrentAppIcon()
    multiScreenSupport()
    statusBar = StatusBarView()
    System.s.Boot()
    EmbarkMonitor.s.Boot()
    Launcher.s.Boot()
    SwiftMod.s.Boot()
    Magnet.s.Boot()
    Space.s.Boot()
    Focus.s.Boot()
    Slide.s.Boot()
    Switcher.s.Boot()
    secondTask()
    dailyTask()
    Debug.info("\(EmbarkInfo.name) \(EmbarkInfo.version)")
  }

  func isAppStarted() -> Bool {
    return canUse
  }

  func End() {
    NSWorkspace.shared.notificationCenter.removeObserver(self)
    secondTimer?.invalidate()
    dailyTimer?.invalidate()
    secondTimer = nil
    dailyTimer = nil
    InputEventManager.s.unregisterAllListeners()
    EmbarkMonitor.s.Stop()
    _ = Launcher.s.Stop()
    SwiftMod.s.Stop()
    _ = Magnet.s.Stop(end: true)
    _ = Space.s.Stop(end: true)
    _ = Focus.s.Stop(end: true)
    _ = Slide.s.Stop(end: true)
    _ = Switcher.s.Stop(end: true)
  }

  func AppClick(flag: Bool) -> Bool {
    if !canUse {
      _ = PermissionManager.s.CheckAccessibilityPermission()
      return false
    }
    if LauncherBrowserWin.s.IsAnyShow() {
      return true
    }
    if !flag {
      showLauncherOrSpace()
    } else if !isAnySettingWindowShow() {
      if EmbarkConfig.appFirstRun {
        OnboardingWin.s.Show(showWelcome: true)
      } else {
        showLauncherOrSpace()
      }
    }
    return true
  }

  private func isAnySettingWindowShow() -> Bool {
    return AppSettingWin.s.IsShow() ||
           LauncherSettingWin.s.IsShow() ||
           SwiftSettingWin.s.IsShow() ||
           MagnetSettingWin.s.IsShow() ||
           FocusSettingWin.s.IsShow() ||
           SlideSettingWin.s.IsShow() ||
           SwitcherSettingWin.s.IsShow() ||
           SpaceSettingWin.s.IsShow()
  }

  private func showLauncherOrSpace() {
    if LauncherConfig.launcher {
      LauncherWin.s.ShowOrHide(mode: .launcher, debounce: true)
    } else if SpaceConfig.space {
      LauncherWin.s.ShowOrHide(mode: .space, debounce: true)
    }
  }

  func ResetDefault() {
    let userDefaults = UserDefaults.standard
    let dictionary = userDefaults.dictionaryRepresentation()
    for (key, _) in dictionary {
      userDefaults.removeObject(forKey: key)
    }
    userDefaults.synchronize()
  }

  private func multiScreenSupport() {
    NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(self.activeSpaceDidChange), name: NSWorkspace.activeSpaceDidChangeNotification, object: nil)
  }

  private func secondTask() {
    secondTimer?.invalidate()
    secondTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
      if !PermissionManager.s.isAccessibilityGranted() {
        NSApp.terminate(nil)
      } else {
        _ = InputEventManager.s.checkHealth()
      }
    }
  }

  private func dailyTask() {
    dailyTimer?.invalidate()
    dailyTimer = Timer.scheduledTimer(withTimeInterval: 24 * 60 * 60, repeats: true) { [weak self] _ in
      guard let self = self else { return }
      oneDaily()
    }
    oneDaily()
  }

  private func oneDaily() {
    DailyTaskManager.s.Append(taskKey: EmbarkInfo.name + "OneDailyTask", interval: 24 * 60 * 60) {
      if EmbarkConfig.appAutoCheckUpdate {
        UpdateManager.s.checkForUpdates(hasUpdateShowDialog: true)
      }
    }
  }

  @objc private func activeSpaceDidChange() {
    if NSWorkspace.shared.runningApplications.first(where: { $0.isActive }) != nil {
      LauncherWin.s.DesktopChanged()
      SwitcherWin.s.DesktopChanged()
    }
  }
}
