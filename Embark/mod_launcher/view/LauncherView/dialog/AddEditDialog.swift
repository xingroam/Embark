import SwiftUI

enum AddEditDialogMode {
  case addMainPanel
  case addSubPanel
  case editPanel
  case editLink
  case editSpace
  case duplicateSpace
}

struct AddEditDialog: View {
  let mode: AddEditDialogMode
  @Binding var name: String
  @Binding var isPresented: Bool
  let onConfirm: (String) -> Void

  var body: some View {
    VStack(spacing: 20) {
      Text(title)
        .font(.title2)
        .fontWeight(.semibold)
      VStack(alignment: .leading, spacing: 10) {
        TextField(placeholder, text: $name)
          .textFieldStyle(RoundedBorderTextFieldStyle())
      }
      HStack(spacing: 10) {
        Button(NSLocalizedString("system.message.cancel", comment: "")) {
          isPresented = false
        }
        .buttonStyle(.bordered)
        Spacer()
        if !name.isEmpty || mode == .editLink {
          Button(confirmButtonLabel) {
            onConfirm(name)
            isPresented = false
          }
          .buttonStyle(.borderedProminent)
        } else {
          Button(confirmButtonLabel) {}
          .buttonStyle(.bordered)
          .disabled(true)
        }
      }
    }
    .padding(20)
    .frame(width: 300)
    .background(BlurredBackground(material: .underWindowBackground, blendingMode: .behindWindow, blur: 1.0))
  }

  private var title: String {
    switch mode {
    case .addMainPanel:
      return NSLocalizedString("launcher.add.panel.dialog.title", comment: "")
    case .addSubPanel:
      return NSLocalizedString("launcher.add.subpanel.dialog.title", comment: "")
    case .editPanel:
      return NSLocalizedString("launcher.panel.dialog.edit_name.title", comment: "")
    case .editLink:
      return NSLocalizedString("launcher.dialog.custom_name.title", comment: "")
    case .editSpace:
      return NSLocalizedString("space.dialog.edit.title", comment: "")
    case .duplicateSpace:
      return NSLocalizedString("space.dialog.duplicate.title", comment: "")
    }
  }

  private var placeholder: String {
    switch mode {
    case .editPanel:
      return NSLocalizedString("launcher.panel.dialog.edit_name.field", comment: "")
    case .editLink:
      return NSLocalizedString("launcher.link.context.custom_name", comment: "")
    case .editSpace, .duplicateSpace:
      return NSLocalizedString("space.snapshot.name", comment: "")
    default:
      return NSLocalizedString("launcher.dialog.add_panel.field", comment: "")
    }
  }

  private var confirmButtonLabel: String {
    switch mode {
    case .editPanel, .editLink, .editSpace, .duplicateSpace:
      return NSLocalizedString("system.message.confirm", comment: "")
    default:
      return NSLocalizedString("system.message.add", comment: "")
    }
  }
}
