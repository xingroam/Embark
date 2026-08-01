import Foundation
import CryptoKit

class Device {
  static func getDeviceCode() -> String {
    let hardwareUUID = getHardwareUUID()
    if hardwareUUID == nil {
      return ""
    }
    return hardwareUUID!.md5Hash()
  }

  static func getHardwareUUID() -> String? {
    let platformExpert = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("IOPlatformExpertDevice"))
    guard platformExpert != 0 else { return nil }
    defer { IOObjectRelease(platformExpert) }
    guard let serialNumberAsCFString = IORegistryEntryCreateCFProperty(platformExpert, "IOPlatformUUID" as CFString, kCFAllocatorDefault, 0) else { return nil }
    return serialNumberAsCFString.takeRetainedValue() as? String
  }
}
