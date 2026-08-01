import SwiftUI

struct SpaceDropDelegate: DropDelegate {
  let item: SpaceTable
  @Binding var items: [SpaceTable]
  let isSorting: Bool

  func dropEntered(info: DropInfo) {
    guard isSorting else { return }
    guard let fromIdStr = info.itemProviders(for: [.text]).first else { return }
    fromIdStr.loadItem(forTypeIdentifier: "public.text", options: nil) { (data, error) in
      DispatchQueue.main.async {
        guard let data = data as? Data,
              let idString = String(data: data, encoding: .utf8),
              let fromId = Int64(idString),
              fromId != item.id,
              let fromIndex = items.firstIndex(where: { $0.id == fromId }),
              let toIndex = items.firstIndex(where: { $0.id == item.id }) else { return }

        withAnimation {
          let fromItem = items[fromIndex]
          items.remove(at: fromIndex)
          items.insert(fromItem, at: toIndex)
          SpaceManager.s.updateSpaceOrder(spaces: items)
        }
      }
    }
  }

  func performDrop(info: DropInfo) -> Bool {
    return isSorting
  }

  func validateDrop(info: DropInfo) -> Bool {
    return isSorting
  }
}
