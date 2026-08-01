import Foundation
import ApplicationServices
import SwiftUI

class InputEventManager: ObservableObject {
  static let s = InputEventManager()
  private var eventTap: CFMachPort?
  private var runLoopSource: CFRunLoopSource?
  private var mouseListeners: [MouseEventListener] = []
  private var keyboardListeners: [KeyboardEventListener] = []
  private var isActive: Bool = false
  private var cachedEventMask: CGEventMask = 0
  private var needsEventMaskUpdate: Bool = true

  // Mouse specific
  private var mouseEventTypeListeners: [MouseEventType: [MouseEventListener]] = [:]
  private var lastMoveEventTime: TimeInterval = 0
  private var lastScrollEventTime: TimeInterval = 0
  var moveDebounceInterval: TimeInterval = 0.2
  var scrollDebounceInterval: TimeInterval = 0.1

  var hasActiveListeners: Bool {
    return mouseListeners.contains { $0.isEnabled } || keyboardListeners.contains { $0.isEnabled }
  }

  private init() {}

  // MARK: - Mouse Listener Creation
  func createMouseListener(eventTypes: [MouseEventType], callback: @escaping MouseEventCallback) -> MouseListener {
    let listener = MouseListener(eventTypes: eventTypes, callback: callback)
    registerMouseListener(listener)
    return listener
  }

  func createLeftClickListener(callback: @escaping MouseEventCallback) -> MouseListener {
    return createMouseListener(eventTypes: [.leftDown, .leftUp], callback: callback)
  }

  func createRightClickListener(callback: @escaping MouseEventCallback) -> MouseListener {
    return createMouseListener(eventTypes: [.rightDown, .rightUp], callback: callback)
  }

  func createMiddleClickListener(callback: @escaping MouseEventCallback) -> MouseListener {
    return createMouseListener(eventTypes: [.middleDown, .middleUp], callback: callback)
  }

  func createMoveListener(callback: @escaping MouseEventCallback) -> MouseListener {
    return createMouseListener(eventTypes: [.moved], callback: callback)
  }

  func createDragListener(callback: @escaping MouseEventCallback) -> MouseListener {
    return createMouseListener(eventTypes: [.dragged], callback: callback)
  }

  func createScrollListener(callback: @escaping MouseEventCallback) -> MouseListener {
    return createMouseListener(eventTypes: [.scrolled], callback: callback)
  }

  func createFullMouseListener(callback: @escaping MouseEventCallback) -> MouseListener {
    return createMouseListener(eventTypes: [.all], callback: callback)
  }

  // MARK: - Keyboard Listener Creation
  func createKeyboardListener(eventTypes: [KeyboardEventType], callback: @escaping KeyboardEventCallback) -> KeyboardListener {
    let listener = KeyboardListener(eventTypes: eventTypes, callback: callback)
    registerKeyboardListener(listener)
    return listener
  }

  func createModifierKeyListener(callback: @escaping KeyboardEventCallback) -> KeyboardListener {
    return createKeyboardListener(eventTypes: [.flagsChanged], callback: callback)
  }

  func createKeyDownListener(callback: @escaping KeyboardEventCallback) -> KeyboardListener {
    return createKeyboardListener(eventTypes: [.keyDown], callback: callback)
  }

  func createKeyUpListener(callback: @escaping KeyboardEventCallback) -> KeyboardListener {
    return createKeyboardListener(eventTypes: [.keyUp], callback: callback)
  }

  func createFullKeyboardListener(callback: @escaping KeyboardEventCallback) -> KeyboardListener {
    return createKeyboardListener(eventTypes: [.all], callback: callback)
  }

  // MARK: - Management
  func checkHealth() -> Bool {
    if hasActiveListeners && !isActive {
      Debug.print("Input event listener exception: has active listeners but not started, restarting...")
      stopMonitoring()
      startMonitoring()
      return false
    }
    if isActive {
      if let eventTap = eventTap {
        let isEnabled = CGEvent.tapIsEnabled(tap: eventTap)
        if !isEnabled {
          Debug.info("Input event listener has become invalid, restarting...")
          System.s.listenerCount += 1
          stopMonitoring()
          startMonitoring()
          return false
        }
      }
      return true
    }
    return true
  }

  func registerMouseListener(_ listener: MouseEventListener) {
    mouseListeners.append(listener)
    updateMouseEventTypeListeners()
    needsEventMaskUpdate = true
    updateMonitoringState()
  }

  func unregisterMouseListener(_ listener: MouseEventListener) {
    mouseListeners.removeAll { $0 === listener }
    updateMouseEventTypeListeners()
    needsEventMaskUpdate = true
    updateMonitoringState()
  }

  func registerKeyboardListener(_ listener: KeyboardEventListener) {
    keyboardListeners.append(listener)
    needsEventMaskUpdate = true
    updateMonitoringState()
  }

  func unregisterKeyboardListener(_ listener: KeyboardEventListener) {
    keyboardListeners.removeAll { $0 === listener }
    needsEventMaskUpdate = true
    updateMonitoringState()
  }

  func unregisterListener(_ listener: MouseEventListener) {
    unregisterMouseListener(listener)
  }

  func unregisterListener(_ listener: KeyboardEventListener) {
    unregisterKeyboardListener(listener)
  }

  func unregisterAllListeners() {
    mouseListeners.removeAll()
    keyboardListeners.removeAll()
    updateMouseEventTypeListeners()
    stopMonitoring()
  }

  private func updateMonitoringState() {
    if !isActive {
      if hasActiveListeners {
        startMonitoring()
      }
    } else {
      if !hasActiveListeners {
        stopMonitoring()
      } else {
        let newEventMask = buildEventMask()
        if newEventMask != cachedEventMask {
          stopMonitoring()
          startMonitoring()
        }
      }
    }
  }

  private func updateMouseEventTypeListeners() {
    mouseEventTypeListeners.removeAll()
    for listener in mouseListeners where listener.isEnabled {
      for eventType in listener.eventTypes {
        if mouseEventTypeListeners[eventType] == nil {
          mouseEventTypeListeners[eventType] = []
        }
        mouseEventTypeListeners[eventType]?.append(listener)
      }
    }
  }

  private func startMonitoring() {
    guard !isActive, hasActiveListeners else { return }
    if needsEventMaskUpdate {
      cachedEventMask = buildEventMask()
      needsEventMaskUpdate = false
    }
    let eventTap = CGEvent.tapCreate(tap: .cgSessionEventTap, place: .headInsertEventTap, options: .defaultTap, eventsOfInterest: cachedEventMask, callback: { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
      return InputEventManager.s.handleEvent(type: type, event: event)
    }, userInfo: nil)
    guard let eventTap = eventTap else {
      return
    }
    self.eventTap = eventTap
    let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
    self.runLoopSource = runLoopSource
    CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
    CGEvent.tapEnable(tap: eventTap, enable: true)
    isActive = true
  }

  private func stopMonitoring() {
    guard isActive else { return }
    if let eventTap = eventTap {
      CGEvent.tapEnable(tap: eventTap, enable: false)
      CFMachPortInvalidate(eventTap)
    }
    if let runLoopSource = runLoopSource {
      CFRunLoopRemoveSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
    }
    self.eventTap = nil
    self.runLoopSource = nil
    isActive = false
  }

  private func buildEventMask() -> CGEventMask {
    var eventMask: CGEventMask = 0

    // Mouse Mask
    for listener in mouseListeners where listener.isEnabled {
      for eventType in listener.eventTypes {
        switch eventType {
        case .leftDown:
          eventMask |= (1 << CGEventType.leftMouseDown.rawValue)
        case .leftUp:
          eventMask |= (1 << CGEventType.leftMouseUp.rawValue)
        case .rightDown:
          eventMask |= (1 << CGEventType.rightMouseDown.rawValue)
        case .rightUp:
          eventMask |= (1 << CGEventType.rightMouseUp.rawValue)
        case .middleDown:
          eventMask |= (1 << CGEventType.otherMouseDown.rawValue)
        case .middleUp:
          eventMask |= (1 << CGEventType.otherMouseUp.rawValue)
        case .moved:
          eventMask |= (1 << CGEventType.mouseMoved.rawValue)
        case .dragged:
          eventMask |= (1 << CGEventType.leftMouseDragged.rawValue) | (1 << CGEventType.rightMouseDragged.rawValue) | (1 << CGEventType.otherMouseDragged.rawValue)
        case .rightDragged:
          eventMask |= (1 << CGEventType.rightMouseDragged.rawValue)
        case .scrolled:
          eventMask |= (1 << CGEventType.scrollWheel.rawValue)
        case .all:
          let leftMouseEvents = UInt64(1 << CGEventType.leftMouseDown.rawValue) | UInt64(1 << CGEventType.leftMouseUp.rawValue)
          let rightMouseEvents = UInt64(1 << CGEventType.rightMouseDown.rawValue) | UInt64(1 << CGEventType.rightMouseUp.rawValue)
          let otherMouseEvents = UInt64(1 << CGEventType.otherMouseDown.rawValue) | UInt64(1 << CGEventType.otherMouseUp.rawValue)
          let moveEvents = UInt64(1 << CGEventType.mouseMoved.rawValue)
          let dragEvents = UInt64(1 << CGEventType.leftMouseDragged.rawValue) | UInt64(1 << CGEventType.rightMouseDragged.rawValue) | UInt64(1 << CGEventType.otherMouseDragged.rawValue)
          let scrollEvents = UInt64(1 << CGEventType.scrollWheel.rawValue)
          eventMask |= leftMouseEvents | rightMouseEvents | otherMouseEvents | moveEvents | dragEvents | scrollEvents
        }
      }
    }

    // Keyboard Mask
    for listener in keyboardListeners where listener.isEnabled {
      for eventType in listener.eventTypes {
        switch eventType {
        case .keyDown:
          eventMask |= (1 << CGEventType.keyDown.rawValue)
        case .keyUp:
          eventMask |= (1 << CGEventType.keyUp.rawValue)
        case .flagsChanged:
          eventMask |= (1 << CGEventType.flagsChanged.rawValue)
        case .all:
          eventMask |= (1 << CGEventType.keyDown.rawValue) | (1 << CGEventType.keyUp.rawValue) | (1 << CGEventType.flagsChanged.rawValue)
        }
      }
    }

    return eventMask
  }

  private func handleEvent(type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
    // Handle Mouse Events
    if isMouseEvent(type) {
      let mouseEventType = convertToMouseEventType(type)
      let currentTime = CFAbsoluteTimeGetCurrent()
      if mouseEventType == .moved {
        if currentTime - lastMoveEventTime < moveDebounceInterval {
          return Unmanaged.passUnretained(event)
        }
        lastMoveEventTime = currentTime
      } else if mouseEventType == .scrolled {
        if currentTime - lastScrollEventTime < scrollDebounceInterval {
          return Unmanaged.passUnretained(event)
        }
        lastScrollEventTime = currentTime
      }

      var relevantListeners: [MouseEventListener] = []
      if let listeners = mouseEventTypeListeners[mouseEventType] {
        relevantListeners.append(contentsOf: listeners)
      }
      if let allListeners = mouseEventTypeListeners[.all] {
        relevantListeners.append(contentsOf: allListeners)
      }

      for listener in relevantListeners where listener.isEnabled {
        let result = listener.callback(mouseEventType, event)
        if result == nil {
          return nil
        }
      }
    }
    // Handle Keyboard Events
    else if isKeyboardEvent(type) {
      let activeListeners = keyboardListeners.filter { $0.isEnabled }
      for listener in activeListeners {
        if listener.eventTypes.contains(.all) || listener.eventTypes.contains(where: { eventType in
          switch eventType {
          case .keyDown: return type == .keyDown
          case .keyUp: return type == .keyUp
          case .flagsChanged: return type == .flagsChanged
          case .all: return true
          }
        }) {
          let result = listener.callback(type, event)
          if result == nil {
            return nil
          }
        }
      }
    }

    return Unmanaged.passUnretained(event)
  }

  private func isMouseEvent(_ type: CGEventType) -> Bool {
    switch type {
    case .leftMouseDown, .leftMouseUp, .rightMouseDown, .rightMouseUp, .otherMouseDown, .otherMouseUp, .mouseMoved, .leftMouseDragged, .rightMouseDragged, .otherMouseDragged, .scrollWheel:
      return true
    default:
      return false
    }
  }

  private func isKeyboardEvent(_ type: CGEventType) -> Bool {
    switch type {
    case .keyDown, .keyUp, .flagsChanged:
      return true
    default:
      return false
    }
  }

  private func convertToMouseEventType(_ type: CGEventType) -> MouseEventType {
    switch type {
    case .leftMouseDown: return .leftDown
    case .leftMouseUp: return .leftUp
    case .rightMouseDown: return .rightDown
    case .rightMouseUp: return .rightUp
    case .otherMouseDown: return .middleDown
    case .otherMouseUp: return .middleUp
    case .mouseMoved: return .moved
    case .leftMouseDragged: return .dragged
    case .rightMouseDragged: return .rightDragged
    case .otherMouseDragged: return .dragged
    case .scrollWheel: return .scrolled
    default: return .moved
    }
  }
}
