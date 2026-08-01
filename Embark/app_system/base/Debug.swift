import Foundation

class Debug {
  private static var logFileURL: URL? {
    guard let appSupportPath = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else { return nil }
    let appDirectory = appSupportPath.appendingPathComponent(EmbarkInfo.bundleIdentifier)
    try? FileManager.default.createDirectory(at: appDirectory, withIntermediateDirectories: true)
    return appDirectory.appendingPathComponent(EmbarkInfo.logFile)
  }

  static func isDebug() -> Bool {
    #if DEBUG
      return true
    #else
      return false
    #endif
  }

  static func isRelease() -> Bool {
    #if DEBUG
      return false
    #else
      return true
    #endif
  }

  static func info(_ items: Any..., separator: String = " ", terminator: String = "\n") {
    let timestamp = DateFormatter.ts.string(from: Date())
    let message = "[\(timestamp)] " + items.map { "\($0)" }.joined(separator: separator) + terminator
    Swift.print(message, terminator: "")
    writeToLogFile(message)
  }

  static func info(_ items: [Any], separator: String = " ", terminator: String = "\n") {
    let timestamp = DateFormatter.ts.string(from: Date())
    let message = "[\(timestamp)] " + items.map { "\($0)" }.joined(separator: separator) + terminator
    Swift.print(message, terminator: "")
    writeToLogFile(message)
  }

  static func print(_ items: Any..., separator: String = " ", terminator: String = "\n") {
    #if DEBUG
    let timestamp = DateFormatter.ts.string(from: Date())
    let message = "[\(timestamp)] " + items.map { "\($0)" }.joined(separator: separator) + terminator
    Swift.print(message, terminator: "")
    writeToLogFile(message)
    #endif
  }

  static func print(_ items: [Any], separator: String = " ", terminator: String = "\n") {
    #if DEBUG
    let timestamp = DateFormatter.ts.string(from: Date())
    let message = "[\(timestamp)] " + items.map { "\($0)" }.joined(separator: separator) + terminator
    Swift.print(message, terminator: "")
    writeToLogFile(message)
    #endif
  }

  static func getLogFilePath() -> String? {
    return logFileURL?.path
  }

  static func clearLogFile() {
    guard let logURL = logFileURL else { return }
    do {
      try "".write(to: logURL, atomically: true, encoding: .utf8)
    } catch {}
  }

  static func readLogFile() -> String? {
    guard let logURL = logFileURL else { return nil }
    do {
      return try String(contentsOf: logURL, encoding: .utf8)
    } catch {
      return nil
    }
  }

  private static func writeToLogFile(_ message: String) {
    guard let logURL = logFileURL else { return }
    let cleanMessage = message.replacingOccurrences(of: "\n", with: "")
    let logEntry = cleanMessage
    do {
      if !FileManager.default.fileExists(atPath: logURL.path) {
        try logEntry.write(to: logURL, atomically: true, encoding: .utf8)
        return
      }
      let existingContent = try String(contentsOf: logURL, encoding: .utf8)
      var lines = existingContent.components(separatedBy: .newlines)
      lines.append(logEntry)
      if lines.count > SystemInfo.maxLogLine {
        lines = Array(lines.suffix(SystemInfo.maxLogLine))
      }
      let newContent = lines.joined(separator: "\n")
      try newContent.write(to: logURL, atomically: true, encoding: .utf8)
    } catch {}
  }
}
