import SwiftUI

struct GridSelector: View {
  @Binding var isSelected: Bool
  let gridType: GridType
  let gridColor: Color
  let fz: CGFloat

  var body: some View {
    Button(action: {
      isSelected.toggle()
      switch gridType {
      case .x2:
        MagnetConfig.magnet2x2 = isSelected
      case .x3x2:
        MagnetConfig.magnet3x2 = isSelected
      case .x3:
        MagnetConfig.magnet3x3 = isSelected
      case .x4x2:
        MagnetConfig.magnet4x2 = isSelected
      case .x4:
        MagnetConfig.magnet4x4 = isSelected
      case .x6:
        MagnetConfig.magnet6x6 = isSelected
      case .x8:
        MagnetConfig.magnet8x8 = isSelected
      case .x10:
        MagnetConfig.magnet10x10 = isSelected
      case .x12:
        MagnetConfig.magnet12x12 = isSelected
      }
      NotificationCenter.default.post(name: NSNotification.Name("MagnetConfigChanged"), object: nil)
    }) {
      ZStack {
        RoundedRectangle(cornerRadius: 2)
          .fill(isSelected ? gridColor.opacity(0.3) : Color.secondary.opacity(0.1))
          .frame(width: 80, height: 62)
          .overlay(
            RoundedRectangle(cornerRadius: 2)
              .stroke(isSelected ? gridColor : Color.secondary.opacity(0.6), lineWidth: 1)
          )
        gridContent
      }
    }
    .buttonStyle(PlainButtonStyle())
  }

  @ViewBuilder
  private var gridContent: some View {
    switch gridType {
    case .x2:
      GridLinesView(
        rows: 2,
        columns: 2,
        isSelected: isSelected,
        gridColor: gridColor,
        containerSize: CGSize(width: 80, height: 62)
      )
    case .x3x2:
      GridLinesView(
        rows: 2,
        columns: 3,
        isSelected: isSelected,
        gridColor: gridColor,
        containerSize: CGSize(width: 80, height: 62)
      )
    case .x3:
      GridLinesView(
        rows: 3,
        columns: 3,
        isSelected: isSelected,
        gridColor: gridColor,
        containerSize: CGSize(width: 80, height: 62)
      )
    case .x4x2:
      GridLinesView(
        rows: 2,
        columns: 4,
        isSelected: isSelected,
        gridColor: gridColor,
        containerSize: CGSize(width: 80, height: 62)
      )
    case .x4:
      GridLinesView(
        rows: 4,
        columns: 4,
        isSelected: isSelected,
        gridColor: gridColor,
        containerSize: CGSize(width: 80, height: 62)
      )
    case .x6:
      GridLinesView(
        rows: 6,
        columns: 6,
        isSelected: isSelected,
        gridColor: gridColor,
        containerSize: CGSize(width: 80, height: 62)
      )
    case .x8:
      GridLinesView(
        rows: 8,
        columns: 8,
        isSelected: isSelected,
        gridColor: gridColor,
        containerSize: CGSize(width: 80, height: 62)
      )
    case .x10:
      GridLinesView(
        rows: 10,
        columns: 10,
        isSelected: isSelected,
        gridColor: gridColor,
        containerSize: CGSize(width: 80, height: 62)
      )
    case .x12:
      GridLinesView(
        rows: 12,
        columns: 12,
        isSelected: isSelected,
        gridColor: gridColor,
        containerSize: CGSize(width: 80, height: 62)
      )
    }
  }
}
