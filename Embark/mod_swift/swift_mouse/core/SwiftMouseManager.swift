import SwiftUI

class SwiftMouseManager: ObservableObject {
  static let s = SwiftMouseManager()
  @Published private(set) var excludedApps: [SwiftMouseExcludeApp] = []
  private var excludedBundleIds: Set<String> = []
  private var linkGestures: [Int64: SwiftMouseGesture] = [:]
  private let lock = NSLock()

  private init() {
    loadExcludedApps()
    loadLinkGestures()
    NotificationCenter.default.addObserver(self, selector: #selector(configChanged), name: NSNotification.Name("SwiftMouseConfigChanged"), object: nil)
  }

  @objc private func configChanged() {
    loadLinkGestures()
  }

  func loadExcludedApps() {
    let apps = DatabaseManager.s.getAllSwiftMouseExcludedApps()
    lock.lock()
    self.excludedBundleIds = Set(apps.filter { $0.enabled }.map { $0.bundleId.lowercased() })
    lock.unlock()
    DispatchQueue.main.async { [weak self] in
      self?.excludedApps = apps
    }
  }

  func addExcludedApp(title: String, bundleId: String) {
    DatabaseManager.s.addSwiftMouseExcludedApp(title: title, bundleId: bundleId)
    loadExcludedApps()
  }

  func removeExcludedApp(bundleId: String) {
    DatabaseManager.s.removeSwiftMouseExcludedApp(bundleId: bundleId)
    loadExcludedApps()
  }

  func isExcluded(bundleId: String?) -> Bool {
    guard let bundleId = bundleId else { return false }
    lock.lock()
    defer { lock.unlock() }
    return excludedBundleIds.contains(bundleId.lowercased())
  }

  func loadLinkGestures() {
    let rawGestures = DatabaseManager.s.loadSwiftMouseLinks()
    var gestures: [Int64: SwiftMouseGesture] = [:]
    for (id, raw) in rawGestures {
      if let g = SwiftMouseGesture(rawValue: raw) {
        gestures[id] = g
      }
    }
    lock.lock()
    self.linkGestures = gestures
    lock.unlock()
  }

  func getLinkForGesture(_ gesture: SwiftMouseGesture) -> Int64? {
    lock.lock()
    defer { lock.unlock() }
    return linkGestures.first(where: { $0.value == gesture })?.key
  }
}
