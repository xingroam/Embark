import Foundation

class CacheNet {
  static let s = CacheNet()
  private var memoryCache: [String: CacheData] = [:]
  private let lock = NSLock()

  private init() {}

  func Request(url: String, forceUpdate: Bool = false, cacheHours: Int = 1) async throws -> Data {
    let cacheKey = url.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? url
    if !forceUpdate {
      if let cachedData = getCachedData(key: cacheKey) {
        if isCacheValid(cachedData: cachedData, cacheHours: cacheHours) {
          return cachedData.data
        }
      }
    }
    let data = try await downloadData(from: url)
    saveCachedData(key: cacheKey, data: data)
    return data
  }

  func removeCache(for url: String) {
    let cacheKey = url.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? url
    lock.lock()
    memoryCache.removeValue(forKey: cacheKey)
    lock.unlock()
  }

  func clearCache() {
    lock.lock()
    memoryCache.removeAll()
    lock.unlock()
  }

  private func getCachedData(key: String) -> CacheData? {
    lock.lock()
    defer { lock.unlock() }
    return memoryCache[key]
  }

  private func saveCachedData(key: String, data: Data) {
    lock.lock()
    memoryCache[key] = CacheData(data: data, timestamp: Date())
    lock.unlock()
  }

  private func isCacheValid(cachedData: CacheData, cacheHours: Int) -> Bool {
    let now = Date()
    let timeInterval = now.timeIntervalSince(cachedData.date)
    let cacheSeconds = TimeInterval(cacheHours * 3600)
    return timeInterval < cacheSeconds
  }

  private func downloadData(from urlString: String) async throws -> Data {
    guard let url = URL(string: urlString) else {
      throw CacheNetError.invalidURL
    }
    let config = URLSessionConfiguration.default
    config.timeoutIntervalForRequest = 30
    config.timeoutIntervalForResource = 30
    let session = URLSession(configuration: config)
    defer {
      session.finishTasksAndInvalidate()
    }
    let (data, response) = try await session.data(from: url)
    guard let httpResponse = response as? HTTPURLResponse else { throw CacheNetError.networkError }
    guard httpResponse.statusCode == 200 else { throw CacheNetError.networkError }
    return data
  }
}
