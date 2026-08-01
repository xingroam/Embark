import SwiftUI
import ApplicationServices

class PermissionManager {
  static let s = PermissionManager()

  private init() {}

  func CheckAccessibilityPermission() -> Bool {
    let hasPermission = AXIsProcessTrusted()
    if !hasPermission {
      OnboardingWin.s.Show(showWelcome: false)
      return false
    }
    return true
  }

  func isAccessibilityGranted() -> Bool {
    return AXIsProcessTrusted()
  }

  func openSystemPreferences() {
    let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
    AXIsProcessTrustedWithOptions(options)
  }

  func isAutomationGranted() -> Bool {
    let script = NSAppleScript(source: "tell application \"System Events\" to return name of first process")
    var error: NSDictionary?
    script?.executeAndReturnError(&error)
    return error == nil
  }

  func openAutomationPreferences() {
    if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Automation") {
      NSWorkspace.shared.open(url)
    }
  }

  func checkAutomationPermission(onGranted: @escaping () -> Void, onOpenSettings: (() -> Void)? = nil) {
    if isAutomationGranted() {
      onGranted()
      return
    }
    DispatchQueue.main.async {
      let alert = NSAlert()
      alert.messageText = NSLocalizedString("system.permission.automation.required.title", comment: "")
      alert.informativeText = NSLocalizedString("system.permission.automation.required.message", comment: "")
      alert.alertStyle = .warning
      alert.addButton(withTitle: NSLocalizedString("system.permission.automation.open_settings", comment: ""))
      alert.addButton(withTitle: NSLocalizedString("system.message.cancel", comment: ""))
      let response = alert.runModal()
      if response == .alertFirstButtonReturn {
        self.openAutomationPreferences()
        onOpenSettings?()
      }
    }
  }
}
