import SwiftUI
import AppKit

class StatusBarView: NSObject, NSMenuDelegate {
  private var statusItem: NSStatusItem?
  private weak var donationItem: NSMenuItem?
  private let donationMenuMinWidth: CGFloat = 220

  override init() {
    super.init()
    setupStatusBar()
    setupLicenseObserver()
  }

  deinit {
    NotificationCenter.default.removeObserver(self)
  }

  private func updateMenu() {
    statusItem?.menu = nil
    let menu = NSMenu()
    menu.delegate = self
    menu.autoenablesItems = false
    if LauncherConfig.launcher {
      let launcherItem = NSMenuItem(title: String(format: LanguageManager.s.localizedString("system.info.open"), FeatureType.launcher.title), action: #selector(openLauncher), keyEquivalent: "l")
      launcherItem.image = NSImage(systemSymbolName: FeatureType.launcher.icon, accessibilityDescription: nil)
      menu.addItem(launcherItem)
    }
    let focusItem = NSMenuItem(title: String(format: LanguageManager.s.localizedString("system.info.enable"), FeatureType.focus.title), action: #selector(openFocus), keyEquivalent: "f")
    if FocusConfig.focus {
      focusItem.image = NSImage(systemSymbolName: "checkmark", accessibilityDescription: nil)
    } else {
      focusItem.image = NSImage(systemSymbolName: FeatureType.focus.icon, accessibilityDescription: nil)
    }
    menu.addItem(focusItem)
    if SpaceConfig.space {
      menu.addItem(NSMenuItem.separator())
      let spaceMenuItem = NSMenuItem(title: FeatureType.space.title, action: nil, keyEquivalent: "")
      spaceMenuItem.image = NSImage(systemSymbolName: FeatureType.space.icon, accessibilityDescription: nil)
      let spaceSubmenu = NSMenu()
      let displaySpaces = SpaceManager.s.spaces
      if displaySpaces.isEmpty {
        let emptyItem = NSMenuItem(title: NSLocalizedString("space.settings.snapshots.empty", comment: ""), action: nil, keyEquivalent: "")
        emptyItem.isEnabled = false
        spaceSubmenu.addItem(emptyItem)
      } else {
        for space in displaySpaces {
          let snapshotItem = NSMenuItem(title: space.name, action: #selector(restoreSnapshot(_:)), keyEquivalent: "")
          snapshotItem.representedObject = space
          snapshotItem.target = self
          spaceSubmenu.addItem(snapshotItem)
        }
      }
      spaceMenuItem.submenu = spaceSubmenu
      menu.addItem(spaceMenuItem)
    }
    menu.addItem(NSMenuItem.separator())
    menu.addItem(createTitleMenuItem(title: LanguageManager.s.localizedString("system.info.features"), color: NSColor.controlAccentColor))
    let launcherSettingItem = NSMenuItem(title: FeatureType.launcher.title, action: #selector(showLauncherSettingsWin), keyEquivalent: "")
    launcherSettingItem.image = NSImage(systemSymbolName: FeatureType.launcher.icon, accessibilityDescription: nil)
    menu.addItem(launcherSettingItem)
    let swiftSettingItem = NSMenuItem(title: FeatureType.swift.title, action: #selector(showSwiftSettingsWin), keyEquivalent: "")
    swiftSettingItem.image = NSImage(systemSymbolName: FeatureType.swift.icon, accessibilityDescription: nil)
    menu.addItem(swiftSettingItem)
    let magnetSettingItem = NSMenuItem(title: FeatureType.magnet.title, action: #selector(showMagnetSettingsWin), keyEquivalent: "")
    magnetSettingItem.image = NSImage(systemSymbolName: FeatureType.magnet.icon, accessibilityDescription: nil)
    menu.addItem(magnetSettingItem)
    let spaceSettingItem = NSMenuItem(title: FeatureType.space.title, action: #selector(showSpaceSettingsWin), keyEquivalent: "")
    spaceSettingItem.image = NSImage(systemSymbolName: FeatureType.space.icon, accessibilityDescription: nil)
    menu.addItem(spaceSettingItem)
    let focusSettingItem = NSMenuItem(title: FeatureType.focus.title, action: #selector(showFocusSettingsWin), keyEquivalent: "")
    focusSettingItem.image = NSImage(systemSymbolName: FeatureType.focus.icon, accessibilityDescription: nil)
    menu.addItem(focusSettingItem)
    let slideSettingItem = NSMenuItem(title: FeatureType.slide.title, action: #selector(showSlideSettingsWin), keyEquivalent: "")
    slideSettingItem.image = NSImage(systemSymbolName: FeatureType.slide.icon, accessibilityDescription: nil)
    menu.addItem(slideSettingItem)
    let switcherSettingItem = NSMenuItem(title: FeatureType.switcher.title, action: #selector(showSwitcherSettingsWin), keyEquivalent: "")
    switcherSettingItem.image = NSImage(systemSymbolName: FeatureType.switcher.icon, accessibilityDescription: nil)
    menu.addItem(switcherSettingItem)
    menu.addItem(NSMenuItem.separator())
    let appSettingItem = NSMenuItem(title: LanguageManager.s.localizedString("embark.statusbar.menu.app_settings"), action: #selector(showAppSettingWin), keyEquivalent: "")
    appSettingItem.image = NSImage(systemSymbolName: "gearshape", accessibilityDescription: nil)
    menu.addItem(appSettingItem)
    let updateItem = NSMenuItem(title: LanguageManager.s.localizedString("embark.statusbar.menu.check_update"), action: #selector(checkUpdate), keyEquivalent: "")
    updateItem.image = NSImage(systemSymbolName: "arrow.2.circlepath", accessibilityDescription: nil)
    menu.addItem(updateItem)
    let aboutItem = NSMenuItem(title: LanguageManager.s.localizedString("embark.statusbar.menu.about"), action: #selector(showAboutPage), keyEquivalent: "")
    aboutItem.image = NSImage(systemSymbolName: "info.circle", accessibilityDescription: nil)
    menu.addItem(aboutItem)
    menu.addItem(NSMenuItem.separator())
    let donationItem = donationMenuItem()
    self.donationItem = donationItem
    menu.addItem(donationItem)
    menu.addItem(NSMenuItem.separator())
    let quitItem = NSMenuItem(title: LanguageManager.s.localizedString("embark.statusbar.menu.quit"), action: #selector(quit), keyEquivalent: "q")
    quitItem.image = NSImage(systemSymbolName: "xmark", accessibilityDescription: nil)
    menu.addItem(quitItem)
    menu.items.forEach { item in
      item.target = self
    }
    statusItem?.menu = menu
  }

  private func setupLicenseObserver() {
    NotificationCenter.default.addObserver(self, selector: #selector(statusChanged), name: NSNotification.Name("LauncherConfigChanged"), object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(statusChanged), name: NSNotification.Name("SpaceConfigChanged"), object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(statusChanged), name: NSNotification.Name("FocusConfigChanged"), object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(statusChanged), name: NSNotification.Name("SpaceDataChanged"), object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(themeChanged), name: NSNotification.Name("AppThemeChanged"), object: nil)
  }

  private func disableMenuItem(_ item: NSMenuItem) {
    item.action = nil
    item.keyEquivalent = ""
    item.isEnabled = false
  }

  private func createTitleMenuItem(title: String, color: NSColor? = nil, opacity: CGFloat = 1.0) -> NSMenuItem {
    let titleItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")
    titleItem.isEnabled = false
    let titleView = NSView(frame: NSRect(x: 0, y: 0, width: 80, height: 18))
    let titleLabel = NSTextField(frame: NSRect(x: 16, y: -2, width: 80, height: 18))
    titleLabel.stringValue = title
    titleLabel.font = NSFont.systemFont(ofSize: 11, weight: .medium)
    if color != nil {
      titleLabel.textColor = color
    }
    titleLabel.isEditable = false
    titleLabel.isBordered = false
    titleLabel.backgroundColor = NSColor.clear
    titleView.addSubview(titleLabel)
    titleView.alphaValue = opacity
    titleItem.view = titleView
    disableMenuItem(titleItem)
    return titleItem
  }

  private func donationMenuItem() -> NSMenuItem {
    let item = NSMenuItem()
    item.isEnabled = true
    let content = DonationView()
      .padding(.horizontal, 8)
      .padding(.vertical, 4)
      .frame(maxWidth: .infinity, alignment: .center)
    let hostingView = NSHostingView(rootView: content)
    hostingView.layoutSubtreeIfNeeded()
    let fittingHeight = ceil(hostingView.fittingSize.height)
    hostingView.frame = NSRect(x: 0, y: 0, width: donationMenuMinWidth, height: max(38, fittingHeight))
    item.view = hostingView
    return item
  }

  func menuWillOpen(_ menu: NSMenu) {
    guard let hostingView = donationItem?.view else { return }
    let targetWidth = max(donationMenuMinWidth, ceil(menu.size.width))
    if abs(hostingView.frame.width - targetWidth) < 0.5 {
      return
    }
    hostingView.frame = NSRect(x: 0, y: 0, width: targetWidth, height: hostingView.frame.height)
    hostingView.layoutSubtreeIfNeeded()
  }

  private func setupStatusBar() {
    statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    if let image = NSImage(named: "StatusBarIcon")?.resized(to: NSSize(width: 18, height: 18)) {
      statusItem?.button?.image = image
      statusItem?.button?.image?.isTemplate = true
    }
    statusItem?.button?.appearance = nil
    if let button = statusItem?.button {
      if button.window != nil {
        DispatchQueue.main.async {
          button.frame = NSRect(x: 0, y: 0, width: button.frame.width, height: NSStatusBar.system.thickness)
        }
      }
    }
    updateMenu()
  }

  @objc private func statusChanged() {
    DispatchQueue.main.async { [weak self] in
      self?.updateMenu()
    }
  }

  @objc private func themeChanged() {
    statusItem?.button?.appearance = nil
  }

  @objc private func openLauncher() {
    LauncherWin.s.ShowOrHide(mode: .launcher)
  }

  @objc private func openFocus() {
    FocusConfig.focus.toggle()
    NotificationCenter.default.post(name: NSNotification.Name("FocusConfigChanged"), object: nil)
    updateMenu()
  }

  @objc private func restoreSnapshot(_ sender: NSMenuItem) {
    guard let space = sender.representedObject as? SpaceTable else { return }
    SpaceManager.s.restoreSpace(space)
  }

  @objc private func showLauncherSettingsWin() {
    LauncherSettingWin.s.Show()
  }

  @objc private func showSwiftSettingsWin() {
    SwiftSettingWin.s.Show()
  }

  @objc private func showMagnetSettingsWin() {
    MagnetSettingWin.s.Show()
  }

  @objc private func showSpaceSettingsWin() {
    SpaceSettingWin.s.Show()
  }

  @objc private func showFocusSettingsWin() {
    FocusSettingWin.s.Show()
  }

  @objc private func showSlideSettingsWin() {
    SlideSettingWin.s.Show()
  }

  @objc private func showSwitcherSettingsWin() {
    SwitcherSettingWin.s.Show()
  }

  @objc private func showAppSettingWin() {
    AppSettingWin.s.Show()
  }

  @objc private func checkUpdate() {
    UpdateManager.s.checkUpdateDialog()
  }

  @objc private func showAboutPage() {
    AppSettingWin.s.ShowAboutPage()
  }

  @objc private func quit() {
    AppManager.Terminate()
  }
}
