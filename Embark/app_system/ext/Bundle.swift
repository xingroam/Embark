import Foundation
import AppKit

extension Bundle {
  var icon: NSImage? {
    if let iconFileName = self.infoDictionary?["CFBundleIconFile"] as? String {
      return NSImage(named: iconFileName)
    }
    if let iconFileName = self.infoDictionary?["CFBundleIconFiles"] as? [String], let firstIcon = iconFileName.first {
      return NSImage(named: firstIcon)
    }
    return nil
  }
}
