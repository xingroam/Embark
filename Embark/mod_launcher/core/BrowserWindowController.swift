import SwiftUI

class BrowserWindow: NSWindow {
  override var canBecomeKey: Bool { return true }
  override var canBecomeMain: Bool { return true }
}

class BrowserWindowController: NSObject, NSWindowDelegate {
  var window: NSWindow?
  private var isPinned = false
  private var isDocked = false
  private var isHidden = false
  private var keepAlive = false
  private var isMobileMode = false
  private var mouseListener: Any?
  private var localMouseListener: Any?
  private var keyDownMonitor: Any?
  private var url: String
  private let title: String
  private let inheritedUseProxy: Bool?
  private let isSecondaryWindow: Bool

  var isShown: Bool {
    return window != nil && !isHidden
  }

  init(url: String, title: String, inheritedUseProxy: Bool? = nil, isSecondaryWindow: Bool = false) {
    self.url = url
    self.title = title
    self.inheritedUseProxy = inheritedUseProxy
    self.isSecondaryWindow = isSecondaryWindow
    super.init()
    NotificationCenter.default.addObserver(self, selector: #selector(screenParametersChanged), name: NSApplication.didChangeScreenParametersNotification, object: nil)
  }

  func updateUrl(_ newUrl: String) {
    self.url = newUrl
  }

  deinit {
    NotificationCenter.default.removeObserver(self)
  }

  @objc private func screenParametersChanged() {
    guard let w = window else { return }
    ensureWindowOnScreen(w)
  }

  private func isFrameOnAnyScreen(_ frame: NSRect) -> Bool {
    let centerPoint = NSPoint(x: frame.midX, y: frame.midY)
    for screen in NSScreen.screens {
      if screen.visibleFrame.contains(centerPoint) {
        return true
      }
    }
    return false
  }

  private func ensureWindowOnScreen(_ w: NSWindow) {
    guard let screen = w.screen ?? NSScreen.main else { return }
    let visibleFrame = screen.visibleFrame
    var frame = w.frame
    if frame.width > visibleFrame.width {
      frame.size.width = visibleFrame.width
    }
    if frame.height > visibleFrame.height {
      frame.size.height = visibleFrame.height
    }
    if frame.maxX > visibleFrame.maxX {
      frame.origin.x = visibleFrame.maxX - frame.width
    }
    if frame.minX < visibleFrame.minX {
      frame.origin.x = visibleFrame.minX
    }
    if frame.maxY > visibleFrame.maxY {
      frame.origin.y = visibleFrame.maxY - frame.height
    }
    if frame.minY < visibleFrame.minY {
      frame.origin.y = visibleFrame.minY
    }
    w.setFrame(frame, display: true)
    saveWindowState()
  }

  func open(animation: Bool = true) {
    if window == nil {
      createWindow()
      if !isSecondaryWindow {
        isPinned = false
      }
    }
    guard let w = self.window else { return }
    isHidden = false
    w.alphaValue = 1.0
    if let linkData = DataManager.s.linkData[url] {
      keepAlive = linkData.keepAlive
      isMobileMode = linkData.isMobileMode
      if !isSecondaryWindow {
        setPinned(linkData.isPinned)
      }
    }
    if let linkData = DataManager.s.linkData[url], let windowState = linkData.windowState {
      let components = windowState.split(separator: ",")
      if components.count == 4,
         let x = Double(components[0]),
         let y = Double(components[1]),
         let width = Double(components[2]),
         let height = Double(components[3]) {
        let savedFrame = NSRect(x: x, y: y, width: width, height: height)
        if isFrameOnAnyScreen(savedFrame) {
          w.setFrame(savedFrame, display: true)
        } else {
          centerWindow(w)
        }
      } else {
        centerWindow(w)
      }
    } else {
      centerWindow(w)
    }
    ensureWindowOnScreen(w)
    AnimationWindow.s.Show(w: w, animation: animation) { [weak self] in
      NSApp.activate(ignoringOtherApps: true)
      w.makeKeyAndOrderFront(nil)
      self?.startEventMonitoring()
    }
  }

  func close(animation: Bool = true) {
    guard let w = window, !isHidden else { return }
    LauncherBrowserWin.s.recordCloseTime(url: url)
    isHidden = true
    stopEventMonitoring()
    if keepAlive {
      AnimationWindow.s.Hide(w: w, animation: animation, duration: 0.05) {
        w.orderOut(nil)
      }
    } else {
      AnimationWindow.s.Hide(w: w, animation: animation, duration: 0.05) { [weak self] in
        self?.cleanup()
      }
    }
  }

  func setPinned(_ pinned: Bool) {
    isPinned = pinned
  }

  func setDocked(_ docked: Bool) {
    isDocked = docked
  }

  func setKeepAlive(_ keepAlive: Bool) {
    self.keepAlive = keepAlive
  }

  func dragWindow(delta: CGSize) {
    guard let w = window else { return }
    let currentOrigin = w.frame.origin
    let newOrigin = CGPoint(x: currentOrigin.x + delta.width, y: currentOrigin.y - delta.height)
    w.setFrameOrigin(newOrigin)
  }

  func windowWillClose(_ notification: Notification) {
    if let w = notification.object as? NSWindow, w === self.window {
      saveWindowState()
      w.contentView = nil
      w.contentViewController = nil
      self.window = nil
      LauncherBrowserWin.s.removeWindow(url: url)
    }
  }

  func windowDidMove(_ notification: Notification) {
    saveWindowState()
  }

  func windowDidResize(_ notification: Notification) {
    saveWindowState()
  }

  private func saveWindowState() {
    guard let w = window else { return }
    let frame = w.frame
    let state = "\(frame.origin.x),\(frame.origin.y),\(frame.size.width),\(frame.size.height)"
    DataManager.s.updateLinkWindowState(linkPath: url, state: state)
  }

  private func centerWindow(_ w: NSWindow) {
    if let screen = NSScreen.main {
      let screenRect = screen.visibleFrame
      let width: CGFloat = 1000
      let height: CGFloat = 800
      let x = screenRect.midX - width / 2
      let y = screenRect.midY - height / 2
      w.setFrame(NSRect(x: x, y: y, width: width, height: height), display: true)
    }
  }

  private func startEventMonitoring() {
    if mouseListener == nil {
      mouseListener = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
        guard let self = self, let w = self.window, !self.isHidden, !self.isPinned, !self.isDocked else { return }
        let clickLocation = NSEvent.mouseLocation
        if !NSPointInRect(clickLocation, w.frame) {
          self.close()
        }
      }
    }
    if localMouseListener == nil {
      localMouseListener = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
        guard let self = self, let w = self.window, !self.isHidden, !self.isPinned, !self.isDocked else { return event }
        if let eventWindow = event.window, eventWindow != w {
          if LauncherBrowserWin.s.IsWindow(eventWindow.windowNumber) {
            self.close()
          }
        }
        return event
      }
    }
    if keyDownMonitor == nil {
      keyDownMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
        guard let self = self, let w = self.window, event.window == w else { return event }
        if event.keyCode == 53 { // Esc
          self.close()
          return nil
        }
        if event.modifierFlags.contains(.command) && event.keyCode == 13 { // Cmd+W
          self.close()
          return nil
        }
        return event
      }
    }
  }

  private func stopEventMonitoring() {
    if let listener = mouseListener {
      NSEvent.removeMonitor(listener)
      mouseListener = nil
    }
    if let listener = localMouseListener {
      NSEvent.removeMonitor(listener)
      localMouseListener = nil
    }
    if let monitor = keyDownMonitor {
      NSEvent.removeMonitor(monitor)
      keyDownMonitor = nil
    }
  }

  private func cleanup() {
    if let w = window {
      w.contentView = nil
      w.contentViewController = nil
      w.close()
    }
    window = nil
  }

  private func createWindow() {
    let initialKeepAlive = DataManager.s.linkData[url]?.keepAlive ?? false
    let initialIsMobileMode = DataManager.s.linkData[url]?.isMobileMode ?? false
    let initialShowInMenuBar = DataManager.s.linkData[url]?.showInMenuBar ?? false
    let initialIsPinned = isSecondaryWindow ? true : (DataManager.s.linkData[url]?.isPinned ?? false)
    let icon = DataManager.s.getLinkIcon(linkPath: url)
    if isSecondaryWindow {
      isPinned = true
    }
    let browserView = LauncherBrowserView(
      urlString: url,
      title: title,
      icon: icon,
      initialKeepAlive: initialKeepAlive,
      initialIsMobileMode: initialIsMobileMode,
      initialShowInMenuBar: initialShowInMenuBar,
      initialIsPinned: initialIsPinned,
      inheritedUseProxy: inheritedUseProxy,
      isSecondaryWindow: isSecondaryWindow,
      onPin: { [weak self] pinned in
        guard let self = self else { return }
        self.setPinned(pinned)
        DataManager.s.updateLinkPinned(linkPath: self.url, isPinned: pinned)
      },
      onKeepAlive: { [weak self] keepAlive in
        guard let self = self else { return }
        self.keepAlive = keepAlive
        DataManager.s.updateLinkKeepAlive(linkPath: self.url, keepAlive: keepAlive)
      },
      onMobileMode: { [weak self] isMobileMode in
        guard let self = self else { return }
        self.isMobileMode = isMobileMode
        DataManager.s.updateLinkMobileMode(linkPath: self.url, isMobileMode: isMobileMode)
      },
      onShowInMenuBar: { [weak self] showInMenuBar in
        guard let self = self else { return }
        DataManager.s.updateLinkShowInMenuBar(linkPath: self.url, showInMenuBar: showInMenuBar)
      },
      onMinimize: { [weak self] in
        self?.window?.miniaturize(nil)
      },
      onClose: { [weak self] in
        self?.close()
      }
    )
    .environmentObject(LauncherThemeManager.s)
    .environmentObject(DataManager.s)
    let w = BrowserWindow(contentViewController: NSHostingController(rootView: browserView))
    w.styleMask = [NSWindow.StyleMask.borderless, NSWindow.StyleMask.resizable, NSWindow.StyleMask.miniaturizable]
    w.level = .floating
    w.backgroundColor = .clear
    w.title = title
    w.isReleasedWhenClosed = false
    w.ignoresMouseEvents = false
    w.collectionBehavior = [NSWindow.CollectionBehavior.moveToActiveSpace]
    w.isMovableByWindowBackground = false
    w.hasShadow = true
    w.delegate = self
    self.window = w
  }
}
