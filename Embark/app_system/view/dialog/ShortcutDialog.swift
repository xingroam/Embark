import SwiftUI
import ApplicationServices

struct ShortcutDialog: View {
  let title: String
  var description: String = ""
  @Binding var isPresented: Bool
  @Binding var shortcutKey: CGKeyCode
  @Binding var shortcutFlags: CGEventFlags
  var onSave: ((CGKeyCode?, CGEventFlags?) -> Void)? = nil
  @State private var currentKeyCode: CGKeyCode?
  @State private var currentFlags: CGEventFlags = CGEventFlags()
  @State private var hasChanges = false
  @StateObject private var recorder = ShortcutRecorder.s

  var body: some View {
    VStack(spacing: 20) {
      VStack(spacing: 5) {
        Text(title)
          .font(.title2)
          .fontWeight(.semibold)
        if !description.isEmpty {
          Text(description)
            .font(.system(size: 12))
            .foregroundColor(.secondary)
        }
      }
      Button(action: {
        if recorder.recordingState.isRecording {
          recorder.stopRecording()
        } else {
          startRecording()
        }
      }) {
        HStack(spacing: 5) {
          if recorder.recordingState.isRecording {
            Text(NSLocalizedString("system.shortcut.dialog.recording", comment: ""))
              .foregroundColor(.white)
          } else if let keyCode = currentKeyCode {
            Text(Keyboard.fullNameShortcut(keyCode: keyCode, flags: currentFlags))
              .foregroundColor(.white)
          } else {
            Text(NSLocalizedString("system.shortcut.dialog.click_to_set", comment: ""))
              .foregroundColor(.white)
          }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(recorder.recordingState.isRecording ? Color.orange : Color.accentColor)
        .cornerRadius(100)
      }
      .buttonStyle(PlainButtonStyle())
      HStack(spacing: 10) {
        Button(NSLocalizedString("system.shortcut.dialog.clear_shortcut", comment: "")) {
          clearShortcut()
        }
        .buttonStyle(.bordered)
        .disabled(currentKeyCode == nil)
        Spacer()
        Button(NSLocalizedString("system.message.cancel", comment: "")) {
          isPresented = false
        }
        .buttonStyle(.bordered)
        if hasChanges {
          Button(NSLocalizedString("system.message.confirm", comment: "")) {
            saveShortcut()
          }
          .buttonStyle(.borderedProminent)
        } else {
          Button(NSLocalizedString("system.message.confirm", comment: "")) {
            saveShortcut()
          }
          .buttonStyle(.bordered)
          .disabled(true)
        }
      }
    }
    .padding(20)
    .frame(width: 400)
    .background(BlurredBackground(material: .underWindowBackground, blendingMode: .behindWindow, blur: 1.0))
    .onAppear {
      loadCurrentShortcut()
    }
    .onDisappear {
      recorder.stopRecording()
    }
    .onReceive(NotificationCenter.default.publisher(for: NSApplication.willResignActiveNotification)) { _ in
      recorder.stopRecording()
    }
  }

  private func loadCurrentShortcut() {
    currentKeyCode = shortcutKey
    currentFlags = shortcutFlags
    hasChanges = false
  }

  private func startRecording() {
    recorder.startRecording { keyCode, flags in
      DispatchQueue.main.async {
        currentKeyCode = keyCode
        currentFlags = flags
        checkForChanges()
      }
    }
  }

  private func checkForChanges() {
    hasChanges = (currentKeyCode != shortcutKey || currentFlags != shortcutFlags)
  }

  private func clearShortcut() {
    recorder.clearShortcut()
    currentKeyCode = nil
    currentFlags = CGEventFlags()
    hasChanges = true
  }

  private func saveShortcut() {
    if let onSave = onSave {
      onSave(currentKeyCode, currentFlags)
    } else {
      if let keyCode = currentKeyCode {
        shortcutKey = keyCode
        shortcutFlags = currentFlags
      } else {
        shortcutKey = .disabled
        shortcutFlags = .disabled
      }
    }
    isPresented = false
  }
}
