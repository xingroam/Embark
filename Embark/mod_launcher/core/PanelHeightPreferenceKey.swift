import SwiftUI

struct PanelHeightPreferenceKey: PreferenceKey {
  static var defaultValue: [Int64: CGFloat] = [:]
  static func reduce(value: inout [Int64: CGFloat], nextValue: () -> [Int64: CGFloat]) {
    value.merge(nextValue()) { _, new in new }
  }
}
