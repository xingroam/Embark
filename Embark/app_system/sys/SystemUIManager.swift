import Foundation
import AppKit
import OSAKit

class SystemUIManager {
  static let s = SystemUIManager()
  var onChange = false
  private var menuBar: Bool = false
  private var dock: Bool = false

  private init() {}

  func Restore(){
    _ = try? SystemUIManager.s.setMenuBarAutohideSync(on: menuBar)
    _ = try? SystemUIManager.s.setDockAutohideSync(on: dock)
  }

  @MainActor
  func getCurrentSystemUI() async -> SystemUI {
    let menuBarHidden = await getMenuBarAutohideStatus()
    let dockHidden = await getDockAutohideStatus()
    if menuBarHidden && dockHidden {
      return .hideBoth
    } else if menuBarHidden {
      return .hideMenuBar
    } else if dockHidden {
      return .hideDock
    } else {
      return .showAll
    }
  }

  func Apply(_ systemUI: SystemUI, boot: Bool = false) {
    Task {
      onChange = true
      if boot {
        menuBar = await getMenuBarAutohideStatus()
        dock = await getDockAutohideStatus()
      }
      let currentMenuBar = await getMenuBarAutohideStatus()
      let currentDock = await getDockAutohideStatus()
      var targetMenuBar = false
      var targetDock = false
      switch systemUI {
      case .showAll:
        targetMenuBar = false
        targetDock = false
      case .hideMenuBar:
        targetMenuBar = true
        targetDock = false
      case .hideDock:
        targetMenuBar = false
        targetDock = true
      case .hideBoth:
        targetMenuBar = true
        targetDock = true
      }
      if currentMenuBar != targetMenuBar {
        try? await setMenuBarAutohide(on: targetMenuBar)
      }
      if currentDock != targetDock {
        try? await setDockAutohide(on: targetDock)
      }
      try? await Task.sleep(nanoseconds: 1000_000_000)
      onChange = false
    }
  }

  @MainActor
  public func getDockAutohideStatus() async -> Bool {
    do {
      let result = try await "tell application \"System Events\" to get the autohide of the dock preferences".runAppleScript()
      return (result as NSString).boolValue
    } catch {
      return false
    }
  }

  @MainActor
  public func setDockAutohide(on: Bool) async throws {
    let command = on ? "tell application \"System Events\" to set the autohide of the dock preferences to true" : "tell application \"System Events\" to set the autohide of the dock preferences to false"
    _ = try await command.runAppleScript()
  }

  @MainActor
  public func getMenuBarAutohideStatus() async -> Bool {
    do {
      let result = try await """
                  tell application "System Events"
                    tell dock preferences to get autohide menu bar
                  end tell
                """.runAppleScript()
      return (result as NSString).boolValue
    } catch {
      return false
    }
  }

  @MainActor
  public func setMenuBarAutohide(on: Bool) async throws {
    let command = on ? """
                tell application "System Events"
                  tell dock preferences to set autohide menu bar to true
                end tell
              """ : """
                tell application "System Events"
                  tell dock preferences to set autohide menu bar to false
                end tell
              """
    _ = try await command.runAppleScript()
  }

  public func setMenuBarAutohideSync(on: Bool) throws {
    let command = on ? """
                tell application "System Events"
                  tell dock preferences to set autohide menu bar to true
                end tell
              """ : """
                tell application "System Events"
                  tell dock preferences to set autohide menu bar to false
                end tell
              """
    let script = NSAppleScript(source: command)
    var error: NSDictionary?
    script?.executeAndReturnError(&error)
    if let error = error {
      throw NSError(domain: "AppleScriptError", code: 0, userInfo: error as? [String: Any])
    }
  }

  public func setDockAutohideSync(on: Bool) throws {
    let command = on ? "tell application \"System Events\" to set the autohide of the dock preferences to true" : "tell application \"System Events\" to set the autohide of the dock preferences to false"
    let script = NSAppleScript(source: command)
    var error: NSDictionary?
    script?.executeAndReturnError(&error)
    if let error = error {
      throw NSError(domain: "AppleScriptError", code: 0, userInfo: error as? [String: Any])
    }
  }

  public func getDockAutohideStatusSync() -> Bool {
    let script = NSAppleScript(source: "tell application \"System Events\" to get the autohide of the dock preferences")
    var error: NSDictionary?
    if let result = script?.executeAndReturnError(&error) {
      return result.booleanValue
    }
    return false
  }

  public func getMenuBarAutohideStatusSync() -> Bool {
    let command = """
      tell application "System Events"
        tell dock preferences to get autohide menu bar
      end tell
    """
    let script = NSAppleScript(source: command)
    var error: NSDictionary?
    if let result = script?.executeAndReturnError(&error) {
      return result.booleanValue
    }
    return false
  }

  public func getCurrentSystemUISync() -> SystemUI {
    let menuBarHidden = getMenuBarAutohideStatusSync()
    let dockHidden = getDockAutohideStatusSync()
    if menuBarHidden && dockHidden {
      return .hideBoth
    } else if menuBarHidden {
      return .hideMenuBar
    } else if dockHidden {
      return .hideDock
    } else {
      return .showAll
    }
  }
}
