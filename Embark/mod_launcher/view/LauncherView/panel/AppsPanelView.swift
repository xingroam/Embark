import SwiftUI

// 应用列表面板视图
struct AppsPanelView: View {
  let maxPanelHeight: CGFloat
  @EnvironmentObject private var dm: DataManager
  @Environment(\.launcherTheme) private var theme
  @State private var searchText = ""
  @State private var scrollToTopID = UUID()

  var body: some View {
    VStack(spacing: 0) {
      HStack(spacing: 5) {
        Text(LanguageManager.s.localizedString("launcher.panel.apps.title"))
          .font(.system(size: theme.textSize, weight: theme.panelTextBold ? .bold : .medium))
          .foregroundColor(theme.panelTextColor)
        Spacer()
      }
      .padding(.horizontal, 8)
      .padding(.vertical, 6)
      .background(theme.panelBackgroundColor.opacity(theme.panelBackgroundOpacity + 0.05))
      searchBoxView
      appsListContent
    }
    .frame(width: theme.panelWidth + LauncherInfo.settingModeAddWidth)
    .frame(height: maxPanelHeight)
    .background(theme.panelBackgroundColor.opacity(theme.panelBackgroundOpacity + 0.05))
    .cornerRadius(8)
    .overlay(
      RoundedRectangle(cornerRadius: 8)
        .stroke(theme.panelBackgroundColor.opacity(theme.panelBackgroundOpacity + 0.05), lineWidth: 1)
    )
    .onDrop(of: [.text], delegate: AppsPanelDropDelegate())
  }

  private var searchBoxView: some View {
    VStack(spacing: 0) {
      HStack(spacing: 5) {
        Image(systemName: "magnifyingglass")
          .foregroundColor(theme.panelTextColor.opacity(0.8))
          .font(.system(size: theme.textSize - 2))
        TextField("", text: $searchText)
          .textFieldStyle(PlainTextFieldStyle())
          .foregroundColor(theme.panelTextColor)
          .font(.system(size: theme.textSize - 1))
        if !searchText.isEmpty {
          Button(action: {
            searchText = ""
          }) {
            Image(systemName: "xmark.circle.fill")
              .foregroundColor(theme.panelTextColor.opacity(0.8))
              .font(.system(size: 10))
          }
          .buttonStyle(PlainButtonStyle())
        }
      }
      .padding(.horizontal, 8)
      .padding(.vertical, 5)
      .background(theme.panelBackgroundColor.opacity(theme.panelBackgroundOpacity - 0.05))
      Rectangle()
        .fill(theme.panelBackgroundColor.opacity(theme.panelBackgroundOpacity + 0.05))
        .frame(height: 1)
    }
  }

  private var appsListContent: some View {
    Group {
      if !dm.updateAppsListCompleted {
        Spacer()
        Text(LanguageManager.s.localizedString("launcher.loading.data"))
          .font(.system(size: theme.textSize))
          .foregroundColor(theme.panelTextColor)
        Spacer()
      } else {
        let links = filteredLinks()
        if links.isEmpty {
          Spacer()
          Text(LanguageManager.s.localizedString("system.message.not_found"))
            .font(.system(size: theme.textSize))
            .foregroundColor(theme.panelTextColor)
          Spacer()
        } else {
          ScrollViewReader { proxy in
            ScrollView {
              LazyVStack(spacing: 0) {
                ForEach(Array(links.enumerated()), id: \.element.path) { index, app in
                  LinkButton(app: app, isShowMode: true, isMiniMode: true, isSelected: false, canHide: false)
                    .id(index == 0 ? "top" : nil)
                    .onDrop(of: [.text], delegate: LinkDropDelegate(
                      targetPanelId: dm.APPS_PANEL_ID,
                      targetIndex: index,
                      targetOrderIndex: 0,
                      onReorder: { fromIndex, toIndex in
                      },
                      onMoveToPanel: { appPath, targetOrderIndex in
                        dm.moveLink(path: appPath, to: dm.APPS_PANEL_ID)
                        LauncherWin.s.Center()
                      }
                    ))
                }
              }
            }
            .frame(maxHeight: .infinity)
            .onChange(of: dm.updateAppsListCompleted) { completed in
              if completed && dm.launcherMode == .settings && !links.isEmpty {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                  withAnimation {
                    proxy.scrollTo("top", anchor: .top)
                  }
                }
              }
            }
          }
        }
      }
    }
  }

  private func filteredLinks() -> [LinkData] {
    let allLinks = dm.getAppsListLinks()
    if searchText.isEmpty {
      return allLinks
    }
    let query = searchText.lowercased()
    return allLinks.filter { link in
      link.name.lowercased().contains(query)
    }
  }
}
