import SwiftUI

extension CGRect {
  func distance(to p: CGPoint) -> CGFloat {
    let cx = max(min(p.x, maxX), minX)
    let cy = max(min(p.y, maxY), minY)
    return hypot(p.x - cx, p.y - cy)
  }
}
