import SwiftUI
import ApplicationServices

class SlideMonitor {
  static let s = SlideMonitor()
  var hiddenWindows: [HiddenWindow] = []
  private var keyboardListener: KeyboardListener?
  private var mouseListener: MouseListener?
  private var lastMousePosition: CGPoint = .zero
  private var lastActionTime: TimeInterval = 0
  private var screenChangeObserver: NSObjectProtocol?
  private var lastScreenCount: Int = 0

  private init() {
    lastScreenCount = NSScreen.screens.count
  }

  private func getScreenForWindow(_ windowData: WindowData) -> NSScreen? {
    let windowCenter = CGPoint(x: windowData.bounds.midX, y: windowData.bounds.midY)
    let mainScreenHeight = NSScreen.screens.first?.frame.height ?? 0
    let cocoaY = mainScreenHeight - windowCenter.y
    let cocoaPoint = CGPoint(x: windowCenter.x, y: cocoaY)
    return NSScreen.screens.first { screen in
      screen.frame.contains(cocoaPoint)
    } ?? NSScreen.main
  }

  func Start() {
    SlideMonitor.s.UpdateConfig()
    setupScreenChangeNotification()
    setupKeyboardHandling()
  }

  func Stop() {
    cleanupScreenChangeNotification()
    cleanupKeyboardHandling()
    cleanupMouseMonitoring()
    if !hiddenWindows.isEmpty {
      for (_, hiddenWindow) in hiddenWindows.enumerated() {
        SlideWindow.s.showOfWindow(hiddenWindow: hiddenWindow)
      }
      hiddenWindows.removeAll()
      Debug.print("Slide Remove All")
    }
  }

  func UpdateConfig() {
    InputEventManager.s.moveDebounceInterval = SlideConfig.slideDelay
    for (_, hiddenWindow) in hiddenWindows.enumerated() {
      let screenFrame = hiddenWindow.screen?.frame ?? NSScreen.main?.frame ?? CGRect.zero
      let newHideBounds = SlideWindow.s.calcHideBounds(showBounds: hiddenWindow.showBounds, dockInfo: hiddenWindow.dockInfo, screenFrame: screenFrame)
      hiddenWindow.hideBounds = newHideBounds
    }
  }

  func ToggleDock(targetWindow: WindowData? = nil) {
    guard let wi = targetWindow ?? WindowFind.FindWindowUnderMouse() else { return }
    let hiddenWindow = self.hiddenWindows.first { $0.windowData.pid == wi.pid && $0.windowData.wid == wi.wid }
    if let hiddenWindow = hiddenWindow {
      self.stopDock(hiddenWindow: hiddenWindow)
    } else {
      self.startDock(wi: wi)
    }
  }

  // MARK: - Dock

  private func startDock(wi: WindowData) {
    guard let element = WindowFind.FindWindowElement(wi: wi) else { return }
    let updatedWi = WindowData(pid: wi.pid, wid: wi.wid, app: wi.app, bounds: wi.bounds, element: element)
    let windowScreen = getScreenForWindow(updatedWi)
    guard let dockInfo = SlideWindow.s.getWindowDockInfo(windowData: updatedWi, screen: windowScreen) else {
      Toast.bottomCenter(message: NSLocalizedString("slide.message.feasible", comment: ""), duration: 3.0)
      return
    }
    if dockInfo.mainDockArea == .leftAndRight {
      Toast.bottomCenter(message: NSLocalizedString("slide.message.fullscreen", comment: ""), duration: 3.0)
      return
    }
    let existingWindow = hiddenWindows.first { $0.windowData.pid == updatedWi.pid && $0.windowData.wid == updatedWi.wid }
    if existingWindow != nil {
      return
    }
    let showBounds = SlideWindow.s.calcShowBounds(bounds: updatedWi.bounds, screen: windowScreen)
    let screenFrame = windowScreen?.frame ?? NSScreen.main?.frame ?? CGRect.zero
    let hideBounds: CGRect
    if dockInfo.mainDockArea == .bottom {
      hideBounds = .zero
    } else {
      hideBounds = SlideWindow.s.calcHideBounds(showBounds: showBounds, dockInfo: dockInfo, screenFrame: screenFrame)
    }
    let hiddenWindow = HiddenWindow(windowData: updatedWi, dockInfo: dockInfo, showBounds: showBounds, hideBounds: hideBounds, screen: windowScreen)
    hiddenWindows.append(hiddenWindow)
    if hiddenWindows.count == 1 {
      startMouseMonitoring()
    }
    if LauncherBrowserWin.s.IsWindow(Int(updatedWi.wid)) {
      LauncherBrowserWin.s.setDocked(wid: updatedWi.wid, docked: true)
    }
    if SlideConfig.slideTip {
      Toast.bottomCenter(message: FeatureType.slide.title + " " + updatedWi.app)
    }
    Debug.print("Slide Start: [\(updatedWi.app), \(updatedWi.pid), \(updatedWi.wid), \(dockInfo.mainDockArea)]")
  }

  private func stopDock(hiddenWindow: HiddenWindow, drag: Bool = false) {
    if let index = hiddenWindows.firstIndex(of: hiddenWindow) {
      hiddenWindows.remove(at: index)
      if hiddenWindows.isEmpty {
        cleanupMouseMonitoring()
      }
      if LauncherBrowserWin.s.IsWindow(Int(hiddenWindow.windowData.wid)) {
        LauncherBrowserWin.s.setDocked(wid: hiddenWindow.windowData.wid, docked: false)
      }
      if !drag {
        SlideWindow.s.showOfWindow(hiddenWindow: hiddenWindow)
      }
      Debug.print("Slide Stop: [\(hiddenWindow.windowData.app), \(hiddenWindow.windowData.pid), \(hiddenWindow.windowData.wid), \(hiddenWindow.dockInfo.mainDockArea)]")
    }
  }

  // MARK: - Mouse Monitoring

  private func startMouseMonitoring() {
    cleanupMouseMonitoring()
    mouseListener = InputEventManager.s.createMouseListener(eventTypes: [.moved, .dragged]) { [weak self] type, event in
      guard let self = self else { return Unmanaged.passUnretained(event) }
      if !self.hiddenWindows.isEmpty {
        self.lastMousePosition = event.location
        self.onMouseMove()
      }
      return Unmanaged.passUnretained(event)
    }
  }

  private func cleanupMouseMonitoring() {
    if let listener = mouseListener {
      InputEventManager.s.unregisterListener(listener)
      mouseListener = nil
    }
  }

  private func onMouseMove() {
    let mouseX = lastMousePosition.x
    let mouseScreen = ScreenManager.s.GetScreen()
    checkAndCleanup()
    for (_, hiddenWindow) in hiddenWindows.enumerated() {
      if SlideWindow.s.windowOnMinimize(windowData: hiddenWindow.windowData) {
        continue
      }
      if let bounds = WindowFind.GetWindowBounds(windowData: hiddenWindow.windowData) {
        if SlideWindow.s.windowAtBothEdges(bounds: bounds, screen: hiddenWindow.screen) {
          continue
        }
        hiddenWindow.currentBounds = bounds
      }
      if SlideWindow.s.boundsEqual(hiddenWindow.currentBounds, hiddenWindow.hideBounds) {
        if SlideWindow.s.shouldShowWindow(hiddenWindow: hiddenWindow, mouseX: mouseX, mouseScreen: mouseScreen, lastMousePosition: lastMousePosition) {
          SlideWindow.s.showOfWindow(hiddenWindow: hiddenWindow, activate: true)
          DispatchQueue.global(qos: .userInitiated).async {
            var attempts = 0
            while attempts < 10 {
              usleep(100000)
              if let bounds = WindowFind.GetWindowBounds(windowData: hiddenWindow.windowData), SlideWindow.s.boundsEqual(bounds, hiddenWindow.showBounds) {
                DispatchQueue.main.async {
                  hiddenWindow.currentBounds = bounds
                }
                break
              }
              attempts += 1
            }
          }
        }
      } else {
        if !SlideWindow.s.mouseInWindow(hiddenWindow: hiddenWindow, lastMousePosition: lastMousePosition) {
          if SlideConfig.slideAutoUndock {
            if let currentBounds = WindowFind.GetWindowBounds(windowData: hiddenWindow.windowData) {
              let currentDockInfo = SlideWindow.s.getWindowDockInfo(windowData: WindowData(pid: hiddenWindow.windowData.pid, wid: hiddenWindow.windowData.wid, app: hiddenWindow.windowData.app, bounds: currentBounds, element: hiddenWindow.windowData.element), screen: hiddenWindow.screen)
              if currentDockInfo == nil || currentDockInfo?.mainDockArea != hiddenWindow.dockInfo.mainDockArea {
                stopDock(hiddenWindow: hiddenWindow, drag: true)
                return
              }
            }
          }
          SlideWindow.s.hideOfWindow(hiddenWindow: hiddenWindow)
          DispatchQueue.global(qos: .userInitiated).async {
            var attempts = 0
            while attempts < 10 {
              usleep(100000)
              if let bounds = WindowFind.GetWindowBounds(windowData: hiddenWindow.windowData), SlideWindow.s.boundsEqual(bounds, hiddenWindow.hideBounds) {
                DispatchQueue.main.async {
                  hiddenWindow.currentBounds = bounds
                }
                break
              }
              attempts += 1
            }
          }
        }
      }
    }
  }

  private func checkAndCleanup() {
    let currentTime = Date().timeIntervalSince1970
    if currentTime - lastActionTime > SlideInfo.slideCleanTime {
      lastActionTime = currentTime
      autoreleasepool {
        if !hiddenWindows.isEmpty {
          hiddenWindows.removeAll { !WindowFind.FindWindowByPidWid(pid: $0.windowData.pid, wid: $0.windowData.wid) }
        }
        if hiddenWindows.isEmpty {
          cleanupMouseMonitoring()
        }
      }
    }
  }

  // MARK: - Keyboard Handling

  private func setupKeyboardHandling() {
    cleanupKeyboardHandling()
    keyboardListener = InputEventManager.s.createKeyDownListener { [weak self] type, event in
      guard let self = self else { return Unmanaged.passUnretained(event) }
      let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
      let flags = event.flags
      if SlideConfig.slide && SlideConfig.slideShortcutKey != .disabled && SlideConfig.slideShortcutFlags != .disabled && keyCode == SlideConfig.slideShortcutKey && flags.contains(SlideConfig.slideShortcutFlags) {
        guard let wi = WindowFind.FindWindowUnderMouse() else { return Unmanaged.passUnretained(event) }
        let hiddenWindow = self.hiddenWindows.first { $0.windowData.pid == wi.pid && $0.windowData.wid == wi.wid }
        if let hiddenWindow = hiddenWindow {
          self.stopDock(hiddenWindow: hiddenWindow)
        } else {
          self.startDock(wi: wi)
        }
        return nil
      }
      return Unmanaged.passUnretained(event)
    }
  }

  private func cleanupKeyboardHandling() {
    if let listener = keyboardListener {
      InputEventManager.s.unregisterListener(listener)
      keyboardListener = nil
    }
  }

  // MARK: - Screen Change Notification

  private func setupScreenChangeNotification() {
    cleanupScreenChangeNotification()
    screenChangeObserver = NotificationCenter.default.addObserver(forName: NSApplication.didChangeScreenParametersNotification, object: nil, queue: .main) { [weak self] _ in
      guard let self = self else { return }
      handleScreenConfigurationChange()
    }
  }

  private func cleanupScreenChangeNotification() {
    if let observer = screenChangeObserver {
      NotificationCenter.default.removeObserver(observer)
      screenChangeObserver = nil
    }
  }

  private func handleScreenConfigurationChange() {
    if NSScreen.screens.count != lastScreenCount {
      if !hiddenWindows.isEmpty {
        for hiddenWindow in hiddenWindows {
          SlideWindow.s.showOfWindow(hiddenWindow: hiddenWindow)
        }
        hiddenWindows.removeAll()
        Debug.print("Slide Remove All")
      }
    }
    lastScreenCount = NSScreen.screens.count
  }
}
