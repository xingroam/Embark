import Foundation
import ServiceManagement

class StartupManager {
  static let s = StartupManager()

  private init() {}

  private var legacyPlistPath: String {
    let launchAgentDir = "~/Library/LaunchAgents"
    let expandedDir = (launchAgentDir as NSString).expandingTildeInPath
    let plistName = "\(EmbarkInfo.bundleIdentifier).plist"
    return (expandedDir as NSString).appendingPathComponent(plistName)
  }

  func migrateIfNeeded() {
    if FileManager.default.fileExists(atPath: legacyPlistPath) {
      removeLegacyPlist()
      do {
        try SMAppService.mainApp.register()
      } catch {
        print("Failed to migrate startup item: \(error)")
      }
    }
  }

  func isAppInStartupItems() -> Bool {
    return SMAppService.mainApp.status == .enabled
  }

  func addAppToStartupItems() {
    removeLegacyPlist()
    do {
      try SMAppService.mainApp.register()
    } catch {
      print("Failed to add to startup items: \(error)")
    }
  }

  func removeAppFromStartupItems() {
    removeLegacyPlist()
    do {
      try SMAppService.mainApp.unregister()
    } catch {
      print("Failed to remove from startup items: \(error)")
    }
  }

  func toggleStartupItem() {
    if isAppInStartupItems() {
      removeAppFromStartupItems()
    } else {
      addAppToStartupItems()
    }
  }

  private func removeLegacyPlist() {
    let fileManager = FileManager.default
    guard fileManager.fileExists(atPath: legacyPlistPath) else { return }
    do {
      let unloadTask = Process()
      unloadTask.executableURL = URL(fileURLWithPath: "/bin/launchctl")
      unloadTask.arguments = ["unload", legacyPlistPath]
      try unloadTask.run()
      unloadTask.waitUntilExit()
      try fileManager.removeItem(atPath: legacyPlistPath)
    } catch {}
  }
}
