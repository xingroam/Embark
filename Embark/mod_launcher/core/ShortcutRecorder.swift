import Foundation
import ApplicationServices
import SwiftUI

struct RecordingState {
  var isRecording: Bool = false
  var currentKeyCode: CGKeyCode?
  var currentFlags: CGEventFlags = CGEventFlags()
}

class ShortcutRecorder: ObservableObject {
  static let s = ShortcutRecorder()
  @Published private(set) var recordingState = RecordingState()
  private var eventTap: CFMachPort?
  private var runLoopSource: CFRunLoopSource?
  private var onShortcutRecorded: ((CGKeyCode, CGEventFlags) -> Void)?

  private init() {}

  deinit {
    cleanupEventTap()
  }

  func startRecording(onShortcutRecorded: @escaping (CGKeyCode, CGEventFlags) -> Void) {
    cleanupEventTap()
    self.onShortcutRecorded = onShortcutRecorded
    updateRecordingState(RecordingState(
      isRecording: true,
      currentKeyCode: nil,
      currentFlags: CGEventFlags()
    ))
    createEventTap()
  }

  func stopRecording() {
    updateRecordingState(RecordingState(
      isRecording: false,
      currentKeyCode: recordingState.currentKeyCode,
      currentFlags: recordingState.currentFlags
    ))
    cleanupEventTap()
  }

  func clearShortcut() {
    updateRecordingState(RecordingState(
      isRecording: recordingState.isRecording,
      currentKeyCode: nil,
      currentFlags: CGEventFlags()
    ))
  }

  private func updateRecordingState(_ newState: RecordingState) {
    DispatchQueue.main.async { [weak self] in
      guard let self = self else { return }
      recordingState = newState
    }
  }

  private func createEventTap() {
    let eventMask = CGEventMask(
      (1 << CGEventType.flagsChanged.rawValue) |
      (1 << CGEventType.keyDown.rawValue)
    )
    eventTap = CGEvent.tapCreate(tap: .cgSessionEventTap, place: .headInsertEventTap, options: .defaultTap, eventsOfInterest: eventMask, callback: { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in Unmanaged<ShortcutRecorder>.fromOpaque(refcon!).takeUnretainedValue().handleEvent(type: type, event: event) }, userInfo: UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()))
    if let eventTap = eventTap {
      runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
      if let runLoopSource = runLoopSource {
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: eventTap, enable: true)
      }
    }
  }

  private func handleEvent(type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
    guard recordingState.isRecording else {
      return Unmanaged.passUnretained(event)
    }
    if type == .flagsChanged {
      let flags = event.flags.modifierOnly
      DispatchQueue.main.async { [weak self] in
        guard let self = self else { return }
        recordingState.currentFlags = flags
      }
    } else if type == .keyDown {
      let keyCode = CGKeyCode(event.getIntegerValueField(.keyboardEventKeycode))
      let flags = event.flags.modifierOnly
      DispatchQueue.main.async { [weak self] in
        guard let self = self else { return }
        recordingState.currentKeyCode = keyCode
        recordingState.currentFlags = flags
        recordingState.isRecording = false
        onShortcutRecorded?(keyCode, flags)
        cleanupEventTap()
      }
    }
    return Unmanaged.passUnretained(event)
  }

  private func cleanupEventTap() {
    if let eventTap = eventTap {
      CGEvent.tapEnable(tap: eventTap, enable: false)
      CFMachPortInvalidate(eventTap)
    }
    eventTap = nil
    runLoopSource = nil
  }
}
