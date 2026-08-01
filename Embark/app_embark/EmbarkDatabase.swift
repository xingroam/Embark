import SwiftUI

struct PanelTable: Codable {
  var id: Int64
  var name: String // 面板名称
  var isSub: Bool // 是否为子面板
  var parentId: Int64? // 父面板ID, nil表示主面板
  var orderIndex: Int // 位置索引
  var panelWidth: Double? // 面板宽度, nil表示使用默认宽度
  var isVisible: Bool // 是否可见

  init(id: Int64, name: String, isSub: Bool, parentId: Int64?, orderIndex: Int, panelWidth: Double? = nil, isVisible: Bool = true) {
    self.id = id
    self.name = name
    self.isSub = isSub
    self.parentId = parentId
    self.orderIndex = orderIndex
    self.panelWidth = panelWidth
    self.isVisible = isVisible
  }
}

struct LinkTable: Codable {
  var id: Int64
  var path: String // 链接路径
  var panelId: Int64 // 面板ID
  var orderIndex: Int // 位置索引
  var linkType: LinkType // 链接类型
  var title: String? // 自定义名称
  var windowState: String? // 窗口状态
  var keepAlive: Bool // 是否保持窗口活跃（隐藏而不销毁）
  var isMobileMode: Bool // 是否为移动端模式
  var showInMenuBar: Bool // 是否在菜单栏显示
  var isPinned: Bool // 是否固定窗口
  var useProxy: Bool // 是否使用自定义代理
  var zoom: Double // 缩放比例
  var isVisible: Bool // 是否可见
}

struct LinkShortcut: Codable, Equatable {
  let keyCode: CGKeyCode
  let flags: CGEventFlags
  let linkType: LinkType

  var displayText: String {
    var parts: [String] = []
    if flags.contains(.maskCommand) {
      parts.append("⌘")
    }
    if flags.contains(.maskControl) {
      parts.append("⌃")
    }
    if flags.contains(.maskAlternate) {
      parts.append("⌥")
    }
    if flags.contains(.maskShift) {
      parts.append("⇧")
    }
    parts.append(Keyboard.keyCodeToCharacter(keyCode))
    return parts.joined(separator: " ")
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let keyCodeInt = try container.decode(Int32.self, forKey: .keyCode)
    let flagsUInt = try container.decode(UInt64.self, forKey: .flags)
    let linkTypeInt = try container.decode(Int.self, forKey: .linkType)
    self.keyCode = CGKeyCode(keyCodeInt)
    self.flags = CGEventFlags(rawValue: flagsUInt)
    self.linkType = LinkType(rawValue: linkTypeInt) ?? .application
  }

  init(keyCode: CGKeyCode, flags: CGEventFlags, linkType: LinkType = .application) {
    self.keyCode = keyCode
    self.flags = Self.normalizeFlags(flags)
    self.linkType = linkType
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(Int32(keyCode), forKey: .keyCode)
    try container.encode(UInt64(flags.rawValue), forKey: .flags)
    try container.encode(linkType, forKey: .linkType)
  }

  static func normalizeFlags(_ flags: CGEventFlags) -> CGEventFlags {
    let modifierMask: UInt64 = CGEventFlags.maskCommand.rawValue | CGEventFlags.maskControl.rawValue | CGEventFlags.maskAlternate.rawValue | CGEventFlags.maskShift.rawValue
    return CGEventFlags(rawValue: flags.rawValue & modifierMask)
  }

  private enum CodingKeys: String, CodingKey {
    case keyCode
    case flags
    case linkType
  }
}

enum SpaceFocusMode: Int, Codable, CaseIterable {
  case keep = 0
  case enable = 1
  case disable = 2

  var displayName: String {
    switch self {
    case .keep:
      return LanguageManager.s.localizedString("space.focus.mode.keep")
    case .enable:
      return LanguageManager.s.localizedString("space.focus.mode.enable")
    case .disable:
      return LanguageManager.s.localizedString("space.focus.mode.disable")
    }
  }

  static var displayOrder: [SpaceFocusMode] {
    return [.keep, .enable, .disable]
  }
}

struct SpaceTable: Codable, Identifiable, Hashable {
  var id: Int64
  var name: String
  var orderIndex: Int
  var focus: SpaceFocusMode
  var systemUI: SystemUI
  let version: Int
  let screens: [ScreenInfo]
  var windows: [WindowSnapshot]
  static let currentVersion = 2

  var isLegacyData: Bool {
    return version < SpaceTable.currentVersion
  }

  init(id: Int64, name: String, orderIndex: Int, focus: SpaceFocusMode, systemUI: SystemUI = .showAll, screens: [ScreenInfo], windows: [WindowSnapshot]) {
    self.id = id
    self.name = name
    self.orderIndex = orderIndex
    self.focus = focus
    self.systemUI = systemUI
    self.version = SpaceTable.currentVersion
    self.screens = screens
    self.windows = windows
  }

  init(id: Int64, name: String, orderIndex: Int, focus: SpaceFocusMode, systemUI: SystemUI = .showAll, version: Int, screens: [ScreenInfo], windows: [WindowSnapshot]) {
    self.id = id
    self.name = name
    self.orderIndex = orderIndex
    self.focus = focus
    self.systemUI = systemUI
    self.version = version
    self.screens = screens
    self.windows = windows
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    self.id = try container.decode(Int64.self, forKey: .id)
    self.name = try container.decode(String.self, forKey: .name)
    self.orderIndex = try container.decode(Int.self, forKey: .orderIndex)
    self.focus = (try? container.decode(SpaceFocusMode.self, forKey: .focus)) ?? .keep
    self.systemUI = (try? container.decode(SystemUI.self, forKey: .systemUI)) ?? .showAll
    self.version = (try? container.decode(Int.self, forKey: .version)) ?? 1
    self.screens = try container.decode([ScreenInfo].self, forKey: .screens)
    self.windows = try container.decode([WindowSnapshot].self, forKey: .windows)
  }

  private enum CodingKeys: String, CodingKey {
    case id, name, orderIndex, focus, systemUI, version, screens, windows
  }
}

struct ScreenInfo: Codable, Hashable {
  let screenIndex: Int
  let frame: CGRect
  let isPrimary: Bool
}

struct WindowSnapshot: Codable, Hashable {
  let bundleIdentifier: String
  let appName: String
  let relativeFrame: CGRect
  let screenIndex: Int
  let isMinimized: Bool
  let title: String?
  var projectPaths: [String]

  init(bundleIdentifier: String, appName: String, relativeFrame: CGRect, screenIndex: Int, isMinimized: Bool, title: String?, projectPaths: [String] = []) {
    self.bundleIdentifier = bundleIdentifier
    self.appName = appName
    self.relativeFrame = relativeFrame
    self.screenIndex = screenIndex
    self.isMinimized = isMinimized
    self.title = title
    self.projectPaths = projectPaths
  }
}
