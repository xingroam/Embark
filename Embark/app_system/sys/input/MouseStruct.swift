import SwiftUI

enum MouseEventType {
  case leftDown
  case leftUp
  case rightDown
  case rightUp
  case middleDown
  case middleUp
  case moved
  case dragged
  case rightDragged
  case scrolled
  case all
}

typealias MouseEventCallback = (MouseEventType, CGEvent) -> Unmanaged<CGEvent>?

protocol MouseEventListener: AnyObject {
  var eventTypes: [MouseEventType] { get }
  var callback: MouseEventCallback { get }
  var isEnabled: Bool { get set }
}

class MouseListener: MouseEventListener {
  let eventTypes: [MouseEventType]
  let callback: MouseEventCallback
  var isEnabled: Bool = true

  init(eventTypes: [MouseEventType], callback: @escaping MouseEventCallback) {
    self.eventTypes = eventTypes
    self.callback = callback
  }
}
