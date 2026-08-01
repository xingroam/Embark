import SwiftUI

extension NSImage {
  func resized(to size: NSSize) -> NSImage {
    if self.size.width == size.width && self.size.height == size.height {
      return self
    }
    return autoreleasepool {
      let resizedImage = NSImage(size: size)
      resizedImage.lockFocus()
      NSGraphicsContext.current?.imageInterpolation = .high
      self.draw(in: NSRect(origin: .zero, size: size))
      resizedImage.unlockFocus()
      return resizedImage
    }
  }
}
