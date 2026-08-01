import SwiftUI
import ApplicationServices

enum SwiftMouseDirection: String {
  case up = "Up"
  case down = "Down"
  case left = "Left"
  case right = "Right"
  case unknown = "Unknown"

  static func from(deltaX: CGFloat, deltaY: CGFloat) -> SwiftMouseDirection {
    if abs(deltaY) > abs(deltaX) {
      return deltaY > 0 ? .down : .up
    } else {
      return deltaX > 0 ? .right : .left
    }
  }
}

enum SwiftMouseGesture: String, Codable, CaseIterable {
  case none
  case up
  case down
  case left
  case right
  case upLeft
  case upRight
  case downLeft
  case downRight
  case leftUp
  case leftDown
  case rightUp
  case rightDown

  var symbol: String {
    switch self {
    case .none: return "nosign"
    case .up: return "arrow.up"
    case .down: return "arrow.down"
    case .left: return "arrow.left"
    case .right: return "arrow.right"
    case .upLeft: return "arrow.turn.up.left"
    case .upRight: return "arrow.turn.up.right"
    case .downLeft: return "arrow.turn.down.left"
    case .downRight: return "arrow.turn.down.right"
    case .leftUp: return "arrow.turn.left.up"
    case .leftDown: return "arrow.turn.left.down"
    case .rightUp: return "arrow.turn.right.up"
    case .rightDown: return "arrow.turn.right.down"
    }
  }

  var direction: SwiftMouseDirection {
    switch self {
    case .none: return .unknown
    case .up: return .up
    case .down: return .down
    case .left: return .left
    case .right: return .right
    case .upLeft: return .left
    case .upRight: return .right
    case .downLeft: return .left
    case .downRight: return .right
    case .leftUp: return .up
    case .leftDown: return .down
    case .rightUp: return .up
    case .rightDown: return .down
    }
  }

  func matches(_ directions: [SwiftMouseDirection]) -> Bool {
    if directions.isEmpty { return false }
    switch self {
    case .none: return false
    case .up: return directions == [.up]
    case .down: return directions == [.down]
    case .left: return directions == [.left]
    case .right: return directions == [.right]
    case .upLeft: return directions == [.up, .left]
    case .upRight: return directions == [.up, .right]
    case .downLeft: return directions == [.down, .left]
    case .downRight: return directions == [.down, .right]
    case .leftUp: return directions == [.left, .up]
    case .leftDown: return directions == [.left, .down]
    case .rightUp: return directions == [.right, .up]
    case .rightDown: return directions == [.right, .down]
    }
  }
}

enum SwiftMouseDragState {
  case idle
  case waiting(point: CGPoint, timestamp: TimeInterval)
  case dragging(startPoint: CGPoint, currentPoint: CGPoint, path: [CGPoint])
}

struct SwiftMouseExcludeApp: Identifiable, Equatable {
  var id: String { bundleId }
  let title: String
  let bundleId: String
  var enabled: Bool
}
