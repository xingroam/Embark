import Foundation
import Security
import AppKit

class CertificateManager {
  static let s = CertificateManager()

  private init() {}

  func checkCertificateExpiration() {
    guard !SystemInfo.isDebug else { return }
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
      guard let self = self else { return }
      if let expirationDate = getCertificateExpirationFromAppSignature() {
        let calendar = Calendar.current
        let now = Date()
        let oneMonthFromNow = calendar.date(byAdding: .month, value: 1, to: now) ?? now
        if expirationDate <= oneMonthFromNow {
          showExpirationWarning(expirationDate: expirationDate)
        }
      } else if let expirationDate = getCertificateExpirationDate() {
        let calendar = Calendar.current
        let now = Date()
        let oneMonthFromNow = calendar.date(byAdding: .month, value: 1, to: now) ?? now
        if expirationDate <= oneMonthFromNow {
          showExpirationWarning(expirationDate: expirationDate)
        }
      }
    }
  }

  private func getCertificateExpirationFromAppSignature() -> Date? {
    guard let signatureInfo = getAppSignatureInfo() else { return nil }
    let lines = signatureInfo.components(separatedBy: .newlines)
    for line in lines {
      if line.contains("Authority=") {
        return getCertificateExpirationFromAuthority(line)
      }
    }
    return nil
  }

  private func getCertificateExpirationDate() -> Date? {
    let task = Process()
    task.launchPath = "/usr/bin/security"
    task.arguments = ["find-identity", "-v", "-p", "codesigning"]
    let pipe = Pipe()
    task.standardOutput = pipe
    task.standardError = pipe
    do {
      try task.run()
      task.waitUntilExit()
      let data = pipe.fileHandleForReading.readDataToEndOfFile()
      let output = String(data: data, encoding: .utf8) ?? ""
      return parseCertificateInfo(output)
    } catch {
      return nil
    }
  }

  private func getCertificateExpirationFromAuthority(_ authorityLine: String) -> Date? {
    let components = authorityLine.components(separatedBy: "=")
    if components.count >= 2 {
      let certificateName = components[1].trimmingCharacters(in: .whitespaces)
      return getCertificateExpirationByName(certificateName)
    }
    return nil
  }

  private func getCertificateExpirationByName(_ certificateName: String) -> Date? {
    let task = Process()
    task.launchPath = "/usr/bin/security"
    task.arguments = ["find-certificate", "-c", certificateName, "-p"]
    let pipe = Pipe()
    task.standardOutput = pipe
    task.standardError = pipe
    do {
      try task.run()
      task.waitUntilExit()
      let data = pipe.fileHandleForReading.readDataToEndOfFile()
      let output = String(data: data, encoding: .utf8) ?? ""
      return parseCertificateDate(output)
    } catch {
      return nil
    }
  }

  private func getAppSignatureInfo() -> String? {
    let bundlePath = Bundle.main.bundlePath
    let task = Process()
    task.launchPath = "/usr/bin/codesign"
    task.arguments = ["-dv", bundlePath]
    let pipe = Pipe()
    task.standardOutput = pipe
    task.standardError = pipe
    do {
      try task.run()
      task.waitUntilExit()
      return String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
    } catch {
      return nil
    }
  }

  private func parseCertificateInfo(_ output: String) -> Date? {
    let lines = output.components(separatedBy: .newlines)
    for line in lines {
      if line.contains("Apple Development") {
        let components = line.components(separatedBy: " ")
        if components.count >= 2 {
          let hash = components[1]
          return getCertificateExpirationFromHash(hash)
        }
      }
    }
    return nil
  }

  private func getCertificateExpirationFromHash(_ hash: String) -> Date? {
    let task = Process()
    task.launchPath = "/usr/bin/security"
    task.arguments = ["find-certificate", "-c", hash, "-p"]
    let pipe = Pipe()
    task.standardOutput = pipe
    task.standardError = pipe
    do {
      try task.run()
      task.waitUntilExit()
      let data = pipe.fileHandleForReading.readDataToEndOfFile()
      let output = String(data: data, encoding: .utf8) ?? ""
      return parseCertificateDate(output)
    } catch {
      return nil
    }
  }

  private func parseCertificateDate(_ output: String) -> Date? {
    let lines = output.components(separatedBy: .newlines)
    for line in lines {
      if line.contains("notAfter") {
        let components = line.components(separatedBy: " ")
        if components.count >= 2 {
          let dateString = components[1]
          let dateFormatter = DateFormatter()
          dateFormatter.dateFormat = "MMM dd HH:mm:ss yyyy zzz"
          return dateFormatter.date(from: dateString)
        }
      }
    }
    return nil
  }

  private func showExpirationWarning(expirationDate: Date) {
    if !shouldShowWarning() {
      return
    }
    let dateFormatter = DateFormatter()
    dateFormatter.dateStyle = .medium
    dateFormatter.timeStyle = .short
    let expirationString = dateFormatter.string(from: expirationDate)
    let calendar = Calendar.current
    let now = Date()
    let daysRemaining = calendar.dateComponents([.day], from: now, to: expirationDate).day ?? 0
    DispatchQueue.main.async {
      let alert = NSAlert()
      alert.messageText = LanguageManager.s.localizedString("system.certificate.expiration.title")
      alert.informativeText = String(format: LanguageManager.s.localizedString("system.certificate.expiration.message"), expirationString, String(daysRemaining))
      alert.alertStyle = .warning
      alert.addButton(withTitle: LanguageManager.s.localizedString("system.message.confirm"))
      alert.addButton(withTitle: LanguageManager.s.localizedString("system.certificate.expiration.remind_later"))
      alert.addButton(withTitle: LanguageManager.s.localizedString("system.certificate.expiration.never_remind"))
      let response = alert.runModal()
      switch response {
      case .alertSecondButtonReturn:
        UserDefaults.standard.set(Date(), forKey: "lastExpirationWarning")
      case .alertThirdButtonReturn:
        UserDefaults.standard.set(Date(), forKey: "neverShowExpirationWarning")
      default:
        break
      }
    }
  }

  private func shouldShowWarning() -> Bool {
    if UserDefaults.standard.object(forKey: "neverShowExpirationWarning") != nil {
      return false
    }
    if let lastWarning = UserDefaults.standard.object(forKey: "lastExpirationWarning") as? Date {
      let calendar = Calendar.current
      let oneDayAgo = calendar.date(byAdding: .day, value: -1, to: Date()) ?? Date()
      return lastWarning < oneDayAgo
    }
    return true
  }
}
