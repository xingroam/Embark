import SwiftUI

struct SettingGeneralView: View {
  @Binding var isStartupEnabled: Bool
  @StateObject private var languageManager = LanguageManager.s
  @State private var isAutoCheckUpdateEnabled: Bool = EmbarkConfig.appAutoCheckUpdate
  @State private var appTheme: AppTheme = EmbarkConfig.appTheme
  @State private var selectedIcon: AppIcon = EmbarkConfig.appIcon
  var onSwitchToPurchase: (() -> Void)?
  private let iconSize: CGFloat = 36

  var body: some View {
    ScrollView {
      VStack(spacing: 0) {
        SettingRow(
          icon: "globe",
          title: languageManager.localizedString("embark.appsettings.general.language"),
          subtitle: languageManager.localizedString("embark.appsettings.general.language.subtitle"),
          trailing: {
            Menu {
              ForEach(languageManager.supportedLanguages) { language in
                Button(action: {
                  languageManager.currentLanguage = language.code
                }) {
                  Text(language.name)
                }
              }
            } label: {
              Text(languageManager.getCurrentLanguageDisplayName())
                .foregroundColor(.primary)
                .font(.system(size: 12))
            }
            .fixedSize(horizontal: true, vertical: false)
            .id("language-menu")
          }
        )
        Line()
        SettingRow(
          icon: "moon.stars",
          title: languageManager.localizedString("embark.appsettings.general.theme"),
          subtitle: languageManager.localizedString("embark.appsettings.general.theme.subtitle"),
          trailing: {
            Menu {
              ForEach(AppTheme.allCases, id: \.self) { theme in
                Button(action: {
                  appTheme = theme
                  EmbarkConfig.appTheme = theme
                }) {
                  Text(theme.title)
                }
              }
            } label: {
              Text(appTheme.title)
                .foregroundColor(.primary)
                .font(.system(size: 12))
            }
            .fixedSize(horizontal: true, vertical: false)
            .id("theme-menu")
          }
        )
        Line()
        SettingRow(
          icon: "person.circle",
          title: languageManager.localizedString("embark.appsettings.general.launch_at_login"),
          subtitle: languageManager.localizedString("embark.appsettings.general.launch_at_login.subtitle"),
          trailing: {
            Toggle("", isOn: $isStartupEnabled)
              .toggleStyle(SwitchToggleStyle())
              .scaleEffect(0.8)
              .offset(x: 5)
              .onChange(of: isStartupEnabled) { newValue in
                if newValue {
                  StartupManager.s.addAppToStartupItems()
                } else {
                  StartupManager.s.removeAppFromStartupItems()
                }
            }
          }
        )
        Line()
        SettingRow(
          icon: "arrow.clockwise",
          title: languageManager.localizedString("embark.appsettings.general.auto_check_update"),
          subtitle: languageManager.localizedString("embark.appsettings.general.auto_check_update.subtitle"),
          trailing: {
            HStack(spacing: 5) {
              Toggle("", isOn: $isAutoCheckUpdateEnabled)
                .onChange(of: isAutoCheckUpdateEnabled) { newValue in
                  EmbarkConfig.appAutoCheckUpdate = newValue
                }
                .toggleStyle(SwitchToggleStyle())
                .scaleEffect(0.8)
                .offset(x: 5)
            }
          }
        )
        Line()
        SettingRow(
          icon: "app.dashed",
          title: languageManager.localizedString("embark.appsettings.general.icon.title"),
          subtitle: "",
          trailing: {
            HStack(spacing: 6) {
              ForEach(AppIcon.all) { icon in
                iconButton(for: icon)
              }
            }
          }
        )
      }
      .settingStyle()
    }
    .padding(30)
    .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("AppThemeChanged"))) { _ in
      appTheme = EmbarkConfig.appTheme
    }
  }

  @ViewBuilder
  private func iconButton(for icon: AppIcon) -> some View {
    Button(action: {
      selectedIcon = icon
      IconManager.s.setAppIcon(to: icon)
    }) {
      ZStack {
        if let image = IconManager.s.getIconImage(for: icon) {
          Image(nsImage: image)
            .resizable()
            .interpolation(.high)
            .aspectRatio(contentMode: .fit)
            .frame(width: iconSize, height: iconSize)
            .cornerRadius(10)
        } else {
          RoundedRectangle(cornerRadius: 10)
            .fill(Color.gray.opacity(0.3))
            .frame(width: iconSize, height: iconSize)
        }
        RoundedRectangle(cornerRadius: 10)
          .stroke(selectedIcon == icon ? Color.accentColor : Color.clear, lineWidth: 2)
          .frame(width: iconSize, height: iconSize)
      }
    }
    .buttonStyle(PlainButtonStyle())
  }
}
