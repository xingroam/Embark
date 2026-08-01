import SwiftUI

struct ConfigPage: View {
  let onComplete: () -> Void
  @State private var isStartupEnabled = true
  @State private var isAutoCheckUpdateEnabled: Bool = EmbarkConfig.appAutoCheckUpdate
  @State private var hasPermission = false
  @State private var selectedIcon: AppIcon = EmbarkConfig.appIcon
  private let fz: CGFloat = 12
  private let iconSize: CGFloat = 48

  var body: some View {
    VStack(spacing: 0) {
      Text(LanguageManager.s.localizedString("embark.onboarding.config.title"))
        .font(.system(size: fz + 12, weight: .semibold))
        .foregroundColor(.primary)
      Spacer().frame(height: 40)
      VStack(spacing: 12) {
        ConfigItem(
          icon: "hand.raised.fill",
          title: LanguageManager.s.localizedString("embark.onboarding.permission.title"),
          subtitle: LanguageManager.s.localizedString("embark.onboarding.permission.subtitle"),
          isEnabled: hasPermission,
          disabledColor: .orange
        ) {
          if hasPermission {
            Image(systemName: "checkmark.circle.fill")
              .font(.system(size: fz + 8))
              .foregroundColor(.green)
          } else {
            Button(action: {
              PermissionManager.s.openSystemPreferences()
            }) {
              Text(LanguageManager.s.localizedString("embark.onboarding.permission.open_settings"))
                .font(.system(size: fz, weight: .medium))
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
          }
        }
        ConfigItem(
          icon: "power",
          title: LanguageManager.s.localizedString("embark.appsettings.general.launch_at_login"),
          subtitle: LanguageManager.s.localizedString("embark.appsettings.general.launch_at_login.subtitle"),
          isEnabled: isStartupEnabled
        ) {
          Toggle("", isOn: $isStartupEnabled)
            .toggleStyle(SwitchToggleStyle())
            .scaleEffect(0.8)
            .offset(x: 6)
        }
        ConfigItem(
          icon: "arrow.clockwise",
          title: LanguageManager.s.localizedString("embark.appsettings.general.auto_check_update"),
          subtitle: LanguageManager.s.localizedString("embark.appsettings.general.auto_check_update.subtitle"),
          isEnabled: isAutoCheckUpdateEnabled
        ) {
          Toggle("", isOn: $isAutoCheckUpdateEnabled)
            .onChange(of: isAutoCheckUpdateEnabled) { newValue in
              EmbarkConfig.appAutoCheckUpdate = newValue
            }
            .toggleStyle(SwitchToggleStyle())
            .scaleEffect(0.8)
            .offset(x: 6)
        }
        ConfigItem(
          icon: "app.dashed",
          title: LanguageManager.s.localizedString("embark.appsettings.general.icon.title"),
          subtitle: "",
          isEnabled: true
        ) {
          HStack(spacing: 6) {
            ForEach(AppIcon.all) { icon in
              iconButton(for: icon)
            }
          }
        }
      }
      .padding(.horizontal, 120)
      Spacer().frame(height: 40)
      Button(action: checkAndLaunch) {
        HStack(spacing: 6) {
          Text(LanguageManager.s.localizedString("embark.onboarding.launch"))
            .font(.system(size: fz + 4, weight: .semibold))
          Image(systemName: "arrow.right")
            .font(.system(size: fz + 4, weight: .semibold))
        }
        .padding(.vertical, 5)
        .padding(.horizontal, 20)
      }
      .buttonStyle(.borderedProminent)
      .controlSize(.large)
      .keyboardShortcut(.return, modifiers: [])
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .onAppear {
      hasPermission = PermissionManager.s.isAccessibilityGranted()
    }
    .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
      hasPermission = PermissionManager.s.isAccessibilityGranted()
    }
  }

  private func checkAndLaunch() {
    if PermissionManager.s.isAccessibilityGranted() {
      EmbarkConfig.appFirstRun = false
      Embark.s.StartApp()
      if isStartupEnabled {
        StartupManager.s.addAppToStartupItems()
      } else {
        StartupManager.s.removeAppFromStartupItems()
      }
      onComplete()
      OnboardingWin.s.Close()
      LauncherWin.s.ShowOrHide(mode: .launcher)
    } else {
      OkAlert.Show(LanguageManager.s.localizedString("embark.onboarding.permission.not_granted"))
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
