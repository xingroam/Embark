import SwiftUI
import QuickLookThumbnailing

class LaunchManager: ObservableObject {
  static let s = LaunchManager()

  private init() {}

  func fetchApps(completion: @escaping ([String]) -> Void) {
    DispatchQueue.global().async {
      autoreleasepool {
        let dl = [
          NSHomeDirectory() + "/Applications",
          "/Applications",
          "/System/Applications",
        ]
        var r: [String] = []
        for d in dl {
          let t = Process()
          t.launchPath = "/usr/bin/mdfind"
          t.arguments = ["-onlyin", d, "kMDItemContentType == 'com.apple.application-bundle'"]
          let pipe = Pipe()
          t.standardOutput = pipe
          do {
            try t.run()
            if let out = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) {
              let apps = out.split(separator: "\n").map { String($0) }
              let filteredApps = apps.filter { appPath in
                !self.isEmbeddedApp(appPath: appPath)
              }
              r.append(contentsOf: filteredApps)
            }
          } catch {
            Debug.print("Launch Manager: Error finding applications: \(error)")
          }
        }
        let finderPath = "/System/Library/CoreServices/Finder.app"
        if FileManager.default.fileExists(atPath: finderPath) && !r.contains(finderPath) {
          r.append(finderPath)
        }
        DispatchQueue.main.async {
          completion(r)
        }
      }
    }
  }

  func launchApp(appPath: String) async -> (success: Bool, error: String?) {
    guard FileManager.default.fileExists(atPath: appPath) else {
      return (false, "Application file does not exist")
    }
    let appURL = URL(fileURLWithPath: appPath)
    let configuration = NSWorkspace.OpenConfiguration()
    configuration.allowsRunningApplicationSubstitution = false
    configuration.activates = true
    configuration.addsToRecentItems = false
    configuration.hides = false
    configuration.hidesOthers = false
    do {
      _ = try await NSWorkspace.shared.openApplication(at: appURL, configuration: configuration)
      return (true, nil)
    } catch {
      return (false, "Failed to launch: \(error.localizedDescription)")
    }
  }

  private func getBundleID(appPath: String) -> String? {
    guard let bundle = Bundle(path: appPath) else { return nil }
    return bundle.bundleIdentifier
  }

  func getAppName(appPath: String) -> String {
    if let d = DataManager.s.linkData[appPath] {
      return d.name
    }
    guard Bundle(path: appPath) != nil else {
      return (appPath as NSString).lastPathComponent.replacingOccurrences(of: ".app", with: "")
    }
    let process = Process()
    process.launchPath = "/usr/bin/mdls"
    process.arguments = ["-name", "kMDItemDisplayName", appPath]
    let pipe = Pipe()
    process.standardOutput = pipe
    do {
      try process.run()
      process.waitUntilExit()
      if let output = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) {
        let lines = output.components(separatedBy: .newlines)
        for line in lines {
          if line.contains("=") {
            let parts = line.components(separatedBy: "=")
            if parts.count >= 2 {
              let value = parts[1].trimmingCharacters(in: .whitespaces).replacingOccurrences(of: "\"", with: "")
              if !value.isEmpty && value != "(null)" && value != (appPath as NSString).lastPathComponent {
                return value.replacingOccurrences(of: ".app", with: "")
              }
            }
          }
        }
      }
    } catch {
      Debug.print("Launch Manager: Error getting application name: \(error)")
    }
    return (appPath as NSString).lastPathComponent.replacingOccurrences(of: ".app", with: "")
  }

  func getIcon(path: String, linkType: LinkType) -> NSImage? {
    switch linkType {
    case .application:
      let originalURL = URL(fileURLWithPath: path)
      let resolvedURL = originalURL.resolvingSymlinksInPath()
      let resolvedPath = resolvedURL.path
      let appIcon = NSWorkspace.shared.icon(forFile: resolvedPath)
      if appIcon.size.width > 0 && appIcon.size.height > 0 {
        return appIcon.resized(to: CGSize(width: LauncherConfig.launcherLinkIconSize, height: LauncherConfig.launcherLinkIconSize))
      }
      if let bundleIcon = Bundle(path: resolvedPath)?.icon {
        return bundleIcon.resized(to: CGSize(width: LauncherConfig.launcherLinkIconSize, height: LauncherConfig.launcherLinkIconSize))
      }
      return appIcon.resized(to: CGSize(width: LauncherConfig.launcherLinkIconSize, height: LauncherConfig.launcherLinkIconSize))
    case .folder:
      return NSWorkspace.shared.icon(forFile: path)
    case .file:
      if LauncherConfig.launcherLinkThumbnails {
        if let thumbnail = generateImageThumbnail(for: path, quality: 1.0) {
          return thumbnail
        }
      }
      return NSWorkspace.shared.icon(forFile: path)
    case .web:
      return nil
    }
  }

  @available(macOS 14.0, *)
  func getFolderIconWithCustomization(path: String, completion: @escaping (NSImage?) -> Void) {
    let url = URL(fileURLWithPath: path)
    let size = CGSize(width: LauncherConfig.launcherLinkIconSize, height: LauncherConfig.launcherLinkIconSize)
    let scale = NSScreen.main?.backingScaleFactor ?? 2.0
    let request = QLThumbnailGenerator.Request(
      fileAt: url,
      size: size,
      scale: scale,
      representationTypes: .icon
    )
    QLThumbnailGenerator.shared.generateBestRepresentation(for: request) { thumbnail, error in
      DispatchQueue.main.async {
        completion(thumbnail?.nsImage)
      }
    }
  }

  func generateImageThumbnail(for filePath: String, quality: CGFloat = 1.0) -> NSImage? {
    guard let image = NSImage(contentsOfFile: filePath) else { return nil }
    let targetSize = CGSize(width: LauncherConfig.launcherLinkIconSize, height: LauncherConfig.launcherLinkIconSize)
    let aspectRatio = min(targetSize.width / image.size.width, targetSize.height / image.size.height)
    let newSize = CGSize(width: image.size.width * aspectRatio, height: image.size.height * aspectRatio)
    let thumbnail = NSImage(size: newSize)
    thumbnail.lockFocus()
    image.draw(in: NSRect(origin: .zero, size: newSize), from: NSRect(origin: .zero, size: image.size), operation: .copy, fraction: quality)
    thumbnail.unlockFocus()
    return thumbnail
  }

  func isAppExists(appPath: String) -> Bool {
    return FileManager.default.fileExists(atPath: appPath)
  }

  private func isEmbeddedApp(appPath: String) -> Bool {
    let pathComponents = (appPath as NSString).pathComponents
    for (index, component) in pathComponents.enumerated() {
      if component.hasSuffix(".app") && index < pathComponents.count - 1 {
        return true
      }
    }
    return false
  }
}
