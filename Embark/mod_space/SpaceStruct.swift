import Foundation
import CoreGraphics
import SwiftUI

enum SpaceScreen: String, CaseIterable, Identifiable {
  case all = "All"
  case current = "Current"

  var id: String { self.rawValue }

  var displayName: String {
    switch self {
    case .all: return NSLocalizedString("space.screen.all", comment: "")
    case .current: return NSLocalizedString("space.screen.current", comment: "")
    }
  }
}

enum SpaceRestoreMode: String, Codable, CaseIterable, Identifiable {
  case keep = "Keep"
  case minimize = "Minimize"
  case close = "Close"

  var id: String { self.rawValue }

  var displayName: String {
    switch self {
    case .keep: return NSLocalizedString("space.restore.mode.keep", comment: "")
    case .minimize: return NSLocalizedString("space.restore.mode.minimize", comment: "")
    case .close: return NSLocalizedString("space.restore.mode.close", comment: "")
    }
  }
}
