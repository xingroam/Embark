import SwiftUI

struct WindowSnapshotRow: View {
  let window: WindowSnapshot
  let fz: CGFloat
  let onAddPath: () -> Void
  let onRemovePath: (Int) -> Void

  var body: some View {
    HStack(alignment: window.projectPaths.isEmpty ? .center : .top, spacing: 4) {
      if let icon = getAppIcon(bundleIdentifier: window.bundleIdentifier) {
        Image(nsImage: icon)
          .resizable()
          .frame(width: 20, height: 20)
      } else {
        Image(systemName: "app.fill")
          .resizable()
          .frame(width: 20, height: 20)
          .foregroundColor(.secondary)
      }
      VStack(alignment: .leading, spacing: 2) {
        Text(window.appName)
          .font(.system(size: fz))
          .lineLimit(1)
        if !window.projectPaths.isEmpty {
          ForEach(Array(window.projectPaths.enumerated()), id: \.offset) { index, path in
            HStack(spacing: 4) {
              Text(path)
                .font(.system(size: fz - 2))
                .foregroundColor(.secondary)
                .lineLimit(1)
                .truncationMode(.middle)
              PressableButton(action: { onRemovePath(index) }) {
                Image(systemName: "xmark.circle.fill")
                  .font(.system(size: fz - 2))
                  .foregroundColor(.secondary)
              }
            }
          }
        }
      }
      Spacer()
      PressableButton(action: onAddPath) {
        Image(systemName: "plus.app")
          .font(.system(size: fz + 2))
          .foregroundColor(.secondary)
      }
    }
    .padding(.vertical, 4)
  }

  private func getAppIcon(bundleIdentifier: String) -> NSImage? {
    guard let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier) else {
      return nil
    }
    return NSWorkspace.shared.icon(forFile: appURL.path)
  }
}
