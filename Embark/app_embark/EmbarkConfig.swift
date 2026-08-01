import SwiftUI

struct EmbarkInfo {
  static let name = { Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String ?? "App" }()
  static let version = { Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "" }()
  static let buildNumber = { Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "" }()
  static let bundleIdentifier = { Bundle.main.bundleIdentifier ?? "" }()
  static let bundleIdentifierLowercased = { Bundle.main.bundleIdentifier?.lowercased() ?? "" }()
  static let website = "https://github.com/potor-com/Embark"
  static let feedbackIssueUrl = "https://github.com/potor-com/Embark/issues/new"

  static let dbFile = "\(name).db"
  static let logFile = "\(name).log"
  static let launcherBgFile = "Launcher.bg"

  static let embarkJson = "https://potor-com.github.io/Embark/embark.json"
  static let embarkJsonHour = 24

  static var currentYear: String {
    String(Calendar.current.component(.year, from: Date()))
  }
}

struct EmbarkConfig {
  static let appFirstRunKey = "appFirstRun"
  static let appAutoCheckUpdateKey = "appAutoCheckUpdate"
  static let appThemeKey = "appTheme"
  static let appIconKey = "appIcon"
  static let appMigrationKey = "appMigration"

  static var appFirstRun: Bool {
    get {
      UserDefaults.standard.object(forKey: appFirstRunKey) as? Bool ?? true
    }
    set {
      UserDefaults.standard.set(newValue, forKey: appFirstRunKey)
    }
  }

  static var appAutoCheckUpdate: Bool {
    get {
      UserDefaults.standard.object(forKey: appAutoCheckUpdateKey) as? Bool ?? true
    }
    set {
      UserDefaults.standard.set(newValue, forKey: appAutoCheckUpdateKey)
    }
  }

  static var appTheme: AppTheme {
    get {
      if let themeString = UserDefaults.standard.string(forKey: appThemeKey), let theme = AppTheme(rawValue: themeString) {
        return theme
      }
      return .system
    }
    set {
      UserDefaults.standard.set(newValue.rawValue, forKey: appThemeKey)
      NotificationCenter.default.post(name: NSNotification.Name("AppThemeChanged"), object: nil)
    }
  }

  static var appIcon: AppIcon {
    get {
      let assetName = UserDefaults.standard.string(forKey: appIconKey) ?? AppIcon.default.assetName
      return AppIcon.all.first { $0.assetName == assetName } ?? AppIcon.default
    }
    set {
      UserDefaults.standard.set(newValue.assetName, forKey: appIconKey)
      IconManager.s.refreshCurrentAppIcon()
    }
  }

  static var appMigration: Bool {
    get {
      UserDefaults.standard.object(forKey: appMigrationKey) as? Bool ?? true
    }
    set {
      UserDefaults.standard.set(newValue, forKey: appMigrationKey)
    }
  }
}
