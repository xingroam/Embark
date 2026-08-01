import SwiftUI

class Lock {
  static let s = Lock()
  private let lock = NSLock()

  private init() {}

  func Operation(_ operation: @escaping () -> Void) {
    defer {
      lock.unlock()
    }
    lock.lock()
    operation()
  }
}
