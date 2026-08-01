import SwiftUI

class SwiftMod {
  static let s = SwiftMod()

  func Boot() {
    SwiftKeyboard.s.Boot()
    SwiftMouse.s.Boot()
  }

  func Start() {
    _ = SwiftKeyboard.s.Start()
    _ = SwiftMouse.s.Start()
  }

  func Stop() {
    _ = SwiftKeyboard.s.Stop()
    _ = SwiftMouse.s.Stop()
  }
}
