import SwiftUI

struct ConfigItem<Trailing: View>: View {
  let icon: String
  let title: String
  let subtitle: String
  var isEnabled: Bool = false
  var disabledColor: Color = .secondary
  @ViewBuilder let trailing: () -> Trailing
  private let fz: CGFloat = 12

  var body: some View {
    HStack(spacing: 15) {
      Image(systemName: icon)
        .font(.system(size: fz + 16, weight: .medium))
        .foregroundColor(isEnabled ? .accentColor : disabledColor)
      VStack(alignment: .leading, spacing: 3) {
        Text(title)
          .font(.system(size: fz + 2, weight: .semibold))
          .foregroundColor(.primary)
        if !subtitle.isEmpty {
          Text(subtitle)
            .font(.system(size: fz))
            .foregroundColor(.secondary)
            .lineLimit(2)
        }
      }
      Spacer()
      trailing()
    }
    .padding(16)
  }
}
