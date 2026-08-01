import SwiftUI

struct LauncherMainView: View {
  @EnvironmentObject private var dm: DataManager
  @EnvironmentObject private var dbm: DatabaseManager
  @EnvironmentObject private var tm: LauncherThemeManager
  @StateObject private var languageManager = LanguageManager.s
  @Binding var newPanelName: String
  @Binding var showAddPanelDialog: Bool
  @Binding var heightUpdateTrigger: Bool
  @Binding var searchText: String
  @Binding var isSearchFocused: Bool
  @Binding var tabKey: TabKeyType
  @Binding var isSpaceEnabled: Bool
  @State private var isFocusEnabled: Bool = FocusConfig.focus
  @State private var maxPanelHeight: CGFloat = LauncherWin.s.maxHeight
  private let controlSize: CGFloat = 34
  private let fontSize: CGFloat = 16
  private let searchWidth: CGFloat = 320
  private let hideOpacity: Double = 0.4

  var body: some View {
    Group {
      if dm.isInitializing {
        VStack(spacing: 0) {
          Text(languageManager.localizedString("launcher.loading.data"))
            .font(.system(size: fontSize, weight: .medium))
            .foregroundColor(tm.currentTheme.linkTextColor)
        }
      } else {
        VStack(spacing: 15) {
          headerView
          mainPanelsAreaView
        }
      }
    }
  }

  private var headerView: some View {
    HStack(spacing: 15) {
      settingsButton
      searchOrAddButton
      Spacer()
      SearchInputView(
        text: $searchText,
        isSearchFocused: $isSearchFocused,
        onUpArrow: {},
        onDownArrow: {},
        onLeftArrow: {},
        onRightArrow: {},
        onTab: {},
        onSubmit: {},
        fontSize: fontSize,
        theme: tm.currentTheme,
        height: controlSize,
        opacityAdd: 0.0,
        cornerRadius: 100
      )
      .frame(maxWidth: searchWidth)
      .opacity(dm.launcherMode == .launcher ? 1.0 : hideOpacity)
      .disabled(dm.launcherMode != .launcher)
      .onChange(of: searchText) { newValue in
        if !newValue.isEmpty && dm.launcherMode != .search {
          LauncherWin.s.Show(mode: .search)
        }
      }
      Spacer()
      focusButton
      spaceButton
    }
  }

  private var mainPanelsAreaView: some View {
    HStack(alignment: .top, spacing: 15) {
      if dm.launcherMode == .settings {
        AppsPanelView(maxPanelHeight: maxPanelHeight)
          .panelSlideAnimation(dm.launcherMode == .settings, duration: LauncherInfo.animationDuration)
      }
      ForEach(dm.getMainPanels(), id: \.id) { panel in
        if dm.launcherMode == .settings || panel.isVisible {
          MainPanelView(panel: panel)
        }
      }
    }
    .backgroundTransitionAnimation(dm.launcherMode == .settings, duration: LauncherInfo.animationDuration)
    .onPreferenceChange(PanelHeightPreferenceKey.self) { heights in
      let height = heights.values.max() ?? 0
      let newHeight = height < LauncherInfo.minPanelHeight ? LauncherInfo.minPanelHeight : height
      maxPanelHeight = newHeight
      LauncherWin.s.maxHeight = newHeight
      LauncherWin.s.Center()
    }
  }

  private var settingsButton: some View {
    Button(action: {
      dm.changeMode(dm.launcherMode == .settings ? .launcher : .settings)
    }) {
      ZStack {
        RoundedRectangle(cornerRadius: 8)
          .fill(dm.launcherMode == .settings ? tm.currentTheme.panelBackgroundColor.opacity(tm.currentTheme.panelBackgroundOpacity + 0.1) : tm.currentTheme.panelBackgroundColor.opacity(tm.currentTheme.panelBackgroundOpacity))
        Image(systemName: "list.bullet")
          .foregroundColor(tm.currentTheme.panelTextColor)
          .font(.system(size: fontSize, weight: .medium))
      }
      .frame(width: controlSize, height: controlSize)
      .contentShape(Rectangle())
    }
    .buttonStyle(PlainButtonStyle())
  }

  private var searchOrAddButton: some View {
    Group {
      if dm.launcherMode == .settings {
        Button(action: {
          newPanelName = ""
          showAddPanelDialog = true
        }) {
          ZStack {
            RoundedRectangle(cornerRadius: 8)
              .fill(tm.currentTheme.panelBackgroundColor.opacity(tm.currentTheme.panelBackgroundOpacity))
            Image(systemName: "plus.rectangle.on.rectangle")
              .foregroundColor(tm.currentTheme.panelTextColor)
              .font(.system(size: fontSize - 2, weight: .medium))
          }
          .contentShape(Rectangle())
          .frame(width: controlSize, height: controlSize)
        }
        .buttonStyle(PlainButtonStyle())
        .settingsIconAnimation(dm.launcherMode == .settings, duration: LauncherInfo.animationDuration)
      } else {
        Button(action: {
          LauncherWin.s.Show(mode: .search)
        }) {
          ZStack {
            RoundedRectangle(cornerRadius: 8)
              .fill(tm.currentTheme.panelBackgroundColor.opacity(tm.currentTheme.panelBackgroundOpacity))
            Image(systemName: "square.grid.2x2")
              .foregroundColor(tm.currentTheme.panelTextColor)
              .font(.system(size: fontSize, weight: .medium))
          }
          .contentShape(Rectangle())
          .frame(width: controlSize, height: controlSize)
        }
        .buttonStyle(PlainButtonStyle())
        .modifier(ConditionalTooltip(
          show: tabKey != .disabled,
          text: languageManager.localizedString("launcher.settings.general.tab_key"),
          edge: .bottom,
          coordinateSpaceName: "LauncherWindow",
          getWindowFrame: { LauncherWin.s.getWindowFrame() }
        ))
        .settingsIconAnimation(dm.launcherMode != .settings, duration: LauncherInfo.animationDuration)
      }
    }
  }

  private var focusButton: some View {
    Button(action: {
      FocusConfig.focus.toggle()
      isFocusEnabled = FocusConfig.focus
      NotificationCenter.default.post(name: NSNotification.Name("FocusConfigChanged"), object: nil)
    }) {
      ZStack {
        RoundedRectangle(cornerRadius: 8)
          .fill(isFocusEnabled ? tm.currentTheme.panelBackgroundColor.opacity(tm.currentTheme.panelBackgroundOpacity + 0.1) : tm.currentTheme.panelBackgroundColor.opacity(tm.currentTheme.panelBackgroundOpacity))
        Image(systemName: FeatureType.focus.icon)
          .foregroundColor(tm.currentTheme.panelTextColor)
          .font(.system(size: fontSize - 2, weight: .medium))
      }
      .contentShape(Rectangle())
      .frame(width: controlSize, height: controlSize)
    }
    .buttonStyle(PlainButtonStyle())
    .modifier(ConditionalTooltip(
      show: dm.launcherMode != .settings,
      text: FeatureType.focus.title,
      edge: .top,
      coordinateSpaceName: "LauncherWindow",
      getWindowFrame: { LauncherWin.s.getWindowFrame() }
    ))
    .opacity(dm.launcherMode != .settings ? 1.0 : hideOpacity)
    .disabled(dm.launcherMode == .settings)
    .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("FocusConfigChanged"))) { _ in
      isFocusEnabled = FocusConfig.focus
    }
  }

  @ViewBuilder
  private var spaceButton: some View {
    if LauncherConfig.launcher {
      Button(action: {
        dm.changeMode(dm.launcherMode == .space ? .launcher : .space)
      }) {
        ZStack {
          RoundedRectangle(cornerRadius: 8)
            .fill(dm.launcherMode == .space ? tm.currentTheme.panelBackgroundColor.opacity(tm.currentTheme.panelBackgroundOpacity + 0.1) : tm.currentTheme.panelBackgroundColor.opacity(tm.currentTheme.panelBackgroundOpacity))
          Image(systemName: FeatureType.space.icon)
            .foregroundColor(tm.currentTheme.panelTextColor)
            .font(.system(size: fontSize - 2, weight: .medium))
        }
        .contentShape(Rectangle())
        .frame(width: controlSize, height: controlSize)
      }
      .buttonStyle(PlainButtonStyle())
      .modifier(ConditionalTooltip(
        show: dm.launcherMode == .launcher,
        text: FeatureType.space.title,
        edge: .top,
        coordinateSpaceName: "LauncherWindow",
        getWindowFrame: { LauncherWin.s.getWindowFrame() }
      ))
      .opacity((dm.launcherMode != .settings && isSpaceEnabled) ? 1.0 : hideOpacity)
      .disabled(dm.launcherMode == .settings || !isSpaceEnabled)
    }
  }
}
