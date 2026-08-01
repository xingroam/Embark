import SwiftUI

struct ProxySettingsView: View {
  @Binding var isPresented: Bool
  @State private var proxyType: Int = LauncherConfig.launcherProxyType
  @State private var proxyHost: String = LauncherConfig.launcherProxyHost
  @State private var proxyPort: String = LauncherConfig.launcherProxyPort
  @State private var proxyUser: String = LauncherConfig.launcherProxyUser
  @State private var proxyPassword: String = LauncherConfig.launcherProxyPassword

  private var isValid: Bool {
    if proxyHost.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return false }
    if proxyPort.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return false }
    if Int(proxyPort) == nil { return false }
    return true
  }

  var body: some View {
    VStack(spacing: 20) {
      Picker("", selection: $proxyType) {
        Text("SOCKS5").tag(0)
        Text("HTTP").tag(1)
      }
      .pickerStyle(.segmented)
      .labelsHidden()
      HStack(spacing: 10) {
        TextField(NSLocalizedString("launcher.proxy.host", comment: ""), text: $proxyHost)
          .textFieldStyle(.roundedBorder)
        TextField(NSLocalizedString("launcher.proxy.port", comment: ""), text: $proxyPort)
          .textFieldStyle(.roundedBorder)
          .frame(width: 80)
      }
      if proxyType == 1 {
        VStack(spacing: 10) {
          TextField(NSLocalizedString("launcher.proxy.username_optional", comment: ""), text: $proxyUser)
            .textFieldStyle(.roundedBorder)
          SecureField(NSLocalizedString("launcher.proxy.password_optional", comment: ""), text: $proxyPassword)
            .textFieldStyle(.roundedBorder)
        }
      }
      HStack {
        Button(NSLocalizedString("system.message.cancel", comment: "")) {
          isPresented = false
        }
        .keyboardShortcut(.cancelAction)
        Spacer()
        Button(NSLocalizedString("system.message.save", comment: "")) {
          saveSettings()
          isPresented = false
        }
        .buttonStyle(.borderedProminent)
        .disabled(!isValid)
        .keyboardShortcut(.defaultAction)
      }
    }
    .padding(20)
    .frame(width: 400)
    .fixedSize(horizontal: false, vertical: true)
  }

  private func saveSettings() {
    LauncherConfig.launcherProxyType = proxyType
    LauncherConfig.launcherProxyHost = proxyHost
    LauncherConfig.launcherProxyPort = proxyPort
    LauncherConfig.launcherProxyUser = proxyUser
    LauncherConfig.launcherProxyPassword = proxyPassword
  }
}
