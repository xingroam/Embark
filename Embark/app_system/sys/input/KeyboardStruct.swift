import SwiftUI

class KeyboardListener: KeyboardEventListener {
  let eventTypes: [KeyboardEventType]
  let callback: KeyboardEventCallback
  var isEnabled: Bool = true

  init(eventTypes: [KeyboardEventType], callback: @escaping KeyboardEventCallback) {
    self.eventTypes = eventTypes
    self.callback = callback
  }
}
