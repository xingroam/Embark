import SwiftUI

@main
struct App: SwiftUI.App {
  @NSApplicationDelegateAdaptor(AppDel.self) var del

  var body: some Scene {
    Settings {
      EmptyView()
    }
  }
}

class AppDel: NSObject, NSApplicationDelegate {
  func applicationDidFinishLaunching(_ n: Notification) {
    Embark.s.Boot()
  }

  func applicationWillTerminate(_ notification: Notification) {
    Embark.s.End()
  }

  func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
    return Embark.s.AppClick(flag: flag)
  }

  func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return false
  }

  func applicationDidBecomeActive(_ notification: Notification) {
  }

  func applicationDidResignActive(_ notification: Notification) {
  }
}
