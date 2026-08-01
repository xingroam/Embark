import SwiftUI
import WebKit
import Network

class WebViewModel: ObservableObject {
  weak var webView: WKWebView?
  @Published var canGoBack = false
  @Published var canGoForward = false
  @Published var currentURL: URL?
  @Published var currentTitle: String?
  @Published var zoomLevel: Double = 1.0

  func goBack() { webView?.goBack() }
  func goForward() { webView?.goForward() }
  func reload() { webView?.reload() }

  func loadURL(_ urlString: String) {
    var validUrlString = urlString
    if !urlString.lowercased().hasPrefix("http://") && !urlString.lowercased().hasPrefix("https://") {
      validUrlString = "https://" + urlString
    }
    if let url = URL(string: validUrlString) {
      webView?.load(URLRequest(url: url))
    }
  }

  func setZoom(_ level: Double) {
    zoomLevel = level
    webView?.pageZoom = CGFloat(level)
  }

  func resetZoom() {
    setZoom(1.0)
  }

  func clearCurrentWebsiteData() {
    guard let webView = webView, let host = webView.url?.host else { return }
    let dataStore = WKWebsiteDataStore.default()
    let dataTypes = WKWebsiteDataStore.allWebsiteDataTypes()
    dataStore.fetchDataRecords(ofTypes: dataTypes) { records in
      let recordsToDelete = records.filter { record in
        return record.displayName.contains(host)
      }
      if !recordsToDelete.isEmpty {
        dataStore.removeData(ofTypes: dataTypes, for: recordsToDelete) {
          DispatchQueue.main.async {
            webView.reload()
          }
        }
      }
    }
  }

  func clearAllWebsiteData() {
    let dataStore = WKWebsiteDataStore.default()
    let dataTypes = WKWebsiteDataStore.allWebsiteDataTypes()
    let dateFrom = Date(timeIntervalSince1970: 0)
    dataStore.removeData(ofTypes: dataTypes, modifiedSince: dateFrom) {
      DispatchQueue.main.async {
        self.webView?.reload()
      }
    }
  }
}
