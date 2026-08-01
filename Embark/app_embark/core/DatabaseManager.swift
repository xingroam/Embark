import SwiftUI
import SQLite3

struct RawShortcut {
  let id: Int64
  let linkPath: String
  let linkId: Int64?
  let linkType: LinkType
}

class DatabaseManager : ObservableObject {
  static let s = DatabaseManager()
  private var db: OpaquePointer?
  private var dbPath: String = ""
  private let dbQueue = DispatchQueue(label: "database-queue", qos: .userInitiated)
  @Published private(set) var panels: [PanelTable] = []
  @Published private(set) var links: [LinkTable] = []
  @Published private(set) var spaces: [SpaceTable] = []
  private var isInitialized = false

  private init() {}

  func boot() {
    guard !isInitialized else { return }
    isInitialized = true
    let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
    let appFolder = appSupport.appendingPathComponent(EmbarkInfo.bundleIdentifier)
    try? FileManager.default.createDirectory(at: appFolder, withIntermediateDirectories: true)
    dbPath = appFolder.appendingPathComponent(EmbarkInfo.dbFile).path
    setupDatabase()
    loadPanels()
    loadLinks()
    loadSpaces()
  }

  deinit {
    sqlite3_close(db)
  }

  private func setupDatabase() {
    if sqlite3_open(dbPath, &db) != SQLITE_OK {
      return
    }
    createTables()
    migrateDatabase()
  }

  private func createTables() {
    let createPanelsTable = """
      CREATE TABLE IF NOT EXISTS panels (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        is_sub BOOLEAN NOT NULL DEFAULT 0,
        parent_id INTEGER,
        order_index INTEGER NOT NULL,
        panel_width REAL,
        is_visible BOOLEAN NOT NULL DEFAULT 1,
        FOREIGN KEY (parent_id) REFERENCES panels (id)
      );
    """
    let createLinksTable = """
      CREATE TABLE IF NOT EXISTS links (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        path TEXT NOT NULL UNIQUE,
        panel_id INTEGER NOT NULL DEFAULT -1,
        order_index INTEGER NOT NULL,
        link_type INTEGER NOT NULL DEFAULT 0,
        title TEXT,
        window_state TEXT,
        keep_alive BOOLEAN NOT NULL DEFAULT 0,
        is_mobile_mode BOOLEAN NOT NULL DEFAULT 0,
        show_in_menubar BOOLEAN NOT NULL DEFAULT 0,
        is_pinned BOOLEAN NOT NULL DEFAULT 0,
        use_proxy BOOLEAN NOT NULL DEFAULT 0,
        zoom REAL NOT NULL DEFAULT 1.0,
        is_visible BOOLEAN NOT NULL DEFAULT 1,
        FOREIGN KEY (panel_id) REFERENCES panels (id)
      );
    """
    let createLinkShortcutsTable = """
      CREATE TABLE IF NOT EXISTS link_shortcuts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        link_path TEXT NOT NULL UNIQUE,
        link_id INTEGER UNIQUE,
        link_type INTEGER NOT NULL DEFAULT 0,
        key_code INTEGER NOT NULL,
        flags INTEGER NOT NULL,
        FOREIGN KEY (link_path) REFERENCES links (path) ON DELETE CASCADE
      );
    """
    let createLinkIconsTable = """
      CREATE TABLE IF NOT EXISTS link_icons (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        link_id INTEGER UNIQUE,
        icon BLOB,
        FOREIGN KEY (link_id) REFERENCES links (id) ON DELETE CASCADE
      );
    """
    let createFocusExcludeTable = """
      CREATE TABLE IF NOT EXISTS focus_exclude (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        bundle_id TEXT NOT NULL UNIQUE,
        is_enabled BOOLEAN NOT NULL DEFAULT 1,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    """
    let createSwiftMouseExcludeTable = """
      CREATE TABLE IF NOT EXISTS swift_mouse_exclude (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        bundle_id TEXT NOT NULL UNIQUE,
        is_enabled BOOLEAN NOT NULL DEFAULT 1,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    """
    let createSwiftMouseLinksTable = """
      CREATE TABLE IF NOT EXISTS swift_mouse_links (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        link_id INTEGER UNIQUE,
        gesture TEXT NOT NULL,
        FOREIGN KEY (link_id) REFERENCES links (id) ON DELETE CASCADE
      );
    """
    let createSwiftKeyboardLinksTable = """
      CREATE TABLE IF NOT EXISTS swift_keyboard_links (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        link_id INTEGER UNIQUE,
        shortcut TEXT NOT NULL,
        FOREIGN KEY (link_id) REFERENCES links (id) ON DELETE CASCADE
      );
    """
    let createSpacesTable = """
      CREATE TABLE IF NOT EXISTS spaces (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        order_index INTEGER NOT NULL DEFAULT 0,
        focus INTEGER NOT NULL DEFAULT 0,
        system_ui INTEGER NOT NULL DEFAULT 0,
        version INTEGER NOT NULL DEFAULT 1,
        screens TEXT,
        windows TEXT
      );
    """
    if sqlite3_exec(db, createPanelsTable, nil, nil, nil) != SQLITE_OK {
      Debug.print("Error creating panels table")
    }
    if sqlite3_exec(db, createLinksTable, nil, nil, nil) != SQLITE_OK {
      Debug.print("Error creating links table")
    }
    if sqlite3_exec(db, createLinkShortcutsTable, nil, nil, nil) != SQLITE_OK {
      Debug.print("Error creating link_shortcuts table")
    }
    if sqlite3_exec(db, createLinkIconsTable, nil, nil, nil) != SQLITE_OK {
      Debug.print("Error creating link_icons table")
    }
    if sqlite3_exec(db, createFocusExcludeTable, nil, nil, nil) != SQLITE_OK {
      Debug.print("Error creating focus_exclude table")
    }
    if sqlite3_exec(db, createSwiftMouseExcludeTable, nil, nil, nil) != SQLITE_OK {
      Debug.print("Error creating swift_mouse_exclude table")
    }
    if sqlite3_exec(db, createSwiftMouseLinksTable, nil, nil, nil) != SQLITE_OK {
      Debug.print("Error creating swift_mouse_links table")
    }
    if sqlite3_exec(db, createSwiftKeyboardLinksTable, nil, nil, nil) != SQLITE_OK {
      Debug.print("Error creating swift_keyboard_links table")
    }
    if sqlite3_exec(db, createSpacesTable, nil, nil, nil) != SQLITE_OK {
      Debug.print("Error creating spaces table")
    }
  }

  private func migrateDatabase() {
    // Links 表添加多个新列
    let checkColumnQuery = "PRAGMA table_info(links)"
    var statement: OpaquePointer?
    var hasCustomNameColumn = false
    var hasTitleColumn = false
    var hasWindowStateColumn = false
    var hasKeepAliveColumn = false
    var hasIsMobileModeColumn = false
    var hasShowInMenuBarColumn = false
    var hasIsPinnedColumn = false
    var hasUseProxyColumn = false
    var hasZoomColumn = false
    var hasIsVisibleColumn = false
    if sqlite3_prepare_v2(db, checkColumnQuery, -1, &statement, nil) == SQLITE_OK {
      while sqlite3_step(statement) == SQLITE_ROW {
        let columnName = String(cString: sqlite3_column_text(statement, 1))
        if columnName == "custom_name" {
          hasCustomNameColumn = true
        } else if columnName == "title" {
          hasTitleColumn = true
        } else if columnName == "window_state" {
          hasWindowStateColumn = true
        } else if columnName == "keep_alive" {
          hasKeepAliveColumn = true
        } else if columnName == "is_mobile_mode" {
          hasIsMobileModeColumn = true
        } else if columnName == "show_in_menubar" {
          hasShowInMenuBarColumn = true
        } else if columnName == "is_pinned" {
          hasIsPinnedColumn = true
        } else if columnName == "use_proxy" {
          hasUseProxyColumn = true
        } else if columnName == "zoom" {
          hasZoomColumn = true
        } else if columnName == "is_visible" {
          hasIsVisibleColumn = true
        }
      }
    }
    sqlite3_finalize(statement)
    if hasCustomNameColumn && !hasTitleColumn {
      let renameQuery = "ALTER TABLE links RENAME COLUMN custom_name TO title"
      sqlite3_exec(db, renameQuery, nil, nil, nil)
    } else if !hasTitleColumn {
      let alterTableQuery = "ALTER TABLE links ADD COLUMN title TEXT"
      sqlite3_exec(db, alterTableQuery, nil, nil, nil)
    }
    if !hasWindowStateColumn {
      sqlite3_exec(db, "ALTER TABLE links ADD COLUMN window_state TEXT", nil, nil, nil)
    }
    if !hasKeepAliveColumn {
      sqlite3_exec(db, "ALTER TABLE links ADD COLUMN keep_alive BOOLEAN NOT NULL DEFAULT 0", nil, nil, nil)
    }
    if !hasIsMobileModeColumn {
      sqlite3_exec(db, "ALTER TABLE links ADD COLUMN is_mobile_mode BOOLEAN NOT NULL DEFAULT 0", nil, nil, nil)
    }
    if !hasShowInMenuBarColumn {
      sqlite3_exec(db, "ALTER TABLE links ADD COLUMN show_in_menubar BOOLEAN NOT NULL DEFAULT 0", nil, nil, nil)
    }
    if !hasIsPinnedColumn {
      sqlite3_exec(db, "ALTER TABLE links ADD COLUMN is_pinned BOOLEAN NOT NULL DEFAULT 0", nil, nil, nil)
    }
    if !hasUseProxyColumn {
      sqlite3_exec(db, "ALTER TABLE links ADD COLUMN use_proxy BOOLEAN NOT NULL DEFAULT 0", nil, nil, nil)
    }
    if !hasZoomColumn {
      sqlite3_exec(db, "ALTER TABLE links ADD COLUMN zoom REAL NOT NULL DEFAULT 1.0", nil, nil, nil)
    }
    if !hasIsVisibleColumn {
      sqlite3_exec(db, "ALTER TABLE links ADD COLUMN is_visible BOOLEAN NOT NULL DEFAULT 1", nil, nil, nil)
    }

    // Panels 表添加 is_visible 列
    let checkPanelsColumnQuery = "PRAGMA table_info(panels)"
    var hasPanelIsVisibleColumn = false
    if sqlite3_prepare_v2(db, checkPanelsColumnQuery, -1, &statement, nil) == SQLITE_OK {
      while sqlite3_step(statement) == SQLITE_ROW {
        let columnName = String(cString: sqlite3_column_text(statement, 1))
        if columnName == "is_visible" {
          hasPanelIsVisibleColumn = true
        }
      }
    }
    sqlite3_finalize(statement)
    if !hasPanelIsVisibleColumn {
      sqlite3_exec(db, "ALTER TABLE panels ADD COLUMN is_visible BOOLEAN NOT NULL DEFAULT 1", nil, nil, nil)
    }

    // Link Shortcuts 表添加 link_id 列
    let checkShortcutsColumnQuery = "PRAGMA table_info(link_shortcuts)"
    var hasLinkIdColumn = false
    if sqlite3_prepare_v2(db, checkShortcutsColumnQuery, -1, &statement, nil) == SQLITE_OK {
      while sqlite3_step(statement) == SQLITE_ROW {
        let columnName = String(cString: sqlite3_column_text(statement, 1))
        if columnName == "link_id" {
          hasLinkIdColumn = true
        }
      }
    }
    sqlite3_finalize(statement)
    if !hasLinkIdColumn {
      if sqlite3_exec(db, "ALTER TABLE link_shortcuts ADD COLUMN link_id INTEGER", nil, nil, nil) == SQLITE_OK {
        sqlite3_exec(db, "UPDATE link_shortcuts SET link_id = (SELECT id FROM links WHERE links.path = link_shortcuts.link_path)", nil, nil, nil)
      }
    }

    // Spaces 表添加 version 和 focus, system_ui 列
    let checkSpacesColumnQuery = "PRAGMA table_info(spaces)"
    var hasSpaceVersionColumn = false
    var hasSpaceFocusColumn = false
    var hasSpaceIsFocusColumn = false
    var hasSpaceSystemUIColumn = false
    if sqlite3_prepare_v2(db, checkSpacesColumnQuery, -1, &statement, nil) == SQLITE_OK {
      while sqlite3_step(statement) == SQLITE_ROW {
        let columnName = String(cString: sqlite3_column_text(statement, 1))
        if columnName == "version" {
          hasSpaceVersionColumn = true
        } else if columnName == "focus" {
          hasSpaceFocusColumn = true
        } else if columnName == "is_focus" {
          hasSpaceIsFocusColumn = true
        } else if columnName == "system_ui" {
          hasSpaceSystemUIColumn = true
        }
      }
    }
    sqlite3_finalize(statement)
    if !hasSpaceVersionColumn {
      sqlite3_exec(db, "ALTER TABLE spaces ADD COLUMN version INTEGER NOT NULL DEFAULT 1", nil, nil, nil)
    }
    if !hasSpaceFocusColumn {
      if sqlite3_exec(db, "ALTER TABLE spaces ADD COLUMN focus INTEGER NOT NULL DEFAULT 0", nil, nil, nil) == SQLITE_OK {
        sqlite3_exec(db, "UPDATE spaces SET focus = CASE WHEN is_focus = 1 THEN 1 ELSE 2 END", nil, nil, nil)
      }
    }
    if hasSpaceIsFocusColumn {
      sqlite3_exec(db, "ALTER TABLE spaces DROP COLUMN is_focus", nil, nil, nil)
    }
    if !hasSpaceSystemUIColumn {
      sqlite3_exec(db, "ALTER TABLE spaces ADD COLUMN system_ui INTEGER NOT NULL DEFAULT 0", nil, nil, nil)
    }
  }

  func loadPanels(){
    dbQueue.sync {
      let query = "SELECT id, name, is_sub, parent_id, order_index, panel_width, is_visible FROM panels ORDER BY order_index"
      var statement: OpaquePointer?
      var panelList: [PanelTable] = []
      if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
        while sqlite3_step(statement) == SQLITE_ROW {
          let id = sqlite3_column_int64(statement, 0)
          let name = String(cString: sqlite3_column_text(statement, 1))
          let isSub = sqlite3_column_int(statement, 2) != 0
          let parentId = sqlite3_column_type(statement, 3) == SQLITE_NULL ? nil : sqlite3_column_int64(statement, 3)
          let orderIndex = Int(sqlite3_column_int(statement, 4))
          let panelWidth = sqlite3_column_type(statement, 5) == SQLITE_NULL ? nil : Double(sqlite3_column_double(statement, 5))
          let isVisible = sqlite3_column_int(statement, 6) != 0
          panelList.append(PanelTable(id: id, name: name, isSub: isSub, parentId: parentId, orderIndex: orderIndex, panelWidth: panelWidth, isVisible: isVisible))
        }
      }
      sqlite3_finalize(statement)
      DispatchQueue.main.async { [weak self] in
        guard let self = self else { return }
        panels = panelList
        objectWillChange.send()
      }
    }
  }

  func loadLinks() {
    dbQueue.sync {
      let query = "SELECT id, path, panel_id, order_index, link_type, title, window_state, keep_alive, is_mobile_mode, show_in_menubar, is_pinned, use_proxy, zoom, is_visible FROM links ORDER BY panel_id, order_index"
      var statement: OpaquePointer?
      var linkList: [LinkTable] = []
      if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
        while sqlite3_step(statement) == SQLITE_ROW {
          let id = sqlite3_column_int64(statement, 0)
          let path = String(cString: sqlite3_column_text(statement, 1))
          let panelId = sqlite3_column_int64(statement, 2)
          let orderIndex = Int(sqlite3_column_int(statement, 3))
          let linkType = LinkType(rawValue: Int(sqlite3_column_int(statement, 4))) ?? .application
          let title = sqlite3_column_type(statement, 5) == SQLITE_NULL ? nil : String(cString: sqlite3_column_text(statement, 5))
          let windowState = sqlite3_column_type(statement, 6) == SQLITE_NULL ? nil : String(cString: sqlite3_column_text(statement, 6))
          let keepAlive = sqlite3_column_int(statement, 7) != 0
          let isMobileMode = sqlite3_column_int(statement, 8) != 0
          let showInMenuBar = sqlite3_column_int(statement, 9) != 0
          let isPinned = sqlite3_column_int(statement, 10) != 0
          let useProxy = sqlite3_column_int(statement, 11) != 0
          let zoom = sqlite3_column_double(statement, 12)
          let isVisible = sqlite3_column_int(statement, 13) != 0
          linkList.append(LinkTable(id: id, path: path, panelId: panelId, orderIndex: orderIndex, linkType: linkType, title: title, windowState: windowState, keepAlive: keepAlive, isMobileMode: isMobileMode, showInMenuBar: showInMenuBar, isPinned: isPinned, useProxy: useProxy, zoom: zoom, isVisible: isVisible))
        }
      }
      sqlite3_finalize(statement)
      DispatchQueue.main.async { [weak self] in
        guard let self = self else { return }
        links = linkList
        objectWillChange.send()
      }
    }
  }

  func addPanel(name: String, isSub: Bool, parentId: Int64?, orderIndex: Int, panelWidth: Double? = nil) -> Int64 {
    var panelId: Int64 = 0
    dbQueue.sync {
      let insertQuery = "INSERT INTO panels (name, is_sub, parent_id, order_index, panel_width) VALUES (?, ?, ?, ?, ?)"
      var statement: OpaquePointer?
      if sqlite3_prepare_v2(db, insertQuery, -1, &statement, nil) == SQLITE_OK {
        sqlite3_bind_text(statement, 1, (name as NSString).utf8String, -1, nil)
        sqlite3_bind_int(statement, 2, isSub ? 1 : 0)
        if let parentId = parentId {
          sqlite3_bind_int64(statement, 3, parentId)
        } else {
          sqlite3_bind_null(statement, 3)
        }
        sqlite3_bind_int(statement, 4, Int32(orderIndex))
        if let panelWidth = panelWidth {
          sqlite3_bind_double(statement, 5, panelWidth)
        } else {
          sqlite3_bind_null(statement, 5)
        }
        sqlite3_step(statement)
        panelId = sqlite3_last_insert_rowid(db)
      }
      sqlite3_finalize(statement)
    }
    return panelId
  }

  func updatePanelName(panelId: Int64, newName: String) {
    dbQueue.sync {
      let updateQuery = "UPDATE panels SET name = ? WHERE id = ?"
      var statement: OpaquePointer?
      if sqlite3_prepare_v2(db, updateQuery, -1, &statement, nil) == SQLITE_OK {
        sqlite3_bind_text(statement, 1, (newName as NSString).utf8String, -1, nil)
        sqlite3_bind_int64(statement, 2, panelId)
        sqlite3_step(statement)
      }
      sqlite3_finalize(statement)
    }
  }

  func updatePanelWidth(panelId: Int64, width: Double?) {
    dbQueue.sync {
      let updateQuery = "UPDATE panels SET panel_width = ? WHERE id = ?"
      var statement: OpaquePointer?
      if sqlite3_prepare_v2(db, updateQuery, -1, &statement, nil) == SQLITE_OK {
        if let width = width {
          sqlite3_bind_double(statement, 1, width)
        } else {
          sqlite3_bind_null(statement, 1)
        }
        sqlite3_bind_int64(statement, 2, panelId)
        sqlite3_step(statement)
      }
      sqlite3_finalize(statement)
    }
  }

  func removePanel(panelId: Int64) {
    dbQueue.sync {
      let deleteLinksQuery = "DELETE FROM links WHERE panel_id = ?"
      var statement: OpaquePointer?
      if sqlite3_prepare_v2(db, deleteLinksQuery, -1, &statement, nil) == SQLITE_OK {
        sqlite3_bind_int64(statement, 1, panelId)
        sqlite3_step(statement)
      }
      sqlite3_finalize(statement)
      let deleteQuery = "DELETE FROM panels WHERE id = ?"
      if sqlite3_prepare_v2(db, deleteQuery, -1, &statement, nil) == SQLITE_OK {
        sqlite3_bind_int64(statement, 1, panelId)
        sqlite3_step(statement)
      }
      sqlite3_finalize(statement)
    }
  }

  func swapPanelOrder(panel1Id: Int64, panel2Id: Int64, panel1OrderIndex: Int, panel2OrderIndex: Int) {
    dbQueue.sync {
      let updateQuery = "UPDATE panels SET order_index = ? WHERE id = ?"
      var statement: OpaquePointer?
      if sqlite3_prepare_v2(db, updateQuery, -1, &statement, nil) == SQLITE_OK {
        sqlite3_bind_int(statement, 1, Int32(panel2OrderIndex))
        sqlite3_bind_int64(statement, 2, panel1Id)
        sqlite3_step(statement)
        sqlite3_reset(statement)
        sqlite3_bind_int(statement, 1, Int32(panel1OrderIndex))
        sqlite3_bind_int64(statement, 2, panel2Id)
        sqlite3_step(statement)
      }
      sqlite3_finalize(statement)
    }
  }

  func movePanelToBelow(panelId: Int64, targetPanelId: Int64) {
    dbQueue.sync {
      let getTargetPanelQuery = "SELECT order_index FROM panels WHERE id = ? AND is_sub = 0"
      var statement: OpaquePointer?
      var targetOrderIndex: Int = 0
      if sqlite3_prepare_v2(db, getTargetPanelQuery, -1, &statement, nil) == SQLITE_OK {
        sqlite3_bind_int64(statement, 1, targetPanelId)
        if sqlite3_step(statement) == SQLITE_ROW {
          targetOrderIndex = Int(sqlite3_column_int(statement, 0))
        }
      }
      sqlite3_finalize(statement)
      let getSourcePanelQuery = "SELECT order_index FROM panels WHERE id = ? AND is_sub = 0"
      var sourceOrderIndex: Int = 0
      if sqlite3_prepare_v2(db, getSourcePanelQuery, -1, &statement, nil) == SQLITE_OK {
        sqlite3_bind_int64(statement, 1, panelId)
        if sqlite3_step(statement) == SQLITE_ROW {
          sourceOrderIndex = Int(sqlite3_column_int(statement, 0))
        }
      }
      sqlite3_finalize(statement)
      if sourceOrderIndex < targetOrderIndex {
        let updateOrderQuery = "UPDATE panels SET order_index = order_index - 1 WHERE is_sub = 0 AND order_index > ? AND order_index <= ?"
        if sqlite3_prepare_v2(db, updateOrderQuery, -1, &statement, nil) == SQLITE_OK {
          sqlite3_bind_int(statement, 1, Int32(sourceOrderIndex))
          sqlite3_bind_int(statement, 2, Int32(targetOrderIndex))
          sqlite3_step(statement)
        }
        sqlite3_finalize(statement)
        let moveQuery = "UPDATE panels SET order_index = ? WHERE id = ?"
        if sqlite3_prepare_v2(db, moveQuery, -1, &statement, nil) == SQLITE_OK {
          sqlite3_bind_int(statement, 1, Int32(targetOrderIndex))
          sqlite3_bind_int64(statement, 2, panelId)
          sqlite3_step(statement)
        }
        sqlite3_finalize(statement)
      } else {
        let updateOrderQuery = "UPDATE panels SET order_index = order_index + 1 WHERE is_sub = 0 AND order_index > ? AND order_index < ?"
        if sqlite3_prepare_v2(db, updateOrderQuery, -1, &statement, nil) == SQLITE_OK {
          sqlite3_bind_int(statement, 1, Int32(targetOrderIndex))
          sqlite3_bind_int(statement, 2, Int32(sourceOrderIndex))
          sqlite3_step(statement)
        }
        sqlite3_finalize(statement)
        let moveQuery = "UPDATE panels SET order_index = ? WHERE id = ?"
        if sqlite3_prepare_v2(db, moveQuery, -1, &statement, nil) == SQLITE_OK {
          sqlite3_bind_int(statement, 1, Int32(targetOrderIndex + 1))
          sqlite3_bind_int64(statement, 2, panelId)
          sqlite3_step(statement)
        }
        sqlite3_finalize(statement)
      }
      Debug.print("Moved panel \(panelId) to below panel \(targetPanelId)")
    }
  }

  func moveSubPanel(subPanelId: Int64, newParentId: Int64, newOrderIndex: Int) {
    dbQueue.sync {
      let updateQuery = "UPDATE panels SET parent_id = ?, order_index = ? WHERE id = ?"
      var statement: OpaquePointer?
      if sqlite3_prepare_v2(db, updateQuery, -1, &statement, nil) == SQLITE_OK {
        sqlite3_bind_int64(statement, 1, newParentId)
        sqlite3_bind_int(statement, 2, Int32(newOrderIndex))
        sqlite3_bind_int64(statement, 3, subPanelId)
        sqlite3_step(statement)
      }
      sqlite3_finalize(statement)
    }
  }

  func getNextPanelOrderIndex(parentId: Int64?) -> Int {
    var maxIndex = 0
    dbQueue.sync {
      let query = "SELECT MAX(order_index) FROM panels WHERE parent_id IS ?"
      var statement: OpaquePointer?
      if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
        if let parentId = parentId {
          sqlite3_bind_int64(statement, 1, parentId)
        } else {
          sqlite3_bind_null(statement, 1)
        }
        if sqlite3_step(statement) == SQLITE_ROW {
          maxIndex = Int(sqlite3_column_int(statement, 0))
        }
      }
      sqlite3_finalize(statement)
    }
    return maxIndex + 1
  }

  func addLink(path: String, panelId: Int64, orderIndex: Int) {
    dbQueue.async {
      let insertQuery = "INSERT OR REPLACE INTO links (path, panel_id, order_index) VALUES (?, ?, ?)"
      var statement: OpaquePointer?
      if sqlite3_prepare_v2(self.db, insertQuery, -1, &statement, nil) == SQLITE_OK {
        sqlite3_bind_text(statement, 1, (path as NSString).utf8String, -1, nil)
        sqlite3_bind_int64(statement, 2, panelId)
        sqlite3_bind_int(statement, 3, Int32(orderIndex))
        sqlite3_step(statement)
      }
      sqlite3_finalize(statement)
    }
  }

  private func _deleteLink(id: Int64, path: String? = nil) {
    var statement: OpaquePointer?
    var linkPath: String? = path
    if linkPath == nil {
      let pathQuery = "SELECT path FROM links WHERE id = ?"
      if sqlite3_prepare_v2(self.db, pathQuery, -1, &statement, nil) == SQLITE_OK {
        sqlite3_bind_int64(statement, 1, id)
        if sqlite3_step(statement) == SQLITE_ROW {
          linkPath = String(cString: sqlite3_column_text(statement, 0))
        }
      }
      sqlite3_finalize(statement)
    }

    // Delete shortcut
    let deleteShortcutQuery: String
    if linkPath != nil {
      deleteShortcutQuery = "DELETE FROM link_shortcuts WHERE link_id = ? OR link_path = ?"
    } else {
      deleteShortcutQuery = "DELETE FROM link_shortcuts WHERE link_id = ?"
    }
    if sqlite3_prepare_v2(self.db, deleteShortcutQuery, -1, &statement, nil) == SQLITE_OK {
      sqlite3_bind_int64(statement, 1, id)
      if let p = linkPath {
        sqlite3_bind_text(statement, 2, (p as NSString).utf8String, -1, nil)
      }
      sqlite3_step(statement)
    }
    sqlite3_finalize(statement)

    // Delete icon
    let deleteIconQuery = "DELETE FROM link_icons WHERE link_id = ?"
    if sqlite3_prepare_v2(self.db, deleteIconQuery, -1, &statement, nil) == SQLITE_OK {
      sqlite3_bind_int64(statement, 1, id)
      sqlite3_step(statement)
    }
    sqlite3_finalize(statement)

    // Delete swift mouse link
    let deleteSwiftMouseQuery = "DELETE FROM swift_mouse_links WHERE link_id = ?"
    if sqlite3_prepare_v2(self.db, deleteSwiftMouseQuery, -1, &statement, nil) == SQLITE_OK {
      sqlite3_bind_int64(statement, 1, id)
      sqlite3_step(statement)
    }
    sqlite3_finalize(statement)

    // Delete swift keyboard link
    let deleteSwiftKeyboardQuery = "DELETE FROM swift_keyboard_links WHERE link_id = ?"
    if sqlite3_prepare_v2(self.db, deleteSwiftKeyboardQuery, -1, &statement, nil) == SQLITE_OK {
      sqlite3_bind_int64(statement, 1, id)
      sqlite3_step(statement)
    }
    sqlite3_finalize(statement)

    // Delete link
    let deleteQuery = "DELETE FROM links WHERE id = ?"
    if sqlite3_prepare_v2(self.db, deleteQuery, -1, &statement, nil) == SQLITE_OK {
      sqlite3_bind_int64(statement, 1, id)
      sqlite3_step(statement)
    }
    sqlite3_finalize(statement)
  }

  func removeLink(id: Int64) {
    dbQueue.async {
      self._deleteLink(id: id)
      DispatchQueue.main.async {
        NotificationCenter.default.post(name: NSNotification.Name("LinkShortcutsChanged"), object: nil)
      }
    }
  }

  func removeLink(path: String) {
    dbQueue.async {
      var linkId: Int64 = 0
      let idQuery = "SELECT id FROM links WHERE path = ?"
      var statement: OpaquePointer?
      if sqlite3_prepare_v2(self.db, idQuery, -1, &statement, nil) == SQLITE_OK {
        sqlite3_bind_text(statement, 1, (path as NSString).utf8String, -1, nil)
        if sqlite3_step(statement) == SQLITE_ROW {
          linkId = sqlite3_column_int64(statement, 0)
        }
      }
      sqlite3_finalize(statement)
      if linkId != 0 {
        self._deleteLink(id: linkId, path: path)
      } else {
        let deleteQuery = "DELETE FROM links WHERE path = ?"
        if sqlite3_prepare_v2(self.db, deleteQuery, -1, &statement, nil) == SQLITE_OK {
          sqlite3_bind_text(statement, 1, (path as NSString).utf8String, -1, nil)
          sqlite3_step(statement)
        }
        sqlite3_finalize(statement)
      }
      DispatchQueue.main.async {
        NotificationCenter.default.post(name: NSNotification.Name("LinkShortcutsChanged"), object: nil)
      }
    }
  }

  func moveLink(path: String, panelId: Int64, orderIndex: Int) {
    dbQueue.async {
      let updateQuery = "UPDATE links SET panel_id = ?, order_index = ? WHERE path = ?"
      var statement: OpaquePointer?
      if sqlite3_prepare_v2(self.db, updateQuery, -1, &statement, nil) == SQLITE_OK {
        sqlite3_bind_int64(statement, 1, panelId)
        sqlite3_bind_int(statement, 2, Int32(orderIndex))
        sqlite3_bind_text(statement, 3, (path as NSString).utf8String, -1, nil)
        sqlite3_step(statement)
      }
      sqlite3_finalize(statement)
    }
  }

  func updateLinkOrder(path: String, panelId: Int64, orderIndex: Int) {
    dbQueue.sync {
      let updateQuery = "UPDATE links SET order_index = ? WHERE path = ? AND panel_id = ?"
      var statement: OpaquePointer?
      if sqlite3_prepare_v2(db, updateQuery, -1, &statement, nil) == SQLITE_OK {
        sqlite3_bind_int(statement, 1, Int32(orderIndex))
        sqlite3_bind_text(statement, 2, (path as NSString).utf8String, -1, nil)
        sqlite3_bind_int64(statement, 3, panelId)
        sqlite3_step(statement)
      }
      sqlite3_finalize(statement)
    }
  }

  func getNextLinkOrderIndex(panelId: Int64) -> Int {
    var maxIndex = 0
    let query = "SELECT MAX(order_index) FROM links WHERE panel_id = ?"
    var statement: OpaquePointer?
    if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
      sqlite3_bind_int64(statement, 1, panelId)
      if sqlite3_step(statement) == SQLITE_ROW {
        maxIndex = Int(sqlite3_column_int(statement, 0))
      }
    }
    sqlite3_finalize(statement)
    return maxIndex + 1
  }

  func addMainPanel(name: String) -> Int64 {
    let orderIndex = getNextPanelOrderIndex(parentId: nil)
    return addPanel(name: name, isSub: false, parentId: nil, orderIndex: orderIndex)
  }

  func addSubPanel(name: String, parentId: Int64) -> Int64 {
    let orderIndex = getNextPanelOrderIndex(parentId: parentId)
    return addPanel(name: name, isSub: true, parentId: parentId, orderIndex: orderIndex)
  }

  func removePanelWithAppMove(panelId: Int64) {
    dbQueue.async {
      var hasShortcutsDeleted = false
      self.removePanelWithChildren(panelId: panelId, hasShortcutsDeleted: &hasShortcutsDeleted)
      DispatchQueue.main.async {
        if hasShortcutsDeleted {
          NotificationCenter.default.post(name: NSNotification.Name("LinkShortcutsChanged"), object: nil)
        }
        self.loadPanels()
        self.loadLinks()
      }
    }
  }

  // 递归删除面板及其所有子面板
  private func removePanelWithChildren(panelId: Int64, hasShortcutsDeleted: inout Bool) {
    var childPanelIds: [Int64] = []
    let query = "SELECT id FROM panels WHERE parent_id = ?"
    var statement: OpaquePointer?
    if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
      sqlite3_bind_int64(statement, 1, panelId)
      while sqlite3_step(statement) == SQLITE_ROW {
        childPanelIds.append(sqlite3_column_int64(statement, 0))
      }
    }
    sqlite3_finalize(statement)
    for childId in childPanelIds {
      removePanelWithChildren(panelId: childId, hasShortcutsDeleted: &hasShortcutsDeleted)
    }
    let getLinksQuery = "SELECT id, path FROM links WHERE panel_id = ?"
    var panelLinks: [(id: Int64, path: String)] = []
    if sqlite3_prepare_v2(db, getLinksQuery, -1, &statement, nil) == SQLITE_OK {
      sqlite3_bind_int64(statement, 1, panelId)
      while sqlite3_step(statement) == SQLITE_ROW {
        let id = sqlite3_column_int64(statement, 0)
        let path = String(cString: sqlite3_column_text(statement, 1))
        panelLinks.append((id: id, path: path))
      }
    }
    sqlite3_finalize(statement)
    for linkInfo in panelLinks {
      if hasLinkShortcut(linkPath: linkInfo.path) {
        hasShortcutsDeleted = true
      }
      _deleteLink(id: linkInfo.id, path: linkInfo.path)
    }
    let deleteQuery = "DELETE FROM panels WHERE id = ?"
    if sqlite3_prepare_v2(db, deleteQuery, -1, &statement, nil) == SQLITE_OK {
      sqlite3_bind_int64(statement, 1, panelId)
      sqlite3_step(statement)
    }
    sqlite3_finalize(statement)
    Debug.print("Deleted panel: \(panelId) with \(panelLinks.count) links")
  }

  func moveLinkWithOrder(path: String, to panelId: Int64) {
    dbQueue.async {
      var orderIndex = 0
      if panelId == -1 {
        orderIndex = 0
      } else {
        let query = "SELECT MAX(order_index) FROM links WHERE panel_id = ?"
        var statement: OpaquePointer?
        if sqlite3_prepare_v2(self.db, query, -1, &statement, nil) == SQLITE_OK {
          sqlite3_bind_int64(statement, 1, panelId)
          if sqlite3_step(statement) == SQLITE_ROW {
            orderIndex = Int(sqlite3_column_int(statement, 0)) + 1
          }
        }
        sqlite3_finalize(statement)
      }
      let checkQuery = "SELECT COUNT(*) FROM links WHERE path = ?"
      var statement: OpaquePointer?
      var exists = false
      if sqlite3_prepare_v2(self.db, checkQuery, -1, &statement, nil) == SQLITE_OK {
        sqlite3_bind_text(statement, 1, (path as NSString).utf8String, -1, nil)
        if sqlite3_step(statement) == SQLITE_ROW {
          exists = sqlite3_column_int(statement, 0) > 0
        }
      }
      sqlite3_finalize(statement)
      if exists {
        let updateQuery = "UPDATE links SET panel_id = ?, order_index = ? WHERE path = ?"
        if sqlite3_prepare_v2(self.db, updateQuery, -1, &statement, nil) == SQLITE_OK {
          sqlite3_bind_int64(statement, 1, panelId)
          sqlite3_bind_int(statement, 2, Int32(orderIndex))
          sqlite3_bind_text(statement, 3, (path as NSString).utf8String, -1, nil)
          sqlite3_step(statement)
        }
        sqlite3_finalize(statement)
      } else {
        let insertQuery = "INSERT OR REPLACE INTO links (path, panel_id, order_index) VALUES (?, ?, ?)"
        if sqlite3_prepare_v2(self.db, insertQuery, -1, &statement, nil) == SQLITE_OK {
          sqlite3_bind_text(statement, 1, (path as NSString).utf8String, -1, nil)
          sqlite3_bind_int64(statement, 2, panelId)
          sqlite3_bind_int(statement, 3, Int32(orderIndex))
          sqlite3_step(statement)
        }
        sqlite3_finalize(statement)
      }
    }
  }

  func reorderLinksInPanel(panelId: Int64, from sourceIndex: Int, to destinationIndex: Int, links: [LinkTable]) {
    if panelId == -1 {
      Debug.print("Link list doesn't allow drag sorting")
      return
    }
    dbQueue.async {
      var panelLinks = links.filter { $0.panelId == panelId }
        .sorted { $0.orderIndex < $1.orderIndex }
      let safeSourceIndex = min(sourceIndex, panelLinks.count - 1)
      let safeDestinationIndex = min(destinationIndex, panelLinks.count - 1)
      if safeSourceIndex != safeDestinationIndex {
        panelLinks.swapAt(safeSourceIndex, safeDestinationIndex)
      }
      for (newIndex, link) in panelLinks.enumerated() {
        self.updateLinkOrder(path: link.path, panelId: panelId, orderIndex: newIndex)
      }
    }
  }

  func swapPanelOrderWithValidation(panel1Id: Int64, panel2Id: Int64, panels: [PanelTable]) {
    let panel1 = panels.first { $0.id == panel1Id }
    let panel2 = panels.first { $0.id == panel2Id }
    guard let panel1 = panel1, let panel2 = panel2 else {
      Debug.print("Panel doesn't exist")
      return
    }
    swapPanelOrder(panel1Id: panel1Id, panel2Id: panel2Id, panel1OrderIndex: panel1.orderIndex, panel2OrderIndex: panel2.orderIndex)
  }

  func moveSubPanelWithValidation(subPanelId: Int64, to newParentId: Int64, panels: [PanelTable]) {
    guard let _ = panels.first(where: { $0.id == subPanelId && $0.isSub }), let _ = panels.first(where: { $0.id == newParentId && !$0.isSub }) else {
      Debug.print("Invalid sub-panel or parent panel")
      return
    }
    let newOrderIndex = getNextPanelOrderIndex(parentId: newParentId)
    moveSubPanel(subPanelId: subPanelId, newParentId: newParentId, newOrderIndex: newOrderIndex)
  }

  func moveSubPanelToSubPanelBelow(subPanelId: Int64, targetSubPanelId: Int64) {
    dbQueue.sync {
      let getTargetSubPanelQuery = "SELECT parent_id, order_index FROM panels WHERE id = ? AND is_sub = 1"
      var statement: OpaquePointer?
      var targetParentId: Int64 = 0
      var targetOrderIndex: Int = 0
      if sqlite3_prepare_v2(db, getTargetSubPanelQuery, -1, &statement, nil) == SQLITE_OK {
        sqlite3_bind_int64(statement, 1, targetSubPanelId)
        if sqlite3_step(statement) == SQLITE_ROW {
          targetParentId = sqlite3_column_int64(statement, 0)
          targetOrderIndex = Int(sqlite3_column_int(statement, 1))
        }
      }
      sqlite3_finalize(statement)
      if targetParentId == 0 {
        Debug.print("Invalid target sub-panel")
        return
      }
      let updateOrderQuery = "UPDATE panels SET order_index = order_index + 1 WHERE parent_id = ? AND order_index > ? AND is_sub = 1"
      if sqlite3_prepare_v2(db, updateOrderQuery, -1, &statement, nil) == SQLITE_OK {
        sqlite3_bind_int64(statement, 1, targetParentId)
        sqlite3_bind_int(statement, 2, Int32(targetOrderIndex))
        sqlite3_step(statement)
      }
      sqlite3_finalize(statement)
      let moveQuery = "UPDATE panels SET parent_id = ?, order_index = ? WHERE id = ?"
      if sqlite3_prepare_v2(db, moveQuery, -1, &statement, nil) == SQLITE_OK {
        sqlite3_bind_int64(statement, 1, targetParentId)
        sqlite3_bind_int(statement, 2, Int32(targetOrderIndex + 1))
        sqlite3_bind_int64(statement, 3, subPanelId)
        sqlite3_step(statement)
      }
      sqlite3_finalize(statement)
      Debug.print("Moved sub-panel \(subPanelId) to below sub-panel \(targetSubPanelId) in parent panel \(targetParentId)")
    }
  }

  func getMainPanels(panels: [PanelTable]) -> [PanelTable] {
    return panels.filter { !$0.isSub }.sorted { $0.orderIndex < $1.orderIndex }
  }

  func getSubPanels(for panelId: Int64, panels: [PanelTable]) -> [PanelTable] {
    return panels.filter { $0.isSub && $0.parentId == panelId }.sorted { $0.orderIndex < $1.orderIndex }
  }

  func setLinkShortcut(linkPath: String, linkId: Int64? = nil, keyCode: CGKeyCode?, flags: CGEventFlags?, linkType: LinkType = .application) {
    dbQueue.async {
      autoreleasepool {
        var finalLinkId = linkId
        if finalLinkId == nil {
           let idQuery = "SELECT id FROM links WHERE path = ?"
           var idStmt: OpaquePointer?
           if sqlite3_prepare_v2(self.db, idQuery, -1, &idStmt, nil) == SQLITE_OK {
             sqlite3_bind_text(idStmt, 1, (linkPath as NSString).utf8String, -1, nil)
             if sqlite3_step(idStmt) == SQLITE_ROW {
               finalLinkId = sqlite3_column_int64(idStmt, 0)
             }
           }
           sqlite3_finalize(idStmt)
        }
        if let keyCode = keyCode, let flags = flags {
          let normalizedFlags = LinkShortcut.normalizeFlags(flags)
          var updated = false
          if let finalLinkId = finalLinkId {
            let updateQuery = "UPDATE link_shortcuts SET link_path = ?, key_code = ?, flags = ?, link_type = ? WHERE link_id = ?"
            var updateStmt: OpaquePointer?
            if sqlite3_prepare_v2(self.db, updateQuery, -1, &updateStmt, nil) == SQLITE_OK {
               sqlite3_bind_text(updateStmt, 1, (linkPath as NSString).utf8String, -1, nil)
               sqlite3_bind_int(updateStmt, 2, Int32(keyCode))
               sqlite3_bind_int64(updateStmt, 3, Int64(normalizedFlags.rawValue))
               sqlite3_bind_int(updateStmt, 4, Int32(linkType.rawValue))
               sqlite3_bind_int64(updateStmt, 5, finalLinkId)
              if sqlite3_step(updateStmt) == SQLITE_DONE {
                if sqlite3_changes(self.db) > 0 {
                  updated = true
                }
               }
            }
            sqlite3_finalize(updateStmt)
          } else {
            let updateQuery = "UPDATE link_shortcuts SET key_code = ?, flags = ?, link_type = ? WHERE link_path = ?"
            var updateStmt: OpaquePointer?
            if sqlite3_prepare_v2(self.db, updateQuery, -1, &updateStmt, nil) == SQLITE_OK {
               sqlite3_bind_int(updateStmt, 1, Int32(keyCode))
               sqlite3_bind_int64(updateStmt, 2, Int64(normalizedFlags.rawValue))
               sqlite3_bind_int(updateStmt, 3, Int32(linkType.rawValue))
               sqlite3_bind_text(updateStmt, 4, (linkPath as NSString).utf8String, -1, nil)
              if sqlite3_step(updateStmt) == SQLITE_DONE {
                if sqlite3_changes(self.db) > 0 {
                  updated = true
                }
              }
            }
            sqlite3_finalize(updateStmt)
          }
          if !updated {
            // We must store link_path even for web links because the column is UNIQUE and NOT NULL.
            // However, for web links, we will rely on link_id for lookup logic.
            let query = "INSERT INTO link_shortcuts (link_path, link_id, key_code, flags, link_type) VALUES (?, ?, ?, ?, ?)"
            var statement: OpaquePointer?
            if sqlite3_prepare_v2(self.db, query, -1, &statement, nil) == SQLITE_OK {
              sqlite3_bind_text(statement, 1, (linkPath as NSString).utf8String, -1, nil)
              if let finalLinkId = finalLinkId {
                sqlite3_bind_int64(statement, 2, finalLinkId)
              } else {
                sqlite3_bind_null(statement, 2)
              }
              sqlite3_bind_int(statement, 3, Int32(keyCode))
              sqlite3_bind_int64(statement, 4, Int64(normalizedFlags.rawValue))
              sqlite3_bind_int(statement, 5, Int32(linkType.rawValue))

              if sqlite3_step(statement) != SQLITE_DONE {
                Debug.print("Error setting link shortcut")
              }
            }
            sqlite3_finalize(statement)
          }
        } else {
          let query: String
          if finalLinkId != nil {
             query = "DELETE FROM link_shortcuts WHERE link_id = ?"
          } else {
             query = "DELETE FROM link_shortcuts WHERE link_path = ?"
          }
          var statement: OpaquePointer?
          if sqlite3_prepare_v2(self.db, query, -1, &statement, nil) == SQLITE_OK {
            if let finalLinkId = finalLinkId {
               sqlite3_bind_int64(statement, 1, finalLinkId)
            } else {
               sqlite3_bind_text(statement, 1, (linkPath as NSString).utf8String, -1, nil)
            }
            if sqlite3_step(statement) != SQLITE_DONE {
              Debug.print("Error deleting link shortcut")
            }
          }
          sqlite3_finalize(statement)
        }
        DispatchQueue.main.async {
          NotificationCenter.default.post(name: NSNotification.Name("LinkShortcutsChanged"), object: nil)
        }
      }
    }
  }

  func getAllRawShortcuts() -> [RawShortcut] {
    var shortcuts: [RawShortcut] = []
    dbQueue.sync {
      let query = "SELECT id, link_path, link_id, link_type FROM link_shortcuts"
      var statement: OpaquePointer?
      if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
        while sqlite3_step(statement) == SQLITE_ROW {
          let id = sqlite3_column_int64(statement, 0)
          let linkPath = String(cString: sqlite3_column_text(statement, 1))
          let linkId = sqlite3_column_type(statement, 2) == SQLITE_NULL ? nil : sqlite3_column_int64(statement, 2)
          let linkType = LinkType(rawValue: Int(sqlite3_column_int(statement, 3))) ?? .application
          shortcuts.append(RawShortcut(id: id, linkPath: linkPath, linkId: linkId, linkType: linkType))
        }
      }
      sqlite3_finalize(statement)
    }
    return shortcuts
  }

  func getAllLinkIconMetadata() -> [(id: Int64, linkId: Int64)] {
    var icons: [(id: Int64, linkId: Int64)] = []
    dbQueue.sync {
      let query = "SELECT id, link_id FROM link_icons"
      var statement: OpaquePointer?
      if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
        while sqlite3_step(statement) == SQLITE_ROW {
          let id = sqlite3_column_int64(statement, 0)
          let linkId = sqlite3_column_int64(statement, 1)
          icons.append((id: id, linkId: linkId))
        }
      }
      sqlite3_finalize(statement)
    }
    return icons
  }

  func deleteLinkIcon(id: Int64) {
    dbQueue.async {
      let query = "DELETE FROM link_icons WHERE id = ?"
      var statement: OpaquePointer?
      if sqlite3_prepare_v2(self.db, query, -1, &statement, nil) == SQLITE_OK {
        sqlite3_bind_int64(statement, 1, id)
        if sqlite3_step(statement) != SQLITE_DONE {
          Debug.print("Error deleting link icon by id")
        }
      }
      sqlite3_finalize(statement)
    }
  }

  func deleteLinkShortcut(id: Int64) {
    dbQueue.async {
      let query = "DELETE FROM link_shortcuts WHERE id = ?"
      var statement: OpaquePointer?
      if sqlite3_prepare_v2(self.db, query, -1, &statement, nil) == SQLITE_OK {
        sqlite3_bind_int64(statement, 1, id)
        if sqlite3_step(statement) != SQLITE_DONE {
          Debug.print("Error deleting link shortcut by id")
        }
      }
      sqlite3_finalize(statement)
    }
  }

  func getLinkShortcuts() -> [String: LinkShortcut] {
    var shortcuts: [String: LinkShortcut] = [:]
    dbQueue.sync {
      autoreleasepool {
        let query = """
          SELECT
            CASE WHEN ls.link_type = 3 THEN l.path ELSE ls.link_path END,
            ls.key_code,
            ls.flags,
            ls.link_type
          FROM link_shortcuts ls
          LEFT JOIN links l ON ls.link_id = l.id
          WHERE ls.key_code IS NOT NULL AND ls.flags IS NOT NULL
        """
        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
          while sqlite3_step(statement) == SQLITE_ROW {
            if let pathCStr = sqlite3_column_text(statement, 0) {
              let path = String(cString: pathCStr)
              let keyCode = CGKeyCode(sqlite3_column_int(statement, 1))
              let flags = CGEventFlags(rawValue: UInt64(sqlite3_column_int64(statement, 2)))
              let linkType = LinkType(rawValue: Int(sqlite3_column_int(statement, 3))) ?? .application
              if !path.isEmpty {
                shortcuts[path] = LinkShortcut(keyCode: keyCode, flags: flags, linkType: linkType)
              }
            }
          }
        }
        sqlite3_finalize(statement)
      }
    }
    return shortcuts
  }

  func getLinkShortcut(linkPath: String) -> LinkShortcut? {
    var shortcut: LinkShortcut?
    dbQueue.sync {
      autoreleasepool {
        var linkId: Int64?
        var linkType: LinkType = .application
        let linkQuery = "SELECT id, link_type FROM links WHERE path = ?"
        var linkStmt: OpaquePointer?
        if sqlite3_prepare_v2(db, linkQuery, -1, &linkStmt, nil) == SQLITE_OK {
          sqlite3_bind_text(linkStmt, 1, (linkPath as NSString).utf8String, -1, nil)
          if sqlite3_step(linkStmt) == SQLITE_ROW {
            linkId = sqlite3_column_int64(linkStmt, 0)
            linkType = LinkType(rawValue: Int(sqlite3_column_int(linkStmt, 1))) ?? .application
          }
        }
        sqlite3_finalize(linkStmt)
        if linkType == .web, let id = linkId {
          let query = "SELECT key_code, flags, link_type FROM link_shortcuts WHERE link_id = ? AND key_code IS NOT NULL AND flags IS NOT NULL"
          var statement: OpaquePointer?
          if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_int64(statement, 1, id)
            if sqlite3_step(statement) == SQLITE_ROW {
              let keyCode = CGKeyCode(sqlite3_column_int(statement, 0))
              let flags = CGEventFlags(rawValue: UInt64(sqlite3_column_int64(statement, 1)))
              let type = LinkType(rawValue: Int(sqlite3_column_int(statement, 2))) ?? .application
              shortcut = LinkShortcut(keyCode: keyCode, flags: flags, linkType: type)
            }
          }
          sqlite3_finalize(statement)
        }
        if shortcut == nil {
          let query = "SELECT key_code, flags, link_type FROM link_shortcuts WHERE link_path = ? AND key_code IS NOT NULL AND flags IS NOT NULL"
          var statement: OpaquePointer?
          if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, (linkPath as NSString).utf8String, -1, nil)
            if sqlite3_step(statement) == SQLITE_ROW {
              let keyCode = CGKeyCode(sqlite3_column_int(statement, 0))
              let flags = CGEventFlags(rawValue: UInt64(sqlite3_column_int64(statement, 1)))
              let type = LinkType(rawValue: Int(sqlite3_column_int(statement, 2))) ?? .application
              shortcut = LinkShortcut(keyCode: keyCode, flags: flags, linkType: type)
            }
          }
          sqlite3_finalize(statement)
        }
      }
    }
    return shortcut
  }

  func batchGetLinkShortcuts(for paths: [String], completion: @escaping ([String: LinkShortcut]) -> Void) {
    if paths.isEmpty {
      DispatchQueue.main.async {
        completion([:])
      }
      return
    }
    dbQueue.async {
      var shortcuts: [String: LinkShortcut] = [:]
      autoreleasepool {
        let placeholders = paths.map { _ in "?" }.joined(separator: ",")
        let query = """
          SELECT
            CASE WHEN ls.link_type = 3 THEN l.path ELSE ls.link_path END,
            ls.key_code,
            ls.flags,
            ls.link_type
          FROM link_shortcuts ls
          LEFT JOIN links l ON ls.link_id = l.id
          WHERE (ls.link_path IN (\(placeholders)) OR l.path IN (\(placeholders)))
          AND ls.key_code IS NOT NULL AND ls.flags IS NOT NULL
        """
        var statement: OpaquePointer?
        if sqlite3_prepare_v2(self.db, query, -1, &statement, nil) == SQLITE_OK {
          for (index, path) in paths.enumerated() {
            sqlite3_bind_text(statement, Int32(index + 1), (path as NSString).utf8String, -1, nil)
          }
          for (index, path) in paths.enumerated() {
            sqlite3_bind_text(statement, Int32(paths.count + index + 1), (path as NSString).utf8String, -1, nil)
          }
          while sqlite3_step(statement) == SQLITE_ROW {
            if let pathCStr = sqlite3_column_text(statement, 0) {
              let path = String(cString: pathCStr)
              let keyCode = CGKeyCode(sqlite3_column_int(statement, 1))
              let flags = CGEventFlags(rawValue: UInt64(sqlite3_column_int64(statement, 2)))
              let linkType = LinkType(rawValue: Int(sqlite3_column_int(statement, 3))) ?? .application
              if !path.isEmpty {
                shortcuts[path] = LinkShortcut(keyCode: keyCode, flags: flags, linkType: linkType)
              }
            }
          }
        }
        sqlite3_finalize(statement)
      }
      DispatchQueue.main.async {
        completion(shortcuts)
      }
    }
  }

  func addAppLink(path: String, panelId: Int64, orderIndex: Int, title: String? = nil, completion: ((Int64) -> Void)? = nil) {
    dbQueue.async {
      let insertQuery = "INSERT OR REPLACE INTO links (path, panel_id, order_index, link_type, title) VALUES (?, ?, ?, ?, ?)"
      var statement: OpaquePointer?
      var linkId: Int64 = 0
      if sqlite3_prepare_v2(self.db, insertQuery, -1, &statement, nil) == SQLITE_OK {
        sqlite3_bind_text(statement, 1, (path as NSString).utf8String, -1, nil)
        sqlite3_bind_int64(statement, 2, panelId)
        sqlite3_bind_int(statement, 3, Int32(orderIndex))
        sqlite3_bind_int(statement, 4, Int32(LinkType.application.rawValue))
        if let title = title {
          sqlite3_bind_text(statement, 5, (title as NSString).utf8String, -1, nil)
        } else {
          sqlite3_bind_null(statement, 5)
        }
        if sqlite3_step(statement) != SQLITE_DONE {
          Debug.print("Error inserting app link")
        }
        linkId = sqlite3_last_insert_rowid(self.db)
      }
      sqlite3_finalize(statement)
      DispatchQueue.main.async { [weak self] in
        self?.loadLinks()
        completion?(linkId)
      }
    }
  }

  func addFolderLink(path: String, panelId: Int64, orderIndex: Int, title: String? = nil, completion: ((Int64) -> Void)? = nil) {
    dbQueue.async {
      let insertQuery = "INSERT OR REPLACE INTO links (path, panel_id, order_index, link_type, title) VALUES (?, ?, ?, ?, ?)"
      var statement: OpaquePointer?
      var linkId: Int64 = 0
      if sqlite3_prepare_v2(self.db, insertQuery, -1, &statement, nil) == SQLITE_OK {
        sqlite3_bind_text(statement, 1, (path as NSString).utf8String, -1, nil)
        sqlite3_bind_int64(statement, 2, panelId)
        sqlite3_bind_int(statement, 3, Int32(orderIndex))
        sqlite3_bind_int(statement, 4, Int32(LinkType.folder.rawValue))
        if let title = title {
          sqlite3_bind_text(statement, 5, (title as NSString).utf8String, -1, nil)
        } else {
          sqlite3_bind_null(statement, 5)
        }
        if sqlite3_step(statement) != SQLITE_DONE {
          Debug.print("Error inserting folder link")
        }
        linkId = sqlite3_last_insert_rowid(self.db)
      }
      sqlite3_finalize(statement)
      DispatchQueue.main.async { [weak self] in
        self?.loadLinks()
        completion?(linkId)
      }
    }
  }

  func addFileLink(path: String, panelId: Int64, orderIndex: Int, title: String? = nil, completion: ((Int64) -> Void)? = nil) {
    dbQueue.async {
      let insertQuery = "INSERT OR REPLACE INTO links (path, panel_id, order_index, link_type, title) VALUES (?, ?, ?, ?, ?)"
      var statement: OpaquePointer?
      var linkId: Int64 = 0
      if sqlite3_prepare_v2(self.db, insertQuery, -1, &statement, nil) == SQLITE_OK {
        sqlite3_bind_text(statement, 1, (path as NSString).utf8String, -1, nil)
        sqlite3_bind_int64(statement, 2, panelId)
        sqlite3_bind_int(statement, 3, Int32(orderIndex))
        sqlite3_bind_int(statement, 4, Int32(LinkType.file.rawValue))
        if let title = title {
          sqlite3_bind_text(statement, 5, (title as NSString).utf8String, -1, nil)
        } else {
          sqlite3_bind_null(statement, 5)
        }
        if sqlite3_step(statement) != SQLITE_DONE {
          Debug.print("Error inserting file link")
        }
        linkId = sqlite3_last_insert_rowid(self.db)
      }
      sqlite3_finalize(statement)
      DispatchQueue.main.async { [weak self] in
        self?.loadLinks()
        completion?(linkId)
      }
    }
  }

  func addWebLink(path: String, panelId: Int64, orderIndex: Int, title: String, icon: Data?, useProxy: Bool = false, showInMenuBar: Bool = false, completion: ((Int64) -> Void)? = nil) {
    dbQueue.async {
      let insertQuery = "INSERT OR REPLACE INTO links (path, panel_id, order_index, link_type, title, use_proxy, show_in_menubar) VALUES (?, ?, ?, ?, ?, ?, ?)"
      var statement: OpaquePointer?
      var linkId: Int64 = 0
      if sqlite3_prepare_v2(self.db, insertQuery, -1, &statement, nil) == SQLITE_OK {
        sqlite3_bind_text(statement, 1, (path as NSString).utf8String, -1, nil)
        sqlite3_bind_int64(statement, 2, panelId)
        sqlite3_bind_int(statement, 3, Int32(orderIndex))
        sqlite3_bind_int(statement, 4, Int32(LinkType.web.rawValue))
        sqlite3_bind_text(statement, 5, (title as NSString).utf8String, -1, nil)
        sqlite3_bind_int(statement, 6, useProxy ? 1 : 0)
        sqlite3_bind_int(statement, 7, showInMenuBar ? 1 : 0)
        if sqlite3_step(statement) == SQLITE_DONE {
           linkId = sqlite3_last_insert_rowid(self.db)
        }
      }
      sqlite3_finalize(statement)
      if linkId > 0, let icon = icon {
        let iconQuery = "INSERT OR REPLACE INTO link_icons (link_id, icon) VALUES (?, ?)"
        if sqlite3_prepare_v2(self.db, iconQuery, -1, &statement, nil) == SQLITE_OK {
          sqlite3_bind_int64(statement, 1, linkId)
          _ = icon.withUnsafeBytes { (bytes: UnsafeRawBufferPointer) in
            sqlite3_bind_blob(statement, 2, bytes.baseAddress, Int32(icon.count), nil)
          }
          sqlite3_step(statement)
        }
        sqlite3_finalize(statement)
      }
      DispatchQueue.main.async { [weak self] in
        self?.loadLinks()
        completion?(linkId)
      }
    }
  }

  func updateWebLink(oldPath: String, newPath: String, title: String, icon: Data?, useProxy: Bool, showInMenuBar: Bool) {
    dbQueue.async {
      var linkId: Int64 = 0
      let idQuery = "SELECT id FROM links WHERE path = ?"
      var statement: OpaquePointer?
      if sqlite3_prepare_v2(self.db, idQuery, -1, &statement, nil) == SQLITE_OK {
        sqlite3_bind_text(statement, 1, (oldPath as NSString).utf8String, -1, nil)
        if sqlite3_step(statement) == SQLITE_ROW {
          linkId = sqlite3_column_int64(statement, 0)
        }
      }
      sqlite3_finalize(statement)
      if linkId == 0 {
        return
      }
      var hasShortcut = false
      let checkShortcutQuery = "SELECT COUNT(*) FROM link_shortcuts WHERE link_id = ?"
      var checkStmt: OpaquePointer?
      if sqlite3_prepare_v2(self.db, checkShortcutQuery, -1, &checkStmt, nil) == SQLITE_OK {
        sqlite3_bind_int64(checkStmt, 1, linkId)
        if sqlite3_step(checkStmt) == SQLITE_ROW {
          hasShortcut = sqlite3_column_int(checkStmt, 0) > 0
        }
      }
      sqlite3_finalize(checkStmt)
      let updateQuery = "UPDATE links SET path = ?, title = ?, use_proxy = ?, show_in_menubar = ? WHERE id = ?"
      if sqlite3_prepare_v2(self.db, updateQuery, -1, &statement, nil) == SQLITE_OK {
        sqlite3_bind_text(statement, 1, (newPath as NSString).utf8String, -1, nil)
        sqlite3_bind_text(statement, 2, (title as NSString).utf8String, -1, nil)
        sqlite3_bind_int(statement, 3, useProxy ? 1 : 0)
        sqlite3_bind_int(statement, 4, showInMenuBar ? 1 : 0)
        sqlite3_bind_int64(statement, 5, linkId)
        if sqlite3_step(statement) != SQLITE_DONE {
          Debug.print("Error updating web link")
        }
      }
      sqlite3_finalize(statement)
      if hasShortcut {
         let updateShortcutQuery = "UPDATE link_shortcuts SET link_path = ? WHERE link_id = ?"
         var updateStmt: OpaquePointer?
         if sqlite3_prepare_v2(self.db, updateShortcutQuery, -1, &updateStmt, nil) == SQLITE_OK {
           sqlite3_bind_text(updateStmt, 1, (newPath as NSString).utf8String, -1, nil)
           sqlite3_bind_int64(updateStmt, 2, linkId)
           sqlite3_step(updateStmt)
         }
         sqlite3_finalize(updateStmt)
      }
      if let icon = icon {
        var updated = false
        let updateIconQuery = "UPDATE link_icons SET icon = ? WHERE link_id = ?"
        var updateStmt: OpaquePointer?
        if sqlite3_prepare_v2(self.db, updateIconQuery, -1, &updateStmt, nil) == SQLITE_OK {
          _ = icon.withUnsafeBytes { (bytes: UnsafeRawBufferPointer) in
            sqlite3_bind_blob(updateStmt, 1, bytes.baseAddress, Int32(icon.count), nil)
          }
          sqlite3_bind_int64(updateStmt, 2, linkId)
          if sqlite3_step(updateStmt) == SQLITE_DONE {
            if sqlite3_changes(self.db) > 0 {
              updated = true
            }
          }
        }
        sqlite3_finalize(updateStmt)
        if !updated {
          let iconQuery = "INSERT INTO link_icons (link_id, icon) VALUES (?, ?)"
          if sqlite3_prepare_v2(self.db, iconQuery, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_int64(statement, 1, linkId)
            _ = icon.withUnsafeBytes { (bytes: UnsafeRawBufferPointer) in
              sqlite3_bind_blob(statement, 2, bytes.baseAddress, Int32(icon.count), nil)
            }
            sqlite3_step(statement)
          }
          sqlite3_finalize(statement)
        }
      } else {
        let deleteIconQuery = "DELETE FROM link_icons WHERE link_id = ?"
        if sqlite3_prepare_v2(self.db, deleteIconQuery, -1, &statement, nil) == SQLITE_OK {
          sqlite3_bind_int64(statement, 1, linkId)
          sqlite3_step(statement)
        }
        sqlite3_finalize(statement)
      }
      DispatchQueue.main.async { [weak self] in
        self?.loadLinks()
        if hasShortcut {
          NotificationCenter.default.post(name: NSNotification.Name("LinkShortcutsChanged"), object: nil)
        }
      }
    }
  }

  func updatePanelVisible(panelId: Int64, isVisible: Bool) {
    dbQueue.sync {
      let updateQuery = "UPDATE panels SET is_visible = ? WHERE id = ?"
      var statement: OpaquePointer?
      if sqlite3_prepare_v2(db, updateQuery, -1, &statement, nil) == SQLITE_OK {
        sqlite3_bind_int(statement, 1, isVisible ? 1 : 0)
        sqlite3_bind_int64(statement, 2, panelId)
        sqlite3_step(statement)
      }
      sqlite3_finalize(statement)
    }
  }

  func updateLinkVisible(linkPath: String, isVisible: Bool) {
    dbQueue.sync {
      let updateQuery = "UPDATE links SET is_visible = ? WHERE path = ?"
      var statement: OpaquePointer?
      if sqlite3_prepare_v2(db, updateQuery, -1, &statement, nil) == SQLITE_OK {
        sqlite3_bind_int(statement, 1, isVisible ? 1 : 0)
        sqlite3_bind_text(statement, 2, (linkPath as NSString).utf8String, -1, nil)
        sqlite3_step(statement)
      }
      sqlite3_finalize(statement)
    }
  }

  func removeLinkShortcut(linkPath: String, linkId: Int64? = nil) {
    dbQueue.async {
      autoreleasepool {
        let query: String
        if linkId != nil {
           query = "DELETE FROM link_shortcuts WHERE link_id = ?"
        } else {
           query = "DELETE FROM link_shortcuts WHERE link_path = ?"
        }
        var statement: OpaquePointer?
        if sqlite3_prepare_v2(self.db, query, -1, &statement, nil) == SQLITE_OK {
          if let finalLinkId = linkId {
            sqlite3_bind_int64(statement, 1, finalLinkId)
          } else {
            sqlite3_bind_text(statement, 1, (linkPath as NSString).utf8String, -1, nil)
          }
          if sqlite3_step(statement) != SQLITE_DONE {
            Debug.print("Error deleting link shortcut")
          }
        }
        sqlite3_finalize(statement)
        DispatchQueue.main.async {
          NotificationCenter.default.post(name: NSNotification.Name("LinkShortcutsChanged"), object: nil)
        }
      }
    }
  }

  func hasLinkShortcut(linkPath: String) -> Bool {
    var hasShortcut = false
    autoreleasepool {
      let query = "SELECT COUNT(*) FROM link_shortcuts WHERE link_path = ?"
      var statement: OpaquePointer?
      if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
        sqlite3_bind_text(statement, 1, (linkPath as NSString).utf8String, -1, nil)
        if sqlite3_step(statement) == SQLITE_ROW {
          hasShortcut = sqlite3_column_int(statement, 0) > 0
        }
      }
      sqlite3_finalize(statement)
    }
    return hasShortcut
  }

  func loadPanelsAsync(completion: @escaping ([PanelTable]) -> Void) {
    dbQueue.async { [weak self] in
      guard let self = self else { return }
      let query = "SELECT id, name, is_sub, parent_id, order_index, panel_width, is_visible FROM panels ORDER BY order_index"
      var statement: OpaquePointer?
      var panelList: [PanelTable] = []
      if sqlite3_prepare_v2(self.db, query, -1, &statement, nil) == SQLITE_OK {
        while sqlite3_step(statement) == SQLITE_ROW {
          let id = sqlite3_column_int64(statement, 0)
          let name = String(cString: sqlite3_column_text(statement, 1))
          let isSub = sqlite3_column_int(statement, 2) != 0
          let parentId = sqlite3_column_type(statement, 3) == SQLITE_NULL ? nil : sqlite3_column_int64(statement, 3)
          let orderIndex = Int(sqlite3_column_int(statement, 4))
          let panelWidth = sqlite3_column_type(statement, 5) == SQLITE_NULL ? nil : Double(sqlite3_column_double(statement, 5))
          let isVisible = sqlite3_column_int(statement, 6) != 0
          panelList.append(PanelTable(id: id, name: name, isSub: isSub, parentId: parentId, orderIndex: orderIndex, panelWidth: panelWidth, isVisible: isVisible))
        }
      }
      sqlite3_finalize(statement)
      DispatchQueue.main.async {
        completion(panelList)
      }
    }
  }

  func loadLinksAsync(completion: @escaping ([LinkTable]) -> Void) {
    dbQueue.async { [weak self] in
      guard let self = self else { return }
      let query = "SELECT id, path, panel_id, order_index, link_type, title, window_state, keep_alive, is_mobile_mode, show_in_menubar, is_pinned, use_proxy, zoom, is_visible FROM links ORDER BY panel_id, order_index"
      var statement: OpaquePointer?
      var linkList: [LinkTable] = []
      if sqlite3_prepare_v2(self.db, query, -1, &statement, nil) == SQLITE_OK {
        while sqlite3_step(statement) == SQLITE_ROW {
          let id = sqlite3_column_int64(statement, 0)
          let path = String(cString: sqlite3_column_text(statement, 1))
          let panelId = sqlite3_column_int64(statement, 2)
          let orderIndex = Int(sqlite3_column_int(statement, 3))
          let linkType = LinkType(rawValue: Int(sqlite3_column_int(statement, 4))) ?? .application
          let title = sqlite3_column_type(statement, 5) == SQLITE_NULL ? nil : String(cString: sqlite3_column_text(statement, 5))
          let windowState = sqlite3_column_type(statement, 6) == SQLITE_NULL ? nil : String(cString: sqlite3_column_text(statement, 6))
          let keepAlive = sqlite3_column_int(statement, 7) != 0
          let isMobileMode = sqlite3_column_int(statement, 8) != 0
          let showInMenuBar = sqlite3_column_int(statement, 9) != 0
          let isPinned = sqlite3_column_int(statement, 10) != 0
          let useProxy = sqlite3_column_int(statement, 11) != 0
          let zoom = sqlite3_column_double(statement, 12)
          let isVisible = sqlite3_column_int(statement, 13) != 0
          linkList.append(LinkTable(id: id, path: path, panelId: panelId, orderIndex: orderIndex, linkType: linkType, title: title, windowState: windowState, keepAlive: keepAlive, isMobileMode: isMobileMode, showInMenuBar: showInMenuBar, isPinned: isPinned, useProxy: useProxy, zoom: zoom, isVisible: isVisible))
        }
      }
      sqlite3_finalize(statement)
      DispatchQueue.main.async {
        completion(linkList)
      }
    }
  }

  func updatePanels(_ newPanels: [PanelTable]) {
    DispatchQueue.main.async { [weak self] in
      guard let self = self else { return }
      panels = newPanels
      objectWillChange.send()
    }
  }

  func updateLinkTitle(linkPath: String, title: String?) {
    dbQueue.async {
      let updateQuery = "UPDATE links SET title = ? WHERE path = ?"
      var statement: OpaquePointer?
      if sqlite3_prepare_v2(self.db, updateQuery, -1, &statement, nil) == SQLITE_OK {
        if let title = title {
          sqlite3_bind_text(statement, 1, (title as NSString).utf8String, -1, nil)
        } else {
          sqlite3_bind_null(statement, 1)
        }
        sqlite3_bind_text(statement, 2, (linkPath as NSString).utf8String, -1, nil)
        if sqlite3_step(statement) != SQLITE_DONE {
          Debug.print("Error updating link title")
        }
      }
      sqlite3_finalize(statement)
      DispatchQueue.main.async { [weak self] in
        self?.loadLinks()
      }
    }
  }

  func updateLinkWindowState(linkPath: String, state: String?) {
    dbQueue.async {
      let updateQuery = "UPDATE links SET window_state = ? WHERE path = ?"
      var statement: OpaquePointer?
      if sqlite3_prepare_v2(self.db, updateQuery, -1, &statement, nil) == SQLITE_OK {
        if let state = state {
          sqlite3_bind_text(statement, 1, (state as NSString).utf8String, -1, nil)
        } else {
          sqlite3_bind_null(statement, 1)
        }
        sqlite3_bind_text(statement, 2, (linkPath as NSString).utf8String, -1, nil)
        if sqlite3_step(statement) != SQLITE_DONE {
          Debug.print("Error updating link window state")
        }
      }
      sqlite3_finalize(statement)
      DispatchQueue.main.async { [weak self] in
        self?.loadLinks()
      }
    }
  }

  func updateLinkKeepAlive(linkPath: String, keepAlive: Bool) {
    dbQueue.async {
      let updateQuery = "UPDATE links SET keep_alive = ? WHERE path = ?"
      var statement: OpaquePointer?
      if sqlite3_prepare_v2(self.db, updateQuery, -1, &statement, nil) == SQLITE_OK {
        sqlite3_bind_int(statement, 1, keepAlive ? 1 : 0)
        sqlite3_bind_text(statement, 2, (linkPath as NSString).utf8String, -1, nil)
        if sqlite3_step(statement) != SQLITE_DONE {
          Debug.print("Error updating link keep_alive")
        }
      }
      sqlite3_finalize(statement)
      DispatchQueue.main.async { [weak self] in
        self?.loadLinks()
      }
    }
  }

  func updateLinkMobileMode(linkPath: String, isMobileMode: Bool) {
    dbQueue.async {
      let updateQuery = "UPDATE links SET is_mobile_mode = ? WHERE path = ?"
      var statement: OpaquePointer?
      if sqlite3_prepare_v2(self.db, updateQuery, -1, &statement, nil) == SQLITE_OK {
        sqlite3_bind_int(statement, 1, isMobileMode ? 1 : 0)
        sqlite3_bind_text(statement, 2, (linkPath as NSString).utf8String, -1, nil)
        if sqlite3_step(statement) != SQLITE_DONE {
          Debug.print("Error updating link is_mobile_mode")
        }
      }
      sqlite3_finalize(statement)
      DispatchQueue.main.async { [weak self] in
        self?.loadLinks()
      }
    }
  }

  func updateLinkShowInMenuBar(linkPath: String, showInMenuBar: Bool) {
    dbQueue.async {
      let updateQuery = "UPDATE links SET show_in_menubar = ? WHERE path = ?"
      var statement: OpaquePointer?
      if sqlite3_prepare_v2(self.db, updateQuery, -1, &statement, nil) == SQLITE_OK {
        sqlite3_bind_int(statement, 1, showInMenuBar ? 1 : 0)
        sqlite3_bind_text(statement, 2, (linkPath as NSString).utf8String, -1, nil)
        if sqlite3_step(statement) != SQLITE_DONE {
          Debug.print("Error updating link show_in_menubar")
        }
      }
      sqlite3_finalize(statement)
      DispatchQueue.main.async { [weak self] in
        self?.loadLinks()
      }
    }
  }

  func updateLinkPinned(linkPath: String, isPinned: Bool) {
    dbQueue.async {
      let updateQuery = "UPDATE links SET is_pinned = ? WHERE path = ?"
      var statement: OpaquePointer?
      if sqlite3_prepare_v2(self.db, updateQuery, -1, &statement, nil) == SQLITE_OK {
        sqlite3_bind_int(statement, 1, isPinned ? 1 : 0)
        sqlite3_bind_text(statement, 2, (linkPath as NSString).utf8String, -1, nil)
        if sqlite3_step(statement) != SQLITE_DONE {
          Debug.print("Error updating link is_pinned")
        }
      }
      sqlite3_finalize(statement)
      DispatchQueue.main.async { [weak self] in
        self?.loadLinks()
      }
    }
  }

  func updateLinkZoom(path: String, zoom: Double) {
    dbQueue.async {
      let updateQuery = "UPDATE links SET zoom = ? WHERE path = ?"
      var statement: OpaquePointer?
      if sqlite3_prepare_v2(self.db, updateQuery, -1, &statement, nil) == SQLITE_OK {
        sqlite3_bind_double(statement, 1, zoom)
        sqlite3_bind_text(statement, 2, (path as NSString).utf8String, -1, nil)
        sqlite3_step(statement)
      }
      sqlite3_finalize(statement)
    }
  }

  func updateLinks(_ newLinks: [LinkTable]) {
    DispatchQueue.main.async { [weak self] in
      guard let self = self else { return }
      links = newLinks
      objectWillChange.send()
    }
  }

  func getFocusExcludedApps() -> [FocusExcludeApp] {
    var apps: [FocusExcludeApp] = []
    dbQueue.sync {
      let query = "SELECT title, bundle_id FROM focus_exclude WHERE is_enabled = 1 ORDER BY created_at DESC"
      var statement: OpaquePointer?
      if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
        while sqlite3_step(statement) == SQLITE_ROW {
          let title = String(cString: sqlite3_column_text(statement, 0))
          let bundleId = String(cString: sqlite3_column_text(statement, 1))
          apps.append(FocusExcludeApp(title: title, bundleId: bundleId, enabled: true))
        }
      }
      sqlite3_finalize(statement)
    }
    return apps
  }

  func getAllFocusExcludedApps() -> [FocusExcludeApp] {
    var apps: [FocusExcludeApp] = []
    dbQueue.sync {
      let query = "SELECT title, bundle_id, is_enabled FROM focus_exclude ORDER BY created_at ASC"
      var statement: OpaquePointer?
      if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
        while sqlite3_step(statement) == SQLITE_ROW {
          let title = String(cString: sqlite3_column_text(statement, 0))
          let bundleId = String(cString: sqlite3_column_text(statement, 1))
          let enabled = sqlite3_column_int(statement, 2) != 0
          apps.append(FocusExcludeApp(title: title, bundleId: bundleId, enabled: enabled))
        }
      }
      sqlite3_finalize(statement)
    }
    return apps
  }

  func addFocusExcludedApp(title: String, bundleId: String) {
    dbQueue.async {
      let checkQuery = "SELECT id FROM focus_exclude WHERE bundle_id = ?"
      var statement: OpaquePointer?
      var exists = false
      if sqlite3_prepare_v2(self.db, checkQuery, -1, &statement, nil) == SQLITE_OK {
        sqlite3_bind_text(statement, 1, (bundleId as NSString).utf8String, -1, nil)
        if sqlite3_step(statement) == SQLITE_ROW {
          exists = true
        }
      }
      sqlite3_finalize(statement)
      if exists {
        let updateQuery = "UPDATE focus_exclude SET is_enabled = 1, title = ? WHERE bundle_id = ?"
        if sqlite3_prepare_v2(self.db, updateQuery, -1, &statement, nil) == SQLITE_OK {
          sqlite3_bind_text(statement, 1, (title as NSString).utf8String, -1, nil)
          sqlite3_bind_text(statement, 2, (bundleId as NSString).utf8String, -1, nil)
          if sqlite3_step(statement) != SQLITE_DONE {
            Debug.print("Error enabling focus excluded app")
          }
        }
        sqlite3_finalize(statement)
      } else {
        let insertQuery = "INSERT INTO focus_exclude (title, bundle_id, is_enabled) VALUES (?, ?, 1)"
        if sqlite3_prepare_v2(self.db, insertQuery, -1, &statement, nil) == SQLITE_OK {
          sqlite3_bind_text(statement, 1, (title as NSString).utf8String, -1, nil)
          sqlite3_bind_text(statement, 2, (bundleId as NSString).utf8String, -1, nil)
          if sqlite3_step(statement) != SQLITE_DONE {
            Debug.print("Error inserting focus excluded app")
          }
        }
        sqlite3_finalize(statement)
      }
    }
  }

  func removeFocusExcludedApp(bundleId: String) {
    dbQueue.async {
      let updateQuery = "UPDATE focus_exclude SET is_enabled = 0 WHERE bundle_id = ?"
      var statement: OpaquePointer?
      if sqlite3_prepare_v2(self.db, updateQuery, -1, &statement, nil) == SQLITE_OK {
        sqlite3_bind_text(statement, 1, (bundleId as NSString).utf8String, -1, nil)
        if sqlite3_step(statement) != SQLITE_DONE {
          Debug.print("Error disabling focus excluded app")
        }
      }
      sqlite3_finalize(statement)
    }
  }

  func getSwiftMouseExcludedApps() -> [SwiftMouseExcludeApp] {
    var apps: [SwiftMouseExcludeApp] = []
    dbQueue.sync {
      let query = "SELECT title, bundle_id FROM swift_mouse_exclude WHERE is_enabled = 1 ORDER BY created_at DESC"
      var statement: OpaquePointer?
      if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
        while sqlite3_step(statement) == SQLITE_ROW {
          let title = String(cString: sqlite3_column_text(statement, 0))
          let bundleId = String(cString: sqlite3_column_text(statement, 1))
          apps.append(SwiftMouseExcludeApp(title: title, bundleId: bundleId, enabled: true))
        }
      }
      sqlite3_finalize(statement)
    }
    return apps
  }

  func getAllSwiftMouseExcludedApps() -> [SwiftMouseExcludeApp] {
    var apps: [SwiftMouseExcludeApp] = []
    dbQueue.sync {
      let query = "SELECT title, bundle_id, is_enabled FROM swift_mouse_exclude ORDER BY created_at ASC"
      var statement: OpaquePointer?
      if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
        while sqlite3_step(statement) == SQLITE_ROW {
          let title = String(cString: sqlite3_column_text(statement, 0))
          let bundleId = String(cString: sqlite3_column_text(statement, 1))
          let enabled = sqlite3_column_int(statement, 2) != 0
          apps.append(SwiftMouseExcludeApp(title: title, bundleId: bundleId, enabled: enabled))
        }
      }
      sqlite3_finalize(statement)
    }
    return apps
  }

  func addSwiftMouseExcludedApp(title: String, bundleId: String, enabled: Bool = true) {
    dbQueue.async {
      let checkQuery = "SELECT id FROM swift_mouse_exclude WHERE bundle_id = ?"
      var statement: OpaquePointer?
      var exists = false
      if sqlite3_prepare_v2(self.db, checkQuery, -1, &statement, nil) == SQLITE_OK {
        sqlite3_bind_text(statement, 1, (bundleId as NSString).utf8String, -1, nil)
        if sqlite3_step(statement) == SQLITE_ROW {
          exists = true
        }
      }
      sqlite3_finalize(statement)
      if exists {
        let updateQuery = "UPDATE swift_mouse_exclude SET is_enabled = ?, title = ? WHERE bundle_id = ?"
        if sqlite3_prepare_v2(self.db, updateQuery, -1, &statement, nil) == SQLITE_OK {
          sqlite3_bind_int(statement, 1, enabled ? 1 : 0)
          sqlite3_bind_text(statement, 2, (title as NSString).utf8String, -1, nil)
          sqlite3_bind_text(statement, 3, (bundleId as NSString).utf8String, -1, nil)
          if sqlite3_step(statement) != SQLITE_DONE {
            Debug.print("Error enabling swift mouse excluded app")
          }
        }
        sqlite3_finalize(statement)
      } else {
        let insertQuery = "INSERT INTO swift_mouse_exclude (title, bundle_id, is_enabled) VALUES (?, ?, ?)"
        if sqlite3_prepare_v2(self.db, insertQuery, -1, &statement, nil) == SQLITE_OK {
          sqlite3_bind_text(statement, 1, (title as NSString).utf8String, -1, nil)
          sqlite3_bind_text(statement, 2, (bundleId as NSString).utf8String, -1, nil)
          sqlite3_bind_int(statement, 3, enabled ? 1 : 0)
          if sqlite3_step(statement) != SQLITE_DONE {
            Debug.print("Error inserting swift mouse excluded app")
          }
        }
        sqlite3_finalize(statement)
      }
    }
  }

  func removeSwiftMouseExcludedApp(bundleId: String) {
    dbQueue.async {
      let updateQuery = "UPDATE swift_mouse_exclude SET is_enabled = 0 WHERE bundle_id = ?"
      var statement: OpaquePointer?
      if sqlite3_prepare_v2(self.db, updateQuery, -1, &statement, nil) == SQLITE_OK {
        sqlite3_bind_text(statement, 1, (bundleId as NSString).utf8String, -1, nil)
        if sqlite3_step(statement) != SQLITE_DONE {
          Debug.print("Error disabling swift mouse excluded app")
        }
      }
      sqlite3_finalize(statement)
    }
  }

  func tableExists(tableName: String) -> Bool {
    var exists = false
    dbQueue.sync {
      let query = "SELECT name FROM sqlite_master WHERE type='table' AND name=?"
      var statement: OpaquePointer?
      if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
        sqlite3_bind_text(statement, 1, (tableName as NSString).utf8String, -1, nil)
        if sqlite3_step(statement) == SQLITE_ROW {
          exists = true
        }
      }
      sqlite3_finalize(statement)
    }
    return exists
  }

  func isFocusExcludeTableEmpty() -> Bool {
    var isEmpty = true
    dbQueue.sync {
      let query = "SELECT COUNT(*) FROM focus_exclude"
      var statement: OpaquePointer?
      if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
        if sqlite3_step(statement) == SQLITE_ROW {
          let count = sqlite3_column_int(statement, 0)
          isEmpty = count == 0
        }
      }
      sqlite3_finalize(statement)
    }
    return isEmpty
  }

  func getLinkIcon(id: Int64) -> Data? {
    var data: Data?
    dbQueue.sync {
      let query = "SELECT icon FROM link_icons WHERE link_id = ?"
      var statement: OpaquePointer?
      if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
        sqlite3_bind_int64(statement, 1, id)
        if sqlite3_step(statement) == SQLITE_ROW {
           if let blob = sqlite3_column_blob(statement, 0) {
             let bytes = sqlite3_column_bytes(statement, 0)
             data = Data(bytes: blob, count: Int(bytes))
           }
        }
      }
      sqlite3_finalize(statement)
    }
    return data
  }

  func loadSwiftMouseLinks() -> [Int64: String] {
    var gestures: [Int64: String] = [:]
    dbQueue.sync {
      let query = "SELECT link_id, gesture FROM swift_mouse_links"
      var statement: OpaquePointer?
      if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
        while sqlite3_step(statement) == SQLITE_ROW {
          let linkId = sqlite3_column_int64(statement, 0)
          if let gesture = sqlite3_column_text(statement, 1) {
            gestures[linkId] = String(cString: gesture)
          }
        }
      }
      sqlite3_finalize(statement)
    }
    return gestures
  }

  func saveSwiftMouseLink(linkId: Int64, gesture: String) {
    dbQueue.async {
      let checkQuery = "SELECT id FROM swift_mouse_links WHERE link_id = ?"
      var statement: OpaquePointer?
      var exists = false
      if sqlite3_prepare_v2(self.db, checkQuery, -1, &statement, nil) == SQLITE_OK {
        sqlite3_bind_int64(statement, 1, linkId)
        if sqlite3_step(statement) == SQLITE_ROW {
          exists = true
        }
      }
      sqlite3_finalize(statement)
      if exists {
        let updateQuery = "UPDATE swift_mouse_links SET gesture = ? WHERE link_id = ?"
        if sqlite3_prepare_v2(self.db, updateQuery, -1, &statement, nil) == SQLITE_OK {
          sqlite3_bind_text(statement, 1, (gesture as NSString).utf8String, -1, nil)
          sqlite3_bind_int64(statement, 2, linkId)
          if sqlite3_step(statement) != SQLITE_DONE {
            Debug.print("Error updating swift mouse link")
          }
        }
        sqlite3_finalize(statement)
      } else {
        let insertQuery = "INSERT INTO swift_mouse_links (link_id, gesture) VALUES (?, ?)"
        if sqlite3_prepare_v2(self.db, insertQuery, -1, &statement, nil) == SQLITE_OK {
          sqlite3_bind_int64(statement, 1, linkId)
          sqlite3_bind_text(statement, 2, (gesture as NSString).utf8String, -1, nil)
          if sqlite3_step(statement) != SQLITE_DONE {
            Debug.print("Error inserting swift mouse link")
          }
        }
        sqlite3_finalize(statement)
      }
    }
  }

  func deleteSwiftMouseLink(linkId: Int64) {
    dbQueue.async {
      let deleteQuery = "DELETE FROM swift_mouse_links WHERE link_id = ?"
      var statement: OpaquePointer?
      if sqlite3_prepare_v2(self.db, deleteQuery, -1, &statement, nil) == SQLITE_OK {
        sqlite3_bind_int64(statement, 1, linkId)
        if sqlite3_step(statement) != SQLITE_DONE {
          Debug.print("Error deleting swift mouse link")
        }
      }
      sqlite3_finalize(statement)
    }
  }

  func loadSwiftKeyboardLinks() -> [Int64: String] {
    var shortcuts: [Int64: String] = [:]
    dbQueue.sync {
      let query = "SELECT link_id, shortcut FROM swift_keyboard_links"
      var statement: OpaquePointer?
      if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
        while sqlite3_step(statement) == SQLITE_ROW {
          let linkId = sqlite3_column_int64(statement, 0)
          if let shortcut = sqlite3_column_text(statement, 1) {
            shortcuts[linkId] = String(cString: shortcut)
          }
        }
      }
      sqlite3_finalize(statement)
    }
    return shortcuts
  }

  func saveSwiftKeyboardLink(linkId: Int64, shortcut: String) {
    dbQueue.async {
      let checkQuery = "SELECT id FROM swift_keyboard_links WHERE link_id = ?"
      var statement: OpaquePointer?
      var exists = false
      if sqlite3_prepare_v2(self.db, checkQuery, -1, &statement, nil) == SQLITE_OK {
        sqlite3_bind_int64(statement, 1, linkId)
        if sqlite3_step(statement) == SQLITE_ROW {
          exists = true
        }
      }
      sqlite3_finalize(statement)
      if exists {
        let updateQuery = "UPDATE swift_keyboard_links SET shortcut = ? WHERE link_id = ?"
        if sqlite3_prepare_v2(self.db, updateQuery, -1, &statement, nil) == SQLITE_OK {
          sqlite3_bind_text(statement, 1, (shortcut as NSString).utf8String, -1, nil)
          sqlite3_bind_int64(statement, 2, linkId)
          if sqlite3_step(statement) != SQLITE_DONE {
            Debug.print("Error updating swift keyboard link")
          }
        }
        sqlite3_finalize(statement)
      } else {
        let insertQuery = "INSERT INTO swift_keyboard_links (link_id, shortcut) VALUES (?, ?)"
        if sqlite3_prepare_v2(self.db, insertQuery, -1, &statement, nil) == SQLITE_OK {
          sqlite3_bind_int64(statement, 1, linkId)
          sqlite3_bind_text(statement, 2, (shortcut as NSString).utf8String, -1, nil)
          if sqlite3_step(statement) != SQLITE_DONE {
            Debug.print("Error inserting swift keyboard link")
          }
        }
        sqlite3_finalize(statement)
      }
    }
  }

  func deleteSwiftKeyboardLink(linkId: Int64) {
    dbQueue.async {
      let deleteQuery = "DELETE FROM swift_keyboard_links WHERE link_id = ?"
      var statement: OpaquePointer?
      if sqlite3_prepare_v2(self.db, deleteQuery, -1, &statement, nil) == SQLITE_OK {
        sqlite3_bind_int64(statement, 1, linkId)
        if sqlite3_step(statement) != SQLITE_DONE {
          Debug.print("Error deleting swift keyboard link")
        }
      }
      sqlite3_finalize(statement)
    }
  }

  private func _loadSpaces() {
    let query = "SELECT id, name, order_index, focus, system_ui, version, screens, windows FROM spaces ORDER BY order_index ASC"
    var statement: OpaquePointer?
    var spaceList: [SpaceTable] = []
    if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
      while sqlite3_step(statement) == SQLITE_ROW {
        let id = sqlite3_column_int64(statement, 0)
        let name = String(cString: sqlite3_column_text(statement, 1))
        let orderIndex = Int(sqlite3_column_int(statement, 2))
        let focusRaw = Int(sqlite3_column_int(statement, 3))
        let focus = SpaceFocusMode(rawValue: focusRaw) ?? .keep
        let systemUIRaw = Int(sqlite3_column_int(statement, 4))
        let systemUI = SystemUI(rawValue: systemUIRaw) ?? .showAll
        let version = Int(sqlite3_column_int(statement, 5))
        let screensJson = String(cString: sqlite3_column_text(statement, 6))
        let windowsJson = String(cString: sqlite3_column_text(statement, 7))
        if version < SpaceTable.currentVersion {
          spaceList.append(SpaceTable(id: id, name: name, orderIndex: orderIndex, focus: focus, systemUI: systemUI, version: version, screens: [], windows: []))
        } else if let screensData = screensJson.data(using: .utf8),
           let windowsData = windowsJson.data(using: .utf8),
           let screens = try? JSONDecoder().decode([ScreenInfo].self, from: screensData),
           let windows = try? JSONDecoder().decode([WindowSnapshot].self, from: windowsData) {
          spaceList.append(SpaceTable(id: id, name: name, orderIndex: orderIndex, focus: focus, systemUI: systemUI, version: version, screens: screens, windows: windows))
        }
      }
    }
    sqlite3_finalize(statement)
    DispatchQueue.main.async { [weak self] in
      guard let self = self else { return }
      self.spaces = spaceList
      NotificationCenter.default.post(name: NSNotification.Name("SpaceDataChanged"), object: nil)
    }
  }

  func loadSpaces() {
    dbQueue.sync {
      _loadSpaces()
    }
  }

  func saveSpace(_ space: SpaceTable) {
    dbQueue.sync {
      let insertQuery = "INSERT INTO spaces (name, order_index, focus, system_ui, version, screens, windows) VALUES (?, ?, ?, ?, ?, ?, ?)"
      let updateQuery = "UPDATE spaces SET name = ?, order_index = ?, focus = ?, system_ui = ?, version = ?, screens = ?, windows = ? WHERE id = ?"
      var statement: OpaquePointer?
      if let screensData = try? JSONEncoder().encode(space.screens),
         let windowsData = try? JSONEncoder().encode(space.windows),
         let screensJson = String(data: screensData, encoding: .utf8),
         let windowsJson = String(data: windowsData, encoding: .utf8) {
        let isNew = space.id == 0
        let query = isNew ? insertQuery : updateQuery
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
          sqlite3_bind_text(statement, 1, (space.name as NSString).utf8String, -1, nil)
          sqlite3_bind_int(statement, 2, Int32(space.orderIndex))
          sqlite3_bind_int(statement, 3, Int32(space.focus.rawValue))
          sqlite3_bind_int(statement, 4, Int32(space.systemUI.rawValue))
          sqlite3_bind_int(statement, 5, Int32(space.version))
          sqlite3_bind_text(statement, 6, (screensJson as NSString).utf8String, -1, nil)
          sqlite3_bind_text(statement, 7, (windowsJson as NSString).utf8String, -1, nil)
          if !isNew {
            sqlite3_bind_int64(statement, 8, space.id)
          }
          if sqlite3_step(statement) != SQLITE_DONE {
            Debug.print("Error saving space")
          }
        }
        sqlite3_finalize(statement)
      }
    }
    loadSpaces()
  }

  func reorderSpaces(_ spaces: [SpaceTable]) {
    dbQueue.async {
      let updateQuery = "UPDATE spaces SET order_index = ? WHERE id = ?"
      var statement: OpaquePointer?
      if sqlite3_prepare_v2(self.db, updateQuery, -1, &statement, nil) == SQLITE_OK {
        for (index, space) in spaces.enumerated() {
          sqlite3_bind_int(statement, 1, Int32(index))
          sqlite3_bind_int64(statement, 2, space.id)
          if sqlite3_step(statement) != SQLITE_DONE {
            Debug.print("Error reordering space")
          }
          sqlite3_reset(statement)
        }
      }
      sqlite3_finalize(statement)
      self._loadSpaces()
    }
  }

  func deleteSpace(id: Int64) {
    dbQueue.sync {
      let deleteQuery = "DELETE FROM spaces WHERE id = ?"
      var statement: OpaquePointer?
      if sqlite3_prepare_v2(db, deleteQuery, -1, &statement, nil) == SQLITE_OK {
        sqlite3_bind_int64(statement, 1, id)
        if sqlite3_step(statement) != SQLITE_DONE {
          Debug.print("Error deleting space")
        }
      }
      sqlite3_finalize(statement)
    }
    loadSpaces()
  }
}
