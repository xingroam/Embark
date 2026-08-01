import SwiftUI

extension Array where Element: Hashable {
  func mostCommon() -> Element? {
    let counts = self.reduce(into: [:]) { counts, element in
      counts[element, default: 0] += 1
    }
    return counts.max(by: { $0.value < $1.value })?.key
  }
}
