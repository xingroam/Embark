import SwiftUI

// 子面板拖动代理
struct SubPanelDropDelegate: DropDelegate {
  let targetSubPanelId: Int64
  let onHoverChanged: (Bool) -> Void

  func performDrop(info: DropInfo) -> Bool {
    let pasteboard = NSPasteboard(name: .drag)
    var draggedStrings: [String] = []
    if let items = pasteboard.pasteboardItems {
      for item in items {
        if let string = item.string(forType: .string) {
          draggedStrings.append(string)
        }
      }
    }
    if let draggedData = draggedStrings.first {
      if draggedData.hasPrefix("APP:") {
        let components = draggedData.split(separator: ":", maxSplits: 2, omittingEmptySubsequences: false)
        if components.count == 3 {
          let sourcePanelId = Int64(components[1]) ?? 0
          let appPath = String(components[2])
          if sourcePanelId == targetSubPanelId {
            return true
          }
          DataManager.s.moveLink(path: appPath, to: targetSubPanelId)
          LauncherWin.s.Center()
          return true
        }
      } else if draggedData.hasPrefix("SUBPANEL:") {
        let components = draggedData.components(separatedBy: ":")
        if components.count == 2 {
          let draggedSubPanelId = Int64(components[1]) ?? 0
          if draggedSubPanelId != targetSubPanelId {
            DataManager.s.moveSubPanelToSubPanelBelow(subPanelId: draggedSubPanelId, targetSubPanelId: targetSubPanelId)
            LauncherWin.s.Center()
            return true
          }
        }
      }
    }
    if let draggedURLs = pasteboard.readObjects(forClasses: [NSURL.self]) as? [URL] {
      for fileURL in draggedURLs {
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: fileURL.path) {
          var isDirectory: ObjCBool = false
          if fileManager.fileExists(atPath: fileURL.path, isDirectory: &isDirectory) {
            if isDirectory.boolValue {
              DataManager.s.addFolderLink(path: fileURL.path, panelId: targetSubPanelId)
            } else {
              DataManager.s.addFileLink(path: fileURL.path, panelId: targetSubPanelId)
            }
          }
        }
      }
      return true
    }
    return false
  }

  func dropUpdated(info: DropInfo) -> DropProposal? {
    if !info.itemProviders(for: [.text]).isEmpty {
      return DropProposal(operation: .move)
    }
    if !info.itemProviders(for: [.fileURL]).isEmpty {
      return DropProposal(operation: .copy)
    }
    return nil
  }
}
