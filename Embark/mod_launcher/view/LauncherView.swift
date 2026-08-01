import SwiftUI

struct LauncherView: View {
  @EnvironmentObject private var dm: DataManager
  @EnvironmentObject private var dbm: DatabaseManager
  @EnvironmentObject private var tm: LauncherThemeManager
  @StateObject private var languageManager = LanguageManager.s
  @ObservedObject private var spaceManager = SpaceManager.s
  @State private var showAddPanelDialog = false
  @State private var heightUpdateTrigger = false
  @State private var hasTriggeredAppCheck = false
  @State private var newPanelName = ""
  @State private var backgroundImage: NSImage? = ImageBackground.loadImage()
  @State private var tabKey: TabKeyType = LauncherConfig.launcherTabKey
  @State private var searchText = ""
  @State private var isSearchFocused = false
  @State private var showSnapshotAlert = false
  @State private var newSpaceName = ""
  @State private var focus: SpaceFocusMode = .keep
  @State private var spaceScreen: SpaceScreen = .all
  @State private var isSpaceEnabled = SpaceConfig.space

  var body: some View {
    Group {
      if dm.launcherMode == .search {
        LauncherSearchView(searchText: $searchText, isSearchFocused: $isSearchFocused)
      } else if dm.launcherMode == .space || dm.launcherMode == .spaceSorting {
        LauncherSpaceView(
          showSnapshotAlert: $showSnapshotAlert,
          newSpaceName: $newSpaceName,
          focus: $focus,
          spaceScreen: $spaceScreen
        )
        .padding(20)
        .fixedSize()
      } else {
        LauncherMainView(
          newPanelName: $newPanelName,
          showAddPanelDialog: $showAddPanelDialog,
          heightUpdateTrigger: $heightUpdateTrigger,
          searchText: $searchText,
          isSearchFocused: $isSearchFocused,
          tabKey: $tabKey,
          isSpaceEnabled: $isSpaceEnabled
        )
        .padding(20)
        .fixedSize()
      }
    }
    .opacity(dm.contentOpacity)
    .onAppear {
      isSearchFocused = dm.launcherMode == .launcher || dm.launcherMode == .search
    }
    .onChange(of: dm.isInitializing) { initializing in
      if !initializing {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
          isSearchFocused = dm.launcherMode == .launcher || dm.launcherMode == .search
        }
      }
    }
    .coordinateSpace(name: "LauncherWindow")
    .stateTransitionAnimation(dm.isInitializing, duration: LauncherInfo.animationDuration)
    .background(
      ZStack {
        tm.currentTheme.backgroundColor.opacity(tm.currentTheme.backgroundColorOpacity)
        if dm.launcherMode != .search, ProcessInfo.processInfo.operatingSystemVersion.majorVersion >= 14, let nsImage = backgroundImage {
          Image(nsImage: nsImage)
            .resizable()
            .scaledToFill()
            .blur(radius: CGFloat(LauncherConfig.launcherBackgroundImageBlur))
            .opacity(LauncherConfig.launcherBackgroundImageOpacity)
        }
      }
    )
    .background(tm.currentTheme.backgroundBlur > 0 ? SwiftBlurBackground(opacity: tm.currentTheme.backgroundBlur) : nil)
    .cornerRadius(20)
    .environment(\.launcherTheme, tm.currentTheme)
    .onDisappear {
      hasTriggeredAppCheck = false
    }
    .onChange(of: dm.launcherMode) { newValue in
      isSearchFocused = newValue == .launcher || newValue == .search
      if newValue != .search {
        LauncherWin.s.Center(wait:true, must: true)
      }
    }
    .onChange(of: heightUpdateTrigger) { newValue in
      if dm.launcherMode != .search {
        LauncherWin.s.Center()
      }
    }
    .onReceive(dm.objectWillChange) { _ in
      if dm.launcherMode != .search {
        LauncherWin.s.Center(wait: true)
      }
    }
    .onReceive(dbm.objectWillChange) { _ in
      if dm.launcherMode != .search {
        LauncherWin.s.Center(wait: true)
      }
    }
    .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ForceSearchFocus"))) { _ in
      let shouldFocus = dm.launcherMode == .launcher || dm.launcherMode == .search
      isSearchFocused = false
      DispatchQueue.main.async {
        isSearchFocused = shouldFocus
      }
    }
    .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("SearchEscapePressed"))) { _ in
      if !searchText.isEmpty {
        searchText = ""
      } else {
        LauncherWin.s.Show(mode: .launcher)
      }
    }
    .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("LauncherImageChanged"))) { _ in
      backgroundImage = ImageBackground.loadImage()
    }
    .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("LauncherTabKeyChanged"))) { _ in
      tabKey = LauncherConfig.launcherTabKey
    }
    .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("SpaceConfigChanged"))) { _ in
      isSpaceEnabled = SpaceConfig.space
    }
    .sheet(isPresented: $showAddPanelDialog) {
      AddEditDialog(
        mode: .addMainPanel,
        name: $newPanelName,
        isPresented: $showAddPanelDialog,
        onConfirm: { name in
          _ = dm.addMainPanel(name: name)
          newPanelName = ""
          heightUpdateTrigger.toggle()
        }
      )
    }
    .sheet(isPresented: $showSnapshotAlert) {
      SnapshotDialog(mode: .new, name: $newSpaceName, spaceScreen: $spaceScreen, focus: $focus, isPresented: $showSnapshotAlert) { windows in
        SpaceManager.s.saveSpace(name: newSpaceName, scope: spaceScreen, focus: focus, windows: windows)
      }
    }
  }
}
