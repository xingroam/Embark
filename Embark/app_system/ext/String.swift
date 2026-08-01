import Foundation
import CryptoKit

extension String {
  var isReallyEmpty: Bool {
    return self.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
  }

  func md5Hash() -> String {
    let data = self.data(using: .utf8) ?? Data()
    let hash = Insecure.MD5.hash(data: data)
    return hash.map { String(format: "%02hhx", $0) }.joined()
  }

  func runAppleScript() async throws -> String {
    let script = NSAppleScript(source: self)
    var error: NSDictionary?
    let result = script?.executeAndReturnError(&error)
    if let error = error {
      throw NSError(domain: "AppleScriptError", code: 0, userInfo: error as? [String: Any])
    }
    return result?.stringValue ?? ""
  }
}
