import Foundation
import SwiftUI

struct WebItem {
  let title: String
  let url: String
}

class WebManager: ObservableObject {
  static func GetWebList(completion: @escaping (Result<[WebItem], Error>) -> Void) {
    Task {
      do {
        let data = try await CacheNet.s.Request(url: EmbarkInfo.embarkJson, cacheHours: EmbarkInfo.embarkJsonHour)
        DispatchQueue.main.async {
          do {
            let json = try JSON(data: data)
            let webArray = json["Web"].arrayValue
            let webItems = webArray.compactMap { item -> WebItem? in
              guard let title = item["Title"].string,
                    let url = item["Url"].string else {
                return nil
              }
              return WebItem(title: title, url: url)
            }
            completion(.success(webItems))
          } catch {
            completion(.failure(error))
          }
        }
      } catch {
        DispatchQueue.main.async {
          completion(.failure(error))
        }
      }
    }
  }
}
