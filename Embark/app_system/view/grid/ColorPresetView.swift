import SwiftUI

struct ColorPresetView: View {
  let colors: [String]
  @Binding var selectedColor: Color
  let fz: CGFloat

  var body: some View {
    VStack(alignment: .leading, spacing: 5) {
      LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 5), count: 10), spacing: 5) {
        ForEach(colors, id: \.self) { hexColor in
          Button(action: {
            if let color = LauncherConfig.hexToColor(hexColor) {
              selectedColor = color
            }
          }) {
            RoundedRectangle(cornerRadius: 3)
              .fill(LauncherConfig.hexToColor(hexColor) ?? Color.secondary)
              .frame(width: 20, height: 20)
          }
          .buttonStyle(PlainButtonStyle())
        }
      }
    }
  }
}
