import SwiftUI

class RestorationContext {
  private var usedWindows: [AXUIElement] = []
  private let lock = NSLock()
  var validScreenIndices: Set<Int> = []
  var screenIndexMapping: [Int: Int] = [:]
  var sortedCurrentScreens: [NSScreen] = []

  func isUsed(_ window: AXUIElement) -> Bool {
    lock.lock()
    defer { lock.unlock() }
    for used in usedWindows {
      if CFEqual(used, window) { return true }
    }
    return false
  }

  func markUsed(_ window: AXUIElement) {
    lock.lock()
    defer { lock.unlock() }
    usedWindows.append(window)
  }
}
