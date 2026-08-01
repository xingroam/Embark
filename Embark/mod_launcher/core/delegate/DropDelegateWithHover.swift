import SwiftUI

// 带悬停效果的拖动代理包装器
struct DropDelegateWithHover: DropDelegate {
  let originalDelegate: any DropDelegate
  let onHoverChanged: (Bool) -> Void
  let onDragEnded: () -> Void

  func performDrop(info: DropInfo) -> Bool {
    onHoverChanged(false)
    onDragEnded()
    DataManager.s.setDraggingState(false)
    return originalDelegate.performDrop(info: info)
  }

  func dropEntered(info: DropInfo) {
    onHoverChanged(true)
    originalDelegate.dropEntered(info: info)
  }

  func dropExited(info: DropInfo) {
    onHoverChanged(false)
    DataManager.s.setDraggingState(false)
    originalDelegate.dropExited(info: info)
  }

  func dropUpdated(info: DropInfo) -> DropProposal? {
    return originalDelegate.dropUpdated(info: info)
  }

  func validateDrop(info: DropInfo) -> Bool {
    return originalDelegate.validateDrop(info: info)
  }
}
