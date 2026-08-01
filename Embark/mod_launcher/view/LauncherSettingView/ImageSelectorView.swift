import SwiftUI
import UniformTypeIdentifiers

struct ImageSelectorView: View {
  let fz: CGFloat
  @State private var selectedImage: NSImage? = nil
  @State private var isShowingFilePicker = false
  @State private var isPressed = false

  var body: some View {
    VStack(spacing: 10) {
      if let image = selectedImage {
        Image(nsImage: image)
          .resizable()
          .scaledToFill()
          .frame(maxWidth: .infinity, maxHeight: .infinity)
          .clipped()
      } else {
        VStack(spacing: 5) {
          Image(systemName: "photo")
            .font(.system(size: 40))
            .foregroundColor(isPressed ? .accentColor : .secondary)
          Text(NSLocalizedString("launcher.settings.background.image_select", comment: ""))
            .font(.system(size: fz - 2))
            .foregroundColor(isPressed ? .accentColor : .secondary)
        }
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .contentShape(Rectangle())
    .background(
      RoundedRectangle(cornerRadius: 10)
        .fill(isPressed ? Color.accentColor.opacity(0.2) : Color.secondary.opacity(0.2))
    )
    .overlay(
      RoundedRectangle(cornerRadius: 10)
        .stroke(isPressed ? Color.accentColor : Color.secondary.opacity(0.6), lineWidth: 1)
    )
    .cornerRadius(10)
    .overlay(alignment: .topTrailing) {
      if selectedImage != nil {
        Button(action: removeImage) {
          ZStack {
            Circle()
              .fill(Color.red)
              .frame(width: 24, height: 24)
            Circle()
              .stroke(Color.white, lineWidth: 2)
              .frame(width: 24, height: 24)
            Image(systemName: "xmark")
              .foregroundColor(.white)
              .font(.system(size: 12, weight: .bold))
          }
        }
        .buttonStyle(PlainButtonStyle())
        .offset(x: 10, y: -10)
      }
    }
    .gesture(
      DragGesture(minimumDistance: 0)
        .onChanged { _ in
          if selectedImage == nil {
            isPressed = true
          }
        }
        .onEnded { _ in
          if selectedImage == nil && isPressed {
            isPressed = false
            selectImage()
          } else {
            isPressed = false
          }
        }
    )
    .onAppear {
      selectedImage = ImageBackground.loadImage()
    }
    .onDisappear {
      selectedImage = nil
    }
  }

  private func selectImage() {
    Dialog.ImagePicker { url in
      guard let url = url else { return }
      do {
        try ImageBackground.saveImage(from: url)
        selectedImage = ImageBackground.loadImage()
        NotificationCenter.default.post(name: NSNotification.Name("LauncherImageChanged"), object: nil)
      } catch {
        Debug.print("Error saving image: \(error)")
      }
    }
  }

  private func removeImage() {
    do {
      try ImageBackground.removeImage()
      selectedImage = nil
      NotificationCenter.default.post(name: NSNotification.Name("LauncherImageChanged"), object: nil)
    } catch {
      Debug.print("Error removing image: \(error)")
    }
  }
}
