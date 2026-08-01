import SwiftUI

class FocusOverlayWin: ObservableObject {
  static let s = FocusOverlayWin()
  @Published var isShowing = false
  private var currentOverlayWindow: NSWindow?
  private var nextOverlayWindow: NSWindow?
  private var fadingOutWindowsCount: Int = 0

  private init() {}

  func IsWindow(_ wid: CGWindowID, title: String? = nil) -> Bool {
    var result = false
    let check = { (win: NSWindow?) -> Bool in
      return win != nil && (win?.windowNumber == Int(wid) || (title != nil && win?.title == title))
    }
    if Thread.isMainThread {
      result = check(currentOverlayWindow) || check(nextOverlayWindow)
    } else {
      DispatchQueue.main.sync {
        result = check(currentOverlayWindow) || check(nextOverlayWindow)
      }
    }
    return result
  }

  func windowID() -> CGWindowID {
    guard Thread.isMainThread else {
      return DispatchQueue.main.sync { windowID() }
    }
    return nextOverlayWindow != nil ? CGWindowID(nextOverlayWindow!.windowNumber) : currentOverlayWindow != nil ? CGWindowID(currentOverlayWindow!.windowNumber) : CGWindowID(0)
  }

  func Close() {
    hideOverlay()
    if let currentWindow = currentOverlayWindow {
      currentWindow.contentViewController = nil
      currentWindow.orderOut(nil)
      currentOverlayWindow = nil
    }
    if let nextWindow = nextOverlayWindow {
      nextWindow.contentViewController = nil
      nextWindow.orderOut(nil)
      nextOverlayWindow = nil
    }
  }

  func showOverlay() {
    if !FocusConfig.focus {
      return
    }
    isShowing = true
    if let nextWindow = nextOverlayWindow {
      nextWindow.orderOut(nil)
      nextOverlayWindow = nil
    }
    if currentOverlayWindow != nil {
      createOverlayWindow(next: true)
    } else {
      createOverlayWindow(next: false)
      if let window = currentOverlayWindow {
        CATransaction.begin()
        CATransaction.setAnimationDuration(FocusConfig.focusAnimation ? FocusConfig.focusDuration : FocusInfo.timerInterval)
        CATransaction.setAnimationTimingFunction(FocusInfo.animationTimingFunction)
        window.animator().alphaValue = 1.0
        CATransaction.commit()
      }
    }
  }

  func hideOverlay() {
    isShowing = false
    if nextOverlayWindow != nil {
      transitionTwo()
    }
    if let currentWindow = currentOverlayWindow {
      CATransaction.begin()
      CATransaction.setAnimationDuration(FocusConfig.focusAnimation ? FocusConfig.focusDuration : FocusInfo.timerInterval)
      CATransaction.setAnimationTimingFunction(FocusInfo.animationTimingFunction)
      CATransaction.setCompletionBlock {
        currentWindow.orderOut(nil)
      }
      currentWindow.animator().alphaValue = 0.0
      CATransaction.commit()
      currentOverlayWindow = nil
    }
    if let nextWindow = nextOverlayWindow {
      nextWindow.orderOut(nil)
      nextOverlayWindow = nil
    }
  }

  private func transitionOne() {
    guard let nextWindow = nextOverlayWindow else { return }
    if FocusConfig.focusAnimation {
      CATransaction.begin()
      CATransaction.setAnimationDuration(FocusConfig.focusDuration)
      CATransaction.setAnimationTimingFunction(FocusInfo.animationTimingFunction)
      CATransaction.setCompletionBlock { [weak self] in
        guard let self = self else { return }
        transitionTwo(second: true)
      }
      nextWindow.animator().alphaValue = 1.0
      if let currentWindow = currentOverlayWindow {
        currentWindow.animator().alphaValue = 0.7
      }
      CATransaction.commit()
    } else {
      nextWindow.alphaValue = 1.0
      transitionTwo(second: false)
    }
  }

  private func transitionTwo(second: Bool = false) {
    if nextOverlayWindow == nil { return }
    transitionThree(second: second)
    currentOverlayWindow = nextOverlayWindow
    nextOverlayWindow = nil
  }

  private func transitionThree(second: Bool = false) {
    if let currentWindow = currentOverlayWindow {
      if FocusConfig.focusAnimation {
        fadingOutWindowsCount += 1
        let shouldSpeedUp = fadingOutWindowsCount > 1
        let duration = shouldSpeedUp ? FocusConfig.focusDuration * 2 : (second ? FocusConfig.focusDuration * 4 : FocusConfig.focusDuration)
        CATransaction.begin()
        CATransaction.setAnimationDuration(duration)
        CATransaction.setAnimationTimingFunction(FocusInfo.animationTimingFunction)
        CATransaction.setCompletionBlock { [weak self] in
          guard let self = self else { return }
          currentWindow.orderOut(nil)
          fadingOutWindowsCount -= 1
        }
        currentWindow.animator().alphaValue = 0.0
        CATransaction.commit()
      } else {
        currentWindow.orderOut(nil)
      }
      currentOverlayWindow = nil
    }
  }

  private func createOverlayWindow(next: Bool) {
    let targetScreen = ScreenManager.s.GetScreen()
    let screenFrame = targetScreen?.frame ?? NSRect.zero
    let screenSize = screenFrame.size
    let overlayView = FocusOverlayView(screenSize: screenSize)
    let hostingController = NSHostingController(rootView: overlayView)
    let win = NSWindow(contentRect: .zero, styleMask: [.borderless], backing: .buffered, defer: false)
    win.contentViewController = hostingController
    win.backgroundColor = .clear
    win.isOpaque = false
    win.ignoresMouseEvents = true
    win.collectionBehavior = [.transient]
    win.level = .normal
    if next {
      win.title = EmbarkInfo.name + "FocusOverlayNext"
    } else {
      win.title = EmbarkInfo.name + "FocusOverlayCurrent"
    }
    win.setFrame(screenFrame, display: true)
    win.alphaValue = 0.0
    win.orderFront(nil)
    if let keyWindow = NSApp.keyWindow, keyWindow != win {
      if LauncherBrowserWin.s.IsWindow(keyWindow.windowNumber) {
        win.order(.below, relativeTo: keyWindow.windowNumber)
      }
    }
    if next {
      nextOverlayWindow = win
      transitionOne()
    } else {
      currentOverlayWindow = win
    }
  }
}
