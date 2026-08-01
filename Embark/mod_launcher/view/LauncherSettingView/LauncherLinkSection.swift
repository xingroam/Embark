import SwiftUI

struct LauncherLinkSection: View {
  let fz: CGFloat
  @Binding var linkIconSize: Double
  @Binding var showThumbnails: Bool
  @Binding var multiLineLinkNames: Bool
  @Binding var textColor: Color
  @Binding var autoTextColor: Bool
  @Binding var linkBackgroundColor: Color
  @Binding var autoLinkBackgroundColor: Bool
  @Binding var backgroundColor: Color
  @Binding var linkOpacity: Double

  var body: some View {
    VStack(spacing: 10) {
      HStack(spacing: 10) {
        Text(NSLocalizedString("launcher.settings.link.title", comment: ""))
          .font(.system(size: fz + 1, weight: .medium))
        Spacer()
      }
      VStack(spacing: 10) {
        HStack(spacing: 5) {
          Text("\(NSLocalizedString("launcher.settings.link.icon_size", comment: "").replacingOccurrences(of: "%@", with: "\(Int(linkIconSize))"))")
            .font(.system(size: fz))
            .frame(maxWidth: .infinity, alignment: .leading)
          CustomSlider(value: $linkIconSize, in: LauncherInfo.iconMinSize...150, step: 5) { value in
            "\(Int(value))"
          }
          .frame(maxWidth: .infinity)
          .onChange(of: linkIconSize) { newValue in
            LauncherConfig.launcherLinkIconSize = newValue
            NotificationCenter.default.post(name: NSNotification.Name("LauncherThemeChanged"), object: nil)
          }
        }
        HStack(spacing: 5) {
          Text(NSLocalizedString("launcher.settings.link.text_color", comment: ""))
            .font(.system(size: fz))
          Spacer()
          CustomPicker(fz: fz, selection: $autoTextColor)
            .onChange(of: autoTextColor) { newValue in
              LauncherConfig.launcherAutoLinkTextColor = newValue
              textColor = LauncherConfig.getRecommendedColor(for: backgroundColor)
              LauncherConfig.launcherLinkTextColor = textColor
              NotificationCenter.default.post(name: NSNotification.Name("LauncherThemeChanged"), object: nil)
            }
          ColorPicker("", selection: $textColor)
            .labelsHidden()
            .scaleEffect(0.9)
            .padding(.horizontal, -2)
            .disabled(autoTextColor)
            .onChange(of: textColor) { newValue in
              LauncherConfig.launcherLinkTextColor = newValue
              NotificationCenter.default.post(name: NSNotification.Name("LauncherThemeChanged"), object: nil)
            }
        }
        HStack(spacing: 5) {
          Text(NSLocalizedString("launcher.settings.link.background_color", comment: ""))
            .font(.system(size: fz))
          Spacer()
          CustomPicker(fz: fz, selection: $autoLinkBackgroundColor)
            .onChange(of: autoLinkBackgroundColor) { newValue in
              LauncherConfig.launcherAutoLinkBackgroundColor = newValue
              linkBackgroundColor = LauncherConfig.getRecommendedColor(for: backgroundColor)
              LauncherConfig.launcherLinkBackgroundColor = linkBackgroundColor
              NotificationCenter.default.post(name: NSNotification.Name("LauncherThemeChanged"), object: nil)
            }
          ColorPicker("", selection: $linkBackgroundColor)
            .labelsHidden()
            .scaleEffect(0.9)
            .padding(.horizontal, -2)
            .disabled(autoLinkBackgroundColor)
            .onChange(of: linkBackgroundColor) { newValue in
              LauncherConfig.launcherLinkBackgroundColor = newValue
              NotificationCenter.default.post(name: NSNotification.Name("LauncherThemeChanged"), object: nil)
            }
        }
        HStack(spacing: 10) {
          Text(String(format: NSLocalizedString("launcher.settings.link.backgound_transparency", comment: ""), "\(Int(round(linkOpacity * 100)))"))
            .font(.system(size: fz))
            .frame(maxWidth: .infinity, alignment: .leading)
          CustomSlider.backgroundOpacity(value: $linkOpacity, in: 0.0...1.0)
            .frame(maxWidth: .infinity)
            .onChange(of: linkOpacity) { newValue in
              LauncherConfig.launcherLinkOpacity = newValue
              NotificationCenter.default.post(name: NSNotification.Name("LauncherThemeChanged"), object: nil)
            }
        }
        HStack(spacing: 5) {
          Text(NSLocalizedString("launcher.settings.link.thumbnails", comment: ""))
            .font(.system(size: fz))
          Spacer()
          Toggle("", isOn: $showThumbnails)
            .sectionToggle()
            .onChange(of: showThumbnails) { newValue in
              LauncherConfig.launcherLinkThumbnails = newValue
              NotificationCenter.default.post(name: NSNotification.Name("LauncherThumbnailsChanged"), object: nil)
            }
        }
        HStack(spacing: 5) {
          Text(NSLocalizedString("launcher.settings.link.multi_line", comment: ""))
            .font(.system(size: fz))
          Spacer()
          Toggle("", isOn: $multiLineLinkNames)
            .sectionToggle()
            .onChange(of: multiLineLinkNames) { newValue in
              LauncherConfig.launcherLinkMultiLine = newValue
              NotificationCenter.default.post(name: NSNotification.Name("LauncherThemeChanged"), object: nil)
            }
        }
      }
      .cardStyle()
    }
  }
}
