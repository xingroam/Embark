import SwiftUI
import ApplicationServices

struct SwitcherSettingView: View {
  @State private var switcher: Bool = SwitcherConfig.switcher
  @State private var switcherShortcutKey: CGKeyCode = SwitcherConfig.switcherShortcutKey
  @State private var switcherShortcutFlags: CGEventFlags = SwitcherConfig.switcherShortcutFlags
  @State private var switcherMode: SwitcherMode = SwitcherConfig.switcherMode
  @State private var switcherSize: SwitcherSize = SwitcherConfig.switcherSize
  @State private var switcherWidth: Double = SwitcherConfig.switcherWidth
  @State private var switcherMaxItemsPerColumn: Double = SwitcherConfig.switcherMaxItemsPerColumn
  @State private var showShortcutDialog = false
  private let fz: CGFloat = 12

  var body: some View {
    VStack(spacing: 10) {
      HStack(spacing: 5) {
        Text(FeatureType.switcher.title)
          .font(.system(size: fz + 1, weight: .medium))
        Spacer()
        Toggle("", isOn: $switcher)
          .toggleStyle(SwitchToggleStyle())
          .scaleEffect(0.8)
          .offset(x: 5)
          .onChange(of: switcher) { newValue in
            SwitcherConfig.switcher = newValue
            NotificationCenter.default.post(name: NSNotification.Name("SwitcherConfigChanged"), object: nil)
          }
      }
      VStack(spacing: 10) {
        VStack(spacing: 10) {
          ShortcutButton(
            keyCode: switcherShortcutKey,
            flags: switcherShortcutFlags,
            onTap: {
              showShortcutDialog = true
            }
          )
          Text(NSLocalizedString("switcher.settings.shortcut.description", comment: ""))
            .font(.system(size: fz - 1))
            .foregroundColor(.secondary)
            .lineLimit(nil)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
        }
        .sheet(isPresented: $showShortcutDialog) {
          ShortcutDialog(
            title: NSLocalizedString("system.shortcut.dialog.title", comment: ""),
            isPresented: $showShortcutDialog,
            shortcutKey: $switcherShortcutKey,
            shortcutFlags: $switcherShortcutFlags
          )
        }
        HStack(spacing: 5) {
          Text(NSLocalizedString("switcher.settings.mode.title", comment: ""))
            .font(.system(size: fz, weight: .regular))
          Spacer()
          Picker("", selection: $switcherMode) {
            ForEach(SwitcherMode.displayCases) { mode in
              Text(mode.title).tag(mode)
            }
          }
          .pickerStyle(MenuPickerStyle())
          .fixedSize(horizontal: true, vertical: false)
          .onChange(of: switcherMode) { newValue in
            SwitcherConfig.switcherMode = newValue
            NotificationCenter.default.post(name: NSNotification.Name("SwitcherConfigChanged"), object: nil)
          }
        }
        HStack(spacing: 5) {
          Text(NSLocalizedString("switcher.settings.size.title", comment: ""))
            .font(.system(size: fz, weight: .regular))
          Spacer()
          Picker("", selection: $switcherSize) {
            ForEach(SwitcherSize.allCases) { size in
              Text(size.title).tag(size)
            }
          }
          .pickerStyle(MenuPickerStyle())
          .fixedSize(horizontal: true, vertical: false)
          .onChange(of: switcherSize) { newValue in
            SwitcherConfig.switcherSize = newValue
            NotificationCenter.default.post(name: NSNotification.Name("SwitcherConfigChanged"), object: nil)
          }
        }
        HStack(spacing: 5) {
          Text(NSLocalizedString("switcher.settings.width.title", comment: "") + ": \(Int(switcherWidth))")
            .font(.system(size: fz, weight: .regular))
            .frame(maxWidth: .infinity, alignment: .leading)
          CustomSlider(value: $switcherWidth, in: 150...600, step: 50, valueFormatter: { _ in "" })
            .frame(maxWidth: .infinity)
            .onChange(of: switcherWidth) { newValue in
              SwitcherConfig.switcherWidth = newValue
              NotificationCenter.default.post(name: NSNotification.Name("SwitcherConfigChanged"), object: nil)
            }
        }
        HStack(spacing: 5) {
          Text(NSLocalizedString("switcher.settings.maxItemsPerColumn.title", comment: "") + ": \(Int(switcherMaxItemsPerColumn))")
            .font(.system(size: fz, weight: .regular))
            .frame(maxWidth: .infinity, alignment: .leading)
          CustomSlider(value: $switcherMaxItemsPerColumn, in: 4...20, step: 1, valueFormatter: { _ in "" })
            .frame(maxWidth: .infinity)
            .onChange(of: switcherMaxItemsPerColumn) { newValue in
              SwitcherConfig.switcherMaxItemsPerColumn = newValue
              NotificationCenter.default.post(name: NSNotification.Name("SwitcherConfigChanged"), object: nil)
            }
        }
      }
      .cardStyle()
      .disabledOverlay(isDisabled: !switcher, isLocked: false)
    }
    .padding(15)
    .frame(width: 460)
    .background(BlurredBackground(material: .underWindowBackground, blendingMode: .behindWindow, blur: 1.0))
    .onAppear {
      switcher = SwitcherConfig.switcher
      switcherShortcutKey = SwitcherConfig.switcherShortcutKey
      switcherShortcutFlags = SwitcherConfig.switcherShortcutFlags
      switcherMode = SwitcherConfig.switcherMode
      switcherWidth = SwitcherConfig.switcherWidth
      switcherMaxItemsPerColumn = SwitcherConfig.switcherMaxItemsPerColumn
    }
    .onChange(of: switcherShortcutKey) { newValue in
      SwitcherConfig.switcherShortcutKey = newValue
    }
    .onChange(of: switcherShortcutFlags) { newValue in
      SwitcherConfig.switcherShortcutFlags = newValue
    }
  }
}
