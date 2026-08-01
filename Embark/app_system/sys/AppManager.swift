import Foundation
import AppKit

class AppManager {
  static func Restart(delay: TimeInterval = 0.3) {
    let process = Process()
    process.launchPath = "/usr/bin/open"
    process.arguments = ["-n", "-a", Bundle.main.bundlePath]
    do {
      try process.run()
      DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
        NSApp.terminate(nil)
      }
    } catch {
      NSApp.terminate(nil)
    }
  }

  static func Terminate() {
    NSApp.terminate(nil)
  }
}
