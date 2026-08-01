import SwiftUI
import AppKit

struct LauncherInfo {
  static let gestureStarted = false
  static let animationDuration = 0.1
  static let minPanelHeight: CGFloat = 300
  static let settingModeAddWidth: CGFloat = 0
  static let iconMinSize: CGFloat = 40
  static let addLinkTip: Bool = true
  static let searchAnimationDuration: TimeInterval = 0.12
  static let addLinkDuration: TimeInterval = 0.2
  static let browserMinWidthForTitle: CGFloat = 500
}

struct LauncherDefine {
  static let launcher: Bool = true
  static let launcherTextSize: CGFloat = 12
  static let launcherTabKey: TabKeyType = .bidirectional
  static let launcherSearchScope: SearchScope = .allApps

  static let launcherBackgroundColor: Color = Color.black
  static let launcherBackgroundColorOpacity: Double = 0.25
  static let launcherBackgroundImageOpacity: Double = 0.75
  static let launcherBackgroundImageBlur: Double = 25.0
  static let launcherBackgroundBlur: Double = 1.0

  static let launcherLinkOpacity: Double = 0.2
  static let launcherLinkTextColor: Color = Color.white
  static let launcherLinkBackgroundColor: Color = Color.white
  static let launcherLinkIconSize: CGFloat = 100
  static let launcherLinkThumbnails: Bool = true
  static let launcherLinkMultiLine: Bool = true

  static let launcherPanelOpacity: Double = 0.1
  static let launcherPanelTextColor: Color = Color.white
  static let launcherPanelBackgroundColor: Color = Color.white
  static let launcherPanelWidth: CGFloat = 250
  static let launcherPanelStretch: Bool = false
  static let launcherPanelTextBold: Bool = false

  static let launcherAutoLinkTextColor: Bool = false
  static let launcherAutoLinkBackgroundColor: Bool = false
  static let launcherAutoPanelTextColor: Bool = false
  static let launcherAutoPanelBackgroundColor: Bool = false

  static let launcherProxyType: Int = 0
}

struct LauncherFree {
  static let launcherBackgroundBlur: Double = 1.0
}

struct LauncherConfig {
  static let launcherMaxHeightKey = "launcherMaxHeight"

  static let launcherKey = "launcher"
  static let launcherTextSizeKey = "launcherTextSize"
  static let launcherTabKeyKey = "launcherTabKey"
  static let launcherSearchScopeKey = "launcherSearchScope"

  static let launcherBackgroundColorKey = "launcherBackgroundColor"
  static let launcherBackgroundColorOpacityKey = "launcherBackgroundColorOpacity"
  static let launcherBackgroundImageOpacityKey = "launcherBackgroundImageOpacity"
  static let launcherBackgroundImageBlurKey = "launcherBackgroundImageBlur"
  static let launcherBackgroundBlurKey = "launcherBackgroundBlur"

  static let launcherLinkTextColorKey = "launcherLinkTextColor"
  static let launcherLinkBackgroundColorKey = "launcherLinkBackgroundColor"
  static let launcherLinkOpacityKey = "launcherLinkOpacity"
  static let launcherLinkIconSizeKey = "launcherLinkIconSize"
  static let launcherLinkThumbnailsKey = "launcherLinkThumbnails"
  static let launcherLinkMultiLineKey = "launcherLinkMultiLine"

  static let launcherPanelTextColorKey = "launcherPanelTextColor"
  static let launcherPanelBackgroundColorKey = "launcherPanelBackgroundColor"
  static let launcherPanelOpacityKey = "launcherPanelOpacity"
  static let launcherPanelWidthKey = "launcherPanelWidth"
  static let launcherPanelStretchKey = "launcherPanelStretch"
  static let launcherPanelTextBoldKey = "launcherPanelTextBold"

  static let launcherAutoLinkTextColorKey = "launcherAutoLinkTextColor"
  static let launcherAutoLinkBackgroundColorKey = "launcherAutoLinkBackgroundColor"
  static let launcherAutoPanelTextColorKey = "launcherAutoPanelTextColor"
  static let launcherAutoPanelBackgroundColorKey = "launcherAutoPanelBackgroundColor"

  static let launcherProxyTypeKey = "launcherProxyType"
  static let launcherProxyHostKey = "launcherProxyHost"
  static let launcherProxyPortKey = "launcherProxyPort"
  static let launcherProxyUserKey = "launcherProxyUser"
  static let launcherProxyPasswordKey = "launcherProxyPassword"

  static var launcherMaxHeight: CGFloat {
    get {
      let value = UserDefaults.standard.double(forKey: launcherMaxHeightKey)
      return value > 0 ? CGFloat(value) : 0
    }
    set {
      UserDefaults.standard.set(Double(newValue), forKey: launcherMaxHeightKey)
    }
  }

  static var launcher: Bool {
    get {
      UserDefaults.standard.object(forKey: launcherKey) as? Bool ?? LauncherDefine.launcher
    }
    set {
      UserDefaults.standard.set(newValue, forKey: launcherKey)
    }
  }

  static var launcherTextSize: CGFloat {
    get {
      let value = UserDefaults.standard.double(forKey: launcherTextSizeKey)
      return value == 0 ? LauncherDefine.launcherTextSize : value
    }
    set {
      UserDefaults.standard.set(newValue, forKey: launcherTextSizeKey)
    }
  }

  static var launcherTabKey: TabKeyType {
    get {
      let rawValue = UserDefaults.standard.integer(forKey: launcherTabKeyKey)
      if let tabKeyType = TabKeyType(rawValue: rawValue) {
        return tabKeyType
      }
      return LauncherDefine.launcherTabKey
    }
    set {
      UserDefaults.standard.set(newValue.rawValue, forKey: launcherTabKeyKey)
    }
  }

  static var launcherSearchScope: SearchScope {
    get {
      let rawValue = UserDefaults.standard.integer(forKey: launcherSearchScopeKey)
      if let scope = SearchScope(rawValue: rawValue) {
        return scope
      }
      return LauncherDefine.launcherSearchScope
    }
    set {
      UserDefaults.standard.set(newValue.rawValue, forKey: launcherSearchScopeKey)
    }
  }

  static var launcherBackgroundColor: Color {
    get {
      let colorString = UserDefaults.standard.string(forKey: launcherBackgroundColorKey) ?? ""
      if colorString.isEmpty {
        return LauncherDefine.launcherBackgroundColor
      }
      return colorFromString(colorString) ?? LauncherDefine.launcherBackgroundColor
    }
    set {
      let colorString = stringFromColor(newValue)
      UserDefaults.standard.set(colorString, forKey: launcherBackgroundColorKey)
    }
  }

  static var launcherBackgroundColorOpacity: Double {
    get {
      UserDefaults.standard.double(forKey: launcherBackgroundColorOpacityKey) - 10
    }
    set {
      UserDefaults.standard.set(newValue + 10, forKey: launcherBackgroundColorOpacityKey)
    }
  }

  static var launcherBackgroundImageOpacity: Double {
    get {
      UserDefaults.standard.double(forKey: launcherBackgroundImageOpacityKey) - 10
    }
    set {
      UserDefaults.standard.set(newValue + 10, forKey: launcherBackgroundImageOpacityKey)
    }
  }

  static var launcherBackgroundImageBlur: Double {
    get {
      UserDefaults.standard.double(forKey: launcherBackgroundImageBlurKey) - 10
    }
    set {
      UserDefaults.standard.set(newValue + 10, forKey: launcherBackgroundImageBlurKey)
    }
  }

  static var launcherBackgroundBlur: Double {
    get {
      UserDefaults.standard.double(forKey: launcherBackgroundBlurKey) - 10
    }
    set {
      UserDefaults.standard.set(newValue + 10, forKey: launcherBackgroundBlurKey)
    }
  }

  static var launcherLinkTextColor: Color {
    get {
      let colorString = UserDefaults.standard.string(forKey: launcherLinkTextColorKey) ?? ""
      if colorString.isEmpty {
        return LauncherDefine.launcherLinkTextColor
      }
      return colorFromString(colorString) ?? LauncherDefine.launcherLinkTextColor
    }
    set {
      let colorString = stringFromColor(newValue)
      UserDefaults.standard.set(colorString, forKey: launcherLinkTextColorKey)
    }
  }

  static var launcherLinkBackgroundColor: Color {
    get {
      let colorString = UserDefaults.standard.string(forKey: launcherLinkBackgroundColorKey) ?? ""
      if colorString.isEmpty {
        return LauncherDefine.launcherLinkBackgroundColor
      }
      return colorFromString(colorString) ?? LauncherDefine.launcherLinkBackgroundColor
    }
    set {
      let colorString = stringFromColor(newValue)
      UserDefaults.standard.set(colorString, forKey: launcherLinkBackgroundColorKey)
    }
  }

  static var launcherLinkOpacity: Double {
    get {
      UserDefaults.standard.object(forKey: launcherLinkOpacityKey) as? Double ?? LauncherDefine.launcherLinkOpacity
    }
    set {
      UserDefaults.standard.set(newValue, forKey: launcherLinkOpacityKey)
    }
  }

  static var launcherLinkIconSize: CGFloat {
    get {
      let value = UserDefaults.standard.double(forKey: launcherLinkIconSizeKey)
      return value == 0 ? LauncherDefine.launcherLinkIconSize : value
    }
    set {
      UserDefaults.standard.set(newValue, forKey: launcherLinkIconSizeKey)
    }
  }

  static var launcherLinkThumbnails: Bool {
    get {
      UserDefaults.standard.object(forKey: launcherLinkThumbnailsKey) as? Bool ?? LauncherDefine.launcherLinkThumbnails
    }
    set {
      UserDefaults.standard.set(newValue, forKey: launcherLinkThumbnailsKey)
    }
  }

  static var launcherLinkMultiLine: Bool {
    get {
      UserDefaults.standard.object(forKey: launcherLinkMultiLineKey) as? Bool ?? LauncherDefine.launcherLinkMultiLine
    }
    set {
      UserDefaults.standard.set(newValue, forKey: launcherLinkMultiLineKey)
    }
  }

  static var launcherPanelTextColor: Color {
    get {
      let colorString = UserDefaults.standard.string(forKey: launcherPanelTextColorKey) ?? ""
      if colorString.isEmpty {
        return LauncherDefine.launcherPanelTextColor
      }
      return colorFromString(colorString) ?? LauncherDefine.launcherPanelTextColor
    }
    set {
      let colorString = stringFromColor(newValue)
      UserDefaults.standard.set(colorString, forKey: launcherPanelTextColorKey)
    }
  }

  static var launcherPanelBackgroundColor: Color {
    get {
      let colorString = UserDefaults.standard.string(forKey: launcherPanelBackgroundColorKey) ?? ""
      if colorString.isEmpty {
        return LauncherDefine.launcherPanelBackgroundColor
      }
      return colorFromString(colorString) ?? LauncherDefine.launcherPanelBackgroundColor
    }
    set {
      let colorString = stringFromColor(newValue)
      UserDefaults.standard.set(colorString, forKey: launcherPanelBackgroundColorKey)
    }
  }

  static var launcherPanelOpacity: Double {
    get {
      UserDefaults.standard.double(forKey: launcherPanelOpacityKey) - 10
    }
    set {
      UserDefaults.standard.set(newValue + 10, forKey: launcherPanelOpacityKey)
    }
  }

  static var launcherPanelWidth: CGFloat {
    get {
      UserDefaults.standard.double(forKey: launcherPanelWidthKey)
    }
    set {
      UserDefaults.standard.set(newValue, forKey: launcherPanelWidthKey)
    }
  }

  static var launcherPanelStretch: Bool {
    get {
      UserDefaults.standard.bool(forKey: launcherPanelStretchKey)
    }
    set {
      UserDefaults.standard.set(newValue, forKey: launcherPanelStretchKey)
    }
  }

  static var launcherPanelTextBold: Bool {
    get {
      UserDefaults.standard.bool(forKey: launcherPanelTextBoldKey)
    }
    set {
      UserDefaults.standard.set(newValue, forKey: launcherPanelTextBoldKey)
    }
  }

  static var launcherAutoLinkTextColor: Bool {
    get {
      return UserDefaults.standard.bool(forKey: launcherAutoLinkTextColorKey)
    }
    set {
      UserDefaults.standard.set(newValue, forKey: launcherAutoLinkTextColorKey)
    }
  }

  static var launcherAutoLinkBackgroundColor: Bool {
    get {
      UserDefaults.standard.object(forKey: launcherAutoLinkBackgroundColorKey) as? Bool ?? LauncherDefine.launcherAutoLinkBackgroundColor
    }
    set {
      UserDefaults.standard.set(newValue, forKey: launcherAutoLinkBackgroundColorKey)
    }
  }

  static var launcherAutoPanelTextColor: Bool {
    get {
      UserDefaults.standard.object(forKey: launcherAutoPanelTextColorKey) as? Bool ?? false
    }
    set {
      UserDefaults.standard.set(newValue, forKey: launcherAutoPanelTextColorKey)
    }
  }

  static var launcherAutoPanelBackgroundColor: Bool {
    get {
      UserDefaults.standard.object(forKey: launcherAutoPanelBackgroundColorKey) as? Bool ?? LauncherDefine.launcherAutoPanelBackgroundColor
    }
    set {
      UserDefaults.standard.set(newValue, forKey: launcherAutoPanelBackgroundColorKey)
    }
  }

  static var launcherProxyType: Int {
    get { UserDefaults.standard.integer(forKey: launcherProxyTypeKey) }
    set { UserDefaults.standard.set(newValue, forKey: launcherProxyTypeKey) }
  }

  static var launcherProxyHost: String {
    get { UserDefaults.standard.string(forKey: launcherProxyHostKey) ?? "" }
    set { UserDefaults.standard.set(newValue, forKey: launcherProxyHostKey) }
  }

  static var launcherProxyPort: String {
    get { UserDefaults.standard.string(forKey: launcherProxyPortKey) ?? "" }
    set { UserDefaults.standard.set(newValue, forKey: launcherProxyPortKey) }
  }

  static var launcherProxyUser: String {
    get { UserDefaults.standard.string(forKey: launcherProxyUserKey) ?? "" }
    set { UserDefaults.standard.set(newValue, forKey: launcherProxyUserKey) }
  }

  static var launcherProxyPassword: String {
    get { UserDefaults.standard.string(forKey: launcherProxyPasswordKey) ?? "" }
    set { UserDefaults.standard.set(newValue, forKey: launcherProxyPasswordKey) }
  }

  static var currentLinkTextColor: Color {
    return launcherAutoLinkTextColor ? getRecommendedColor(for: launcherBackgroundColor) : launcherLinkTextColor
  }

  static var currentLinkBackgroundColor: Color {
    return launcherAutoLinkBackgroundColor ? getRecommendedColor(for: launcherBackgroundColor) : launcherLinkBackgroundColor
  }

  static var currentPanelTextColor: Color {
    return launcherAutoPanelTextColor ? getRecommendedColor(for: launcherBackgroundColor) : launcherPanelTextColor
  }

  static var currentPanelBackgroundColor: Color {
    return launcherAutoPanelBackgroundColor ? getRecommendedColor(for: launcherBackgroundColor) : launcherPanelBackgroundColor
  }

  static func getPanelOpacity(baseDepth: Double = 0.1, offset: Double = 0.0) -> Double {
    return Swift.min(Swift.max(launcherPanelOpacity + offset, 0.0), 0.8)
  }

  static func colorToHex(_ color: Color) -> String {
    let uiColor = NSColor(color)
    guard let convertedColor = uiColor.usingColorSpace(.sRGB) else {
      return "#000000"
    }
    let red = Int(round(convertedColor.redComponent * 255))
    let green = Int(round(convertedColor.greenComponent * 255))
    let blue = Int(round(convertedColor.blueComponent * 255))
    return String(format: "#%02X%02X%02X", red, green, blue)
  }

  static func hexToColor(_ hex: String) -> Color? {
    var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
    hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
    guard hexSanitized.count == 6 || hexSanitized.count == 3 else { return nil }
    var rgb: UInt64 = 0
    guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }
    if hexSanitized.count == 6 {
      let red = Double((rgb & 0xFF0000) >> 16) / 255.0
      let green = Double((rgb & 0x00FF00) >> 8) / 255.0
      let blue = Double(rgb & 0x0000FF) / 255.0
      return Color(red: red, green: green, blue: blue)
    }
    let red = Double((rgb & 0xF00) >> 8) / 15.0
    let green = Double((rgb & 0x0F0) >> 4) / 15.0
    let blue = Double(rgb & 0x00F) / 15.0
    return Color(red: red, green: green, blue: blue)
  }

  static func isLightColor(_ color: Color) -> Bool {
    let uiColor = NSColor(color)
    guard let convertedColor = uiColor.usingColorSpace(.sRGB) else {
      return false
    }
    let red = convertedColor.redComponent
    let green = convertedColor.greenComponent
    let blue = convertedColor.blueComponent
    let luminance = 0.299 * red + 0.587 * green + 0.114 * blue
    return luminance > 0.5
  }

  static func isLightHexColor(_ hex: String) -> Bool {
    guard let color = hexToColor(hex) else { return false }
    return isLightColor(color)
  }

  static func getColorLuminance(_ color: Color) -> Double {
    let uiColor = NSColor(color)
    guard let convertedColor = uiColor.usingColorSpace(.sRGB) else {
      return 0.5
    }
    let red = convertedColor.redComponent
    let green = convertedColor.greenComponent
    let blue = convertedColor.blueComponent
    return 0.299 * red + 0.587 * green + 0.114 * blue
  }

  static func getHexColorLuminance(_ hex: String) -> Double? {
    guard let color = hexToColor(hex) else { return nil }
    return getColorLuminance(color)
  }

  static func getRecommendedColor(for backgroundColor: Color) -> Color {
    return isLightColor(backgroundColor) ? .black : .white
  }

  static func getRecommendedColor(for hexBackgroundColor: String) -> Color {
    guard let backgroundColor = hexToColor(hexBackgroundColor) else { return .black }
    return getRecommendedColor(for: backgroundColor)
  }

  static func getBackgroundColorHex() -> String {
    return colorToHex(launcherBackgroundColor)
  }

  static func setBackgroundColorFromHex(_ hexString: String) {
    if let color = hexToColor(hexString) {
      launcherBackgroundColor = color
    }
  }

  static func getColorContrast(_ color: Color) -> Double {
    return (1.0 + 0.05) / (getColorLuminance(color) + 0.05)
  }

  static func getHexColorContrast(_ hex: String) -> Double? {
    guard let color = hexToColor(hex) else { return nil }
    return getColorContrast(color)
  }

  static func isAccessibleColor(_ color: Color) -> Bool {
    return getColorContrast(color) >= 4.5
  }

  static func isAccessibleHexColor(_ hex: String) -> Bool {
    guard let color = hexToColor(hex) else { return false }
    return isAccessibleColor(color)
  }

  static func linkPadding() -> Double {
    return launcherLinkIconSize / 20
  }

  static func spacePadding() -> Double {
    return launcherLinkIconSize / 8
  }

  private static func stringFromColor(_ color: Color) -> String {
    let components = color.cgColor?.components ?? [0, 0, 0, 1]
    let r = components.count > 0 ? components[0] : 0
    let g = components.count > 1 ? components[1] : 0
    let b = components.count > 2 ? components[2] : 0
    let rStr = String(format: "%.6f", r)
    let gStr = String(format: "%.6f", g)
    let bStr = String(format: "%.6f", b)
    return "\(rStr),\(gStr),\(bStr)"
  }

  private static func colorFromString(_ colorString: String) -> Color? {
    let components = colorString.split(separator: ",")
    guard components.count >= 3, let r = Double(components[0]), let g = Double(components[1]), let b = Double(components[2]) else {
      return nil
    }
    return Color(red: r, green: g, blue: b)
  }
}
