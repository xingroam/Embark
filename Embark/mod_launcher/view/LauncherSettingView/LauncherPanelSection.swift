import SwiftUI

struct LauncherPanelSection: View {
  let fz: CGFloat
  @Binding var panelWidth: Double
  @Binding var titleBackgroundStretch: Bool
  @Binding var titleTextBold: Bool
  @Binding var panelColorOpacity: Double
  @Binding var panelColor: Color
  @Binding var autoPanelColor: Bool
  @Binding var panelTextColor: Color
  @Binding var autoPanelTextColor: Bool
  @Binding var backgroundColor: Color

  var body: some View {
    VStack(spacing: 10) {
      HStack(spacing: 10) {
        Text(NSLocalizedString("launcher.settings.panel.title", comment: ""))
          .font(.system(size: fz + 1, weight: .medium))
        Spacer()
      }
      VStack(spacing: 10) {
        HStack(spacing: 10) {
          Text("\(NSLocalizedString("launcher.settings.panel.width", comment: "").replacingOccurrences(of: "%@", with: "\(Int(panelWidth))"))")
            .font(.system(size: fz))
            .frame(maxWidth: .infinity, alignment: .leading)
          CustomSlider.panelWidth(value: $panelWidth)
            .frame(maxWidth: .infinity)
            .onChange(of: panelWidth) { newValue in
              LauncherConfig.launcherPanelWidth = newValue
              NotificationCenter.default.post(name: NSNotification.Name("LauncherPanelWidthChanged"), object: nil)
              NotificationCenter.default.post(name: NSNotification.Name("LauncherThemeChanged"), object: nil)
            }
        }
        HStack(spacing: 5) {
          Text(NSLocalizedString("launcher.settings.panel.text_color", comment: ""))
            .font(.system(size: fz))
          Spacer()
          CustomPicker(fz: fz, selection: $autoPanelTextColor)
            .onChange(of: autoPanelTextColor) { newValue in
              LauncherConfig.launcherAutoPanelTextColor = newValue
              panelTextColor = LauncherConfig.getRecommendedColor(for: backgroundColor)
              LauncherConfig.launcherPanelTextColor = panelTextColor
              NotificationCenter.default.post(name: NSNotification.Name("LauncherThemeChanged"), object: nil)
            }
          ColorPicker("", selection: $panelTextColor)
            .labelsHidden()
            .scaleEffect(0.9)
            .padding(.horizontal, -2)
            .disabled(autoPanelTextColor)
            .onChange(of: panelTextColor) { newValue in
              LauncherConfig.launcherPanelTextColor = newValue
              NotificationCenter.default.post(name: NSNotification.Name("LauncherThemeChanged"), object: nil)
            }
        }
        HStack(spacing: 5) {
          Text(NSLocalizedString("launcher.settings.panel.background_color", comment: ""))
            .font(.system(size: fz))
          Spacer()
          CustomPicker(fz: fz, selection: $autoPanelColor)
            .onChange(of: autoPanelColor) { newValue in
              LauncherConfig.launcherAutoPanelBackgroundColor = newValue
              panelColor = LauncherConfig.getRecommendedColor(for: backgroundColor)
              LauncherConfig.launcherPanelBackgroundColor = panelColor
              NotificationCenter.default.post(name: NSNotification.Name("LauncherThemeChanged"), object: nil)
            }
          ColorPicker("", selection: $panelColor)
            .labelsHidden()
            .scaleEffect(0.9)
            .padding(.horizontal, -2)
            .disabled(autoPanelColor)
            .onChange(of: panelColor) { newValue in
              LauncherConfig.launcherPanelBackgroundColor = newValue
              NotificationCenter.default.post(name: NSNotification.Name("LauncherThemeChanged"), object: nil)
            }
        }
        HStack(spacing: 10) {
          Text(String(format: NSLocalizedString("launcher.settings.panel.backgound_transparency", comment: ""), "\(Int(round(panelColorOpacity * 100)))"))
            .font(.system(size: fz))
            .frame(maxWidth: .infinity, alignment: .leading)
          CustomSlider.backgroundOpacity(value: $panelColorOpacity, in: 0.0...1.0)
            .frame(maxWidth: .infinity)
            .onChange(of: panelColorOpacity) { newValue in
              LauncherConfig.launcherPanelOpacity = newValue
              NotificationCenter.default.post(name: NSNotification.Name("LauncherThemeChanged"), object: nil)
            }
        }
        HStack(spacing: 5) {
          Text(NSLocalizedString("launcher.settings.panel.background_stretch", comment: ""))
            .font(.system(size: fz))
          Spacer()
          Toggle("", isOn: $titleBackgroundStretch)
            .sectionToggle()
            .onChange(of: titleBackgroundStretch) { newValue in
              LauncherConfig.launcherPanelStretch = newValue
              NotificationCenter.default.post(name: NSNotification.Name("LauncherThemeChanged"), object: nil)
            }
        }
        HStack(spacing: 5) {
          Text(NSLocalizedString("launcher.settings.panel.text_bold", comment: ""))
            .font(.system(size: fz))
          Spacer()
          Toggle("", isOn: $titleTextBold)
            .sectionToggle()
            .onChange(of: titleTextBold) { newValue in
              LauncherConfig.launcherPanelTextBold = newValue
              NotificationCenter.default.post(name: NSNotification.Name("LauncherThemeChanged"), object: nil)
            }
        }
      }
      .cardStyle()
    }
  }
}
