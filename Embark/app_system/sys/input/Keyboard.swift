import SwiftUI
import ApplicationServices

class Keyboard {
  static func shortNameShortcut(keyCode: CGKeyCode, flags: CGEventFlags) -> String {
    var parts: [String] = []
    if flags.contains(.maskCommand) {
      parts.append("⌘")
    }
    if flags.contains(.maskControl) {
      parts.append("⌃")
    }
    if flags.contains(.maskAlternate) {
      parts.append("⌥")
    }
    if flags.contains(.maskShift) {
      parts.append("⇧")
    }
    parts.append(keyCodeToCharacter(keyCode))
    return parts.joined()
  }

  static func fullNameShortcut(keyCode: CGKeyCode, flags: CGEventFlags) -> String {
    if keyCode.isDisabled {
      return NSLocalizedString("system.shortcut.dialog.click_to_set", comment: "")
    }
    var parts: [String] = []
    if flags.contains(.maskCommand) {
      parts.append("Command")
    }
    if flags.contains(.maskControl) {
      parts.append("Control")
    }
    if flags.contains(.maskAlternate) {
      parts.append("Option")
    }
    if flags.contains(.maskShift) {
      parts.append("Shift")
    }
    parts.append(keyCodeToFullName(keyCode))
    return parts.joined(separator: " + ")
  }

  static func keyCodeToCharacter(_ keyCode: CGKeyCode) -> String {
    switch keyCode {
      case 0: return "A"
      case 1: return "S"
      case 2: return "D"
      case 3: return "F"
      case 4: return "H"
      case 5: return "G"
      case 6: return "Z"
      case 7: return "X"
      case 8: return "C"
      case 9: return "V"
      case 11: return "B"
      case 12: return "Q"
      case 13: return "W"
      case 14: return "E"
      case 15: return "R"
      case 16: return "Y"
      case 17: return "T"
      case 18: return "1"
      case 19: return "2"
      case 20: return "3"
      case 21: return "4"
      case 22: return "6"
      case 23: return "5"
      case 24: return "="
      case 25: return "9"
      case 26: return "7"
      case 27: return "-"
      case 28: return "8"
      case 29: return "0"
      case 30: return "]"
      case 31: return "O"
      case 32: return "U"
      case 33: return "["
      case 34: return "I"
      case 35: return "P"
      case 37: return "L"
      case 38: return "J"
      case 39: return "'"
      case 40: return "K"
      case 41: return ";"
      case 42: return "\\"
      case 43: return ","
      case 44: return "/"
      case 45: return "N"
      case 46: return "M"
      case 47: return "."
      case 50: return "`"
      case 65: return "."
      case 67: return "*"
      case 69: return "+"
      case 71: return "⌧"
      case 75: return "/"
      case 76: return "↵"
      case 78: return "-"
      case 81: return "="
      case 82: return "0"
      case 83: return "1"
      case 84: return "2"
      case 85: return "3"
      case 86: return "4"
      case 87: return "5"
      case 88: return "6"
      case 89: return "7"
      case 91: return "8"
      case 92: return "9"
      case 36: return "↵"
      case 48: return "⇥"
      case 49: return "␣"
      case 51: return "⌫"
      case 53: return "⎋"
      case 96: return "F5"
      case 97: return "F6"
      case 98: return "F7"
      case 99: return "F3"
      case 100: return "F8"
      case 101: return "F9"
      case 103: return "F11"
      case 105: return "F13"
      case 107: return "F14"
      case 109: return "F10"
      case 111: return "F12"
      case 114: return "⎋"
      case 115: return "↖"
      case 116: return "⇞"
      case 117: return "⌦"
      case 118: return "F4"
      case 119: return "↘"
      case 120: return "F2"
      case 121: return "⇟"
      case 122: return "F1"
      case 123: return "←"
      case 124: return "→"
      case 125: return "↓"
      case 126: return "↑"
      case 144: return "⌧"
      default: return "?"
    }
  }

  static func keyCodeToFullName(_ keyCode: CGKeyCode) -> String {
    switch keyCode {
      case 0: return "A"
      case 1: return "S"
      case 2: return "D"
      case 3: return "F"
      case 4: return "H"
      case 5: return "G"
      case 6: return "Z"
      case 7: return "X"
      case 8: return "C"
      case 9: return "V"
      case 11: return "B"
      case 12: return "Q"
      case 13: return "W"
      case 14: return "E"
      case 15: return "R"
      case 16: return "Y"
      case 17: return "T"
      case 18: return "1"
      case 19: return "2"
      case 20: return "3"
      case 21: return "4"
      case 22: return "6"
      case 23: return "5"
      case 24: return "="
      case 25: return "9"
      case 26: return "7"
      case 27: return "-"
      case 28: return "8"
      case 29: return "0"
      case 30: return "]"
      case 31: return "O"
      case 32: return "U"
      case 33: return "["
      case 34: return "I"
      case 35: return "P"
      case 37: return "L"
      case 38: return "J"
      case 39: return "'"
      case 40: return "K"
      case 41: return ";"
      case 42: return "\\"
      case 43: return ","
      case 44: return "/"
      case 45: return "N"
      case 46: return "M"
      case 47: return "."
      case 50: return "`"
      case 65: return "Decimal"
      case 67: return "Multiply"
      case 69: return "Plus"
      case 71: return "Clear"
      case 75: return "Divide"
      case 76: return "Enter"
      case 78: return "Minus"
      case 81: return "Equals"
      case 82: return "Numpad 0"
      case 83: return "Numpad 1"
      case 84: return "Numpad 2"
      case 85: return "Numpad 3"
      case 86: return "Numpad 4"
      case 87: return "Numpad 5"
      case 88: return "Numpad 6"
      case 89: return "Numpad 7"
      case 91: return "Numpad 8"
      case 92: return "Numpad 9"
      case 36: return "Return"
      case 48: return "Tab"
      case 49: return "Space"
      case 51: return "Delete"
      case 53: return "Escape"
      case 96: return "F5"
      case 97: return "F6"
      case 98: return "F7"
      case 99: return "F3"
      case 100: return "F8"
      case 101: return "F9"
      case 103: return "F11"
      case 105: return "F13"
      case 107: return "F14"
      case 109: return "F10"
      case 111: return "F12"
      case 114: return "Help"
      case 115: return "Home"
      case 116: return "Page Up"
      case 117: return "Forward Delete"
      case 118: return "F4"
      case 119: return "End"
      case 120: return "F2"
      case 121: return "Page Down"
      case 122: return "F1"
      case 123: return "Left Arrow"
      case 124: return "Right Arrow"
      case 125: return "Down Arrow"
      case 126: return "Up Arrow"
      case 144: return "Clear"
      default: return "?"
    }
  }

  static func characterToKeyCode(_ character: String) -> CGKeyCode? {
    switch character {
      case "A": return 0
      case "S": return 1
      case "D": return 2
      case "F": return 3
      case "H": return 4
      case "G": return 5
      case "Z": return 6
      case "X": return 7
      case "C": return 8
      case "V": return 9
      case "B": return 11
      case "Q": return 12
      case "W": return 13
      case "E": return 14
      case "R": return 15
      case "Y": return 16
      case "T": return 17
      case "1": return 18
      case "2": return 19
      case "3": return 20
      case "4": return 21
      case "6": return 22
      case "5": return 23
      case "=": return 24
      case "9": return 25
      case "7": return 26
      case "-": return 27
      case "8": return 28
      case "0": return 29
      case "]": return 30
      case "O": return 31
      case "U": return 32
      case "[": return 33
      case "I": return 34
      case "P": return 35
      case "L": return 37
      case "J": return 38
      case "'": return 39
      case "K": return 40
      case ";": return 41
      case "\\": return 42
      case ",": return 43
      case "/": return 44
      case "N": return 45
      case "M": return 46
      case ".": return 47
      case "`": return 50
      case "⌧": return 71
      case "↵": return 76
      case "⇥": return 48
      case "␣": return 49
      case "⌫": return 51
      case "⎋": return 53
      case "F5": return 96
      case "F6": return 97
      case "F7": return 98
      case "F3": return 99
      case "F8": return 100
      case "F9": return 101
      case "F11": return 103
      case "F13": return 105
      case "F14": return 107
      case "F10": return 109
      case "F12": return 111
      case "↖": return 115
      case "⇞": return 116
      case "⌦": return 117
      case "F4": return 118
      case "↘": return 119
      case "F2": return 120
      case "⇟": return 121
      case "F1": return 122
      case "←": return 123
      case "→": return 124
      case "↓": return 125
      case "↑": return 126
      default: return nil
    }
  }

  static func fullNameToKeyCode(_ name: String) -> CGKeyCode? {
    switch name {
      case "A": return 0
      case "S": return 1
      case "D": return 2
      case "F": return 3
      case "H": return 4
      case "G": return 5
      case "Z": return 6
      case "X": return 7
      case "C": return 8
      case "V": return 9
      case "B": return 11
      case "Q": return 12
      case "W": return 13
      case "E": return 14
      case "R": return 15
      case "Y": return 16
      case "T": return 17
      case "1": return 18
      case "2": return 19
      case "3": return 20
      case "4": return 21
      case "6": return 22
      case "5": return 23
      case "=": return 24
      case "9": return 25
      case "7": return 26
      case "-": return 27
      case "8": return 28
      case "0": return 29
      case "]": return 30
      case "O": return 31
      case "U": return 32
      case "[": return 33
      case "I": return 34
      case "P": return 35
      case "L": return 37
      case "J": return 38
      case "'": return 39
      case "K": return 40
      case ";": return 41
      case "\\": return 42
      case ",": return 43
      case "/": return 44
      case "N": return 45
      case "M": return 46
      case ".": return 47
      case "`": return 50
      case "Decimal": return 65
      case "Multiply": return 67
      case "Plus": return 69
      case "Clear": return 71
      case "Divide": return 75
      case "Enter": return 76
      case "Minus": return 78
      case "Equals": return 81
      case "Numpad 0": return 82
      case "Numpad 1": return 83
      case "Numpad 2": return 84
      case "Numpad 3": return 85
      case "Numpad 4": return 86
      case "Numpad 5": return 87
      case "Numpad 6": return 88
      case "Numpad 7": return 89
      case "Numpad 8": return 91
      case "Numpad 9": return 92
      case "Return": return 36
      case "Tab": return 48
      case "Space": return 49
      case "Delete": return 51
      case "Escape": return 53
      case "F5": return 96
      case "F6": return 97
      case "F7": return 98
      case "F3": return 99
      case "F8": return 100
      case "F9": return 101
      case "F11": return 103
      case "F13": return 105
      case "F14": return 107
      case "F10": return 109
      case "F12": return 111
      case "Help": return 114
      case "Home": return 115
      case "Page Up": return 116
      case "Forward Delete": return 117
      case "F4": return 118
      case "End": return 119
      case "F2": return 120
      case "Page Down": return 121
      case "F1": return 122
      case "Left Arrow": return 123
      case "Right Arrow": return 124
      case "Down Arrow": return 125
      case "Up Arrow": return 126
      default: return nil
    }
  }
}
