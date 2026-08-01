import SwiftUI

class AnimationWindow {
  static let s = AnimationWindow()

  private init() {}

  func Create<T: View>(v: T, styleMask: NSWindow.StyleMask = [.borderless], level: NSWindow.Level = .normal, backgroundColor: NSColor = NSColor.clear, title: String = "") -> NSWindow {
    let w = BorderlessKeyWindow(contentViewController: NSHostingController(rootView: v))
    w.backgroundColor = backgroundColor
    w.styleMask = styleMask
    w.level = level
    w.hasShadow = true
    w.isReleasedWhenClosed = false
    w.ignoresMouseEvents = false
    w.collectionBehavior = [.moveToActiveSpace]
    w.isMovableByWindowBackground = false
    w.animationBehavior = .default
    if !title.isEmpty {
      w.title = title
    }
    return w
  }

  func Show(w: NSWindow, animation: Bool = true, duration: TimeInterval = SystemInfo.winShowAnimation, completion: @escaping () -> Void = {}) {
    DispatchQueue.main.async {
      let postAnimationActions = {
        w.makeKey()
        completion()
      }
      if animation && duration != 0 {
        w.alphaValue = 0.3
        w.orderFront(nil)
        NSAnimationContext.runAnimationGroup({ c in
          c.duration = duration
          c.timingFunction = CAMediaTimingFunction(name: .easeIn)
          c.allowsImplicitAnimation = true
          w.animator().alphaValue = 1
        }) {
          w.orderFront(nil)
          postAnimationActions()
        }
      } else {
        w.alphaValue = 1
        w.orderFront(nil)
        postAnimationActions()
      }
    }
  }

  func Hide(w: NSWindow, animation: Bool = true, duration: TimeInterval = SystemInfo.winHideAnimation, completion: @escaping () -> Void = {}) {
    DispatchQueue.main.async {
      let postAnimationActions = {
        w.resignKey()
        completion()
      }
      if animation && duration != 0 {
        NSAnimationContext.runAnimationGroup({ c in
          c.duration = duration
          c.timingFunction = CAMediaTimingFunction(name: .easeOut)
          c.allowsImplicitAnimation = true
          w.animator().alphaValue = 0.3
        }) {
          w.orderOut(nil)
          postAnimationActions()
        }
      } else {
        w.orderOut(nil)
        postAnimationActions()
      }
    }
  }
}
