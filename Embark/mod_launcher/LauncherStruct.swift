import SwiftUI

enum LauncherMode: Int {
  case launcher = 1
  case search = 2
  case settings = 3
  case space = 4
  case spaceSorting = 5
}

struct LinkData {
  var id: Int64 // 数据库ID
  var path: String // 链接路径
  var panelId: Int64 // 面板ID, -1表示在应用列表中
  var orderIndex: Int // 位置索引
  var name: String // 链接名称
  var icon: NSImage? // 链接图标
  var shortcut: LinkShortcut? // 链接快捷键
  var linkType: LinkType // 链接类型
  var fileModificationDate: Date? // 文件修改日期，用于动态更新缩略图
  var title: String? // 自定义名称
  var iconData: Data? // 图标数据
  var windowState: String? // 窗口状态 (x,y,width,height)
  var keepAlive: Bool // 是否保持窗口活跃（隐藏而不销毁）
  var isMobileMode: Bool // 是否为移动端模式
  var showInMenuBar: Bool // 是否在菜单栏显示
  var isPinned: Bool // 是否固定窗口
  var useProxy: Bool // 是否使用自定义代理
  var zoom: Double // 缩放比例
  var isVisible: Bool // 是否可见
}

enum LinkType: Int, Codable, CaseIterable {
  case application = 0
  case folder = 1
  case file = 2
  case web = 3

  var iconName: String {
    switch self {
    case .application:
      return "app.dashed"
    case .folder:
      return "folder"
    case .file:
      return "doc"
    case .web:
      return "globe"
    }
  }
}

enum TabKeyType: Int, CaseIterable, Identifiable {
  case disabled = 0
  case toSearch = 1
  case bidirectional = 2

  var id: Int { self.rawValue }

  var displayName: String {
    switch self {
    case .disabled:
      return NSLocalizedString("launcher.settings.general.tab_key.disabled", comment: "")
    case .toSearch:
      return NSLocalizedString("launcher.settings.general.tab_key.to_search", comment: "")
    case .bidirectional:
      return NSLocalizedString("launcher.settings.general.tab_key.bidirectional", comment: "")
    }
  }
}

enum SearchScope: Int, CaseIterable, Identifiable {
  case all = 0
  case allApps = 1
  case otherApps = 2

  var id: Int { self.rawValue }

  var displayName: String {
    switch self {
    case .all:
      return NSLocalizedString("launcher.settings.general.search_scope.all", comment: "")
    case .allApps:
      return NSLocalizedString("launcher.settings.general.search_scope.all_apps", comment: "")
    case .otherApps:
      return NSLocalizedString("launcher.settings.general.search_scope.other_apps", comment: "")
    }
  }
}

struct ColorPresets {
  static let accentColors: [String] = [
    "#FF4444", // 亮红色
    "#FF8C00", // 深橙色
    "#FFD700", // 金色
    "#7FFF00", // 查特鲁斯绿
    "#00FA9A", // 中春绿
    "#00CED1", // 深绿松石
    "#1E90FF", // 道奇蓝
    "#4169E1", // 皇家蓝
    "#8A2BE2", // 蓝紫色
    "#9370DB", // 中紫色
    "#FF1493", // 深粉色
    "#FF69B4", // 热粉色
    "#DC143C", // 深红色
    "#FF6347", // 番茄红
    "#32CD32", // 酸橙绿
    "#20B2AA", // 浅海洋绿
    "#4682B4", // 钢蓝色
    "#6A5ACD", // 板岩蓝
    "#BA55D3", // 中兰花紫
    "#C71585"  // 中紫红色
  ]
}
