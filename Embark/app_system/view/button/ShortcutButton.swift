import SwiftUI
import ApplicationServices

struct ShortcutButton: View {
  let keyCode: CGKeyCode?
  let flags: CGEventFlags
  let onTap: () -> Void

  var body: some View {
    Button(action: onTap) {
      Text(keyCode != nil ? Keyboard.fullNameShortcut(keyCode: keyCode!, flags: flags) : NSLocalizedString("system.shortcut.dialog.click_to_set", comment: ""))
        .foregroundColor(.white)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Color.accentColor)
        .cornerRadius(100)
    }
    .buttonStyle(PlainButtonStyle())
  }
}
