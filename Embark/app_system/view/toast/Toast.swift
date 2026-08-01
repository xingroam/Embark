import SwiftUI

class Toast {
  static let s = Toast()

  private init() {}

  static func bottomCenter(title: String? = nil, message: String, icon: Image? = Image("StatusBarIcon"), duration: TimeInterval = 1.0) {
    DispatchQueue.main.async {
      let m = title != nil ? "\(title!): \(message)" : message
      ToastWin.s.showToast(message: m, icon: icon, duration: duration, position: .bottomCenter(50))
    }
  }

  static func showPersistent(message: String, icon: Image? = Image("StatusBarIcon")) {
    DispatchQueue.main.async {
      ToastWin.s.showToast(message: message, icon: icon, position: .bottomCenter(50), isPersistent: true)
    }
  }

  static func hide() {
    DispatchQueue.main.async {
      ToastWin.s.hideToast()
    }
  }
}
