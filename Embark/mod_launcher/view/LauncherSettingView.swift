import SwiftUI

struct LauncherSettingView: View {
  @State private var launcher: Bool = LauncherConfig.launcher
  @State private var textSize: Double = LauncherConfig.launcherTextSize
  @State private var tabKey: TabKeyType = LauncherConfig.launcherTabKey
  @State private var searchScope: SearchScope = LauncherConfig.launcherSearchScope
  @State private var backgroundColor: Color = LauncherConfig.launcherBackgroundColor
  @State private var backgroundColorOpacity: Double = LauncherConfig.launcherBackgroundColorOpacity
  @State private var backgroundBlur: Double = LauncherConfig.launcherBackgroundBlur
  @State private var imageOpacity: Double = LauncherConfig.launcherBackgroundImageOpacity
  @State private var imageBlur: Double = LauncherConfig.launcherBackgroundImageBlur
  @State private var textColor: Color = LauncherConfig.launcherLinkTextColor
  @State private var autoTextColor: Bool = LauncherConfig.launcherAutoLinkTextColor
  @State private var linkBackgroundColor: Color = LauncherConfig.launcherLinkBackgroundColor
  @State private var autoLinkBackgroundColor: Bool = LauncherConfig.launcherAutoLinkBackgroundColor
  @State private var linkOpacity: Double = LauncherConfig.launcherLinkOpacity
  @State private var panelColor: Color = LauncherConfig.launcherPanelBackgroundColor
  @State private var autoPanelColor: Bool = LauncherConfig.launcherAutoPanelBackgroundColor
  @State private var panelColorOpacity: Double = LauncherConfig.launcherPanelOpacity
  @State private var panelWidth: Double = LauncherConfig.launcherPanelWidth
  @State private var titleBackgroundStretch: Bool = LauncherConfig.launcherPanelStretch
  @State private var titleTextBold: Bool = LauncherConfig.launcherPanelTextBold
  @State private var linkIconSize: Double = LauncherConfig.launcherLinkIconSize
  @State private var showThumbnails: Bool = LauncherConfig.launcherLinkThumbnails
  @State private var multiLineLinkNames: Bool = LauncherConfig.launcherLinkMultiLine
  @State private var panelTextColor: Color = LauncherConfig.launcherPanelTextColor
  @State private var autoPanelTextColor: Bool = LauncherConfig.launcherAutoPanelTextColor
  @State private var lastBackgroundColor: Color = LauncherConfig.launcherBackgroundColor
  @State private var lastBackgroundColorOpacity: Double = LauncherConfig.launcherBackgroundColorOpacity
  @State private var initialIconSize: Double = LauncherConfig.launcherLinkIconSize
  private let color1: Color = .blue
  private let color2: Color = .green
  private let color3: Color = .orange
  private let color4: Color = .purple
  private let color5: Color = .indigo
  private let color6: Color = .red
  private let fz: CGFloat = 12
  @State private var selectedTab: String = "general"

  var body: some View {
    VStack(spacing: 10) {
      HStack(spacing: 5) {
        Text(FeatureType.launcher.title)
          .font(.system(size: fz + 1, weight: .medium))
        Spacer()
        Toggle("", isOn: $launcher)
          .toggleStyle(SwitchToggleStyle())
          .scaleEffect(0.8)
          .offset(x: 5)
          .onChange(of: launcher) { newValue in
            LauncherConfig.launcher = newValue
            if newValue {
              LauncherWin.s.Show(mode: .launcher)
            } else {
              LauncherWin.s.Hide()
            }
            NotificationCenter.default.post(name: NSNotification.Name("LauncherConfigChanged"), object: nil)
          }
      }
      VStack(spacing: 10) {
        SegmentedControl(
          tabs: [
            SegmentedControlTab(id: "general", title: NSLocalizedString("launcher.settings.button.general", comment: "")),
            SegmentedControlTab(id: "content", title: NSLocalizedString("launcher.settings.button.content", comment: ""))
          ],
          selectedTab: $selectedTab,
          fontSize: fz
        ) { currentTab in
          switch currentTab {
          case "general":
            LauncherGeneralSection(
              color: color1,
              fz: fz,
              textSize: $textSize,
              tabKey: $tabKey,
              searchScope: $searchScope
            )
            LauncherBackgoundSeciton(
              fz: fz,
              backgroundColor: $backgroundColor,
              opacity: $backgroundColorOpacity,
              blur: $backgroundBlur,
              imageOpacity: $imageOpacity,
              imageBlur: $imageBlur,
              onColorChange: { newValue in
                if newValue != lastBackgroundColor {
                  lastBackgroundColor = newValue
                  LauncherConfig.launcherBackgroundColor = newValue
                  if autoTextColor {
                    textColor = LauncherConfig.getRecommendedColor(for: newValue)
                    LauncherConfig.launcherLinkTextColor = textColor
                  }
                  if autoLinkBackgroundColor {
                    linkBackgroundColor = LauncherConfig.getRecommendedColor(for: newValue)
                    LauncherConfig.launcherLinkBackgroundColor = linkBackgroundColor
                  }
                  if autoPanelTextColor {
                    panelTextColor = LauncherConfig.getRecommendedColor(for: newValue)
                    LauncherConfig.launcherPanelTextColor = panelTextColor
                  }
                  if autoPanelColor {
                    panelColor = LauncherConfig.getRecommendedColor(for: newValue)
                    LauncherConfig.launcherPanelBackgroundColor = panelColor
                  }
                  NotificationCenter.default.post(name: NSNotification.Name("LauncherThemeChanged"), object: nil)
                }
              },
              onOpacityChange: { newValue in
                if abs(newValue - lastBackgroundColorOpacity) > 0.001 {
                  lastBackgroundColorOpacity = newValue
                  LauncherConfig.launcherBackgroundColorOpacity = newValue
                  NotificationCenter.default.post(name: NSNotification.Name("LauncherThemeChanged"), object: nil)
                }
              }
            )
          case "content":
            LauncherLinkSection(
              fz: fz,
              linkIconSize: $linkIconSize,
              showThumbnails: $showThumbnails,
              multiLineLinkNames: $multiLineLinkNames,
              textColor: $textColor,
              autoTextColor: $autoTextColor,
              linkBackgroundColor: $linkBackgroundColor,
              autoLinkBackgroundColor: $autoLinkBackgroundColor,
              backgroundColor: $backgroundColor,
              linkOpacity: $linkOpacity,
            )
            LauncherPanelSection(
              fz: fz,
              panelWidth: $panelWidth,
              titleBackgroundStretch: $titleBackgroundStretch,
              titleTextBold: $titleTextBold,
              panelColorOpacity: $panelColorOpacity,
              panelColor: $panelColor,
              autoPanelColor: $autoPanelColor,
              panelTextColor: $panelTextColor,
              autoPanelTextColor: $autoPanelTextColor,
              backgroundColor: $backgroundColor,
            )
          default:
            EmptyView()
          }
        }
      }
      .disabledOverlay(isDisabled: !launcher, isLocked: false)
    }
    .padding(15)
    .frame(width: 460)
    .background(BlurredBackground(material: .underWindowBackground, blendingMode: .behindWindow, blur: 1.0))
    .onAppear {
      launcher = LauncherConfig.launcher
      textSize = LauncherConfig.launcherTextSize
      tabKey = LauncherConfig.launcherTabKey
      searchScope = LauncherConfig.launcherSearchScope
      textColor = LauncherConfig.launcherLinkTextColor
      linkBackgroundColor = LauncherConfig.launcherLinkBackgroundColor
      autoTextColor = LauncherConfig.launcherAutoLinkTextColor
      panelColor = LauncherConfig.launcherPanelBackgroundColor
      linkOpacity = LauncherConfig.launcherLinkOpacity
      autoPanelColor = LauncherConfig.launcherAutoPanelBackgroundColor
      panelTextColor = LauncherConfig.launcherPanelTextColor
      panelColor = LauncherConfig.launcherPanelBackgroundColor
      autoPanelTextColor = LauncherConfig.launcherAutoPanelTextColor
      panelColorOpacity = LauncherConfig.launcherPanelOpacity
      panelWidth = LauncherConfig.launcherPanelWidth
      titleBackgroundStretch = LauncherConfig.launcherPanelStretch
      titleTextBold = LauncherConfig.launcherPanelTextBold
      linkIconSize = LauncherConfig.launcherLinkIconSize
      initialIconSize = LauncherConfig.launcherLinkIconSize
      showThumbnails = LauncherConfig.launcherLinkThumbnails
      multiLineLinkNames = LauncherConfig.launcherLinkMultiLine
      backgroundColor = LauncherConfig.launcherBackgroundColor
      backgroundColorOpacity = LauncherConfig.launcherBackgroundColorOpacity
      backgroundBlur = LauncherConfig.launcherBackgroundBlur
      imageOpacity = LauncherConfig.launcherBackgroundImageOpacity
      imageBlur = LauncherConfig.launcherBackgroundImageBlur
      lastBackgroundColor = LauncherConfig.launcherBackgroundColor
      lastBackgroundColorOpacity = LauncherConfig.launcherBackgroundColorOpacity
      if launcher {
        if !LauncherWin.s.onShow {
          LauncherWin.s.Show(mode: .launcher)
        }
      }
    }
    .onDisappear {
      if linkIconSize != initialIconSize {
        DataManager.s.iconSizeChanged = true
      }
      LauncherWin.s.Hide()
    }
  }
}
