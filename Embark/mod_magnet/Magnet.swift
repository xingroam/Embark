import SwiftUI

class Magnet {
  static let s = Magnet()
  private var isRunning: Bool = false

  func Boot() {
    if UserDefaults.standard.object(forKey: MagnetConfig.magnetKey) == nil {
      MagnetConfig.magnet = MagnetDefine.magnet
    }
    if UserDefaults.standard.object(forKey: MagnetConfig.magnetDragShortcutKey) == nil {
      MagnetConfig.magnetDragShortcut = MagnetDefine.magnetDragShortcut
    }
    if UserDefaults.standard.object(forKey: MagnetConfig.magnetResizeShortcutKey) == nil {
      MagnetConfig.magnetResizeShortcut = MagnetDefine.magnetResizeShortcut
    }
    if UserDefaults.standard.object(forKey: MagnetConfig.magnet3x2Key) == nil {
      MagnetConfig.magnet2x2 = MagnetDefine.magnet2x2
    }
    if UserDefaults.standard.object(forKey: MagnetConfig.magnet3x2Key) == nil {
      MagnetConfig.magnet3x2 = MagnetDefine.magnet3x2
    }
    if UserDefaults.standard.object(forKey: MagnetConfig.magnet3x3Key) == nil {
      MagnetConfig.magnet3x3 = MagnetDefine.magnet3x3
    }
    if UserDefaults.standard.object(forKey: MagnetConfig.magnet4x2Key) == nil {
      MagnetConfig.magnet4x2 = MagnetDefine.magnet4x2
    }
    if UserDefaults.standard.object(forKey: MagnetConfig.magnet4x4Key) == nil {
      MagnetConfig.magnet4x4 = MagnetDefine.magnet4x4
    }
    if UserDefaults.standard.object(forKey: MagnetConfig.magnet6x6Key) == nil {
      MagnetConfig.magnet6x6 = MagnetDefine.magnet6x6
    }
    if UserDefaults.standard.object(forKey: MagnetConfig.magnet8x8Key) == nil {
      MagnetConfig.magnet8x8 = MagnetDefine.magnet8x8
    }
    if UserDefaults.standard.object(forKey: MagnetConfig.magnet10x10Key) == nil {
      MagnetConfig.magnet10x10 = MagnetDefine.magnet10x10
    }
    if UserDefaults.standard.object(forKey: MagnetConfig.magnet12x12Key) == nil {
      MagnetConfig.magnet12x12 = MagnetDefine.magnet12x12
    }
    if UserDefaults.standard.object(forKey: MagnetConfig.magnetTipKey) == nil {
      MagnetConfig.magnetTip = MagnetDefine.magnetTip
    }
    NotificationCenter.default.addObserver(forName: NSNotification.Name("MagnetConfigChanged"), object: nil, queue: .main) { [weak self] _ in
      guard let self = self else { return }
      if Start() {
        return
      }
      if Stop() {
        return
      }
    }
    _ = Start()
  }

  func Start() -> Bool {
    if MagnetConfig.magnet {
      if !isRunning {
        isRunning = true
        MagnetMonitor.s.Start()
        return true
      }
    }
    return false
  }

  func Stop(end: Bool = false) -> Bool {
    if !MagnetConfig.magnet || end {
      if isRunning {
        isRunning = false
        MagnetMonitor.s.Stop()
        return true
      }
    }
    return false
  }

  func ResetToFree(_ msg: Bool = true) {
    if MagnetConfig.magnet2x2 == MagnetFree.magnet2x2 &&
       MagnetConfig.magnet3x3 == MagnetFree.magnet3x3 &&
       MagnetConfig.magnet4x2 == MagnetFree.magnet4x2 &&
       MagnetConfig.magnet4x4 == MagnetFree.magnet4x4 &&
       MagnetConfig.magnet6x6 == MagnetFree.magnet6x6 &&
       MagnetConfig.magnet8x8 == MagnetFree.magnet8x8 &&
       MagnetConfig.magnet10x10 == MagnetFree.magnet10x10 &&
       MagnetConfig.magnet12x12 == MagnetFree.magnet12x12 &&
       MagnetConfig.magnetTip == MagnetFree.magnetTip {
      return
    }
    MagnetConfig.magnet2x2 = MagnetFree.magnet2x2
    MagnetConfig.magnet3x2 = MagnetFree.magnet3x2
    MagnetConfig.magnet3x3 = MagnetFree.magnet3x3
    MagnetConfig.magnet4x2 = MagnetFree.magnet4x2
    MagnetConfig.magnet4x4 = MagnetFree.magnet4x4
    MagnetConfig.magnet6x6 = MagnetFree.magnet6x6
    MagnetConfig.magnet8x8 = MagnetFree.magnet8x8
    MagnetConfig.magnet10x10 = MagnetFree.magnet10x10
    MagnetConfig.magnet12x12 = MagnetFree.magnet12x12
    MagnetConfig.magnetTip = MagnetFree.magnetTip
    if msg {
      NotificationCenter.default.post(name: NSNotification.Name("MagnetConfigChanged"), object: nil)
    }
  }
}
