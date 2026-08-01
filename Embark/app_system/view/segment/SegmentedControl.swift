import SwiftUI

struct SegmentedControlTab: Identifiable {
  let id: String
  let title: String

  init(id: String, title: String) {
    self.id = id
    self.title = title
  }
}

struct SegmentedControl<Content: View>: View {
  let tabs: [SegmentedControlTab]
  @Binding var selectedTab: String
  let fontSize: CGFloat
  let content: (String) -> Content

  init(
    tabs: [SegmentedControlTab],
    selectedTab: Binding<String>,
    fontSize: CGFloat = 13,
    @ViewBuilder content: @escaping (String) -> Content
  ) {
    self.tabs = tabs
    self._selectedTab = selectedTab
    self.fontSize = fontSize
    self.content = content
  }

  var body: some View {
    VStack(spacing: 10) {
      HStack(spacing: 0) {
        ForEach(tabs) { tab in
          Button(action: { selectedTab = tab.id }) {
            Text(tab.title)
              .font(.system(size: fontSize, weight: .medium))
              .frame(maxWidth: .infinity)
              .padding(.vertical, 8)
              .background(
                RoundedRectangle(cornerRadius: 100)
                  .fill(selectedTab == tab.id ? Color.accentColor : Color.clear)
              )
              .foregroundColor(.primary)
              .contentShape(Rectangle())
          }
          .buttonStyle(.plain)
        }
      }
      .frame(maxWidth: .infinity)
      .background(Color.secondary.opacity(0.2))
      .clipShape(RoundedRectangle(cornerRadius: 100))
      content(selectedTab)
    }
  }
}
