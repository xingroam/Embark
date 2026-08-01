import SwiftUI

struct GridSection: View {
  let color: Color
  let fz: CGFloat
  @Binding var isMagnet3x2: Bool
  @Binding var isMagnet6x6: Bool
  @Binding var isMagnet8x8: Bool
  @Binding var isMagnet10x10: Bool
  @Binding var isMagnet12x12: Bool

  var body: some View {
    VStack(spacing: 10) {
      HStack(spacing: 5) {
        Text(NSLocalizedString("magnet.settings.grid.title", comment: ""))
          .font(.system(size: fz + 1, weight: .medium))
        Spacer()
        Text(statusMessage)
          .font(.system(size: fz))
          .foregroundColor(statusHasColor ? color : .secondary)
      }
      HStack(spacing: 10) {
        VStack(spacing: 10) {
          GridSelector(
            isSelected: $isMagnet3x2,
            gridType: GridType.x3x2,
            gridColor: color,
            fz: fz
          )
          Text(NSLocalizedString("magnet.settings.grid.3x2", comment: ""))
            .font(.system(size: fz))
            .foregroundColor(isMagnet3x2 ? color : .secondary)
        }
        VStack(spacing: 10) {
          GridSelector(
            isSelected: $isMagnet6x6,
            gridType: GridType.x6,
            gridColor: color,
            fz: fz
          )
          Text(NSLocalizedString("magnet.settings.grid.6x6", comment: ""))
            .font(.system(size: fz))
            .foregroundColor(isMagnet6x6 ? color : .secondary)
        }
        VStack(spacing: 10) {
          GridSelector(
            isSelected: $isMagnet8x8,
            gridType: GridType.x8,
            gridColor: color,
            fz: fz
          )
          Text(NSLocalizedString("magnet.settings.grid.8x8", comment: ""))
            .font(.system(size: fz))
            .foregroundColor(isMagnet8x8 ? color : .secondary)
        }
        VStack(spacing: 10) {
          GridSelector(
            isSelected: $isMagnet10x10,
            gridType: GridType.x10,
            gridColor: color,
            fz: fz
          )
          Text(NSLocalizedString("magnet.settings.grid.10x10", comment: ""))
            .font(.system(size: fz))
            .foregroundColor(isMagnet10x10 ? color : .secondary)
        }
        VStack(spacing: 10) {
          GridSelector(
            isSelected: $isMagnet12x12,
            gridType: GridType.x12,
            gridColor: color,
            fz: fz
          )
          Text(NSLocalizedString("magnet.settings.grid.12x12", comment: ""))
            .font(.system(size: fz))
            .foregroundColor(isMagnet12x12 ? color : .secondary)
        }
      }
      .cardStyle()
    }
  }

  private var statusMessage: String {
    if !isMagnet3x2 && !isMagnet6x6 && !isMagnet8x8 && !isMagnet10x10 && !isMagnet12x12 {
      return NSLocalizedString("magnet.settings.grid.status.disabled", comment: "")
    } else if isMagnet3x2 && isMagnet6x6 && isMagnet8x8 && isMagnet10x10 && isMagnet12x12 {
      return NSLocalizedString("magnet.settings.grid.status.all_enabled", comment: "")
    } else {
      var list = [String]()
      if isMagnet3x2 {
        list.append("3x2")
      }
      if isMagnet6x6 {
        list.append("6x6")
      }
      if isMagnet8x8 {
        list.append("8x8")
      }
      if isMagnet10x10 {
        list.append("10x10")
      }
      if isMagnet12x12 {
        list.append("12x12")
      }
      return String(format: NSLocalizedString("magnet.settings.grid.status.partial_enabled", comment: ""), list.joined(separator: "、"))
    }
  }

  private var statusHasColor: Bool {
    if !isMagnet3x2 && !isMagnet6x6 && !isMagnet8x8 && !isMagnet10x10 && !isMagnet12x12 {
      return false
    }
    return true
  }
}
