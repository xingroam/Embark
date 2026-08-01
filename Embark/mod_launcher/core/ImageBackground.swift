import Foundation
import AppKit

struct ImageBackground {
  private static var cachedImage: NSImage?

  private static var bgFileURL: URL? {
    guard let appSupportPath = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else { return nil }
    let appDirectory = appSupportPath.appendingPathComponent(EmbarkInfo.bundleIdentifier)
    try? FileManager.default.createDirectory(at: appDirectory, withIntermediateDirectories: true)
    return appDirectory.appendingPathComponent(EmbarkInfo.launcherBgFile)
  }

  static func getBgFilePath() -> String? {
    return bgFileURL?.path
  }

  static func getBgFileURL() -> URL? {
    return bgFileURL
  }

  static func loadImage() -> NSImage? {
    if let cached = cachedImage {
      return cached
    }
    guard let fileURL = bgFileURL else { return nil }
    if FileManager.default.fileExists(atPath: fileURL.path) {
      if let image = NSImage(contentsOf: fileURL) {
        cachedImage = image
        return cachedImage
      }
    }
    return nil
  }

  static func saveImage(from sourceURL: URL) throws {
    guard let fileURL = bgFileURL else {
      throw NSError(domain: "ImageBackground", code: 1, userInfo: [NSLocalizedDescriptionKey: "Cannot determine background file URL"])
    }
    if FileManager.default.fileExists(atPath: fileURL.path) {
      try FileManager.default.removeItem(at: fileURL)
    }
    try FileManager.default.copyItem(at: sourceURL, to: fileURL)
    cachedImage = NSImage(contentsOf: fileURL)
  }

  static func removeImage() throws {
    guard let fileURL = bgFileURL else {
      throw NSError(domain: "ImageBackground", code: 1, userInfo: [NSLocalizedDescriptionKey: "Cannot determine background file URL"])
    }
    try FileManager.default.removeItem(at: fileURL)
    cachedImage = nil
  }

  static func imageExists() -> Bool {
    guard let fileURL = bgFileURL else { return false }
    return FileManager.default.fileExists(atPath: fileURL.path)
  }
}
