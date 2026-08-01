import SwiftUI

struct SwiftSettingView: View {
  @State private var minIdx: Int? = SwiftShortcut.allCases.firstIndex(where: { $0 == SwiftKeyboardConfig.swiftKeyboardMinimize })
  @State private var reIdx: Int? = SwiftShortcut.allCases.firstIndex(where: { $0 == SwiftKeyboardConfig.swiftKeyboardRestore })
  @State private var maxIdx: Int? = SwiftShortcut.allCases.firstIndex(where: { $0 == SwiftKeyboardConfig.swiftKeyboardMaximize })
  @State private var closeIdx: Int? = SwiftShortcut.allCases.firstIndex(where: { $0 == SwiftKeyboardConfig.swiftKeyboardClose })
  @State private var launcherIdx: Int? = SwiftShortcut.allCases.firstIndex(where: { $0 == SwiftKeyboardConfig.swiftKeyboardLauncher })
  @State private var spaceIdx: Int? = SwiftShortcut.allCases.firstIndex(where: { $0 == SwiftKeyboardConfig.swiftKeyboardSpace })
  @State private var focusIdx: Int? = SwiftShortcut.allCases.firstIndex(where: { $0 == SwiftKeyboardConfig.swiftKeyboardFocus })
  @State private var slideIdx: Int? = SwiftShortcut.allCases.firstIndex(where: { $0 == SwiftKeyboardConfig.swiftKeyboardSlide })
  @State private var switcherIdx: Int? = SwiftShortcut.allCases.firstIndex(where: { $0 == SwiftKeyboardConfig.swiftKeyboardSwitcher })
  @State private var mouseMaxMode: SwiftMaximizeMode = SwiftMouseConfig.swiftMouseMaximizeMode
  @State private var mouseCloseMode: SwiftCloseMode = SwiftMouseConfig.swiftMouseCloseMode
  @State private var keyboardMaxMode: SwiftMaximizeMode = SwiftKeyboardConfig.swiftKeyboardMaximizeMode
  @State private var keyboardCloseMode: SwiftCloseMode = SwiftKeyboardConfig.swiftKeyboardCloseMode
  @State private var detection: Double = SwiftKeyboardConfig.swiftKeyboardDetection
  @State private var swiftMouse: Bool = SwiftMouseConfig.swiftMouse
  @State private var swiftKeyboard: Bool = SwiftKeyboardConfig.swiftKeyboard
  @State private var swiftMouseDistance: Double = SwiftMouseConfig.swiftMouseDistance
  @State private var swiftMousePathOpacity: Double = SwiftMouseConfig.swiftMousePathOpacity
  @State private var gestureMinimize: SwiftMouseGesture = SwiftMouseConfig.swiftMouseMinimize
  @State private var gestureRestore: SwiftMouseGesture = SwiftMouseConfig.swiftMouseRestore
  @State private var gestureMaximize: SwiftMouseGesture = SwiftMouseConfig.swiftMouseMaximize
  @State private var gestureClose: SwiftMouseGesture = SwiftMouseConfig.swiftMouseClose
  @State private var gestureLauncher: SwiftMouseGesture = SwiftMouseConfig.swiftMouseLauncher
  @State private var gestureSpace: SwiftMouseGesture = SwiftMouseConfig.swiftMouseSpace
  @State private var gestureFocus: SwiftMouseGesture = SwiftMouseConfig.swiftMouseFocus
  @State private var gestureSlide: SwiftMouseGesture = SwiftMouseConfig.swiftMouseSlide
  @State private var gestureSwitcher: SwiftMouseGesture = SwiftMouseConfig.swiftMouseSwitcher
  @State private var selectedTab: String
  private let color1: Color = .blue
  private let color2: Color = .green
  private let color3: Color = .orange
  private let color4: Color = .purple
  private let color5: Color = .indigo
  private let color6: Color = .red
  private let fz: CGFloat = 12
  private let opts = SwiftShortcut.allCases.filter { $0 != .disabled }
  private let selectedSubTab: String?

  init(selectedTab: String = "mouse", selectedSubTab: String? = nil) {
    _selectedTab = State(initialValue: selectedTab)
    self.selectedSubTab = selectedSubTab
  }

  var body: some View {
    VStack(spacing: 10) {
      SegmentedControl(
        tabs: [
          SegmentedControlTab(id: "mouse", title: NSLocalizedString("swift.mouse.title", comment: "")),
          SegmentedControlTab(id: "keyboard", title: NSLocalizedString("swift.keyboard.title", comment: ""))
        ],
        selectedTab: $selectedTab,
        fontSize: fz
      ) { currentTab in
        switch currentTab {
        case "mouse":
          VStack(spacing: 10) {
            HStack(spacing: 5) {
              Text(NSLocalizedString("swift.mouse.title", comment: "") + " " + NSLocalizedString("swift.mouse.settings.note", comment: ""))
                .font(.system(size: fz + 1, weight: .medium))
              Spacer()
              Toggle("", isOn: $swiftMouse)
                .toggleStyle(SwitchToggleStyle())
                .scaleEffect(0.8)
                .offset(x: 5)
                .onChange(of: swiftMouse) { newValue in
                  SwiftMouseConfig.swiftMouse = newValue
                  NotificationCenter.default.post(name: NSNotification.Name("SwiftMouseConfigChanged"), object: nil)
                }
            }
            VStack(spacing: 10) {
              SwiftMouseGestureSection(
                fz: fz,
                colorMaximize: color3,
                colorClose: color4,
                gestureMinimize: $gestureMinimize,
                gestureRestore: $gestureRestore,
                gestureMaximize: $gestureMaximize,
                gestureClose: $gestureClose,
                gestureLauncher: $gestureLauncher,
                gestureSpace: $gestureSpace,
                gestureFocus: $gestureFocus,
                gestureSlide: $gestureSlide,
                gestureSwitcher: $gestureSwitcher,
                maxMode: $mouseMaxMode,
                closeMode: $mouseCloseMode
              )
              SwiftMouseGeneralSection(
                color: color1,
                fz: fz,
                swiftMouseDistance: $swiftMouseDistance,
                swiftMousePathOpacity: $swiftMousePathOpacity
              )
              SwiftMouseExcludeSection(
                color: color6,
                fz: fz
              )
            }
            .disabledOverlay(isDisabled: !swiftMouse, isLocked: false)
          }
        case "keyboard":
          VStack(spacing: 10) {
            HStack(spacing: 5) {
              Text(NSLocalizedString("swift.keyboard.title", comment: "") + " " + NSLocalizedString("swift.keyboard.settings.note", comment: ""))
                .font(.system(size: fz + 1, weight: .medium))
              Spacer()
              Toggle("", isOn: $swiftKeyboard)
                .toggleStyle(SwitchToggleStyle())
                .scaleEffect(0.8)
                .offset(x: 5)
                .onChange(of: swiftKeyboard) { newValue in
                  SwiftKeyboardConfig.swiftKeyboard = newValue
                  NotificationCenter.default.post(name: NSNotification.Name("SwiftKeyboardConfigChanged"), object: nil)
                }
            }
            VStack(spacing: 10) {
              SwiftKeyboardShortcutSection(
                colorMinimize: color2,
                colorMaximize: color3,
                colorClose: color4,
                colorEmbark: color1,
                fz: fz,
                opts: opts,
                minIdx: $minIdx,
                reIdx: $reIdx,
                maxIdx: $maxIdx,
                closeIdx: $closeIdx,
                launcherIdx: $launcherIdx,
                spaceIdx: $spaceIdx,
                focusIdx: $focusIdx,
                slideIdx: $slideIdx,
                switcherIdx: $switcherIdx,
                maxMode: $keyboardMaxMode,
                closeMode: $keyboardCloseMode,
                selectedSubTab: selectedSubTab
              )
              SwiftKeyboardDetectionSection(
                color: color5,
                fz: fz,
                detection: $detection
              )
            }
            .disabledOverlay(isDisabled: !swiftKeyboard, isLocked: false)
          }
        default:
          EmptyView()
        }
      }
    }
    .padding(15)
    .frame(width: 480)
    .coordinateSpace(name: "SwiftSettingWindow")
    .background(BlurredBackground(material: .underWindowBackground, blendingMode: .behindWindow, blur: 1.0))
    .onAppear {
      updateState()
      NotificationCenter.default.addObserver(forName: NSNotification.Name("SwiftMouseConfigChanged"), object: nil, queue: .main) { _ in
        updateState()
      }
    }
  }

  private func updateState() {
    minIdx = SwiftShortcut.allCases.firstIndex(where: { $0 == SwiftKeyboardConfig.swiftKeyboardMinimize })
    reIdx = SwiftShortcut.allCases.firstIndex(where: { $0 == SwiftKeyboardConfig.swiftKeyboardRestore })
    maxIdx = SwiftShortcut.allCases.firstIndex(where: { $0 == SwiftKeyboardConfig.swiftKeyboardMaximize })
    closeIdx = SwiftShortcut.allCases.firstIndex(where: { $0 == SwiftKeyboardConfig.swiftKeyboardClose })
    launcherIdx = SwiftShortcut.allCases.firstIndex(where: { $0 == SwiftKeyboardConfig.swiftKeyboardLauncher })
    spaceIdx = SwiftShortcut.allCases.firstIndex(where: { $0 == SwiftKeyboardConfig.swiftKeyboardSpace })
    focusIdx = SwiftShortcut.allCases.firstIndex(where: { $0 == SwiftKeyboardConfig.swiftKeyboardFocus })
    slideIdx = SwiftShortcut.allCases.firstIndex(where: { $0 == SwiftKeyboardConfig.swiftKeyboardSlide })
    switcherIdx = SwiftShortcut.allCases.firstIndex(where: { $0 == SwiftKeyboardConfig.swiftKeyboardSwitcher })
    mouseMaxMode = SwiftMouseConfig.swiftMouseMaximizeMode
    mouseCloseMode = SwiftMouseConfig.swiftMouseCloseMode
    keyboardMaxMode = SwiftKeyboardConfig.swiftKeyboardMaximizeMode
    keyboardCloseMode = SwiftKeyboardConfig.swiftKeyboardCloseMode
    detection = SwiftKeyboardConfig.swiftKeyboardDetection
    swiftMouse = SwiftMouseConfig.swiftMouse
    swiftKeyboard = SwiftKeyboardConfig.swiftKeyboard
    swiftMouseDistance = SwiftMouseConfig.swiftMouseDistance
    swiftMousePathOpacity = SwiftMouseConfig.swiftMousePathOpacity
    gestureMinimize = SwiftMouseConfig.swiftMouseMinimize
    gestureRestore = SwiftMouseConfig.swiftMouseRestore
    gestureMaximize = SwiftMouseConfig.swiftMouseMaximize
    gestureClose = SwiftMouseConfig.swiftMouseClose
    gestureLauncher = SwiftMouseConfig.swiftMouseLauncher
    gestureSpace = SwiftMouseConfig.swiftMouseSpace
    gestureFocus = SwiftMouseConfig.swiftMouseFocus
    gestureSlide = SwiftMouseConfig.swiftMouseSlide
    gestureSwitcher = SwiftMouseConfig.swiftMouseSwitcher
  }
}
