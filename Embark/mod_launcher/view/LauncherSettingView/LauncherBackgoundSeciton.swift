import SwiftUI

struct LauncherBackgoundSeciton: View {
  let fz: CGFloat
  @Binding var backgroundColor: Color
  @Binding var opacity: Double
  @Binding var blur: Double
  @Binding var imageOpacity: Double
  @Binding var imageBlur: Double
  @State private var hexString: String = ""
  @State private var isEditingHex: Bool = false
  @State private var lastColor: Color = .clear
  @State private var hasBackgroundImage: Bool = false
  var onColorChange: ((Color) -> Void)?
  var onOpacityChange: ((Double) -> Void)?

  var body: some View {
    VStack(spacing: 10) {
      HStack(spacing: 10) {
        Text(NSLocalizedString("launcher.settings.background.title", comment: ""))
          .font(.system(size: fz + 1, weight: .medium))
        Spacer()
      }
      VStack(spacing: 10) {
        HStack(spacing: 10) {
          Text(NSLocalizedString("launcher.settings.background.color", comment: ""))
            .font(.system(size: fz))
            .frame(maxWidth: .infinity, alignment: .leading)
          Spacer()
          ColorPicker("", selection: $backgroundColor)
            .labelsHidden()
            .onChange(of: backgroundColor) { newValue in
              if !isEditingHex {
                hexString = LauncherConfig.colorToHex(newValue)
                if newValue != lastColor {
                  lastColor = newValue
                  LauncherConfig.launcherBackgroundColor = newValue
                  onColorChange?(newValue)
                }
              }
            }
          TextField("#ffffff", text: $hexString)
            .frame(width: 70)
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .font(.system(size: fz - 2))
            .onSubmit {
              LauncherConfig.setBackgroundColorFromHex(hexString)
              backgroundColor = LauncherConfig.launcherBackgroundColor
              isEditingHex = false
            }
            .onTapGesture {
              isEditingHex = true
            }
        }
        ColorPresetView(
          colors: ColorPresets.accentColors,
          selectedColor: $backgroundColor,
          fz: fz,
        )
        HStack(spacing: 10) {
          Text(String(format: NSLocalizedString("launcher.settings.background.color_transparency", comment: ""), "\(Int(round(opacity * 100)))"))
            .font(.system(size: fz))
            .frame(maxWidth: .infinity, alignment: .leading)
          CustomSlider.backgroundOpacity(value: $opacity)
            .frame(maxWidth: .infinity)
            .onChange(of: opacity) { newValue in
              onOpacityChange?(newValue)
            }
        }
        if ProcessInfo.processInfo.operatingSystemVersion.majorVersion >= 14 {
          VStack(spacing: 10) {
            HStack(spacing: 10) {
              Text(NSLocalizedString("launcher.settings.background.image", comment: ""))
                .font(.system(size: fz))
                .frame(maxWidth: .infinity, alignment: .leading)
              Spacer()
            }
            ImageSelectorView(fz: fz)
              .frame(width: 100, height: 100)
            HStack(spacing: 10) {
              Text(String(format: NSLocalizedString("launcher.settings.background.image_transparency", comment: ""), "\(Int(round(imageOpacity * 100)))"))
                .font(.system(size: fz))
                .frame(maxWidth: .infinity, alignment: .leading)
                .foregroundColor(hasBackgroundImage ? .primary : .secondary)
              CustomSlider.backgroundOpacity(value: $imageOpacity)
                .frame(maxWidth: .infinity)
                .disabled(!hasBackgroundImage)
                .onChange(of: imageOpacity) { newValue in
                  LauncherConfig.launcherBackgroundImageOpacity = newValue
                  NotificationCenter.default.post(name: NSNotification.Name("LauncherThemeChanged"), object: nil)
                }
            }
            HStack(spacing: 10) {
              Text(String(format: NSLocalizedString("launcher.settings.background.image_blur", comment: ""), "\(Int(round(imageBlur)))"))
                .font(.system(size: fz))
                .frame(maxWidth: .infinity, alignment: .leading)
                .foregroundColor(hasBackgroundImage ? .primary : .secondary)
              CustomSlider.imageBlur(value: $imageBlur)
                .frame(maxWidth: .infinity)
                .disabled(!hasBackgroundImage)
                .onChange(of: imageBlur) { newValue in
                  LauncherConfig.launcherBackgroundImageBlur = newValue
                  NotificationCenter.default.post(name: NSNotification.Name("LauncherThemeChanged"), object: nil)
                }
            }
          }
        }
        HStack(spacing: 10) {
          Text(String(format: NSLocalizedString("launcher.settings.background.blur", comment: ""), "\(Int(blur * 100))"))
            .font(.system(size: fz))
            .frame(maxWidth: .infinity, alignment: .leading)
          CustomSlider.blur(value: $blur)
            .frame(maxWidth: .infinity)
            .onChange(of: blur) { newValue in
              LauncherConfig.launcherBackgroundBlur = newValue
              NotificationCenter.default.post(name: NSNotification.Name("LauncherThemeChanged"), object: nil)
            }
        }
      }
      .cardStyle()
      .onAppear {
        hexString = LauncherConfig.getBackgroundColorHex()
        lastColor = backgroundColor
        hasBackgroundImage = ImageBackground.loadImage() != nil
      }
      .onChange(of: backgroundColor) { newValue in
        if !isEditingHex {
          hexString = LauncherConfig.colorToHex(newValue)
        }
      }
      .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("LauncherImageChanged"))) { _ in
        hasBackgroundImage = ImageBackground.loadImage() != nil
      }
    }
  }
}
