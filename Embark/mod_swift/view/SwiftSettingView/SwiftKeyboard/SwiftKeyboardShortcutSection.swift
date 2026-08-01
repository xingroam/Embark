import SwiftUI

struct SwiftKeyboardShortcutSection: View {
  let colorMinimize: Color
  let colorMaximize: Color
  let colorClose: Color
  let colorEmbark: Color
  let fz: CGFloat
  let opts: [SwiftShortcut]
  @Binding var minIdx: Int?
  @Binding var reIdx: Int?
  @Binding var maxIdx: Int?
  @Binding var closeIdx: Int?
  @Binding var launcherIdx: Int?
  @Binding var spaceIdx: Int?
  @Binding var focusIdx: Int?
  @Binding var slideIdx: Int?
  @Binding var switcherIdx: Int?
  @Binding var maxMode: SwiftMaximizeMode
  @Binding var closeMode: SwiftCloseMode
  let selectedSubTab: String?
  @State private var selectedTab: Int = 0
  @State private var linkShortcuts: [Int64: Int] = [:]
  @State private var sortedLinks: [LinkData] = []

  var body: some View {
    HStack(alignment: .top, spacing: 10) {
      VStack(spacing: 5) {
        sidebarItem(title: NSLocalizedString("swift.settings.tab.window", comment: ""), tag: 0)
        sidebarItem(title: EmbarkInfo.name, tag: 1)
        sidebarItem(title: FeatureType.launcher.title, tag: 2, isDisabled: !LauncherConfig.launcher)
      }
      .frame(width: 100)
      .padding(10)
      .background(Color.secondary.opacity(0.05))
      .cornerRadius(6)
      VStack(spacing: 0) {
        switch selectedTab {
        case 0:
          windowSettingsView()
        case 1:
          launchBaySettingsView()
        default:
          linkSettingsView()
        }
      }
      .cardStyle()
    }
    .fixedSize(horizontal: false, vertical: true)
    .cornerRadius(6)
    .onAppear {
      if let subTab = selectedSubTab {
        if subTab == EmbarkInfo.name {
          selectedTab = 1
        }
      }
      let rawShortcuts = DatabaseManager.s.loadSwiftKeyboardLinks()
      var shortcuts: [Int64: Int] = [:]
      for (id, raw) in rawShortcuts {
        if let idx = opts.firstIndex(where: { $0.rawValue == raw }) {
          shortcuts[id] = idx
        }
      }
      self.linkShortcuts = shortcuts
      let allLinks = Array(DataManager.s.linkData.values)
      DispatchQueue.global(qos: .userInitiated).async {
        let links = allLinks.filter({ $0.id != -1 }).sorted(by: {
          if $0.panelId != $1.panelId {
            return $0.panelId < $1.panelId
          }
          return $0.orderIndex < $1.orderIndex
        })
        DispatchQueue.main.async {
          self.sortedLinks = links
        }
      }
    }
  }

  private func windowSettingsView() -> some View {
    VStack(spacing: 10) {
      headerWithTooltip(title: "swift.settings.minimize", showTooltip: true)
      shortcutRow(selectedIdx: $minIdx, type: .minimize, color: colorMinimize)
      headerWithTooltip(title: "swift.settings.restore", showTooltip: false)
      shortcutRow(selectedIdx: $reIdx, type: .restore, color: colorMinimize)
      headerWithTooltip(title: "swift.settings.maximize", showTooltip: true)
      shortcutRow(selectedIdx: $maxIdx, type: .maximize, color: colorMaximize)
      HStack(spacing: 5) {
        ForEach(SwiftMaximizeMode.allCases, id: \.self) { m in
          let sel = maxMode == m
          Button(action: {
            maxMode = m
            SwiftKeyboardConfig.swiftKeyboardMaximizeMode = m
            NotificationCenter.default.post(name: NSNotification.Name("SwiftKeyboardConfigChanged"), object: nil)
          }) {
            ModeButtonLabel(text: m.displayName, selected: sel, color: colorMaximize, fz: fz)
              .opacity(maxIdx == nil ? 0.5 : 1.0)
          }
          .buttonStyle(PlainButtonStyle())
          .disabled(maxIdx == nil)
        }
      }
      headerWithTooltip(title: "swift.settings.close", showTooltip: true)
      shortcutRow(selectedIdx: $closeIdx, type: .close, color: colorClose)
      HStack(spacing: 5) {
        ForEach(SwiftCloseMode.allCases, id: \.self) { m in
          let sel = closeMode == m
          Button(action: {
            closeMode = m
            SwiftKeyboardConfig.swiftKeyboardCloseMode = m
            NotificationCenter.default.post(name: NSNotification.Name("SwiftKeyboardConfigChanged"), object: nil)
          }) {
            ModeButtonLabel(text: m.displayName, selected: sel, color: colorClose, fz: fz)
              .opacity(closeIdx == nil ? 0.5 : 1.0)
          }
          .buttonStyle(PlainButtonStyle())
          .disabled(closeIdx == nil)
        }
      }
    }
  }

  private func launchBaySettingsView() -> some View {
    VStack(spacing: 10) {
      headerWithTooltip(title: FeatureType.launcher.title, showTooltip: false)
      shortcutRow(selectedIdx: $launcherIdx, type: .launcher, color: colorEmbark, isDisabled: !LauncherConfig.launcher)
      headerWithTooltip(title: FeatureType.space.title, showTooltip: false)
      shortcutRow(selectedIdx: $spaceIdx, type: .space, color: colorEmbark, isDisabled: !SpaceConfig.space)
      VStack(spacing: 10) {
        headerWithTooltip(title: FeatureType.focus.title, showTooltip: false)
        shortcutRow(selectedIdx: $focusIdx, type: .focus, color: colorEmbark)
        headerWithTooltip(title: FeatureType.slide.title, showTooltip: false)
        shortcutRow(selectedIdx: $slideIdx, type: .slide, color: colorEmbark, isDisabled: !SlideConfig.slide)
        headerWithTooltip(title: FeatureType.switcher.title, showTooltip: false)
        shortcutRow(selectedIdx: $switcherIdx, type: .switcher, color: colorEmbark, isDisabled: !SwitcherConfig.switcher)
      }
    }
  }

  private func linkSettingsView() -> some View {
    return ScrollView {
      LazyVStack(spacing: 10) {
        ForEach(sortedLinks, id: \.id) { link in
          HStack {
            if let icon = link.icon {
              Image(nsImage: icon)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 18, height: 18)
            } else {
              Image(systemName: link.linkType.iconName)
                .font(.system(size: 14))
                .frame(width: 18, height: 18)
                .foregroundColor(.secondary)
            }
            Text(link.title ?? link.name)
              .lineLimit(1)
            Spacer()
            let binding = Binding<Int?>(
              get: { linkShortcuts[link.id] },
              set: { newValue in
                updateLinkShortcut(linkId: link.id, newIndex: newValue)
              }
            )
            Picker("", selection: binding) {
              Text(NSLocalizedString("system.info.none", comment: "")).tag(nil as Int?)
              ForEach(opts.indices, id: \.self) { i in
                Text(opts[i].rawValue).tag(i as Int?)
              }
            }
            .pickerStyle(MenuPickerStyle())
            .fixedSize(horizontal: true, vertical: false)
          }
        }
      }
    }
    .frame(height: 300)
  }

  private func updateLinkShortcut(linkId: Int64, newIndex: Int?) {
    let oldIndex = linkShortcuts[linkId]
    if newIndex == oldIndex { return }
    if let idx = newIndex {
      if minIdx == idx { minIdx = nil; SwiftKeyboardConfig.swiftKeyboardMinimize = nil }
      if reIdx == idx { reIdx = nil; SwiftKeyboardConfig.swiftKeyboardRestore = nil }
      if maxIdx == idx { maxIdx = nil; SwiftKeyboardConfig.swiftKeyboardMaximize = nil }
      if closeIdx == idx { closeIdx = nil; SwiftKeyboardConfig.swiftKeyboardClose = nil }
      if launcherIdx == idx { launcherIdx = nil; SwiftKeyboardConfig.swiftKeyboardLauncher = nil }
      if spaceIdx == idx { spaceIdx = nil; SwiftKeyboardConfig.swiftKeyboardSpace = nil }
      if focusIdx == idx { focusIdx = nil; SwiftKeyboardConfig.swiftKeyboardFocus = nil }
      if slideIdx == idx { slideIdx = nil; SwiftKeyboardConfig.swiftKeyboardSlide = nil }
      if switcherIdx == idx { switcherIdx = nil; SwiftKeyboardConfig.swiftKeyboardSwitcher = nil }
      for (otherId, otherIdx) in linkShortcuts {
        if otherId != linkId && otherIdx == idx {
          linkShortcuts[otherId] = nil
          DatabaseManager.s.deleteSwiftKeyboardLink(linkId: otherId)
          break
        }
      }
    }
    linkShortcuts[linkId] = newIndex
    if let idx = newIndex {
      DatabaseManager.s.saveSwiftKeyboardLink(linkId: linkId, shortcut: opts[idx].rawValue)
    } else {
      DatabaseManager.s.deleteSwiftKeyboardLink(linkId: linkId)
    }
    NotificationCenter.default.post(name: NSNotification.Name("SwiftKeyboardConfigChanged"), object: nil)
  }

  private func sidebarItem(title: String, tag: Int, isDisabled: Bool = false) -> some View {
    Button(action: { selectedTab = tag }) {
      Text(title)
        .font(.system(size: fz))
        .foregroundColor(selectedTab == tag ? .white : .primary)
        .padding(5)
        .frame(maxWidth: .infinity, alignment: .center)
        .background(selectedTab == tag ? Color.accentColor : Color.clear)
        .cornerRadius(100)
        .contentShape(Rectangle())
    }
    .buttonStyle(PlainButtonStyle())
    .disabled(isDisabled)
    .opacity(isDisabled ? 0.5 : 1.0)
  }

  private func headerWithTooltip(title: String, showTooltip: Bool) -> some View {
    HStack(alignment: .firstTextBaseline, spacing: 5) {
      Text(NSLocalizedString(title, comment: ""))
        .font(.system(size: fz))
      if showTooltip {
        Image(systemName: "questionmark.circle")
          .foregroundColor(.primary)
          .font(.system(size: fz))
          .tooltip(NSLocalizedString("swift.settings.tooltip", comment: ""), edge: .top, coordinateSpaceName: "SwiftSettingWindow") {
            SwiftSettingWin.s.getWindowFrame()
          }
      }
      Spacer()
    }
  }

  private func shortcutRow(selectedIdx: Binding<Int?>, type: ShortcutType, color: Color, isDisabled: Bool = false) -> some View {
    HStack(spacing: 5) {
      ForEach(opts.indices, id: \.self) { i in
        Button(action: {
          handleTap(i, type: type)
        }) {
          ShortcutButtonLabel(text: opts[i].rawValue, selected: selectedIdx.wrappedValue == i, color: color, fz: fz)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.5 : 1.0)
      }
    }
  }

  private enum ShortcutType {
    case minimize, restore, maximize, close, launcher, space, focus, slide, switcher
  }

  private func handleTap(_ i: Int, type: ShortcutType) {
    let isSelected: Bool
    switch type {
      case .minimize: isSelected = (minIdx == i)
      case .restore: isSelected = (reIdx == i)
      case .maximize: isSelected = (maxIdx == i)
      case .close: isSelected = (closeIdx == i)
      case .launcher: isSelected = (launcherIdx == i)
      case .space: isSelected = (spaceIdx == i)
      case .focus: isSelected = (focusIdx == i)
      case .slide: isSelected = (slideIdx == i)
      case .switcher: isSelected = (switcherIdx == i)
    }
    if isSelected {
      switch type {
        case .minimize: minIdx = nil; SwiftKeyboardConfig.swiftKeyboardMinimize = nil
        case .restore: reIdx = nil; SwiftKeyboardConfig.swiftKeyboardRestore = nil
        case .maximize: maxIdx = nil; SwiftKeyboardConfig.swiftKeyboardMaximize = nil
        case .close: closeIdx = nil; SwiftKeyboardConfig.swiftKeyboardClose = nil
        case .launcher: launcherIdx = nil; SwiftKeyboardConfig.swiftKeyboardLauncher = nil
        case .space: spaceIdx = nil; SwiftKeyboardConfig.swiftKeyboardSpace = nil
        case .focus: focusIdx = nil; SwiftKeyboardConfig.swiftKeyboardFocus = nil
        case .slide: slideIdx = nil; SwiftKeyboardConfig.swiftKeyboardSlide = nil
        case .switcher: switcherIdx = nil; SwiftKeyboardConfig.swiftKeyboardSwitcher = nil
      }
    } else {
      switch type {
        case .minimize: minIdx = i; SwiftKeyboardConfig.swiftKeyboardMinimize = opts[i]
        case .restore: reIdx = i; SwiftKeyboardConfig.swiftKeyboardRestore = opts[i]
        case .maximize: maxIdx = i; SwiftKeyboardConfig.swiftKeyboardMaximize = opts[i]
        case .close: closeIdx = i; SwiftKeyboardConfig.swiftKeyboardClose = opts[i]
        case .launcher: launcherIdx = i; SwiftKeyboardConfig.swiftKeyboardLauncher = opts[i]
        case .space: spaceIdx = i; SwiftKeyboardConfig.swiftKeyboardSpace = opts[i]
        case .focus: focusIdx = i; SwiftKeyboardConfig.swiftKeyboardFocus = opts[i]
        case .slide: slideIdx = i; SwiftKeyboardConfig.swiftKeyboardSlide = opts[i]
        case .switcher: switcherIdx = i; SwiftKeyboardConfig.swiftKeyboardSwitcher = opts[i]
      }
      if type != .minimize && minIdx == i { minIdx = nil; SwiftKeyboardConfig.swiftKeyboardMinimize = nil }
      if type != .restore && reIdx == i { reIdx = nil; SwiftKeyboardConfig.swiftKeyboardRestore = nil }
      if type != .maximize && maxIdx == i { maxIdx = nil; SwiftKeyboardConfig.swiftKeyboardMaximize = nil }
      if type != .close && closeIdx == i { closeIdx = nil; SwiftKeyboardConfig.swiftKeyboardClose = nil }
      if type != .launcher && launcherIdx == i { launcherIdx = nil; SwiftKeyboardConfig.swiftKeyboardLauncher = nil }
      if type != .space && spaceIdx == i { spaceIdx = nil; SwiftKeyboardConfig.swiftKeyboardSpace = nil }
      if type != .focus && focusIdx == i { focusIdx = nil; SwiftKeyboardConfig.swiftKeyboardFocus = nil }
      if type != .slide && slideIdx == i { slideIdx = nil; SwiftKeyboardConfig.swiftKeyboardSlide = nil }
      if type != .switcher && switcherIdx == i { switcherIdx = nil; SwiftKeyboardConfig.swiftKeyboardSwitcher = nil }
      for (linkId, idx) in linkShortcuts {
        if idx == i {
          linkShortcuts[linkId] = nil
          DatabaseManager.s.deleteSwiftKeyboardLink(linkId: linkId)
        }
      }
    }
    NotificationCenter.default.post(name: NSNotification.Name("SwiftKeyboardConfigChanged"), object: nil)
  }
}
