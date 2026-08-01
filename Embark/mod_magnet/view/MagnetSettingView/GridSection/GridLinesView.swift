import SwiftUI

struct GridLinesView: View {
  let rows: Int
  let columns: Int
  let isSelected: Bool
  let gridColor: Color
  let containerSize: CGSize

  var body: some View {
    Path { path in
      let cellWidth = containerSize.width / CGFloat(columns)
      let cellHeight = containerSize.height / CGFloat(rows)
      for i in 1..<columns {
        let x = cellWidth * CGFloat(i)
        path.move(to: CGPoint(x: x, y: 0))
        path.addLine(to: CGPoint(x: x, y: containerSize.height))
      }
      for i in 1..<rows {
        let y = cellHeight * CGFloat(i)
        path.move(to: CGPoint(x: 0, y: y))
        path.addLine(to: CGPoint(x: containerSize.width, y: y))
      }
    }
    .stroke(isSelected ? gridColor : Color.secondary.opacity(0.6), lineWidth: 1)
    .frame(width: containerSize.width, height: containerSize.height)
    .clipped()
  }
}
