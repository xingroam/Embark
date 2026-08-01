import SwiftUI

// 文件/文件夹拖拽代理
struct FileDropDelegate: DropDelegate {
  let panelId: Int64

  func performDrop(info: DropInfo) -> Bool {
    let pasteboard = NSPasteboard(name: .drag)
    if let draggedURLs = pasteboard.readObjects(forClasses: [NSURL.self]) as? [URL] {
      for fileURL in draggedURLs {
        Debug.print("File dropped: \(fileURL.path)")
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: fileURL.path) {
          var isDirectory: ObjCBool = false
          if fileManager.fileExists(atPath: fileURL.path, isDirectory: &isDirectory) {
            if isDirectory.boolValue {
              DataManager.s.addFolderLink(path: fileURL.path, panelId: panelId)
            } else {
              DataManager.s.addFileLink(path: fileURL.path, panelId: panelId)
            }
          }
        }
      }
      return true
    }
    return false
  }

  func dropEntered(info: DropInfo) {
    Debug.print("File drag entered panel area")
  }

  func dropUpdated(info: DropInfo) -> DropProposal? {
    return DropProposal(operation: .copy)
  }
}
