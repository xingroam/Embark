import SwiftUI

struct PanelWidthDialog: View {
  let panelId: Int64
  let panelName: String
  let currentWidth: Double?
  @Binding var isPresented: Bool
  @State private var panelWidth: Double
  @EnvironmentObject private var dm: DataManager

  init(panelId: Int64, panelName: String, currentWidth: Double?, isPresented: Binding<Bool>) {
    self.panelId = panelId
    self.panelName = panelName
    self.currentWidth = currentWidth
    self._isPresented = isPresented
    self._panelWidth = State(initialValue: currentWidth ?? LauncherConfig.launcherPanelWidth)
  }

  var body: some View {
    VStack(spacing: 20) {
      HStack(spacing: 0) {
        Text(NSLocalizedString("launcher.panel.width.dialog.title", comment: ""))
          .font(.title2)
          .fontWeight(.medium)
      }
      VStack(alignment: .leading, spacing: 10) {
        Text("\(NSLocalizedString("launcher.panel.width.dialog.panel", comment: "").replacingOccurrences(of: "%@", with: panelName))")
          .font(.headline)
        HStack(spacing: 5) {
          Text(NSLocalizedString("launcher.panel.width.dialog.custom_width", comment: ""))
            .font(.body)
          Spacer()
          Text("\(Int(panelWidth))")
            .font(.body)
            .fontWeight(.medium)
            .foregroundColor(.accentColor)
        }
        CustomSlider.panelWidth(value: $panelWidth)
          .frame(height: 30)
      }
      HStack(spacing: 10) {
        Button(NSLocalizedString("launcher.panel.width.dialog.use_default", comment: "")) {
          panelWidth = LauncherConfig.launcherPanelWidth
        }
        .buttonStyle(.bordered)
        Spacer()
        Button(NSLocalizedString("system.message.cancel", comment: "")) {
          isPresented = false
        }
        .buttonStyle(.bordered)
        Button(NSLocalizedString("system.message.confirm", comment: "")) {
          if panelWidth == LauncherConfig.launcherPanelWidth {
            dm.updatePanelWidth(panelId: panelId, width: nil)
          } else {
            dm.updatePanelWidth(panelId: panelId, width: panelWidth)
          }
          NotificationCenter.default.post(name: NSNotification.Name("PanelWidthChanged"), object: panelId)
          isPresented = false
        }
        .buttonStyle(.borderedProminent)
      }
    }
    .padding(20)
    .frame(width: 400)
    .background(BlurredBackground(material: .underWindowBackground, blendingMode: .behindWindow, blur: 1.0))
  }
}
