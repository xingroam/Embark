import SwiftUI
import WebKit
import Network

struct LauncherBrowserView: View {
  let urlString: String
  let title: String
  let icon: NSImage?
  let initialKeepAlive: Bool
  let initialIsMobileMode: Bool
  let initialShowInMenuBar: Bool
  let initialIsPinned: Bool
  let inheritedUseProxy: Bool?
  let isSecondaryWindow: Bool
  let onPin: (Bool) -> Void
  let onKeepAlive: (Bool) -> Void
  let onMobileMode: (Bool) -> Void
  let onShowInMenuBar: (Bool) -> Void
  let onMinimize: () -> Void
  let onClose: () -> Void
  @EnvironmentObject private var tm: LauncherThemeManager
  @EnvironmentObject private var dm: DataManager
  @State private var isPinned = false
  @State private var isKeepAlive = false
  @State private var isMobileMode = false
  @State private var isShowInMenuBar = false
  @State private var showMoreMenu = false
  @State private var showEditWebLinkDialog = false
  @State private var currentKey: String
  @StateObject private var webViewModel = WebViewModel()
  private let fz: CGFloat = 12

  init(urlString: String, title: String, icon: NSImage?, initialKeepAlive: Bool, initialIsMobileMode: Bool, initialShowInMenuBar: Bool, initialIsPinned: Bool, inheritedUseProxy: Bool? = nil, isSecondaryWindow: Bool = false, onPin: @escaping (Bool) -> Void, onKeepAlive: @escaping (Bool) -> Void, onMobileMode: @escaping (Bool) -> Void, onShowInMenuBar: @escaping (Bool) -> Void, onMinimize: @escaping () -> Void, onClose: @escaping () -> Void) {
    self.urlString = urlString
    self.title = title
    self.icon = icon
    self.initialKeepAlive = initialKeepAlive
    self.initialIsMobileMode = initialIsMobileMode
    self.initialShowInMenuBar = initialShowInMenuBar
    self.initialIsPinned = initialIsPinned
    self.inheritedUseProxy = inheritedUseProxy
    self.isSecondaryWindow = isSecondaryWindow
    self.onPin = onPin
    self.onKeepAlive = onKeepAlive
    self.onMobileMode = onMobileMode
    self.onShowInMenuBar = onShowInMenuBar
    self.onMinimize = onMinimize
    self.onClose = onClose
    _currentKey = State(initialValue: urlString)
  }

  var body: some View {
    GeometryReader { geometry in
      VStack(spacing: 0) {
        toolbarView(showTitleAndIcon: geometry.size.width >= LauncherInfo.browserMinWidthForTitle)
        WebView(urlString: currentKey, isMobileMode: isMobileMode, viewModel: webViewModel, useProxy: dm.linkData[currentKey]?.useProxy ?? inheritedUseProxy ?? false, zoom: webViewModel.zoomLevel)
      }
    }
    .background(tm.currentTheme.backgroundColor.opacity(tm.currentTheme.backgroundColorOpacity))
    .background(tm.currentTheme.backgroundBlur > 0 ? SwiftBlurBackground(opacity: tm.currentTheme.backgroundBlur) : nil)
    .cornerRadius(20)
    .overlay(
      ZStack(alignment: .bottomTrailing) {
        Path { path in
          path.move(to: CGPoint(x: 4, y: 16))
          path.addLine(to: CGPoint(x: 16, y: 4))
          path.move(to: CGPoint(x: 8, y: 16))
          path.addLine(to: CGPoint(x: 16, y: 8))
          path.move(to: CGPoint(x: 12, y: 16))
          path.addLine(to: CGPoint(x: 16, y: 12))
        }
        .stroke(Color.secondary.opacity(0.5), lineWidth: 1)
        .frame(width: 22, height: 22)
        ResizeHandle()
      }
      .frame(width: 20, height: 20)
      .background(Color.black.opacity(0.01))
      .padding(3), alignment: .bottomTrailing
    )
    .sheet(isPresented: $showEditWebLinkDialog) {
      if let link = DataManager.s.linkData[currentKey] {
        WebDialog(panelId: link.panelId, isPresented: $showEditWebLinkDialog, editingLink: link, editMode: true, onComplete: { newUrl in
          self.currentKey = newUrl
          self.webViewModel.loadURL(newUrl)
        })
      }
    }
    .onChange(of: webViewModel.currentTitle) { newTitle in
      if let newTitle = newTitle, !newTitle.isEmpty {
        NSApp.keyWindow?.title = newTitle
      }
    }
  }

  @ViewBuilder
  func toolbarView(showTitleAndIcon: Bool) -> some View {
    ZStack {
      if showTitleAndIcon {
        HStack(spacing: 8) {
          if let icon = dm.linkData[currentKey]?.icon ?? icon {
            Image(nsImage: icon)
              .resizable()
              .aspectRatio(contentMode: .fit)
              .frame(width: 20, height: 20)
          } else {
            Image(systemName: LinkType.web.iconName)
              .resizable()
              .aspectRatio(contentMode: .fit)
              .frame(width: 16, height: 16)
              .foregroundColor(tm.currentTheme.panelTextColor)
          }
          Text(truncatedTitle(dm.linkData[currentKey]?.title ?? webViewModel.currentTitle ?? title))
            .font(.system(size: fz + 2, weight: .medium))
            .foregroundColor(tm.currentTheme.panelTextColor)
        }
        .allowsHitTesting(false)
      }
      HStack {
        HStack(spacing: 5) {
          if isPinned {
            BrowserToolbarButton(systemName: "xmark", pressedColor: Color.red, theme: tm) { onClose() }
            BrowserToolbarButton(systemName: "minus", pressedColor: Color.orange, theme: tm) {
              onMinimize()
            }
          }
          BrowserToolbarButton(systemName: "chevron.left", theme: tm) { webViewModel.goBack() }
            .disabled(!webViewModel.canGoBack)
          BrowserToolbarButton(systemName: "chevron.right", theme: tm) { webViewModel.goForward() }
            .disabled(!webViewModel.canGoForward)
          BrowserToolbarButton(systemName: "arrow.clockwise", theme: tm) { webViewModel.reload() }
        }
        .padding(.leading, 10)
        Spacer()
        if !isSecondaryWindow {
          HStack(spacing: 5) {
            BrowserToolbarButton(systemName: "pin", isActive: isPinned, theme: tm) {
              isPinned.toggle()
              onPin(isPinned)
            }
            .tooltip(NSLocalizedString("launcher.browser.pin.tooltip", comment: ""), coordinateSpaceName: "BrowserWindow", getWindowFrame: { NSApp.keyWindow?.frame })
          BrowserToolbarButton(systemName: "infinity", isActive: isKeepAlive, iconColor: nil, theme: tm) {
            isKeepAlive.toggle()
            onKeepAlive(isKeepAlive)
          }
          .tooltip(NSLocalizedString("launcher.browser.keepalive.tooltip", comment: ""), coordinateSpaceName: "BrowserWindow", getWindowFrame: { NSApp.keyWindow?.frame })
          BrowserToolbarButton(systemName: "menubar.arrow.up.rectangle", isActive: isShowInMenuBar, iconColor: nil, theme: tm) {
            isShowInMenuBar.toggle()
            onShowInMenuBar(isShowInMenuBar)
          }
          .tooltip(NSLocalizedString("launcher.browser.menubar.tooltip", comment: ""), coordinateSpaceName: "BrowserWindow", getWindowFrame: { NSApp.keyWindow?.frame })
          BrowserToolbarButton(systemName: "iphone", isActive: isMobileMode, iconColor: nil, theme: tm) {
            isMobileMode.toggle()
            onMobileMode(isMobileMode)
          }
          .tooltip(NSLocalizedString("launcher.browser.mobilemode.tooltip", comment: ""), coordinateSpaceName: "BrowserWindow", getWindowFrame: { NSApp.keyWindow?.frame })
          Button(action: {
            showMoreMenu.toggle()
          }) {
              Image(systemName: "ellipsis")
                .font(.system(size: fz + 2))
                .frame(width: 16, height: 16)
                .modifier(BrowserIconStyleModifier(theme: tm, isActive: showMoreMenu, isPressed: false))
            }
            .buttonStyle(.plain)
            .popover(isPresented: $showMoreMenu, arrowEdge: .bottom) {
              VStack(alignment: .leading, spacing: 5) {
                VStack(alignment: .leading, spacing: 6) {
                  HStack {
                    Text(NSLocalizedString("launcher.browser.zoom", comment: ""))
                    .font(.caption)
                    .foregroundColor(.secondary)
                  Spacer()
                  Button(action: {
                    webViewModel.resetZoom()
                    dm.updateLinkZoom(path: currentKey, zoom: 1.0)
                  }) {
                    Image(systemName: "arrow.counterclockwise")
                      .font(.system(size: fz))
                      .foregroundColor(tm.currentTheme.panelTextColor)
                  }
                  .buttonStyle(.plain)
                }
                HStack {
                  Text("A").font(.system(size: fz - 2)).foregroundColor(tm.currentTheme.panelTextColor)
                  Slider(value: Binding(
                    get: { webViewModel.zoomLevel },
                    set: {
                      webViewModel.setZoom($0)
                      dm.updateLinkZoom(path: currentKey, zoom: $0)
                    }
                  ), in: 0.5...3.0)
                  Text("A").font(.system(size: fz + 2)).foregroundColor(tm.currentTheme.panelTextColor)
                }
              }
              Divider()
              BrowserMenuButton(
                text: NSLocalizedString("launcher.link.context.settings", comment: ""),
                action: {
                  showMoreMenu = false
                  showEditWebLinkDialog = true
                },
                theme: tm
              )
              BrowserMenuButton(
                text: NSLocalizedString("launcher.browser.set_default", comment: ""),
                action: {
                  showMoreMenu = false
                  if let current = webViewModel.currentURL?.absoluteString, current != currentKey {
                    let currentTitle = dm.linkData[currentKey]?.title ?? title
                    let currentIcon = dm.linkData[currentKey]?.icon ?? icon
                    let iconData = currentIcon?.tiffRepresentation
                    let useProxy = dm.linkData[currentKey]?.useProxy ?? false
                    let showInMenuBar = dm.linkData[currentKey]?.showInMenuBar ?? false
                    DataManager.s.editWebLink(oldPath: currentKey, newPath: current, title: currentTitle, iconData: iconData, useProxy: useProxy, showInMenuBar: showInMenuBar, fetchIcon: true) {
                      self.currentKey = current
                    }
                  }
                },
                theme: tm
              )
              BrowserMenuButton(
                text: NSLocalizedString("launcher.browser.copy_url", comment: ""),
                action: {
                  showMoreMenu = false
                  if let current = webViewModel.currentURL?.absoluteString {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(current, forType: .string)
                    Toast.bottomCenter(message: NSLocalizedString("launcher.browser.copied", comment: ""))
                  }
                },
                theme: tm
              )
              Divider()
              BrowserMenuButton(
                text: NSLocalizedString("launcher.browser.clear_data", comment: ""),
                action: {
                  showMoreMenu = false
                  webViewModel.clearCurrentWebsiteData()
                },
                theme: tm
              )
              BrowserMenuButton(
                text: NSLocalizedString("launcher.browser.clear_all_data", comment: ""),
                action: {
                  showMoreMenu = false
                  webViewModel.clearAllWebsiteData()
                },
                theme: tm
              )
            }
            .padding(12)
            .frame(width: 240)
          }
        }
        .padding(.trailing, 10)
        }
      }
    }
    .frame(height: 42)
    .background(DraggableArea())
    .contentShape(Rectangle())
    .coordinateSpace(name: "BrowserWindow")
    .onAppear {
      isKeepAlive = initialKeepAlive
      isMobileMode = initialIsMobileMode
      isShowInMenuBar = initialShowInMenuBar
      isPinned = initialIsPinned
      if let zoom = dm.linkData[currentKey]?.zoom {
        webViewModel.setZoom(zoom)
      }
    }
  }

  private func truncatedTitle(_ text: String, maxLength: Int = 30) -> String {
    guard text.count > maxLength else { return text }
    let halfLength = (maxLength - 3) / 2
    let start = text.prefix(halfLength)
    let end = text.suffix(halfLength)
    return "\(start)...\(end)"
  }
}
