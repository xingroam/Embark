import SwiftUI

struct SwiftMouseGestureSection: View {
  let fz: CGFloat
  let colorMaximize: Color
  let colorClose: Color
  @Binding var gestureMinimize: SwiftMouseGesture
  @Binding var gestureRestore: SwiftMouseGesture
  @Binding var gestureMaximize: SwiftMouseGesture
  @Binding var gestureClose: SwiftMouseGesture
  @Binding var gestureLauncher: SwiftMouseGesture
  @Binding var gestureSpace: SwiftMouseGesture
  @Binding var gestureFocus: SwiftMouseGesture
  @Binding var gestureSlide: SwiftMouseGesture
  @Binding var gestureSwitcher: SwiftMouseGesture
  @Binding var maxMode: SwiftMaximizeMode
  @Binding var closeMode: SwiftCloseMode
  @State private var selectedTab: Int = 0
  @State private var linkGestures: [Int64: SwiftMouseGesture] = [:]
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
    .onAppear {
      let rawGestures = DatabaseManager.s.loadSwiftMouseLinks()
      var gestures: [Int64: SwiftMouseGesture] = [:]
      for (id, raw) in rawGestures {
        if let g = SwiftMouseGesture(rawValue: raw) {
          gestures[id] = g
        }
      }
      self.linkGestures = gestures
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
      gesturePicker(title: NSLocalizedString("swift.settings.minimize", comment: ""), binding: binding(for: .minimize), target: .minimize, showTooltip: true)
      gesturePicker(title: NSLocalizedString("swift.settings.restore", comment: ""), binding: binding(for: .restore), target: .restore)
      VStack(spacing: 10) {
        gesturePicker(title: NSLocalizedString("swift.settings.maximize", comment: ""), binding: binding(for: .maximize), target: .maximize, showTooltip: true)
        HStack(spacing: 5) {
          ForEach(SwiftMaximizeMode.allCases, id: \.self) { m in
            let sel = maxMode == m
            Button(action: {
              maxMode = m
              SwiftMouseConfig.swiftMouseMaximizeMode = m
              NotificationCenter.default.post(name: NSNotification.Name("SwiftMouseConfigChanged"), object: nil)
            }) {
              ModeButtonLabel(text: m.displayName, selected: sel, color: colorMaximize, fz: fz)
                .opacity(gestureMaximize == .none ? 0.5 : 1.0)
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(gestureMaximize == .none)
          }
        }
      }
      VStack(spacing: 10) {
        gesturePicker(title: NSLocalizedString("swift.settings.close", comment: ""), binding: binding(for: .close), target: .close, showTooltip: true)
        HStack(spacing: 5) {
          ForEach(SwiftCloseMode.allCases, id: \.self) { m in
            let sel = closeMode == m
            Button(action: {
              closeMode = m
              SwiftMouseConfig.swiftMouseCloseMode = m
              NotificationCenter.default.post(name: NSNotification.Name("SwiftMouseConfigChanged"), object: nil)
            }) {
              ModeButtonLabel(text: m.displayName, selected: sel, color: colorClose, fz: fz)
                .opacity(gestureClose == .none ? 0.5 : 1.0)
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(gestureClose == .none)
          }
        }
      }
    }
  }

  private func launchBaySettingsView() -> some View {
    VStack(spacing: 10) {
      gesturePicker(title: FeatureType.launcher.title, binding: binding(for: .launcher), target: .launcher, isDisabled: !LauncherConfig.launcher)
      VStack(spacing: 10) {
        gesturePicker(title: FeatureType.space.title, binding: binding(for: .space), target: .space, isDisabled: !SpaceConfig.space)
        gesturePicker(title: FeatureType.focus.title, binding: binding(for: .focus), target: .focus)
        gesturePicker(title: FeatureType.slide.title, binding: binding(for: .slide), target: .slide, isDisabled: !SlideConfig.slide)
        gesturePicker(title: FeatureType.switcher.title, binding: binding(for: .switcher), target: .switcher, isDisabled: !SwitcherConfig.switcher)
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
            let binding = Binding<SwiftMouseGesture>(
              get: { linkGestures[link.id] ?? SwiftMouseGesture.none },
              set: { newValue in
                updateLinkGesture(linkId: link.id, newGesture: newValue)
              }
            )
            Picker("", selection: binding) {
              ForEach(SwiftMouseGesture.allCases, id: \.self) { gesture in
                if !getDisabledGestures().contains(gesture) {
                  Image(systemName: gesture.symbol).tag(gesture)
                }
              }
            }
            .pickerStyle(MenuPickerStyle())
            .frame(width: 60)
          }
        }
      }
    }
    .frame(height: 300)
  }

  private func updateLinkGesture(linkId: Int64, newGesture: SwiftMouseGesture) {
    let oldGesture = linkGestures[linkId] ?? SwiftMouseGesture.none
    if newGesture == oldGesture { return }
    let targets: [GestureTarget] = [.minimize, .restore, .maximize, .close, .launcher, .space, .focus, .slide, .switcher]
    for t in targets {
      if getGesture(t) == newGesture {
        setGesture(t, value: SwiftMouseGesture.none)
        saveConfig()
        break
      }
    }
    for (otherId, otherGesture) in linkGestures {
      if otherId != linkId && otherGesture == newGesture {
        linkGestures[otherId] = SwiftMouseGesture.none
        DatabaseManager.s.deleteSwiftMouseLink(linkId: otherId)
        break
      }
    }
    linkGestures[linkId] = newGesture
    if newGesture == SwiftMouseGesture.none {
      DatabaseManager.s.deleteSwiftMouseLink(linkId: linkId)
    } else {
      DatabaseManager.s.saveSwiftMouseLink(linkId: linkId, gesture: newGesture.rawValue)
    }
    NotificationCenter.default.post(name: NSNotification.Name("SwiftMouseConfigChanged"), object: nil)
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

  private func gesturePicker(title: String, binding: Binding<SwiftMouseGesture>, target: GestureTarget, showTooltip: Bool = false, isDisabled: Bool = false) -> some View {
    let disabledGestures = target == .switcher ? [] : getDisabledGestures()
    return HStack(spacing: 5) {
      if showTooltip {
        HStack(alignment: .firstTextBaseline, spacing: 5) {
          Text(title)
            .font(.system(size: fz, weight: .regular))
          Image(systemName: "questionmark.circle")
            .foregroundColor(.primary)
            .font(.system(size: fz))
            .tooltip(NSLocalizedString("swift.settings.tooltip", comment: ""), edge: .top, coordinateSpaceName: "SwiftSettingWindow") {
              SwiftSettingWin.s.getWindowFrame()
            }
        }
      } else {
        Text(title)
          .font(.system(size: fz, weight: .regular))
      }
      Spacer()
      Picker("", selection: binding) {
        ForEach(SwiftMouseGesture.allCases, id: \.self) { gesture in
          if !disabledGestures.contains(gesture) {
            Image(systemName: gesture.symbol).tag(gesture)
          }
        }
      }
      .pickerStyle(MenuPickerStyle())
      .fixedSize(horizontal: true, vertical: false)
      .disabled(isDisabled)
      .opacity(isDisabled ? 0.5 : 1.0)
    }
  }

  private func getDisabledGestures() -> Set<SwiftMouseGesture> {
    if SwitcherConfig.switcherMode == .switchMode {
      switch gestureSwitcher {
      case .up: return [.upLeft, .upRight]
      case .down: return [.downLeft, .downRight]
      case .left: return [.leftUp, .leftDown]
      case .right: return [.rightUp, .rightDown]
      default: return []
      }
    }
    return []
  }

  private enum GestureTarget {
    case minimize, restore, maximize, close, launcher, space, focus, slide, switcher
  }

  private func getGesture(_ target: GestureTarget) -> SwiftMouseGesture {
    switch target {
    case .minimize: return gestureMinimize
    case .restore: return gestureRestore
    case .maximize: return gestureMaximize
    case .close: return gestureClose
    case .launcher: return gestureLauncher
    case .space: return gestureSpace
    case .focus: return gestureFocus
    case .slide: return gestureSlide
    case .switcher: return gestureSwitcher
    }
  }

  private func setGesture(_ target: GestureTarget, value: SwiftMouseGesture) {
    switch target {
    case .minimize: gestureMinimize = value
    case .restore: gestureRestore = value
    case .maximize: gestureMaximize = value
    case .close: gestureClose = value
    case .launcher: gestureLauncher = value
    case .space: gestureSpace = value
    case .focus: gestureFocus = value
    case .slide: gestureSlide = value
    case .switcher: gestureSwitcher = value
    }
  }

  private func binding(for target: GestureTarget) -> Binding<SwiftMouseGesture> {
    Binding<SwiftMouseGesture>(
      get: { self.getGesture(target) },
      set: { newValue in
        let oldValue = self.getGesture(target)
        if newValue != oldValue {
          self.setGesture(target, value: newValue)
          if newValue != SwiftMouseGesture.none {
            self.resetConflictingGesture(target: target, oldGesture: oldValue, newGesture: newValue)
          }
          self.saveConfig()
          NotificationCenter.default.post(name: NSNotification.Name("SwiftMouseConfigChanged"), object: nil)
        }
      }
    )
  }

  private func resetConflictingGesture(target: GestureTarget, oldGesture: SwiftMouseGesture, newGesture: SwiftMouseGesture) {
    let targets: [GestureTarget] = [.minimize, .restore, .maximize, .close, .launcher, .space, .focus, .slide, .switcher]
    var conflictFound = false
    for t in targets {
      if t != target && getGesture(t) == newGesture {
        setGesture(t, value: SwiftMouseGesture.none)
        conflictFound = true
        break
      }
    }
    if !conflictFound {
      for (linkId, gesture) in linkGestures {
        if gesture == newGesture {
          linkGestures[linkId] = SwiftMouseGesture.none
          DatabaseManager.s.deleteSwiftMouseLink(linkId: linkId)
          break
        }
      }
    }
  }

  private func saveConfig() {
    SwiftMouseConfig.swiftMouseMinimize = gestureMinimize
    SwiftMouseConfig.swiftMouseRestore = gestureRestore
    SwiftMouseConfig.swiftMouseMaximize = gestureMaximize
    SwiftMouseConfig.swiftMouseClose = gestureClose
    SwiftMouseConfig.swiftMouseLauncher = gestureLauncher
    SwiftMouseConfig.swiftMouseSpace = gestureSpace
    SwiftMouseConfig.swiftMouseFocus = gestureFocus
    SwiftMouseConfig.swiftMouseSlide = gestureSlide
    SwiftMouseConfig.swiftMouseSwitcher = gestureSwitcher
  }
}
