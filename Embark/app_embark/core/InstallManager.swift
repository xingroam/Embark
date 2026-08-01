import SwiftUI

class InstallManager {
  static let s = InstallManager()

  func needsInstall() -> Bool {
    let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
    let dbDir = appSupport.appendingPathComponent(EmbarkInfo.bundleIdentifier)
    let dbPath = dbDir.appendingPathComponent(EmbarkInfo.dbFile)
    return !FileManager.default.fileExists(atPath: dbPath.path)
  }

  func installDefaultData() {
    installLauncherDefaultData()
    installFocusDefaultData()
    installSwiftMouseDefaultData()
  }

  private func installLauncherDefaultData() {
    let home = NSHomeDirectory()
    createPanelsFromConfigs([
      ("system", nil, [
        "/System/Applications/System Settings.app",
        "/System/Applications/App Store.app",
        "/System/Applications/Shortcuts.app"
      ]),
      ("work", nil, [
        "/System/Applications/Notes.app",
        "/System/Applications/Mail.app",
        "/System/Applications/Messages.app",
        "/System/Applications/FaceTime.app"
      ]),
      ("entertainment", "work", [
        "/System/Applications/Music.app",
        "/System/Applications/Podcasts.app"
      ]),
      ("personal", nil, [
        "/System/Applications/Photos.app",
        "/System/Applications/Calendar.app",
        "/System/Applications/Contacts.app",
        "/System/Applications/Passwords.app"
      ]),
      ("network", "personal", [
        "/System/Applications/Stocks.app"
      ]),
      ("tools", nil, [
        "/System/Applications/Maps.app",
        "/System/Applications/Weather.app",
        "/System/Applications/Calculator.app"
      ]),
      ("folder", nil, [
        "\(home)/Desktop",
        "\(home)/Downloads"
      ])
    ])
  }

  private func installFocusDefaultData() {
    DatabaseManager.s.addFocusExcludedApp(title: "Finder", bundleId: "com.apple.finder")
  }

  private func installSwiftMouseDefaultData() {
    DatabaseManager.s.addSwiftMouseExcludedApp(title: "Finder", bundleId: "com.apple.finder", enabled: false)
  }

  private func createPanelsFromConfigs(_ configs: [(key: String, parentKey: String?, links: [String])]) {
    autoreleasepool {
      var panelIds: [String: Int64] = [:]
      for config in configs {
        let panelName = getLocalizedPanelName(config.key)
        let panelId: Int64
        if let parentKey = config.parentKey, let parentId = panelIds[parentKey] {
          panelId = DatabaseManager.s.addSubPanel(name: panelName, parentId: parentId)
        } else {
          panelId = DatabaseManager.s.addMainPanel(name: panelName)
        }
        panelIds[config.key] = panelId
        addLinksToPanel(paths: config.links, panelId: panelId, panelName: panelName)
      }
    }
    DatabaseManager.s.loadPanels()
    DatabaseManager.s.loadLinks()
  }

  private func addLinksToPanel(paths: [String], panelId: Int64, panelName: String) {
    autoreleasepool {
      var addedCount = 0
      for path in paths {
        if FileManager.default.fileExists(atPath: path) {
          if !path.hasSuffix(".app") {
            DatabaseManager.s.addFolderLink(path: path, panelId: panelId, orderIndex: addedCount)
          } else {
            DatabaseManager.s.addAppLink(path: path, panelId: panelId, orderIndex: addedCount)
          }
          addedCount += 1
        }
      }
    }
  }

  private func getLocalizedPanelName(_ key: String) -> String {
    return NSLocalizedString("launcher.install.panel.\(key)", comment: "")
  }
}
