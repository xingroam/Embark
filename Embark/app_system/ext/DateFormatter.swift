import SwiftUI

extension DateFormatter {
  static let ts: DateFormatter = {
    let f = DateFormatter()
    f.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
    return f
  }()
}
