import SwiftUI

class SwitcherWin: NSObject {
  static let s = SwitcherWin()
  private var window: NSWindow?
  private var mouseListener: MouseListener?

  private override init() {
    super.init()
    NotificationCenter.default.addObserver(self, selector: #selector(handleFunctionExecuted(_:)), name: NSNotification.Name("FunctionExecuted"), object: nil)
    if SwitcherInfo.gestureStarted {
      NotificationCenter.default.addObserver(self, selector: #selector(handleGestureStarted), name: NSNotification.Name("GestureStarted"), object: nil)
    }
  }

  deinit {
    NotificationCenter.default.removeObserver(self)
    stopEventMonitoring()
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

  func IsVisible() -> Bool {
    return window != nil
  }

  func getWindow() -> NSWindow? {
    return window
  }

  func Open(atMouse: Bool = false, mouseLocation: CGPoint? = nil, animate: Bool = false, direction: String? = nil) {
    NotificationCenter.default.post(name: NSNotification.Name("FunctionExecuted"), object: nil, userInfo: ["source": FeatureType.switcher.title])
    if window != nil { return }
    let w = AnimationWindow.s.Create(
      v: SwitcherView(),
      styleMask: [.borderless],
      level: .floating,
      backgroundColor: .clear,
      title: EmbarkInfo.name + FeatureType.switcher.title
    )
    w.level = .floating
    self.window = w
    if let contentViewController = w.contentViewController {
      let size = contentViewController.view.intrinsicContentSize
      if size.width > 0, size.height > 0 {
        w.setContentSize(size)
      }
    }
    updateFrame(atMouse: atMouse, mouseLocation: mouseLocation, direction: direction)
    AnimationWindow.s.Show(w: w, animation: animate) {
      w.makeKey()
    }
    NSApp.activate(ignoringOtherApps: true)
    startEventMonitoring()
  }

  func updateFrame(atMouse: Bool = false, mouseLocation: CGPoint? = nil, direction: String? = nil) {
    guard let w = window else { return }
    if let contentViewController = w.contentViewController {
      let size = contentViewController.view.intrinsicContentSize
      if size.width > 0, size.height > 0 {
        w.setContentSize(size)
      }
    }
    if atMouse {
      var mouseLoc = NSEvent.mouseLocation
      if let loc = mouseLocation {
        let primaryScreenHeight = NSScreen.screens.first?.frame.height ?? NSScreen.main?.frame.height ?? 0
        mouseLoc = CGPoint(x: loc.x, y: primaryScreenHeight - loc.y)
      }
      let windowSize = w.frame.size
      var newOrigin = CGPoint(x: mouseLoc.x - windowSize.width / 2, y: mouseLoc.y - windowSize.height / 2)
      if let direction = direction {
        switch direction {
        case "Up":
          newOrigin.y = mouseLoc.y
        case "Down":
          newOrigin.y = mouseLoc.y - windowSize.height
        case "Left":
          newOrigin.x = mouseLoc.x - windowSize.width
        case "Right":
          newOrigin.x = mouseLoc.x
        default:
          break
        }
      }
      let targetScreen = NSScreen.screens.first(where: { $0.frame.contains(mouseLoc) }) ?? NSScreen.main
      if let screen = targetScreen {
        let screenFrame = screen.visibleFrame
        if newOrigin.x < screenFrame.minX { newOrigin.x = screenFrame.minX }
        if newOrigin.y < screenFrame.minY { newOrigin.y = screenFrame.minY }
        if newOrigin.x + windowSize.width > screenFrame.maxX { newOrigin.x = screenFrame.maxX - windowSize.width }
        if newOrigin.y + windowSize.height > screenFrame.maxY { newOrigin.y = screenFrame.maxY - windowSize.height }
      }
      w.setFrameOrigin(newOrigin)
    } else {
      ScreenManager.s.Center(w, winCenter: true)
    }
  }

  func Close(animate: Bool = false, completion: (() -> Void)? = nil) {
    guard let w = window else {
      completion?()
      return
    }
    stopEventMonitoring()
    AnimationWindow.s.Hide(w: w, animation: animate) { [weak self] in
      w.close()
      self?.window = nil
      completion?()
    }
  }

  func DesktopChanged() {
    if window != nil {
      Close()
    }
  }

  private func startEventMonitoring() {
    stopEventMonitoring()
    mouseListener = InputEventManager.s.createMouseListener(eventTypes: [.leftDown, .rightDown]) { [weak self] eventType, event in
      guard let self = self, let w = self.window, w.isVisible else {
        return Unmanaged.passUnretained(event)
      }
      var isInWindowContent = false
      if let contentView = w.contentView {
        let mouseLocation = NSEvent.mouseLocation
        let windowLocation = w.convertFromScreen(NSRect(origin: mouseLocation, size: .zero)).origin
        let hitView = contentView.hitTest(windowLocation)
        isInWindowContent = hitView != nil
      }
      if !isInWindowContent {
        DispatchQueue.main.async { [weak self] in
          self?.Close()
        }
      }
      return Unmanaged.passUnretained(event)
    }
  }

  private func stopEventMonitoring() {
    if let listener = mouseListener {
      InputEventManager.s.unregisterListener(listener)
      mouseListener = nil
    }
  }

  @objc private func handleFunctionExecuted(_ notification: Notification) {
    let source = notification.userInfo?["source"] as? String ?? ""
    if source == FeatureType.switcher.title {
      return
    }
    if window != nil {
      DispatchQueue.main.async { [weak self] in
        guard let self = self else { return }
        self.Close()
      }
    }
  }

  @objc private func handleGestureStarted() {
    if window != nil {
      DispatchQueue.main.async { [weak self] in
        guard let self = self else { return }
        self.Close(animate: false)
      }
    }
  }
}
