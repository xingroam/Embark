import SwiftUI

struct LauncherSearchView: View {
  @EnvironmentObject private var dm: DataManager
  @EnvironmentObject private var tm: LauncherThemeManager
  @StateObject private var languageManager = LanguageManager.s
  @Binding var searchText: String
  @Binding var isSearchFocused: Bool
  @State private var searchSelectedIndex: Int = 0
  @State private var searchIsSearchMode: Bool = false
  @State private var searchIconCheckPerformed = false
  @State private var searchScope: SearchScope = LauncherConfig.launcherSearchScope
  @State private var searchGridColumns: Int = 5
  private let controlSize: CGFloat = 34
  private let fontSize: CGFloat = 16
  private let searchPadding: CGFloat = 120
  private let searchPaddingBottom: CGFloat = 40
  private let searchInputWidth: CGFloat = 420

  var body: some View {
    ZStack(alignment: .top) {
      if filteredSearchApps.isEmpty {
        VStack {
          Spacer()
          Text(languageManager.localizedString("system.message.not_found"))
            .font(.system(size: tm.currentTheme.textSize))
            .foregroundColor(tm.currentTheme.panelTextColor)
          Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
      } else {
        ScrollView {
          GeometryReader { geometry in
            Color.clear
              .onChange(of: geometry.size.width) { width in
                let availableWidth = width - (searchPadding * 2)
                let cols = Int(availableWidth / LauncherConfig.launcherPanelWidth)
                searchGridColumns = cols > 0 ? cols : 1
              }
              .onAppear {
                let availableWidth = geometry.size.width - (searchPadding * 2)
                let cols = Int(availableWidth / LauncherConfig.launcherPanelWidth)
                searchGridColumns = cols > 0 ? cols : 1
              }
          }
          .frame(height: 0)
          LazyVGrid(columns: [GridItem(.adaptive(minimum: LauncherConfig.launcherPanelWidth), spacing: 0)], spacing: 0) {
            ForEach(Array(filteredSearchApps.enumerated()), id: \.element.path) { index, app in
              LinkButton(app: app, isShowMode: true, isMiniMode: false, isSelected: searchIsSearchMode && index == searchSelectedIndex, canHide: false)
                .id(index)
            }
          }
          .padding(.top, searchPadding)
          .padding(.horizontal, searchPadding)
          .padding(.bottom, searchPaddingBottom)
        }
      }
      HStack(spacing: 15) {
        Button(action: {
          backToLauncherFromSearch()
        }) {
          ZStack {
            RoundedRectangle(cornerRadius: 8)
              .fill(tm.currentTheme.panelBackgroundColor.opacity(tm.currentTheme.panelBackgroundOpacity + 0.1))
            RoundedRectangle(cornerRadius: 8)
              .stroke(tm.currentTheme.panelBackgroundColor.opacity(tm.currentTheme.panelBackgroundOpacity + 0.1), lineWidth: 1)
            Image(systemName: "chevron.left")
              .foregroundColor(tm.currentTheme.panelTextColor)
              .font(.system(size: fontSize, weight: .medium))
          }
          .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .frame(width: controlSize + 4, height: controlSize + 4)
        SearchInputView(
          text: $searchText,
          isSearchFocused: $isSearchFocused,
          onUpArrow: { searchNavigateUp() },
          onDownArrow: { searchNavigateDown() },
          onLeftArrow: { searchNavigateLeft() },
          onRightArrow: { searchNavigateRight() },
          onTab: { searchNavigateRight() },
          onSubmit: {
            if searchIsSearchMode && !filteredSearchApps.isEmpty {
              launchSearchApp(filteredSearchApps[searchSelectedIndex])
            } else {
              LauncherWin.s.Hide()
            }
          },
          fontSize: fontSize,
          theme: tm.currentTheme,
          height: controlSize + 4,
          opacityAdd: 0.1,
          cornerRadius: 8,
          showBorder: true
        )
        .frame(maxWidth: searchInputWidth)
      }
      .padding(.top, 50)
    }
    .contentShape(Rectangle())
    .onTapGesture {
      LauncherWin.s.Hide()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .onAppear {
      loadSearchData()
    }
    .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("LauncherSearchScopeChanged"))) { _ in
      searchScope = LauncherConfig.launcherSearchScope
    }
    .onChange(of: dm.iconCacheInvalidated) { invalidated in
      if invalidated && dm.launcherMode == .search {
        searchIconCheckPerformed = false
        dm.resetIconCacheInvalidatedFlag()
        checkAndReloadSearchIcons()
      }
    }
    .onChange(of: searchText) { newValue in
      searchIsSearchMode = !newValue.isEmpty
      searchSelectedIndex = 0
    }
  }

  private var searchApps: [LinkData] {
    return dm.getSearchApps(scope: searchScope)
  }

  private var filteredSearchApps: [LinkData] {
    if searchText.isEmpty {
      return searchApps
    }
    let query = searchText.lowercased()
    return searchApps.filter { linkData in
      let nameMatch = linkData.name.lowercased().contains(query)
      let titleMatch = linkData.title?.lowercased().contains(query) ?? false
      return nameMatch || titleMatch
    }.sorted { app1, app2 in
      let name1 = (app1.title ?? app1.name).lowercased()
      let name2 = (app2.title ?? app2.name).lowercased()
      let starts1 = name1.hasPrefix(query)
      let starts2 = name2.hasPrefix(query)
      if starts1 && !starts2 { return true }
      if !starts1 && starts2 { return false }
      return name1 < name2
    }
  }

  private func loadSearchData() {
    searchSelectedIndex = 0
    searchIsSearchMode = !searchText.isEmpty
    dm.updateOtherLinks {
      if !searchIconCheckPerformed {
        checkAndReloadSearchIcons()
      }
    }
  }

  private func checkAndReloadSearchIcons() {
    if searchIconCheckPerformed {
      return
    }
    searchIconCheckPerformed = true
    let appsNeedingIcons = searchApps.filter { dm.getLinkIcon(linkPath: $0.path) == nil && $0.linkType == .application }
    if !appsNeedingIcons.isEmpty {
      DispatchQueue.main.async {
        dm.resetIconLoadingCancelled()
        dm.loadIconsAsync(for: appsNeedingIcons.map { $0.path })
      }
    }
  }

  private func backToLauncherFromSearch() {
    searchText = ""
    LauncherWin.s.Show(mode: .launcher)
  }

  private func searchNavigateLeft() {
    guard searchIsSearchMode && !filteredSearchApps.isEmpty else { return }
    if searchSelectedIndex > 0 {
      searchSelectedIndex -= 1
    } else {
      searchSelectedIndex = filteredSearchApps.count - 1
    }
  }

  private func searchNavigateRight() {
    guard searchIsSearchMode && !filteredSearchApps.isEmpty else { return }
    if searchSelectedIndex < filteredSearchApps.count - 1 {
      searchSelectedIndex += 1
    } else {
      searchSelectedIndex = 0
    }
  }

  private func searchNavigateUp() {
    guard searchIsSearchMode && !filteredSearchApps.isEmpty else { return }
    if searchSelectedIndex >= searchGridColumns {
      searchSelectedIndex -= searchGridColumns
    }
  }

  private func searchNavigateDown() {
    guard searchIsSearchMode && !filteredSearchApps.isEmpty else { return }
    if searchSelectedIndex + searchGridColumns < filteredSearchApps.count {
      searchSelectedIndex += searchGridColumns
    }
  }

  private func launchSearchApp(_ app: LinkData) {
    LauncherWin.s.Hide()
    Task {
      _ = await dm.launchLinkWithValidation(path: app.path, linkName: app.name)
    }
  }
}
