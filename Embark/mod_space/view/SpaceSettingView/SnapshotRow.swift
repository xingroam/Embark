import SwiftUI

struct SnapshotRow: View {
  let snapshot: SpaceTable
  let fz: CGFloat
  let onDelete: () -> Void

  var body: some View {
    HStack(spacing: 5) {
      VStack(alignment: .leading, spacing: 2) {
        Text(snapshot.name)
          .font(.system(size: fz, weight: .medium))
          .foregroundColor(.primary)
          .lineLimit(1)
        HStack(spacing: 5) {
          if snapshot.isLegacyData {
            Text("? \(NSLocalizedString("space.button.screens", comment: ""))")
            Text("? \(NSLocalizedString("space.button.apps", comment: ""))")
          } else {
            Text("\(snapshot.screens.count) \(NSLocalizedString("space.button.screens", comment: ""))")
            Text("\(Set(snapshot.windows.map { $0.bundleIdentifier }).count) \(NSLocalizedString("space.button.apps", comment: ""))")
          }
        }
        .font(.system(size: fz - 2))
        .foregroundColor(.secondary)
      }
      Spacer()
      Button(action: onDelete) {
        Image(systemName: "trash")
          .font(.system(size: fz))
      }
      .buttonStyle(.borderless)
    }
  }
}
