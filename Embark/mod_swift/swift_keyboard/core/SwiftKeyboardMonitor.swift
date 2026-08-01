import SwiftUI
import ApplicationServices

class SwiftKeyboardMonitor {
  static let s = SwiftKeyboardMonitor()
  static let escapeKeyCode: CGKeyCode = 53
  private var modifierKeyTimestamps: [SwiftShortcut: TimeInterval] = [:]
  private var fullKeyboardListener: KeyboardListener?
  private var lastWindowShortcut: SwiftShortcut?
  private var isActionTriggered: Bool = false
  private var modifierKeyStates: [SwiftShortcut: Bool] = [:]
  private var detection: TimeInterval { SwiftKeyboardConfig.swiftKeyboardDetection }
  private var otherKeyPressed: Bool = false
  private var lastOtherKeyTimestamp: TimeInterval = 0
  private var lastActionTime: TimeInterval = 0
  private var linkShortcuts: [Int64: SwiftShortcut] = [:]

  private init() {
    NotificationCenter.default.addObserver(self, selector: #selector(configChanged), name: NSNotification.Name("SwiftKeyboardConfigChanged"), object: nil)
  }

  @objc private func configChanged() {
    loadLinkShortcuts()
  }

  @objc func resetState() {
    otherKeyPressed = false
    lastOtherKeyTimestamp = 0
    lastWindowShortcut = nil
    isActionTriggered = false
    modifierKeyTimestamps.removeAll()
    modifierKeyStates.removeAll()
  }

  func Start() {
    setupKeyboardHandling()
    loadLinkShortcuts()
  }

  func Stop() {
    cleanupKeyboardHandling()
  }

  private func setupKeyboardHandling() {
    cleanupKeyboardHandling()
    fullKeyboardListener = InputEventManager.s.createFullKeyboardListener { [weak self] type, event in
      guard let self = self else { return Unmanaged.passUnretained(event) }
      let currentTimestamp = Date().timeIntervalSince1970
      let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
      switch type {
      case .keyDown:
        if keyCode != Self.escapeKeyCode {
          self.handleOtherKeyPress(currentTimestamp: currentTimestamp)
        }
      case .keyUp:
        if keyCode == Self.escapeKeyCode {
          self.handleEscapeKeyRelease(currentTimestamp: currentTimestamp)
        }
      case .flagsChanged:
        self.handleWindowShortcutChange(event: event, currentTimestamp: currentTimestamp)
      default:
        break
      }
      return Unmanaged.passUnretained(event)
    }
  }

  private func cleanupKeyboardHandling() {
    if let listener = fullKeyboardListener {
      InputEventManager.s.unregisterListener(listener)
      fullKeyboardListener = nil
    }
  }

  private func loadLinkShortcuts() {
    let rawShortcuts = DatabaseManager.s.loadSwiftKeyboardLinks()
    var shortcuts: [Int64: SwiftShortcut] = [:]
    for (id, raw) in rawShortcuts {
      if let s = SwiftShortcut(rawValue: raw) {
        shortcuts[id] = s
      }
    }
    self.linkShortcuts = shortcuts
  }

  func markOtherKeyPressed() {
    let currentTimestamp = Date().timeIntervalSince1970
    handleOtherKeyPress(currentTimestamp: currentTimestamp)
  }

  private func handleOtherKeyPress(currentTimestamp: TimeInterval) {
    otherKeyPressed = true
    lastOtherKeyTimestamp = currentTimestamp
    lastWindowShortcut = nil
    isActionTriggered = false
    modifierKeyTimestamps.removeAll()
  }

  private func handleEscapeKeyRelease(currentTimestamp: TimeInterval) {
    let escapeKey: SwiftShortcut = .escape
    let lastTimestamp = modifierKeyTimestamps[escapeKey] ?? 0
    if shouldTriggerAction(key: escapeKey, lastTimestamp: lastTimestamp, currentTimestamp: currentTimestamp) {
      performAction(for: escapeKey)
      return
    }
    modifierKeyTimestamps[escapeKey] = currentTimestamp
    lastWindowShortcut = escapeKey
    isActionTriggered = false
  }

  private func handleWindowShortcutChange(event: CGEvent, currentTimestamp: TimeInterval) {
    for modifierKey in SwiftShortcut.allCases.filter({ $0 != .disabled }) {
      guard modifierKey != .escape else { continue }
      let isCurrentlyPressed = event.flags.contains(modifierKey.flag)
      let wasPreviouslyPressed = modifierKeyStates[modifierKey] ?? false
      if !wasPreviouslyPressed && isCurrentlyPressed {
        resetOtherWindowShortcuts(except: modifierKey)
      }
      if wasPreviouslyPressed && !isCurrentlyPressed {
        let lastTimestamp = modifierKeyTimestamps[modifierKey] ?? 0
        if shouldTriggerAction(key: modifierKey, lastTimestamp: lastTimestamp, currentTimestamp: currentTimestamp) {
          performAction(for: modifierKey)
          return
        }
        modifierKeyTimestamps[modifierKey] = currentTimestamp
        lastWindowShortcut = modifierKey
        isActionTriggered = false
      }
      modifierKeyStates[modifierKey] = isCurrentlyPressed
    }
    if !SwiftShortcut.allCases.filter({ $0 != .disabled }).contains(where: { modifierKeyStates[$0] ?? false }) {
      cleanupExpiredStates(currentTimestamp: currentTimestamp)
      otherKeyPressed = false
    }
  }

  private func performAction(for key: SwiftShortcut) {
    if let linkId = linkShortcuts.first(where: { $0.value == key })?.key {
      if let link = DataManager.s.linkData.values.first(where: { $0.id == linkId }) {
        NotificationCenter.default.post(name: NSNotification.Name("FunctionExecuted"), object: nil, userInfo: ["source": FeatureType.swift.title])
        resetState()
        Task {
          _ = await DataManager.s.launchLinkWithValidation(path: link.path, linkName: link.name)
        }
        checkAndCleanup()
        return
      }
    }
    switch key {
    case SwiftKeyboardConfig.swiftKeyboardLauncher:
      if LauncherConfig.launcher {
        NotificationCenter.default.post(name: NSNotification.Name("FunctionExecuted"), object: nil, userInfo: ["source": FeatureType.swift.title, "function": FeatureType.launcher.title])
        resetState()
        if DataManager.s.launcherMode == .search && LauncherWin.s.IsShow() {
          LauncherWin.s.Hide()
        } else {
          LauncherWin.s.ShowOrHide(mode: .launcher)
        }
        checkAndCleanup()
      }
    case SwiftKeyboardConfig.swiftKeyboardSpace:
      if SpaceConfig.space {
        NotificationCenter.default.post(name: NSNotification.Name("FunctionExecuted"), object: nil, userInfo: ["source": FeatureType.swift.title, "function": FeatureType.space.title])
        resetState()
        if DataManager.s.launcherMode == .search && LauncherWin.s.IsShow() {
          LauncherWin.s.Hide()
        } else {
          LauncherWin.s.ShowOrHide(mode: .space)
        }
        checkAndCleanup()
      }
    case SwiftKeyboardConfig.swiftKeyboardFocus:
      NotificationCenter.default.post(name: NSNotification.Name("FunctionExecuted"), object: nil, userInfo: ["source": FeatureType.swift.title])
      resetState()
      FocusConfig.focus.toggle()
      NotificationCenter.default.post(name: NSNotification.Name("FocusConfigChanged"), object: nil)
      checkAndCleanup()
    case SwiftKeyboardConfig.swiftKeyboardSlide:
      if SlideConfig.slide {
        NotificationCenter.default.post(name: NSNotification.Name("FunctionExecuted"), object: nil, userInfo: ["source": FeatureType.swift.title])
        resetState()
        SlideMonitor.s.ToggleDock()
        checkAndCleanup()
      }
    case SwiftKeyboardConfig.swiftKeyboardSwitcher:
      if SwitcherConfig.switcher {
        NotificationCenter.default.post(name: NSNotification.Name("FunctionExecuted"), object: nil, userInfo: ["source": FeatureType.swift.title])
        resetState()
        SwitcherManager.s.ShowOrHide(animate: false, atMouse: false, forceSelectMode: true)
        checkAndCleanup()
      }
    default:
      NotificationCenter.default.post(name: NSNotification.Name("FunctionExecuted"), object: nil, userInfo: ["source": FeatureType.swift.title])
      resetState()
      switch key {
      case SwiftKeyboardConfig.swiftKeyboardMinimize:
        SwiftManager.s.MinWindow()
        checkAndCleanup()
      case SwiftKeyboardConfig.swiftKeyboardRestore:
        SwiftManager.s.ReWindow()
        checkAndCleanup()
      case SwiftKeyboardConfig.swiftKeyboardMaximize:
        SwiftManager.s.MaxWindow(mode: SwiftKeyboardConfig.swiftKeyboardMaximizeMode)
        checkAndCleanup()
      case SwiftKeyboardConfig.swiftKeyboardClose:
        SwiftManager.s.CloseWindow(mode: SwiftKeyboardConfig.swiftKeyboardCloseMode)
        checkAndCleanup()
      default:
        break
      }
    }
  }

  private func checkAndCleanup() {
    let currentTime = Date().timeIntervalSince1970
    if currentTime - lastActionTime > SwiftInfo.swiftCleanTime {
      lastActionTime = currentTime
      SwiftManager.s.cleanup()
    }
  }

  private func resetOtherWindowShortcuts(except currentKey: SwiftShortcut) {
    for key in SwiftShortcut.allCases.filter({ $0 != .disabled }) {
      if key != currentKey {
        modifierKeyTimestamps[key] = 0
        modifierKeyStates[key] = false
      }
    }
  }

  private func cleanupExpiredStates(currentTimestamp: TimeInterval) {
    let expirationThreshold = detection * 2
    for key in SwiftShortcut.allCases {
      if let lastTimestamp = modifierKeyTimestamps[key],
         currentTimestamp - lastTimestamp > expirationThreshold {
        modifierKeyTimestamps[key] = 0
        modifierKeyStates[key] = false
      }
    }
  }

  private func shouldTriggerAction(key: SwiftShortcut, lastTimestamp: TimeInterval, currentTimestamp: TimeInterval) -> Bool {
    guard !otherKeyPressed else { return false }
    return lastWindowShortcut == key && (currentTimestamp - lastTimestamp) < detection && !isActionTriggered
  }
}
