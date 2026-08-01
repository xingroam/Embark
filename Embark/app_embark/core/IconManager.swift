import SwiftUI

class IconManager {
  static let s = IconManager()

  private init() {}

  func setAppIcon(to icon: AppIcon) {
    EmbarkConfig.appIcon = icon
  }

  func refreshCurrentAppIcon() {
    let icon = EmbarkConfig.appIcon
    if icon.isDefault {
      NSApp.applicationIconImage = nil
      #if !DEBUG
        if let defaultIconPath = Bundle.main.path(forResource: "AppIcon", ofType: "icns") {
          if let defaultIcon = NSImage(contentsOfFile: defaultIconPath) {
            NSWorkspace.shared.setIcon(defaultIcon, forFile: Bundle.main.bundlePath, options: [])
          }
        } else {
          if let bundleIcon = Bundle.main.icon {
            NSWorkspace.shared.setIcon(bundleIcon, forFile: Bundle.main.bundlePath, options: [])
          }
        }
      #endif
    } else {
      guard let image = NSImage(named: icon.assetName) else {
        print("Failed to load icon: \(icon.assetName)")
        return
      }
      NSApp.applicationIconImage = image
      #if !DEBUG
        NSWorkspace.shared.setIcon(image, forFile: Bundle.main.bundlePath, options: [])
      #endif
    }
  }

  func getIconImage(for icon: AppIcon) -> NSImage? {
    if icon.isDefault {
      return Bundle.main.icon
    }
    return NSImage(named: icon.assetName)
  }
}
