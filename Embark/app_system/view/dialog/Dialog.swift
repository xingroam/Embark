import SwiftUI
import AppKit
import UniformTypeIdentifiers

class Dialog {
  static func ApplicationPicker(defaultDirectory: URL? = FileManager.default.urls(for: .applicationDirectory, in: .localDomainMask).first, level: NSWindow.Level = .popUpMenu, completion: @escaping (URL?) -> Void) {
    let panel = NSOpenPanel()
    panel.canChooseFiles = true
    panel.canChooseDirectories = false
    panel.allowsMultipleSelection = false
    panel.allowedContentTypes = [.application]
    panel.level = level
    if let directory = defaultDirectory {
      panel.directoryURL = directory
    }
    panel.begin { response in
      if response == .OK, let url = panel.url {
        completion(url)
      } else {
        completion(nil)
      }
    }
  }

  static func ImagePicker(allowedTypes: [UTType] = [.png, .jpeg, .gif, .tiff], level: NSWindow.Level = .popUpMenu, completion: @escaping (URL?) -> Void) {
    let panel = NSOpenPanel()
    panel.canChooseFiles = true
    panel.canChooseDirectories = false
    panel.allowsMultipleSelection = false
    panel.allowedContentTypes = allowedTypes
    panel.level = level
    panel.begin { response in
      if response == .OK {
        completion(panel.url)
      } else {
        completion(nil)
      }
    }
  }

  static func FileOrDirectoryPicker(allowsMultipleSelection: Bool = true, canChooseFiles: Bool = true, canChooseDirectories: Bool = true, level: NSWindow.Level = .popUpMenu, completion: @escaping ([URL]) -> Void) {
    let panel = NSOpenPanel()
    panel.canChooseFiles = canChooseFiles
    panel.canChooseDirectories = canChooseDirectories
    panel.allowsMultipleSelection = allowsMultipleSelection
    panel.level = level
    panel.begin { response in
      if response == .OK {
        completion(panel.urls)
      } else {
        completion([])
      }
    }
  }
}
