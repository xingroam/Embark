import SwiftUI

struct LinkTextContent: View {
  let app: LinkData
  let theme: LauncherTheme
  @EnvironmentObject private var dm: DataManager
  @State private var multiLineNames: Bool = LauncherConfig.launcherLinkMultiLine

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(app.title ?? app.name)
        .font(.system(size: theme.textSize, weight: .medium))
        .lineLimit(multiLineNames ? nil : 1)
        .truncationMode(multiLineNames ? .tail : .middle)
        .foregroundColor(theme.linkTextColor)
      if let shortcut = dm.getLinkShortcut(linkPath: app.path) {
        Text(shortcut.displayText)
          .font(.system(size: theme.textSize - 4))
          .foregroundColor(theme.linkTextColor.opacity(0.5))
          .lineLimit(1)
          .padding(.horizontal, 2)
          .padding(.vertical, 1)
          .background(
            RoundedRectangle(cornerRadius: 2)
              .fill(theme.linkTextColor.opacity(0.05))
              .overlay(
                RoundedRectangle(cornerRadius: 2)
                  .stroke(theme.linkTextColor.opacity(0.1), lineWidth: 1)
              )
          )
      }
    }
    .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("LauncherThemeChanged"))) { _ in
      multiLineNames = LauncherConfig.launcherLinkMultiLine
    }
  }
}
