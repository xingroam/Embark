import SwiftUI

// 应用列表面板拖动代理
struct AppsPanelDropDelegate: DropDelegate {
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
          let appPath = String(components[2])
          if let linkType = DataManager.s.linkData[appPath]?.linkType {
            if linkType != .application {
              return false
            }
          }
          Debug.print("App moved to apps list: \(appPath)")
          DataManager.s.moveLink(path: appPath, to: DataManager.s.APPS_PANEL_ID)
          LauncherWin.s.Center()
        }
      }
    }
    return true
  }

  func validateDrop(info: DropInfo) -> Bool {
    return true
  }
}
