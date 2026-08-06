import Foundation
import SwiftUI

struct WebItem {
  let title: String
  let url: String
}

class DefineManager: ObservableObject {
  private static func GetEmbarkJson(completion: @escaping (Result<JSON, Error>) -> Void) {
    Task {
      do {
        let data = try await CacheNet.s.Request(url: EmbarkInfo.embarkJson, cacheHours: EmbarkInfo.embarkJsonHour)
        DispatchQueue.main.async {
          do {
            completion(.success(try JSON(data: data)))
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

  static func GetSponsorUrl(completion: @escaping (Result<String, Error>) -> Void) {
    GetEmbarkJson { result in
      switch result {
      case .success(let json):
        if let sponsorUrl = json["Sponsor"]["Url"].string ?? json["Sponsor"].string {
          completion(.success(sponsorUrl))
          return
        }
        let error = NSError(domain: "Embark", code: -1, userInfo: [NSLocalizedDescriptionKey: "Sponsor URL not found in embark.json"])
        completion(.failure(error))
      case .failure(let error):
        completion(.failure(error))
      }
    }
  }

  static func GetWebList(completion: @escaping (Result<[WebItem], Error>) -> Void) {
    GetEmbarkJson { result in
      switch result {
      case .success(let json):
        let webArray = json["Web"].arrayValue
        let webItems = webArray.compactMap { item -> WebItem? in
          guard let title = item["Title"].string,
                let url = item["Url"].string else {
            return nil
          }
          return WebItem(title: title, url: url)
        }
        completion(.success(webItems))
      case .failure(let error):
        completion(.failure(error))
      }
    }
  }
}
