import SwiftUI

// 主面板拖动代理
struct MainPanelDropDelegate: DropDelegate {
  let panelId: Int64

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
          if sourcePanelId == panelId {
            return true
          }
          DataManager.s.moveLink(path: appPath, to: panelId)
          LauncherWin.s.Center()
          return true
        }
      } else if draggedData.hasPrefix("PANEL:") {
        let components = draggedData.components(separatedBy: ":")
        if components.count == 2 {
          let draggedPanelId = Int64(components[1]) ?? 0
          if draggedPanelId != panelId {
            DataManager.s.movePanelToBelow(panelId: draggedPanelId, targetPanelId: panelId)
            return true
          }
        }
      } else if draggedData.hasPrefix("SUBPANEL:") {
        let components = draggedData.components(separatedBy: ":")
        if components.count == 2 {
          let draggedSubPanelId = Int64(components[1]) ?? 0
          DataManager.s.moveSubPanel(subPanelId: draggedSubPanelId, to: panelId)
          return true
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

  func dropEntered(info: DropInfo) {}

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
