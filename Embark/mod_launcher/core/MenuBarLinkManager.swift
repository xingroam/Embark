import Cocoa
import SwiftUI

class MenuBarLinkManager {
  static let s = MenuBarLinkManager()
  private var statusItems: [Int64: NSStatusItem] = [:]

  private init() {}

  func syncWithLinks(_ links: [String: LinkData]) {
    DispatchQueue.main.async { [weak self] in
      guard let self = self else { return }
      let allLinkIds = Set(links.values.map { $0.id })
      let currentTrackedIds = Set(self.statusItems.keys)
      for id in currentTrackedIds.subtracting(allLinkIds) {
        if let item = self.statusItems[id] {
          NSStatusBar.system.removeStatusItem(item)
          self.statusItems.removeValue(forKey: id)
        }
      }
      for link in links.values.sorted(by: { $0.id < $1.id }) {
        if link.showInMenuBar {
          let item: NSStatusItem
          if let existingItem = self.statusItems[link.id] {
            item = existingItem
          } else {
            item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
            item.autosaveName = "embark_link_\(link.id)"
            self.statusItems[link.id] = item
          }
          if !item.isVisible {
            item.isVisible = true
          }
          item.length = NSStatusItem.squareLength
          if let button = item.button {
            button.imagePosition = .imageOnly
            let iconSize: CGFloat = link.linkType == .web ? 16 : 18
            if let iconData = link.iconData, let image = NSImage(data: iconData) {
              image.size = NSSize(width: iconSize, height: iconSize)
              button.image = image
            } else if let icon = link.icon {
              icon.size = NSSize(width: iconSize, height: iconSize)
              button.image = icon
            } else {
              button.image = NSImage(systemSymbolName: link.linkType.iconName, accessibilityDescription: nil)
            }
            button.action = #selector(self.menuBarItemClicked(_:))
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
          }
        } else {
          if let item = self.statusItems[link.id], item.isVisible {
            item.isVisible = false
          }
        }
      }
    }
  }

  func removeLink(path: String) {
    DispatchQueue.main.async { [weak self] in
      guard let self = self else { return }
      if let link = DataManager.s.linkData[path] {
        let id = link.id
        if let item = self.statusItems[id] {
          NSStatusBar.system.removeStatusItem(item)
          self.statusItems.removeValue(forKey: id)
        }
      }
    }
  }

  @objc private func menuBarItemClicked(_ sender: NSStatusBarButton) {
    guard let id = statusItems.first(where: { $0.value.button == sender })?.key else { return }
    guard let link = DataManager.s.linkData.values.first(where: { $0.id == id }) else { return }
    Task {
      _ = await DataManager.s.launchLinkWithValidation(path: link.path, linkName: link.name)
    }
  }
}
