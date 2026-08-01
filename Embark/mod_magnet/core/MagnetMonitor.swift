import SwiftUI
import ApplicationServices

class MagnetMonitor {
  static let s = MagnetMonitor()
  private var modifierKeyListener: KeyboardListener?
  private var isActive: Bool = false

  private init() {}

  func Start() {
    setupKeyboardHandling()
  }

  func Stop() {
    cleanupKeyboardHandling()
  }

  func notifyControlCompleted() {
    isActive = false
  }

  private func setupKeyboardHandling() {
    cleanupKeyboardHandling()
    modifierKeyListener = InputEventManager.s.createModifierKeyListener { [weak self] type, event in
      guard let self = self else { return Unmanaged.passUnretained(event) }
      let flags = event.flags
      let magnetDragActive = flags.contains(MagnetConfig.magnetDragShortcut.flags)
      let magnetResizeActive = flags.contains(MagnetConfig.magnetResizeShortcut.flags)
      if self.isActive {
        if !magnetDragActive && !magnetResizeActive {
          WindowDrag.s.stop()
          WindowResize.s.stop()
          self.isActive = false
        }
        return Unmanaged.passUnretained(event)
      }
      if magnetDragActive {
        self.isActive = true
        NotificationCenter.default.post(name: NSNotification.Name("FunctionExecuted"), object: nil, userInfo: ["source": FeatureType.magnet.title])
        _ = WindowDrag.s.startMagnetDrag()
      } else if magnetResizeActive {
        self.isActive = true
        NotificationCenter.default.post(name: NSNotification.Name("FunctionExecuted"), object: nil, userInfo: ["source": FeatureType.magnet.title])
        _ = WindowResize.s.startMagnetResize()
      }
      return Unmanaged.passUnretained(event)
    }
  }

  private func cleanupKeyboardHandling() {
    if let listener = modifierKeyListener {
      InputEventManager.s.unregisterListener(listener)
      modifierKeyListener = nil
    }
  }
}
