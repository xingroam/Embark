import SwiftUI

// 统一的应用拖动代理
struct LinkDropDelegate: DropDelegate {
  let targetPanelId: Int64
  let targetIndex: Int
  let targetOrderIndex: Int
  let onReorder: (Int, Int) -> Void
  let onMoveToPanel: (String, Int) -> Void

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
          if sourcePanelId == self.targetPanelId {
            let links = DataManager.s.getLinks(for: self.targetPanelId)
            if let sourceIndex = links.firstIndex(where: { $0.path == appPath }) {
              self.onReorder(sourceIndex, self.targetIndex)
            }
          } else {
            if let linkType = DataManager.s.linkData[appPath]?.linkType {
              if linkType != .application && self.targetPanelId == DataManager.s.APPS_PANEL_ID {
                return false
              }
            }
            self.onMoveToPanel(appPath, self.targetOrderIndex)
            LauncherWin.s.Center()
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
            let insertIndex = self.targetOrderIndex + 1
            if isDirectory.boolValue {
              if fileURL.pathExtension.lowercased() == "app" {
                let existingLinks = DataManager.s.linkData.values.filter { $0.panelId == self.targetPanelId }
                for link in existingLinks {
                  if link.orderIndex >= insertIndex {
                    DatabaseManager.s.updateLinkOrder(path: link.path, panelId: self.targetPanelId, orderIndex: link.orderIndex + 1)
                  }
                }
                DataManager.s.addAppLink(path: fileURL.path, panelId: self.targetPanelId, orderIndex: insertIndex)
              } else {
                if self.targetPanelId == DataManager.s.APPS_PANEL_ID { continue }
                let existingLinks = DataManager.s.linkData.values.filter { $0.panelId == self.targetPanelId }
                for link in existingLinks {
                  if link.orderIndex >= insertIndex {
                    DatabaseManager.s.updateLinkOrder(path: link.path, panelId: self.targetPanelId, orderIndex: link.orderIndex + 1)
                  }
                }
                DataManager.s.addFolderLink(path: fileURL.path, panelId: self.targetPanelId, orderIndex: insertIndex)
              }
            } else {
              if self.targetPanelId == DataManager.s.APPS_PANEL_ID { continue }
              let existingLinks = DataManager.s.linkData.values.filter { $0.panelId == self.targetPanelId }
              for link in existingLinks {
                if link.orderIndex >= insertIndex {
                  DatabaseManager.s.updateLinkOrder(path: link.path, panelId: self.targetPanelId, orderIndex: link.orderIndex + 1)
                }
              }
              DataManager.s.addFileLink(path: fileURL.path, panelId: self.targetPanelId, orderIndex: insertIndex)
            }
            LauncherWin.s.Center()
          }
        }
      }
    }
    return true
  }

  func validateDrop(info: DropInfo) -> Bool {
    return true
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
