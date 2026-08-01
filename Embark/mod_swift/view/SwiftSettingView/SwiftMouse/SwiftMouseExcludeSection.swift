import SwiftUI

struct SwiftMouseExcludeSection: View {
  let color: Color
  let fz: CGFloat
  @ObservedObject var smm = SwiftMouseManager.s

  var body: some View {
    VStack(spacing: 10) {
      HStack(spacing: 5) {
        Text(NSLocalizedString("system.settings.exclude.title", comment: ""))
          .font(.system(size: fz + 1, weight: .medium))
          .foregroundColor(.primary)
        Spacer()
        SelectAddButton(color: color, fz: fz, style: .icon) {
          Dialog.ApplicationPicker { selectedURL in
            guard let url = selectedURL else { return }
            if let bundle = Bundle(url: url), let bundleId = bundle.bundleIdentifier {
              let appName = url.deletingPathExtension().lastPathComponent
              smm.addExcludedApp(title: appName, bundleId: bundleId)
            }
          }
        }
      }
      VStack(spacing: 10) {
        if smm.excludedApps.isEmpty {
        HStack(spacing: 0) {
          Text(NSLocalizedString("system.settings.exclude.empty", comment: ""))
            .font(.system(size: fz - 1))
            .foregroundColor(.secondary)
          Spacer()
        }
      } else {
        Group {
          if smm.excludedApps.count <= 4 {
            VStack(spacing: 5) {
              ForEach(smm.excludedApps) { app in
                appRow(app: app)
              }
            }
          } else {
            ScrollView(.vertical, showsIndicators: true) {
              VStack(spacing: 5) {
                ForEach(smm.excludedApps) { app in
                  appRow(app: app)
                }
              }
              .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(height: 140)
          }
        }
      }
    }
    .cardStyle()
    }
    .onAppear {
      smm.loadExcludedApps()
    }
  }

  private func appRow(app: SwiftMouseExcludeApp) -> some View {
    HStack(spacing: 5) {
      if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: app.bundleId),
         let appIcon = LaunchManager.s.getIcon(path: appURL.path, linkType: .application) {
        Image(nsImage: appIcon)
          .resizable()
          .frame(width: 20, height: 20)
      } else {
        Image(systemName: "app.fill")
          .font(.system(size: 16))
          .foregroundColor(.secondary)
          .frame(width: 20, height: 20)
      }
      Text(app.title)
        .font(.system(size: fz - 1))
        .foregroundColor(.primary)
      Spacer()
      Button(action: {
        if app.enabled {
          smm.removeExcludedApp(bundleId: app.bundleId)
        } else {
          smm.addExcludedApp(title: app.title, bundleId: app.bundleId)
        }
      }) {
        Image(systemName: app.enabled ? "minus.circle.fill" : "plus.circle.fill")
          .font(.system(size: fz))
          .foregroundColor(.secondary)
      }
      .buttonStyle(PlainButtonStyle())
    }
    .padding(5)
    .background(app.enabled ? color.opacity(0.5) : .clear)
    .cornerRadius(6)
  }
}
