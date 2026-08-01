import SwiftUI

struct AppSettingView: View {
  @State private var selectedTab: SettingsTab
  @State private var isStartupEnabled: Bool = false
  @State private var hoverState: Bool = false
  @StateObject private var updateManager = UpdateManager.s
  private let fz: CGFloat = 12
  private let initialTab: SettingsTab?

  init(initialTab: SettingsTab? = nil) {
    self.initialTab = initialTab
    self._selectedTab = State(initialValue: initialTab ?? .general)
  }

  var body: some View {
    GeometryReader { geometry in
      HStack(spacing: 0) {
        sidebarView
        separatorView
        contentView(geometry: geometry)
      }
    }
    .frame(width: 700, height: 600)
    .background(BlurredBackground(material: .underWindowBackground, blendingMode: .behindWindow, blur: 1.0))
    .onAppear {
      isStartupEnabled = StartupManager.s.isAppInStartupItems()
    }
  }

  private var sidebarView: some View {
    VStack(spacing: 0) {
      ForEach(SettingsTab.allCases, id: \.self) { tab in
        tabButton(tab: tab)
      }
      Spacer()
      appInfoButton
    }
    .frame(width: 160)
    .padding(.vertical, 5)
  }

  private func tabButton(tab: SettingsTab) -> some View {
    Button(action: {
      selectedTab = tab
    }) {
      HStack(spacing: 5) {
        Image(systemName: tab.icon(customerActive: false))
          .font(.system(size: fz))
          .foregroundColor(selectedTab == tab ? .white : .primary)
          .frame(width: 20, height: 20)
        Text(tab.title(customerActive: false))
          .font(.system(size: fz, weight: .medium))
          .foregroundColor(selectedTab == tab ? .white : .primary)
        Spacer()
      }
      .padding(.horizontal, 8)
      .padding(.vertical, 6)
      .background(selectedTab == tab ? Color.accentColor : Color.clear)
      .cornerRadius(5)
      .contentShape(Rectangle())
    }
    .buttonStyle(PlainButtonStyle())
    .padding(.horizontal, 8)
    .padding(.vertical, 2)
  }

  private var appInfoButton: some View {
    Button(action: {
      UpdateManager.s.checkUpdateDialog()
    }) {
      VStack(spacing: 5) {
        if let appIcon = Bundle.main.icon {
          Image(nsImage: appIcon)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 28, height: 28)
        }
        HStack(spacing: 3) {
          Text(EmbarkInfo.name)
            .font(.system(size: fz - 2, weight: .medium))
            .foregroundColor(.primary)
          Text(EmbarkInfo.version)
            .font(.system(size: fz - 2))
            .foregroundColor(.secondary)
        }
      }
      .padding(.horizontal, 20)
      .padding(.vertical, 15)
      .background(
        RoundedRectangle(cornerRadius: 6)
          .fill(Color.primary.opacity(0.05))
          .opacity(hoverState ? 1 : 0)
      )
      .contentShape(Rectangle())
    }
    .padding(.bottom, 10)
    .buttonStyle(PlainButtonStyle())
    .onHover { isHovered in
      hoverState = isHovered
    }
  }

  private var separatorView: some View {
    Rectangle()
      .fill(Color.secondary.opacity(0.1))
      .frame(width: 1)
  }

  private func contentView(geometry: GeometryProxy) -> some View {
    VStack(spacing: 0) {
      switch selectedTab {
      case .general:
        SettingGeneralView(isStartupEnabled: $isStartupEnabled, onSwitchToPurchase: {
          selectedTab = .general
        })
      case .about:
        SettingAboutView()
      }
    }
    .frame(width: geometry.size.width - 161)
    .background(Color(NSColor.controlBackgroundColor).opacity(0.7))
  }
}
