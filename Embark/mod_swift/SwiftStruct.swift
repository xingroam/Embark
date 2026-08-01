import SwiftUI
import ApplicationServices

enum SwiftMaximizeMode: String, CaseIterable {
  case max = "Maximize"
  case full = "Fullscreen"

  var displayName: String {
    switch self {
    case .max:
      return NSLocalizedString("swift.struct.maximize.mode.max", comment: "")
    case .full:
      return NSLocalizedString("swift.struct.maximize.mode.full", comment: "")
    }
  }
}

enum SwiftCloseMode: String, CaseIterable {
  case standard = "Standard"
  case direct = "Direct"
  case force = "Force"

  var displayName: String {
    switch self {
    case .standard:
      return NSLocalizedString("swift.struct.close.mode.standard", comment: "")
    case .direct:
      return NSLocalizedString("swift.struct.close.mode.direct", comment: "")
    case .force:
      return NSLocalizedString("swift.struct.close.mode.force", comment: "")
    }
  }
}

struct SwiftMaxData: Hashable {
  let pid: pid_t
  let wid: CGWindowID

  init(pid: pid_t, wid: CGWindowID) {
    self.pid = pid
    self.wid = wid
  }

  init(windowData: WindowData) {
    self.pid = windowData.pid
    self.wid = windowData.wid
  }
}
