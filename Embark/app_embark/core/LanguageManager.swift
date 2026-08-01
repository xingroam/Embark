import Foundation
import SwiftUI

class LanguageManager: ObservableObject {
  static let s = LanguageManager()
  let supportedLanguages: [LanguageOption] = [
    LanguageOption(code: "en", name: "English"),
    LanguageOption(code: "de", name: "Deutsch"),
    LanguageOption(code: "es", name: "Español"),
    LanguageOption(code: "fr", name: "Français"),
    LanguageOption(code: "it", name: "Italiano"),
    LanguageOption(code: "zh-Hans", name: "简体中文"),
    LanguageOption(code: "zh-Hant", name: "繁體中文"),
    LanguageOption(code: "ja", name: "日本語"),
    LanguageOption(code: "ko", name: "한국어")
  ]
  @Published var currentLanguage: String {
    didSet {
      setAppleLanguages([currentLanguage])
      updateAppLanguage()
    }
  }

  private init() {
    let appleLanguages = UserDefaults.standard.object(forKey: "AppleLanguages") as? [String] ?? []
    if let firstLanguage = appleLanguages.first, supportedLanguages.contains(where: { $0.code == firstLanguage }) {
      currentLanguage = firstLanguage
    } else {
      let systemLanguage = Locale.current.language.languageCode?.identifier ?? "en"
      let systemRegion = Locale.current.region?.identifier ?? ""
      if systemLanguage == "zh" {
        if systemRegion == "TW" || systemRegion == "HK" {
          currentLanguage = "zh-Hant"
        } else {
          currentLanguage = "zh-Hans"
        }
      } else if supportedLanguages.contains(where: { $0.code == systemLanguage }) {
        currentLanguage = systemLanguage
      } else {
        currentLanguage = "en"
      }
      setAppleLanguages([currentLanguage])
    }
  }

  func getCurrentLanguageDisplayName() -> String {
    if let language = supportedLanguages.first(where: { $0.code == currentLanguage }) {
      return language.name
    }
    return "English"
  }

  func getLanguageOption(for code: String) -> LanguageOption? {
    return supportedLanguages.first(where: { $0.code == code })
  }

  func localizedString(_ key: String) -> String {
    return NSLocalizedString(key, comment: "")
  }

  private func setAppleLanguages(_ languages: [String]) {
    UserDefaults.standard.set(languages, forKey: "AppleLanguages")
    NotificationCenter.default.post(name: NSNotification.Name("AppleLanguagesDidChange"), object: nil)
  }

  private func updateAppLanguage() {
    DispatchQueue.main.async { [weak self] in
      guard let self = self else { return }
      objectWillChange.send()
      CancelAlert.Show(message: localizedString("embark.appsettings.general.language.changed.message"), ok: localizedString("embark.appsettings.general.language.changed.restart"), cancel: localizedString("embark.appsettings.general.language.changed.later"), restart: true)
    }
  }

  func getLocalizedNotes(from notes: [String: String]) -> String {
    if let localizedNotes = notes[currentLanguage] {
      return localizedNotes
    }
    if let englishNotes = notes["en"] {
      return englishNotes
    }
    return notes.values.first ?? ""
  }
}
