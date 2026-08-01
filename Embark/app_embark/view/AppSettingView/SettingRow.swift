import SwiftUI

struct SettingRow<Content: View>: View {
  let icon: String
  let title: String
  let subtitle: String
  let trailing: Content
  private let fz: CGFloat = 13

  init(icon: String, title: String, subtitle: String, @ViewBuilder trailing: () -> Content) {
    self.icon = icon
    self.title = title
    self.subtitle = subtitle
    self.trailing = trailing()
  }

  var body: some View {
    HStack(spacing: 10) {
      Image(systemName: icon)
        .font(.system(size: fz + 1))
        .foregroundColor(.secondary)
        .frame(width: 20, height: 20)
      VStack(alignment: .leading, spacing: 5) {
        Text(title)
          .font(.system(size: fz, weight: .medium))
          .foregroundColor(.primary)
        if !subtitle.isEmpty {
          Text(subtitle)
            .font(.system(size: fz - 2))
            .foregroundColor(.secondary)
        }
      }
      Spacer()
      trailing
    }
    .padding(.leading, 10)
    .padding(.trailing, 15)
    .padding(.vertical, 10)
    .background(Color.clear)
    .contentShape(Rectangle())
  }
}
