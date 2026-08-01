import SwiftUI

struct FocusGeneralSection: View {
  let color: Color
  let fz: CGFloat
  @Binding var focusShortcutKey: CGKeyCode
  @Binding var focusShortcutFlags: CGEventFlags
  @Binding var focusStyle: FocusStyle
  @Binding var focusColor: FocusColor
  @Binding var focusOpacity: Double
  @Binding var focusBlur: CGFloat
  @Binding var showShortcutDialog: Bool

  var body: some View {
    VStack(spacing: 10) {
      ShortcutButton(
        keyCode: focusShortcutKey == .disabled ? nil : focusShortcutKey,
        flags: focusShortcutFlags,
        onTap: {
          showShortcutDialog = true
        }
      )
      .onChange(of: focusShortcutKey) { newValue in
        FocusConfig.focusShortcutKey = newValue
        NotificationCenter.default.post(name: NSNotification.Name("FocusConfigChanged"), object: nil)
      }
      .onChange(of: focusShortcutFlags) { newValue in
        FocusConfig.focusShortcutFlags = newValue
        NotificationCenter.default.post(name: NSNotification.Name("FocusConfigChanged"), object: nil)
      }
      Text(NSLocalizedString("focus.settings.shortcut.description", comment: ""))
        .font(.system(size: fz - 1))
        .foregroundColor(.secondary)
        .lineLimit(nil)
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)
      VStack(spacing: 10) {
        HStack(spacing: 5) {
          Text(NSLocalizedString("focus.settings.style.title", comment: ""))
            .font(.system(size: fz, weight: .regular))
          Spacer()
          Picker("", selection: $focusStyle) {
            ForEach(FocusStyle.allCases.filter { style in
              if #available(macOS 14.0, *) {
                return true
              } else {
                return style != .grain
              }
            }) { style in
              Text(style.displayName).tag(style)
            }
          }
          .pickerStyle(MenuPickerStyle())
          .fixedSize(horizontal: true, vertical: false)
          .onChange(of: focusStyle) { newValue in
            FocusConfig.focusStyle = newValue
            NotificationCenter.default.post(name: NSNotification.Name("FocusConfigChanged"), object: nil)
          }
        }
        HStack(spacing: 5) {
          Text(NSLocalizedString("focus.settings.color.title", comment: ""))
            .font(.system(size: fz, weight: .regular))
          Spacer()
          Picker("", selection: $focusColor) {
            ForEach(FocusColor.allCases) { style in
              Text(style.displayName).tag(style)
            }
          }
          .pickerStyle(MenuPickerStyle())
          .fixedSize(horizontal: true, vertical: false)
          .onChange(of: focusColor) { newValue in
            FocusConfig.focusColor = newValue
            NotificationCenter.default.post(name: NSNotification.Name("FocusConfigChanged"), object: nil)
          }
        }
        HStack(spacing: 5) {
          Text(NSLocalizedString("focus.settings.transparency.title", comment: "") + ": " + String(format: "%.0f%%", focusOpacity * 100))
            .font(.system(size: fz, weight: .regular))
            .frame(maxWidth: .infinity, alignment: .leading)
          CustomSlider(value: Binding<Double>(get: { focusOpacity }, set: { focusOpacity = $0 }), in: 0.0...0.9, step: 0.01, valueFormatter: { _ in "" })
            .frame(maxWidth: .infinity)
            .onChange(of: focusOpacity) { newValue in
              FocusConfig.focusOpacity = newValue
              NotificationCenter.default.post(name: NSNotification.Name("FocusConfigChanged"), object: nil)
            }
        }
        HStack(spacing: 5) {
          Text(NSLocalizedString("focus.settings.blur.title", comment: "") + ": " + String(format: "%.0f%%", focusBlur * 100))
            .font(.system(size: fz, weight: .regular))
            .frame(maxWidth: .infinity, alignment: .leading)
          CustomSlider(value: Binding<Double>(get: { Double(focusBlur) }, set: { focusBlur = CGFloat($0) }), in: 0.0...1.0, step: 0.01, valueFormatter: { _ in "" })
            .frame(maxWidth: .infinity)
            .onChange(of: focusBlur) { newValue in
              FocusConfig.focusBlur = newValue
              NotificationCenter.default.post(name: NSNotification.Name("FocusConfigChanged"), object: nil)
            }
        }
      }
    }
    .cardStyle()
  }
}
