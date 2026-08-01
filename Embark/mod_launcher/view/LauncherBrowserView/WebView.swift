import SwiftUI
import WebKit
import Network

struct WebView: NSViewRepresentable {
  let urlString: String
  let isMobileMode: Bool
  @ObservedObject var viewModel: WebViewModel
  let useProxy: Bool
  let zoom: Double

  func makeCoordinator() -> Coordinator {
    Coordinator(self)
  }

  func makeNSView(context: Context) -> WKWebView {
    let config = WKWebViewConfiguration()
    config.preferences.setValue(true, forKey: "developerExtrasEnabled")
    if #available(macOS 14.0, *), useProxy {
      let dataStore = WKWebsiteDataStore.default()
      let host = LauncherConfig.launcherProxyHost
      let port = LauncherConfig.launcherProxyPort
      let type = LauncherConfig.launcherProxyType
      if let portInt = UInt16(port), !host.isEmpty {
        let endpoint = NWEndpoint.hostPort(host: NWEndpoint.Host(host), port: NWEndpoint.Port(integerLiteral: portInt))
        let proxyConfig: ProxyConfiguration
        if type == 0 {
          proxyConfig = ProxyConfiguration(socksv5Proxy: endpoint)
        } else {
          proxyConfig = ProxyConfiguration(httpCONNECTProxy: endpoint)
        }
        dataStore.proxyConfigurations = [proxyConfig]
        config.websiteDataStore = dataStore
      }
    }
    let webView = WKWebView(frame: .zero, configuration: config)
    updateUserAgent(webView)
    webView.navigationDelegate = context.coordinator
    webView.uiDelegate = context.coordinator
    viewModel.webView = webView
    return webView
  }

  func updateNSView(_ nsView: WKWebView, context: Context) {
    nsView.pageZoom = CGFloat(zoom)
    if context.coordinator.lastIsMobileMode != isMobileMode {
      context.coordinator.lastIsMobileMode = isMobileMode
      updateUserAgent(nsView)
      nsView.reload()
    }
    if viewModel.webView != nsView {
        viewModel.webView = nsView
    }
    if !context.coordinator.isLoaded {
      if let url = URL(string: urlString) {
        context.coordinator.isLoaded = true
        let request = URLRequest(url: url)
        nsView.load(request)
      }
    }
  }

  private func updateUserAgent(_ webView: WKWebView) {
    if isMobileMode {
      webView.customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 17_2 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.2 Mobile/15E148 Safari/604.1"
    } else {
      webView.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.2 Safari/605.1.15"
    }
  }

  static func dismantleNSView(_ nsView: WKWebView, coordinator: Coordinator) {
    nsView.stopLoading()
    nsView.load(URLRequest(url: URL(string: "about:blank")!))
    nsView.navigationDelegate = nil
    nsView.uiDelegate = nil
  }

  class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate, WKDownloadDelegate {
    var parent: WebView
    var isLoaded = false
    var lastIsMobileMode: Bool?

    init(_ parent: WebView) {
      self.parent = parent
      self.lastIsMobileMode = parent.isMobileMode
    }

    // MARK: - WKNavigationDelegate

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
      if navigationAction.targetFrame == nil {
        if let url = navigationAction.request.url {
          let useProxy = self.parent.useProxy
          let title = url.absoluteString
          DispatchQueue.main.async {
            LauncherBrowserWin.s.ToggleOrOpen(url: url.absoluteString, title: title, useProxy: useProxy, isSecondaryWindow: true)
          }
        }
        decisionHandler(.cancel)
        return
      }
      decisionHandler(.allow)
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
      if navigationResponse.canShowMIMEType {
        decisionHandler(.allow)
      } else {
        decisionHandler(.download)
      }
    }

    func webView(_ webView: WKWebView, navigationResponse: WKNavigationResponse, didBecome download: WKDownload) {
      download.delegate = self
    }

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
      updateState(webView)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
      updateState(webView)
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
      updateState(webView)
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
      updateState(webView)
    }

    // MARK: - WKUIDelegate

    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
      if navigationAction.targetFrame == nil {
        if let url = navigationAction.request.url {
          let useProxy = self.parent.useProxy
          let title = url.absoluteString
          DispatchQueue.main.async {
            LauncherBrowserWin.s.ToggleOrOpen(url: url.absoluteString, title: title, useProxy: useProxy, isSecondaryWindow: true)
          }
        }
      }
      return nil
    }

    // MARK: - WKDownloadDelegate

    func download(_ download: WKDownload, decideDestinationUsing response: URLResponse, suggestedFilename: String, completionHandler: @escaping (URL?) -> Void) {
      let savePanel = NSSavePanel()
      savePanel.nameFieldStringValue = suggestedFilename
      savePanel.canCreateDirectories = true
      savePanel.isExtensionHidden = false
      savePanel.begin { result in
        if result == .OK {
          completionHandler(savePanel.url)
        } else {
          completionHandler(nil)
        }
      }
    }

    func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
      if challenge.protectionSpace.authenticationMethod == "NSURLAuthenticationMethodHTTPProxy" || challenge.protectionSpace.authenticationMethod == "NSURLAuthenticationMethodSOCKSProxy" {
        let host = challenge.protectionSpace.host
        let port = challenge.protectionSpace.port
        if host == LauncherConfig.launcherProxyHost && port == Int(LauncherConfig.launcherProxyPort) {
          let user = LauncherConfig.launcherProxyUser
          let password = LauncherConfig.launcherProxyPassword
          if !user.isEmpty {
            let credential = URLCredential(user: user, password: password, persistence: .forSession)
            completionHandler(.useCredential, credential)
            return
          }
        }
      }
      completionHandler(.performDefaultHandling, nil)
    }

    private func updateState(_ webView: WKWebView) {
      DispatchQueue.main.async {
        self.parent.viewModel.canGoBack = webView.canGoBack
        self.parent.viewModel.canGoForward = webView.canGoForward
        self.parent.viewModel.currentURL = webView.url
        if let title = webView.title, !title.isEmpty {
          self.parent.viewModel.currentTitle = title
        }
        self.parent.viewModel.zoomLevel = Double(webView.pageZoom)
      }
    }
  }
}
