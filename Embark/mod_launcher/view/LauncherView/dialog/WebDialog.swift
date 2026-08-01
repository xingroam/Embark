import SwiftUI

struct WebDialog: View {
  let panelId: Int64
  let editingLink: LinkData?
  let editMode: Bool
  @Binding var isPresented: Bool
  var onComplete: ((String) -> Void)? = nil
  @State private var title: String = ""
  @State private var url: String = ""
  @State private var iconData: Data? = nil
  @State private var isHoveringIcon = false
  @State private var useProxy: Bool = false
  @State private var showInMenuBar: Bool = false
  @State private var showProxySettings = false
  @State private var webList: [WebItem] = []
  @EnvironmentObject private var dm: DataManager
  private let fz: CGFloat = 12

  init(panelId: Int64, isPresented: Binding<Bool>, editingLink: LinkData? = nil, editMode: Bool = false, onComplete: ((String) -> Void)? = nil) {
    self.panelId = panelId
    self._isPresented = isPresented
    self.editingLink = editingLink
    self.editMode = editMode
    self.onComplete = onComplete
    if let link = editingLink {
      _title = State(initialValue: link.title ?? link.name)
      _url = State(initialValue: link.path)
      _iconData = State(initialValue: link.iconData)
      _useProxy = State(initialValue: link.useProxy)
      _showInMenuBar = State(initialValue: link.showInMenuBar)
    }
  }

  var body: some View {
    VStack(spacing: 20) {
      VStack(spacing: 0) {
        Text(editingLink == nil ? NSLocalizedString("launcher.dialog.add.title", comment: "") : NSLocalizedString("launcher.dialog.setting.title", comment: ""))
          .font(.title2)
          .fontWeight(.semibold)
      }
      HStack(alignment: .top, spacing: 10) {
        if editingLink != nil {
          ZStack {
            if let data = iconData, let nsImage = NSImage(data: data) {
              Image(nsImage: nsImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 60, height: 60)
            } else {
              Image(systemName: "globe")
                .font(.system(size: 40))
                .foregroundColor(.gray.opacity(0.5))
            }
            if isHoveringIcon {
              ZStack {
                RoundedRectangle(cornerRadius: 12)
                  .fill(Color.black.opacity(0.3))
                Image(systemName: "pencil")
                  .foregroundColor(.white)
                  .font(.title2)
              }
            }
          }
          .frame(width: 60, height: 60)
          .onHover { hovering in
            isHoveringIcon = hovering
          }
          .onTapGesture {
            selectIcon()
          }
        }
        VStack(alignment: .leading, spacing: 10) {
          HStack(spacing: 5) {
            TextField(NSLocalizedString("launcher.add.web.dialog.title_placeholder", comment: ""), text: $title)
              .textFieldStyle(RoundedBorderTextFieldStyle())
            if !webList.isEmpty {
              Menu {
                ForEach(webList, id: \.title) { item in
                  Button(item.title) {
                    title = item.title
                    url = item.url
                  }
                }
              } label: {
                Image(systemName: "chevron.down.circle")
                  .foregroundColor(.primary)
              }
              .menuStyle(BorderlessButtonMenuStyle())
              .menuIndicator(.hidden)
              .fixedSize()
            }
          }
          TextField(NSLocalizedString("launcher.add.web.dialog.url_placeholder", comment: ""), text: $url)
            .textFieldStyle(RoundedBorderTextFieldStyle())
          if !editMode  {
            HStack {
              Text(NSLocalizedString("launcher.add.web.show_in_menubar", comment: ""))
              Spacer()
              Toggle("", isOn: $showInMenuBar)
                .sectionToggle()
            }
          }
          HStack {
            Text(NSLocalizedString("launcher.add.web.use_proxy", comment: ""))
            Spacer()
            Toggle("", isOn: $useProxy)
              .sectionToggle()
          }
        }
      }
      .padding(.horizontal, 10)
      HStack(spacing: 10) {
        Button(NSLocalizedString("launcher.add.web.set_proxy", comment: "")) {
          showProxySettings = true
        }
        .buttonStyle(.bordered)
        Spacer()
        Button(NSLocalizedString("system.message.cancel", comment: "")) {
          isPresented = false
        }
        .buttonStyle(.bordered)
        if !title.isEmpty && !url.isEmpty {
          Button(NSLocalizedString("system.message.confirm", comment: "")) {
            confirm()
          }
          .buttonStyle(.borderedProminent)
        } else {
          Button(NSLocalizedString("system.message.confirm", comment: "")) {
            confirm()
          }
          .buttonStyle(.bordered)
          .disabled(true)
        }
      }
    }
    .padding(20)
    .frame(width: 400)
    .background(BlurredBackground(material: .underWindowBackground, blendingMode: .behindWindow, blur: 1.0))
    .sheet(isPresented: $showProxySettings) {
      ProxySettingsView(isPresented: $showProxySettings)
    }
    .onAppear {
      dm.setDialogShowing(true)
      WebManager.GetWebList { result in
        if case .success(let list) = result {
          self.webList = list
        }
      }
    }
    .onDisappear {
      dm.setDialogShowing(false)
    }
  }

  private func selectIcon() {
    Dialog.ImagePicker(allowedTypes: [.image]) { url in
      guard let url = url else { return }
      if let data = try? Data(contentsOf: url) {
        self.iconData = data
      }
    }
  }

  private func confirm() {
    let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
    let trimmedUrl = url.trimmingCharacters(in: .whitespacesAndNewlines)
    if !trimmedTitle.isEmpty && !trimmedUrl.isEmpty {
      var finalUrl = trimmedUrl
      if !finalUrl.lowercased().hasPrefix("http://") && !finalUrl.lowercased().hasPrefix("https://") {
        finalUrl = "https://" + finalUrl
      }
      let currentIconData = iconData
      let currentUseProxy = useProxy
      let currentShowInMenuBar = showInMenuBar
      let currentEditingLink = editingLink
      let currentPanelId = panelId
      let currentOnComplete = onComplete
      isPresented = false
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
        if let editingLink = currentEditingLink {
          let message = "\(trimmedTitle) " + NSLocalizedString("launcher.add.web.updating", comment: "")
          LoadingAlert.s.Show(message)
          let urlChanged = finalUrl != editingLink.path
          let iconChanged = currentIconData != editingLink.iconData
          let shouldFetchIcon = urlChanged && !iconChanged
          DataManager.s.editWebLink(oldPath: editingLink.path, newPath: finalUrl, title: trimmedTitle, iconData: currentIconData, useProxy: currentUseProxy, showInMenuBar: currentShowInMenuBar, fetchIcon: shouldFetchIcon) {
            LoadingAlert.s.Close {
              currentOnComplete?(finalUrl)
            }
          }
        } else {
          let message = "\(trimmedTitle) " + NSLocalizedString("launcher.add.web.adding", comment: "")
          LoadingAlert.s.Show(message)
          if let iconData = currentIconData {
            DataManager.s.addWebLink(path: finalUrl, panelId: currentPanelId, title: trimmedTitle, iconData: iconData, useProxy: currentUseProxy, showInMenuBar: currentShowInMenuBar) {
              LoadingAlert.s.Close {
                currentOnComplete?(finalUrl)
              }
            }
          } else {
            DataManager.s.addWebLink(path: finalUrl, panelId: currentPanelId, title: trimmedTitle, useProxy: currentUseProxy, showInMenuBar: currentShowInMenuBar) {
              LoadingAlert.s.Close {
                currentOnComplete?(finalUrl)
              }
            }
          }
        }
      }
    }
  }
}
