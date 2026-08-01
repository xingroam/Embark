import SwiftUI
import UniformTypeIdentifiers

enum FileFolderDialogMode {
  case file
  case folder
}

struct FileFolderDialog: View {
  let mode: FileFolderDialogMode
  @Binding var isPresented: Bool
  let onAdd: (String) -> Void
  @State private var selectedPath: String = ""
  @State private var isShowingPicker = false
  @State private var isProcessing = false
  @State private var showError = false
  @State private var errorMessage = ""

  var body: some View {
    VStack(spacing: 20) {
      Text(NSLocalizedString("launcher.dialog.add.title", comment: ""))
        .font(.title2)
        .fontWeight(.semibold)
      VStack(alignment: .leading, spacing: 10) {
        HStack(spacing: 10) {
          TextField(pathLabel, text: $selectedPath)
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .disabled(true)
          Button(chooseButtonLabel) {
            isShowingPicker = true
          }
          .buttonStyle(.borderedProminent)
          .disabled(isProcessing)
        }
      }
      HStack(spacing: 10) {
        Button(NSLocalizedString("system.message.cancel", comment: "")) {
          isPresented = false
        }
        .buttonStyle(.bordered)
        .disabled(isProcessing)
        Spacer()
        if !selectedPath.isEmpty {
          Button(addButtonLabel) {
            processAdd()
          }
          .buttonStyle(.borderedProminent)
        } else {
          Button(addButtonLabel) {
            processAdd()
          }
          .buttonStyle(.bordered)
          .disabled(true)
        }
      }
    }
    .padding(20)
    .frame(width: 400)
    .background(BlurredBackground(material: .underWindowBackground, blendingMode: .behindWindow, blur: 1.0))
    .fileImporter(
      isPresented: $isShowingPicker,
      allowedContentTypes: mode == .file ? [.data] : [.folder],
      allowsMultipleSelection: false
    ) { result in
      DispatchQueue.main.async {
        switch result {
        case .success(let urls):
          if let url = urls.first {
            selectedPath = url.path
          }
        case .failure(let error):
          let errorKey = mode == .file ? "launcher.error.select_file_failed" : "launcher.error.select_folder_failed"
          errorMessage = "\(NSLocalizedString(errorKey, comment: "").replacingOccurrences(of: "%@", with: error.localizedDescription))"
          showError = true
        }
        isShowingPicker = false
      }
    }
    .onDisappear {
      selectedPath = ""
      isProcessing = false
      showError = false
      errorMessage = ""
    }
    .alert(NSLocalizedString("launcher.error.title", comment: ""), isPresented: $showError) {
      Button(NSLocalizedString("system.message.confirm", comment: "")) { }
    } message: {
      Text(errorMessage)
    }
  }

  private var pathLabel: String {
    NSLocalizedString(mode == .file ? "launcher.add.file.dialog.file_path" : "launcher.add.folder.dialog.folder_path", comment: "")
  }

  private var chooseButtonLabel: String {
    NSLocalizedString(mode == .file ? "launcher.add.file.dialog.choose_file" : "launcher.add.folder.dialog.choose_folder", comment: "")
  }

  private var addButtonLabel: String {
    NSLocalizedString(mode == .file ? "system.message.add" : "system.message.add", comment: "")
  }

  private func processAdd() {
    guard !selectedPath.isEmpty else { return }
    isProcessing = true
    let fileManager = FileManager.default
    guard fileManager.fileExists(atPath: selectedPath) else {
      errorMessage = NSLocalizedString("launcher.error.path_not_exists", comment: "")
      showError = true
      isProcessing = false
      return
    }
    var isDirectory: ObjCBool = false
    let exists = fileManager.fileExists(atPath: selectedPath, isDirectory: &isDirectory)
    if mode == .file {
      guard exists && !isDirectory.boolValue else {
        errorMessage = NSLocalizedString("launcher.error.path_not_file", comment: "")
        showError = true
        isProcessing = false
        return
      }
    } else {
      guard exists && isDirectory.boolValue else {
        errorMessage = NSLocalizedString("launcher.error.path_not_folder", comment: "")
        showError = true
        isProcessing = false
        return
      }
    }
    DispatchQueue.global(qos: .userInitiated).async {
      onAdd(selectedPath)
      DispatchQueue.main.async {
        isPresented = false
      }
    }
  }
}
