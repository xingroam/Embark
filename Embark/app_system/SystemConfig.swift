import SwiftUI

struct SystemInfo {
  static let isDebug = Debug.isDebug()
  static let maxLogLine = 500
  static let winShowAnimation: TimeInterval = 0.06
  static let winHideAnimation: TimeInterval = 0.03
}
