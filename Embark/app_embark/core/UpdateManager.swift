import Foundation
import AppKit

#if canImport(Sparkle)
import Sparkle
#endif

enum UpdateState {
  case idle
  case checking
  case error(String)
}

final class UpdateManager: ObservableObject {
  static let s = UpdateManager()

  private let languageManager = LanguageManager.s

  @Published private(set) var state: UpdateState = .idle

  #if canImport(Sparkle)
  private let updaterController: SPUStandardUpdaterController
  #endif

  var isCheckingForUpdates: Bool {
    if case .checking = state {
      return true
    }
    return false
  }

  private init() {
    #if canImport(Sparkle)
    updaterController = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)
    #endif
  }

  func checkUpdateDialog() {
    checkForUpdates()
  }

  func checkForUpdates(hasUpdateShowDialog: Bool = false) {
    _ = hasUpdateShowDialog
    DispatchQueue.main.async {
      self.state = .checking
      #if canImport(Sparkle)
      self.updaterController.checkForUpdates(nil)
      self.state = .idle
      #else
      let failedText = self.languageManager.localizedString("embark.update.error.check_failed")
      self.state = .error(failedText)
      let alert = NSAlert()
      alert.messageText = self.languageManager.localizedString("embark.update.dialog.error.title")
      alert.informativeText = failedText
      alert.addButton(withTitle: self.languageManager.localizedString("system.info.ok"))
      alert.runModal()
      #endif
    }
  }
}
