import SwiftUI

class LauncherWin: NSObject, NSWindowDelegate {
  static let s = LauncherWin()
  var onShow = false
  private var win: NSWindow?
  private var mouseListener: MouseListener?
  private var keyboardListener: KeyboardListener?
  private var lastWindowSize: NSSize = .zero
  private var isHiding = false
  private var lastShowTime: TimeInterval = 0
  private var lastHideTime: TimeInterval = 0
  private let keyEscape: Int64 = 53
  private let keyTab: Int64 = 48
  private var keepMode: Bool = false
  private var savedLauncherFrame: NSRect?

  var maxHeight: CGFloat {
    get {
      let saved = LauncherConfig.launcherMaxHeight
      return saved > 0 ? saved : LauncherInfo.minPanelHeight
    }
    set {
      if newValue != LauncherConfig.launcherMaxHeight {
        LauncherConfig.launcherMaxHeight = newValue
      }
    }
  }

  private override init() {
    super.init()
    NotificationCenter.default.addObserver(self, selector: #selector(handleFunctionExecuted(_:)), name: NSNotification.Name("FunctionExecuted"), object: nil)
    if LauncherInfo.gestureStarted {
      NotificationCenter.default.addObserver(self, selector: #selector(handleGestureStarted), name: NSNotification.Name("GestureStarted"), object: nil)
    }
    NotificationCenter.default.addObserver(self, selector: #selector(menuDidBeginTracking), name: NSMenu.didBeginTrackingNotification, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(menuDidEndTracking), name: NSMenu.didEndTrackingNotification, object: nil)
  }

  deinit {
    NotificationCenter.default.removeObserver(self)
    stopEventMonitoring()
  }

  func IsWindow(_ wid: CGWindowID, title: String? = nil) -> Bool {
    var result = false
    if Thread.isMainThread {
      result = win != nil && (win?.windowNumber == Int(wid) || (title != nil && win?.title == title))
    } else {
      DispatchQueue.main.sync {
        result = win != nil && (win?.windowNumber == Int(wid) || (title != nil && win?.title == title))
      }
    }
    return result
  }

  func getWindowFrame() -> NSRect? {
    return win?.frame
  }

  func windowWillClose(_ notification: Notification) {
    if let w = notification.object as? NSWindow, w === self.win {
      stopEventMonitoring()
      onShow = false
      isHiding = false
      win = nil
    }
  }

  func IsShow() -> Bool {
    return onShow
  }

  func DesktopChanged() {
    if onShow && !isHiding {
      Hide(animation: false)
    }
  }

  func Close(){
    if win != nil {
      autoreleasepool {
        stopEventMonitoring()
        if let w = win {
          w.orderOut(nil)
          w.contentView = nil
          w.contentViewController = nil
        }
        win = nil
        onShow = false
        isHiding = false
      }
    }
  }

  func ShowOrHide(mode: LauncherMode, debounce: Bool = false) {
    if DataManager.s.launcherMode != mode {
      if onShow {
        DataManager.s.changeMode(mode)
        return
      }
    }
    if debounce {
      let currentTime = Date().timeIntervalSince1970
      if currentTime - max(lastShowTime, lastHideTime) < 0.2 {
        return
      }
    }
    if onShow {
      Hide()
    } else {
      Show(mode: mode)
    }
  }

  func Show(mode: LauncherMode, animation: Bool = true) {
    let modeChanged = DataManager.s.launcherMode != mode
    if modeChanged && !(DataManager.s.launcherMode == .launcher && mode == .search) && !(DataManager.s.launcherMode == .search && mode == .launcher) {
      DataManager.s.changeMode(mode)
    }
    NotificationCenter.default.post(name: NSNotification.Name("FunctionExecuted"), object: nil, userInfo: ["source": FeatureType.launcher.title])
    lastShowTime = Date().timeIntervalSince1970
    let previousMode = DataManager.s.launcherMode
    let needCreateWindow = win == nil
    if needCreateWindow {
      create()
    }
    guard let w = self.win else { return }
    if modeChanged && onShow && !needCreateWindow {
      if previousMode == .launcher && mode == .search {
        animateFromLauncherToSearch(window: w)
      } else if previousMode == .search && mode == .launcher {
        animateFromSearchToLauncher(window: w)
      }
      return
    }
    if modeChanged && ((DataManager.s.launcherMode == .launcher && mode == .search) || (DataManager.s.launcherMode == .search && mode == .launcher)) {
      DataManager.s.changeMode(mode)
    }
    if mode == .search {
      if previousMode == .launcher && onShow {
        savedLauncherFrame = w.frame
      }
      if let screen = ScreenManager.s.GetScreen() {
        let visibleFrame = screen.visibleFrame
        w.setFrame(visibleFrame, display: true)
      }
    } else {
      if previousMode == .search && mode == .launcher, let savedFrame = savedLauncherFrame {
        w.setFrame(savedFrame, display: true)
      } else {
        ScreenManager.s.Center(w, winCenter: true)
      }
    }
    self.lastWindowSize = .zero
    NSApp.activate(ignoringOtherApps: true)
    if needCreateWindow {
      AnimationWindow.s.Show(w: w, animation: animation) { [weak self] in
        guard let self = self else { return }
        self.handleWindowShowCompleted(window: w, mode: mode)
      }
    } else if modeChanged {
      if !onShow {
        AnimationWindow.s.Show(w: w, animation: animation) { [weak self] in
          guard let self = self else { return }
          self.handleWindowShowCompleted(window: w, mode: mode)
        }
      }
    }
  }

  func Hide(animation: Bool = true, completion: @escaping () -> Void = {}) {
    guard let w = win, !isHiding else {
      completion()
      return
    }
    lastHideTime = Date().timeIntervalSince1970
    isHiding = true
    AnimationWindow.s.Hide(w: w, animation: animation) { [weak self] in
      guard let self = self else { return }
      stopEventMonitoring()
      onShow = false
      isHiding = false
      savedLauncherFrame = nil
      DataManager.s.clearAppsListIconCache()
      if DataManager.s.iconSizeChanged {
        DataManager.s.reloadApplicationIconsAfterSizeChange()
      }
      Close()
      completion()
    }
  }

  func Center(wait: Bool = false, must: Bool = false) {
    guard let w = win, w.isVisible || must else { return }
    if wait {
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
        guard let self = self else { return }
        let currentSize = w.frame.size
        if currentSize == lastWindowSize {
          return
        }
        lastWindowSize = currentSize
        ScreenManager.s.Center(w, winCenter: true)
      }
    } else {
      DispatchQueue.main.async { [weak self] in
        guard let self = self else { return }
        let currentSize = w.frame.size
        if currentSize == lastWindowSize {
          return
        }
        lastWindowSize = currentSize
        ScreenManager.s.Center(w, winCenter: true)
      }
    }
  }

  private func create() {
    if win == nil {
      let launcherView = LauncherView()
        .environmentObject(LauncherThemeManager.s)
        .environmentObject(DataManager.s)
        .environmentObject(DatabaseManager.s)
      self.win = AnimationWindow.s.Create(
        v: AnyView(launcherView),
        styleMask: [.borderless],
        level: .floating,
        backgroundColor: NSColor.clear,
        title: EmbarkInfo.name + FeatureType.launcher.title
      )
      self.win?.delegate = self
      if let contentViewController = self.win?.contentViewController {
        let size = contentViewController.view.intrinsicContentSize
        if size.width > 0, size.height > 0 {
          self.win?.setContentSize(size)
        }
      }
    }
  }

  private func startEventMonitoring() {
    stopEventMonitoring()
    mouseListener = InputEventManager.s.createMouseListener(eventTypes: [.leftDown, .rightDown]) { [weak self] eventType, event in
      guard let self = self, let w = self.win, w.isVisible, !self.isHiding else {
        return Unmanaged.passUnretained(event)
      }
      if LauncherSettingWin.s.IsShow() || DataManager.s.launcherMode == .settings || DataManager.s.launcherMode == .search || DataManager.s.isDialogShowing {
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
          guard let self = self else { return }
          if !isHiding && !keepMode {
            Hide()
          }
        }
      }
      return Unmanaged.passUnretained(event)
    }
    keyboardListener = InputEventManager.s.createKeyboardListener(eventTypes: [.keyDown, .keyUp]) { [weak self] eventType, event in
      guard let self = self else {
        return Unmanaged.passUnretained(event)
      }
      let handled = self.handleKeyboardEvent(event, isKeyUp: eventType == .keyUp)
      return handled ? nil : Unmanaged.passUnretained(event)
    }
  }

  private func handleKeyboardEvent(_ event: CGEvent, isKeyUp: Bool) -> Bool {
    guard let w = self.win, w.isVisible, !self.isHiding else { return false }
    if LauncherSettingWin.s.IsShow() || DataManager.s.launcherMode == .settings || DataManager.s.launcherMode == .space {
      return false
    }
    switch event.getIntegerValueField(.keyboardEventKeycode) {
    case keyEscape:
      if isKeyUp {
        DispatchQueue.main.async { [weak self] in
          guard let self = self else { return }
          if DataManager.s.launcherMode == .search {
            NotificationCenter.default.post(name: NSNotification.Name("SearchEscapePressed"), object: nil)
          } else {
            ShowOrHide(mode: DataManager.s.launcherMode)
          }
        }
      }
      return true
    case keyTab:
      if event.flags.contains(.maskShift) || event.flags.contains(.maskControl) || event.flags.contains(.maskAlternate) || event.flags.contains(.maskCommand) {
        return false
      }
      if DataManager.s.launcherMode == .search {
        if LauncherConfig.launcherTabKey == .bidirectional {
          if isKeyUp {
            DispatchQueue.main.async { [weak self] in
              guard let self = self else { return }
              Show(mode: .launcher, animation: false)
            }
          }
          return true
        }
        return false
      }
      if LauncherConfig.launcherTabKey == .toSearch || LauncherConfig.launcherTabKey == .bidirectional {
        if isKeyUp {
          DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            Show(mode: .search, animation: false)
          }
        }
        return true
      }
      return false
    default:
      return false
    }
  }

  private func stopEventMonitoring() {
    if let listener = mouseListener {
      InputEventManager.s.unregisterListener(listener)
      mouseListener = nil
    }
    if let listener = keyboardListener {
      InputEventManager.s.unregisterListener(listener)
      keyboardListener = nil
    }
  }

  @objc private func handleFunctionExecuted(_ notification: Notification) {
    if LauncherSettingWin.s.IsShow() {
      return
    }
    let source = notification.userInfo?["source"] as? String ?? ""
    if source == FeatureType.launcher.title {
      return
    }
    let function = notification.userInfo?["function"] as? String ?? ""
    if function == FeatureType.launcher.title || function == FeatureType.space.title {
      return
    }
    if onShow {
      DispatchQueue.main.async { [weak self] in
        guard let self = self else { return }
        Hide()
      }
    }
  }

  @objc private func handleGestureStarted() {
    if onShow {
      DispatchQueue.main.async { [weak self] in
        guard let self = self else { return }
        Hide(animation: false)
      }
    }
  }

  @objc private func menuDidBeginTracking(_ notification: Notification) {
    keepMode = true
  }

  @objc private func menuDidEndTracking(_ notification: Notification) {
    keepMode = false
  }

  private func handleWindowShowCompleted(window: NSWindow, mode: LauncherMode) {
    startEventMonitoring()
    onShow = true
    DispatchQueue.main.async {
      window.makeKey()
      if mode == .launcher || mode == .search {
        NotificationCenter.default.post(name: NSNotification.Name("ForceSearchFocus"), object: nil)
      }
    }
  }

  private func animateFromLauncherToSearch(window: NSWindow) {
    let startFrame = window.frame
    savedLauncherFrame = startFrame
    guard let screen = ScreenManager.s.GetScreen() else { return }
    let targetFrame = screen.visibleFrame
    DataManager.s.contentOpacity = 0
    window.alphaValue = 0.0
    DataManager.s.changeMode(.search)
    self.lastWindowSize = .zero
    NSApp.activate(ignoringOtherApps: true)
    DispatchQueue.main.async {
      window.makeKey()
      NotificationCenter.default.post(name: NSNotification.Name("ForceSearchFocus"), object: nil)
    }
    NSAnimationContext.runAnimationGroup({ context in
      context.duration = LauncherInfo.searchAnimationDuration
      context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
      context.allowsImplicitAnimation = true
      window.animator().setFrame(targetFrame, display: true)
      window.animator().alphaValue = 1.0
    }) {
      DataManager.s.contentOpacity = 1.0
      DispatchQueue.main.async {
        NotificationCenter.default.post(name: NSNotification.Name("ForceSearchFocus"), object: nil)
      }
    }
  }

  private func animateFromSearchToLauncher(window: NSWindow) {
    guard let targetFrame = savedLauncherFrame else {
      DataManager.s.changeMode(.launcher)
      self.lastWindowSize = .zero
      return
    }
    DataManager.s.contentOpacity = 0
    window.alphaValue = 0.0
    NSApp.activate(ignoringOtherApps: true)
    NSAnimationContext.runAnimationGroup({ context in
      context.duration = LauncherInfo.searchAnimationDuration
      context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
      context.allowsImplicitAnimation = true
      window.animator().setFrame(targetFrame, display: true)
      window.animator().alphaValue = 1.0
    }) { [weak self] in
      guard let self = self else { return }
      DataManager.s.changeMode(.launcher)
      DataManager.s.contentOpacity = 1.0
      self.lastWindowSize = .zero
      DispatchQueue.main.async {
        window.makeKey()
        NotificationCenter.default.post(name: NSNotification.Name("ForceSearchFocus"), object: nil)
      }
    }
  }
}
