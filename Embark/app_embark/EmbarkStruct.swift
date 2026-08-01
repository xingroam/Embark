import SwiftUI

struct AppIcon: Hashable, Identifiable {
  var id: String { assetName }
  var assetName: String
  var isDefault: Bool

  static let all: [AppIcon] = [
    .default,
    .black,
    .dev,
    .summer,
    .tech,
  ]

  static let `default` = AppIcon(
    assetName: "AppIcon",
    isDefault: true
  )

  static let black = AppIcon(
    assetName: "AppIcon-Black",
    isDefault: false
  )

  static let dev = AppIcon(
    assetName: "AppIcon-Dev",
    isDefault: false
  )

  static let summer = AppIcon(
    assetName: "AppIcon-Summer",
    isDefault: false
  )

  static let tech = AppIcon(
    assetName: "AppIcon-Tech",
    isDefault: false
  )
}

enum SettingsTab: String, CaseIterable {
  case general
  case about

  func title(customerActive: Bool) -> String {
    switch self {
    case .general:
      return NSLocalizedString("embark.struct.settings.tab.general", comment: "")
    case .about:
      return NSLocalizedString("embark.struct.settings.tab.about", comment: "")
    }
  }

  func icon(customerActive: Bool) -> String {
    switch self {
    case .general:
      return "gearshape"
    case .about:
      return "info.circle"
    }
  }
}

enum FeatureType: CaseIterable {
  case launcher
  case swift
  case magnet
  case space
  case focus
  case slide
  case switcher

  var title: String {
    switch self {
    case .launcher:
      return NSLocalizedString("embark.struct.feature.launcher.title", comment: "")
    case .swift:
      return NSLocalizedString("embark.struct.feature.swift.title", comment: "")
    case .magnet:
      return NSLocalizedString("embark.struct.feature.magnet.title", comment: "")
    case .space:
      return NSLocalizedString("embark.struct.feature.space.title", comment: "")
    case .focus:
      return NSLocalizedString("embark.struct.feature.focus.title", comment: "")
    case .slide:
      return NSLocalizedString("embark.struct.feature.slide.title", comment: "")
    case .switcher:
      return NSLocalizedString("embark.struct.feature.switcher.title", comment: "")
    }
  }

  var icon: String {
    switch self {
    case .launcher:
      return "square.grid.3x3"
    case .swift:
      return "macwindow"
    case .magnet:
      return "uiwindow.split.2x1"
    case .space:
      return "rectangle.3.group"
    case .focus:
      return "eye"
    case .slide:
      return "arrow.left.and.right.square"
    case .switcher:
      return "arrow.left.arrow.right"
    }
  }
}

struct LanguageOption: Identifiable, Hashable {
  let id = UUID()
  let code: String
  let name: String

  func hash(into hasher: inout Hasher) {
    hasher.combine(code)
  }

  static func == (lhs: LanguageOption, rhs: LanguageOption) -> Bool {
    return lhs.code == rhs.code
  }
}

enum AppTheme: String, CaseIterable {
  case system
  case light
  case dark

  var title: String {
    switch self {
    case .system:
      return NSLocalizedString("embark.config.theme.system", comment: "")
    case .light:
      return NSLocalizedString("embark.config.theme.light", comment: "")
    case .dark:
      return NSLocalizedString("embark.config.theme.dark", comment: "")
    }
  }

  var colorScheme: ColorScheme? {
    switch self {
    case .system:
      return nil
    case .light:
      return .light
    case .dark:
      return .dark
    }
  }
}


enum KeyboardEventType {
  case keyDown
  case keyUp
  case flagsChanged
  case all
}

protocol KeyboardEventListener: AnyObject {
  var eventTypes: [KeyboardEventType] { get }
  var callback: KeyboardEventCallback { get }
  var isEnabled: Bool { get set }
}

typealias KeyboardEventCallback = (CGEventType, CGEvent) -> Unmanaged<CGEvent>?
