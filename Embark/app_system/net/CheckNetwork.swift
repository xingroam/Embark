import Foundation
import Network
import Combine

class CheckNetwork: ObservableObject {
  static let s = CheckNetwork()
  @Published var isConnected = false
  @Published var connectionType: NWInterface.InterfaceType?
  private let monitor = NWPathMonitor()
  private let queue = DispatchQueue(label: "CheckNetworkMonitor")

  private init() {
    monitor.pathUpdateHandler = { [weak self] path in
      DispatchQueue.main.async { [weak self] in
        guard let self = self else { return }
        isConnected = path.status == .satisfied
        connectionType = path.availableInterfaces.first?.type
      }
    }
    monitor.start(queue: queue)
  }

  deinit {
    monitor.cancel()
  }
}
