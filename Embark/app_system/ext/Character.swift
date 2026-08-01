import SwiftUI

extension Character {
  var isHexDigit: Bool {
    return isASCII && (isNumber || ("a"..."f").contains(lowercased()) || ("A"..."F").contains(self))
  }
}
