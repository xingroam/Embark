import Cocoa
import Carbon

class SwitcherMonitor {
  static let s = SwitcherMonitor()
  private var keyboardListener: KeyboardListener?
  private var pollingThread: Thread?

  private init() {}

  func Start() {
    setupKeyboardHandling()
  }

  func Stop() {
    cleanupKeyboardHandling()
  }

  private func setupKeyboardHandling() {
    cleanupKeyboardHandling()
    keyboardListener = InputEventManager.s.createKeyboardListener(eventTypes: [.flagsChanged, .keyDown]) { [weak self] type, event in
      guard let self = self else { return Unmanaged.passUnretained(event) }
      let configuredFlags = SwitcherConfig.switcherShortcutFlags
      if type == .flagsChanged {
        let eventFlags = event.flags
        let isConfiguredFlagPressed = eventFlags.containsModifier(configuredFlags)
        if !isConfiguredFlagPressed {
          self.onModifierReleased()
        }
      } else if type == .keyDown {
        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
        if keyCode == Int64(SwitcherConfig.switcherShortcutKey) {
          let currentFlags = event.flags
          let isConfiguredFlagPressed = currentFlags.containsModifier(configuredFlags)
          if isConfiguredFlagPressed {
            self.handleShortcutTriggered()
            return nil
          }
        }
      }
      return Unmanaged.passUnretained(event)
    }
  }

  private func cleanupKeyboardHandling() {
    stopPolling()
    if let listener = keyboardListener {
      InputEventManager.s.unregisterListener(listener)
      keyboardListener = nil
    }
  }

  private func onModifierReleased() {
    if SwitcherManager.s.currentMode == .shortcutMode && (SwitcherManager.s.isSwitcherVisible || SwitcherManager.s.isLoading) {
      stopPolling()
      self.finishOnMain()
    }
  }

  private func handleShortcutTriggered() {
    if !SwitcherManager.s.isSwitcherVisible && !SwitcherManager.s.isLoading {
      SwitcherManager.s.showSwitcher(animate: false, mode: .shortcutMode, sortByMRU: true, atMouse: false, autoSelect: true)
      startPolling()
    } else if SwitcherManager.s.isSwitcherVisible {
      self.selectNext()
    }
  }

  private func selectNext() {
    if SwitcherManager.s.windows.isEmpty { return }
    SwitcherManager.s.selectedIndex = (SwitcherManager.s.selectedIndex + 1) % SwitcherManager.s.windows.count
  }

  private func finishOnMain() {
    CFRunLoopPerformBlock(CFRunLoopGetMain(), CFRunLoopMode.commonModes.rawValue) {
      SwitcherManager.s.finishSwitchMode()
    }
    CFRunLoopWakeUp(CFRunLoopGetMain())
  }

  private func startPolling() {
    stopPolling()
    let thread = Thread { [weak self] in
      while !Thread.current.isCancelled {
        Thread.sleep(forTimeInterval: 0.05)
        if Thread.current.isCancelled { break }
        let flags = CGEventSource.flagsState(.hidSystemState)
        let configuredFlags = SwitcherConfig.switcherShortcutFlags
        if !flags.containsModifier(configuredFlags) {
          self?.finishOnMain()
          break
        }
      }
    }
    thread.qualityOfService = .userInteractive
    pollingThread = thread
    thread.start()
  }

  private func stopPolling() {
    pollingThread?.cancel()
    pollingThread = nil
  }
}
