import Cocoa
import SwiftUI

class SpaceLoaderWin: NSObject {
  static let s = SpaceLoaderWin()
  let state = SpaceLoaderState()
  private var window: NSWindow?

  private override init() {
    super.init()
  }

  func IsWindow(_ wid: CGWindowID, title: String? = nil) -> Bool {
    var result = false
    if Thread.isMainThread {
      result = window != nil && (window?.windowNumber == Int(wid) || (title != nil && window?.title == title))
    } else {
      DispatchQueue.main.sync {
        result = window != nil && (window?.windowNumber == Int(wid) || (title != nil && window?.title == title))
      }
    }
    return result
  }

  func Show(animation: Bool = true) {
    if window == nil {
      let w = AnimationWindow.s.Create(
        v: SpaceLoaderView(state: self.state),
        styleMask: [.borderless],
        level: .floating,
        backgroundColor: .clear,
        title: EmbarkInfo.name + FeatureType.space.title + "Loader"
      )
      w.ignoresMouseEvents = true
      self.window = w
    }
    guard let w = window else { return }
    self.state.isAnimating = true
    ScreenManager.s.Center(w, winCenter: true)
    AnimationWindow.s.Show(w: w, animation: animation)
  }

  func Close(animation: Bool = true) {
    guard let w = window else { return }
    self.state.isAnimating = false
    AnimationWindow.s.Hide(w: w, animation: animation) { [weak self] in
      w.close()
      self?.window = nil
    }
  }
}
