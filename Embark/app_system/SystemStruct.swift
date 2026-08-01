import SwiftUI

enum SystemUI: Int, CaseIterable, Identifiable, Codable {
  case showAll = 0
  case hideMenuBar = 1
  case hideDock = 2
  case hideBoth = 3

  var id: Int { self.rawValue }

  var displayName: String {
    switch self {
    case .showAll:
      return NSLocalizedString("system.systemui.showAll", comment: "")
    case .hideMenuBar:
      return NSLocalizedString("system.systemui.hideMenuBar", comment: "")
    case .hideDock:
      return NSLocalizedString("system.systemui.hideDock", comment: "")
    case .hideBoth:
      return NSLocalizedString("system.systemui.hideBoth", comment: "")
    }
  }
}

enum WindowFocusState {
  case windowFocused(WindowData)
  case noWindowFocused
}

enum TooltipDirection {
  case top
  case bottom
}

struct WindowData: Hashable {
  let pid: pid_t
  let wid: CGWindowID
  let app: String
  let bundleIdentifier: String?
  let bounds: CGRect
  let element: AXUIElement?
  let layer: Int  // CGWindow layer (0=normal, 3=floating, etc.)
  let title: String?
  let isMinimized: Bool
  let isTimeout: Bool

  init(pid: pid_t = 0, wid: CGWindowID = 0, app: String = "", bundleIdentifier: String? = nil, bounds: CGRect, element: AXUIElement? = nil, layer: Int = 0, title: String? = nil, isMinimized: Bool = false, isTimeout: Bool = false) {
    self.pid = pid
    self.wid = wid
    self.app = app
    self.bundleIdentifier = bundleIdentifier
    self.bounds = bounds
    self.element = element
    self.layer = layer
    self.title = title
    self.isMinimized = isMinimized
    self.isTimeout = isTimeout
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(pid)
    hasher.combine(wid)
    hasher.combine(app)
    hasher.combine(bundleIdentifier)
    hasher.combine(bounds.origin.x)
    hasher.combine(bounds.origin.y)
    hasher.combine(bounds.size.width)
    hasher.combine(bounds.size.height)
    hasher.combine(layer)
    hasher.combine(title)
  }

  static func == (lhs: WindowData, rhs: WindowData) -> Bool {
    return lhs.pid == rhs.pid && lhs.wid == rhs.wid && lhs.app == rhs.app && lhs.bundleIdentifier == rhs.bundleIdentifier && lhs.bounds == rhs.bounds && lhs.layer == rhs.layer && lhs.title == rhs.title
  }
}

enum ButtonStyle {
  case primary, secondary

  var backgroundColor: Color {
    switch self {
    case .primary:
      return Color.accentColor
    case .secondary:
      return Color.secondary.opacity(0.1)
    }
  }
  var foregroundColor: Color {
    switch self {
    case .primary:
      return .white
    case .secondary:
      return .primary
    }
  }
  var borderColor: Color {
    switch self {
    case .primary:
      return Color.accentColor
    case .secondary:
      return Color.secondary.opacity(0.3)
    }
  }
  var hoverBackgroundColor: Color {
    switch self {
    case .primary:
      return Color.accentColor.opacity(0.8)
    case .secondary:
      return Color.secondary.opacity(0.2)
    }
  }
}

enum ButtonSize {
  case tiny, small, normal, medium, large

  var paddingHorizontal: CGFloat {
    switch self {
    case .tiny:
      return 4
    case .small:
      return 6
    case .normal:
      return 8
    case .medium:
      return 10
    case .large:
      return 12
    }
  }
  var paddingVertical: CGFloat {
    switch self {
    case .tiny:
      return 1
    case .small:
      return 2
    case .normal:
      return 4
    case .medium:
      return 6
    case .large:
      return 8
    }
  }
  var fontSize: CGFloat {
    switch self {
    case .tiny:
      return 10
    case .small:
      return 11
    case .normal:
      return 12
    case .medium:
      return 14
    case .large:
      return 16
    }
  }
  var cornerRadius: CGFloat {
    switch self {
    case .tiny:
      return 5
    case .small:
      return 5
    case .normal:
      return 5
    case .medium:
      return 5
    case .large:
      return 5
    }
  }
}

struct CacheData: Sendable {
  let data: Data
  let timestamp: TimeInterval

  var date: Date {
    return Date(timeIntervalSince1970: timestamp)
  }

  init(data: Data, timestamp: Date) {
    self.data = data
    self.timestamp = timestamp.timeIntervalSince1970
  }
}

enum CacheNetError: Error {
  case invalidURL
  case networkError
}
