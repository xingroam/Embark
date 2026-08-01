import SwiftUI

struct SwitcherWindowInfo: Identifiable, Hashable {
  let id: CGWindowID
  let ownerName: String
  let name: String
  let ownerPID: pid_t
  let frame: CGRect
  var icon: NSImage?
  let isMinimized: Bool
  let element: AXUIElement?
  var isTimeout: Bool = false

  func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }

  static func == (lhs: SwitcherWindowInfo, rhs: SwitcherWindowInfo) -> Bool {
    lhs.id == rhs.id
  }
}

enum SwitcherSize: String, Codable, CaseIterable, Identifiable {
  case small = "small"
  case medium = "medium"
  case large = "large"

  var id: String { self.rawValue }

  var title: String {
    switch self {
    case .small: return NSLocalizedString("switcher.size.small", comment: "")
    case .medium: return NSLocalizedString("switcher.size.medium", comment: "")
    case .large: return NSLocalizedString("switcher.size.large", comment: "")
    }
  }

  var iconSize: CGFloat {
    switch self {
    case .small: return 34
    case .medium: return 42
    case .large: return 50
    }
  }

  var textSize: CGFloat {
    switch self {
    case .small: return 12
    case .medium: return 14
    case .large: return 16
    }
  }

  var padding: CGFloat {
    switch self {
    case .small: return 6
    case .medium: return 8
    case .large: return 10
    }
  }
}

enum SwitcherMode: String, Codable, CaseIterable, Identifiable {
  case switchMode = "switch"
  case selectMode = "select"
  case shortcutMode = "shortcut"

  var id: String { self.rawValue }

  var title: String {
    switch self {
    case .switchMode: return NSLocalizedString("switcher.mode.switch", comment: "")
    case .selectMode: return NSLocalizedString("switcher.mode.select", comment: "")
    case .shortcutMode: return ""
    }
  }

  static var displayCases: [SwitcherMode] {
    return [.switchMode, .selectMode]
  }
}
