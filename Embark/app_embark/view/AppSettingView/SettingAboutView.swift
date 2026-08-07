import SwiftUI

struct SettingAboutView: View {
  private let fz: CGFloat = 12
  @StateObject private var languageManager = LanguageManager.s
  @StateObject private var updateManager = UpdateManager.s
  @State private var shareButtonView: NSView?

  var body: some View {
    VStack(spacing: 0) {
      Spacer()
      VStack(spacing: 10) {
        if let appIcon = Bundle.main.icon {
          Image(nsImage: appIcon)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 108, height: 108)
        } else {
          Image(systemName: "app")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 108, height: 108)
            .foregroundColor(.accentColor)
        }
        VStack(spacing: 5) {
          Text(EmbarkInfo.name)
            .font(.system(size: 28, weight: .bold))
            .foregroundColor(.primary)
          Text(String(format: languageManager.localizedString("embark.about.version"), versionText))
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(.secondary)
        }
      }
      .padding(.bottom, 60)
      VStack(spacing: 0) {
        SettingRow(
          icon: "arrow.2.circlepath",
          title: languageManager.localizedString("embark.about.check_update"),
          subtitle: languageManager.localizedString("embark.about.check_update.subtitle"),
          trailing: {
            CommonButton(title: languageManager.localizedString("embark.about.check_update.now"), style: .primary, size: .normal) {
              updateManager.checkUpdateDialog()
            }
          }
        )
      }
      .settingStyle()
      .padding(.bottom, 20)
      VStack(spacing: 0) {
        Button(action: {
          if let url = URL(string: EmbarkInfo.website) {
            NSWorkspace.shared.open(url)
          }
        }) {
          SettingRow(
            icon: "globe",
            title: languageManager.localizedString("embark.about.website"),
            subtitle: "",
            trailing: {
              Image(systemName: "chevron.right")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
            }
          )
        }
        .buttonStyle(PlainButtonStyle())
        Line()
        Button(action: {
          if let url = URL(string: EmbarkInfo.feedbackIssueUrl) {
            NSWorkspace.shared.open(url)
          }
        }) {
          SettingRow(
            icon: "envelope",
            title: languageManager.localizedString("embark.about.feedback"),
            subtitle: "",
            trailing: {
              Image(systemName: "chevron.right")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
            }
          )
        }
        .buttonStyle(PlainButtonStyle())
        Line()
        Button(action: {
          if let url = URL(string: "https://xingroam.github.io/Embark/TERMS.md") {
            NSWorkspace.shared.open(url)
          }
        }) {
          SettingRow(
            icon: "doc.text",
            title: languageManager.localizedString("embark.about.terms_of_service"),
            subtitle: "",
            trailing: {
              Image(systemName: "chevron.right")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
            }
          )
        }
        .buttonStyle(PlainButtonStyle())
        Line()
        Button(action: {
          if let url = URL(string: "https://xingroam.github.io/Embark/PRIVACY.md") {
            NSWorkspace.shared.open(url)
          }
        }) {
          SettingRow(
            icon: "hand.raised",
            title: languageManager.localizedString("embark.about.privacy_policy"),
            subtitle: "",
            trailing: {
              Image(systemName: "chevron.right")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
            }
          )
        }
        .buttonStyle(PlainButtonStyle())
      }
      .settingStyle()
      .padding(.bottom, 12)
      Text("©️ \(EmbarkInfo.currentYear) Potor")
        .font(.system(size: 12))
        .foregroundColor(.secondary)
        .padding(.bottom, 8)
      Spacer()
    }
    .padding(.horizontal, 40)
    .padding(.vertical, 15)
  }

  private var versionText: String {
    guard !EmbarkInfo.buildNumber.isEmpty else {
      return EmbarkInfo.version
    }
    return "\(EmbarkInfo.version) (\(EmbarkInfo.buildNumber))"
  }
}
