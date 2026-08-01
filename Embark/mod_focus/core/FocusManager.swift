import SwiftUI

class FocusManager: ObservableObject {
  static let s = FocusManager()

  @Published private(set) var excludedApps: [FocusExcludeApp] = []
  private var excludedBundleIds: Set<String> = []

  private init() {
    loadExcludedApps()
  }

  func loadExcludedApps() {
    let apps = DatabaseManager.s.getAllFocusExcludedApps()
    DispatchQueue.main.async { [weak self] in
      self?.excludedApps = apps
      self?.excludedBundleIds = Set(apps.filter { $0.enabled }.map { $0.bundleId.lowercased() })
    }
  }

  func addExcludedApp(title: String, bundleId: String) {
    DatabaseManager.s.addFocusExcludedApp(title: title, bundleId: bundleId)
    loadExcludedApps()
  }

  func removeExcludedApp(bundleId: String) {
    DatabaseManager.s.removeFocusExcludedApp(bundleId: bundleId)
    loadExcludedApps()
  }

  func isExcluded(bundleId: String?) -> Bool {
    guard let bundleId = bundleId else { return false }
    return excludedBundleIds.contains(bundleId.lowercased())
  }
}
