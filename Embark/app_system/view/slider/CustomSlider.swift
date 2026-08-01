import SwiftUI

struct CustomSlider: View {
  @Binding var value: Double
  let range: ClosedRange<Double>
  let step: Double
  let valueFormatter: (Double) -> String
  @Environment(\.isEnabled) private var isEnabled

  init(value: Binding<Double>, in range: ClosedRange<Double>, step: Double = 0.1, valueFormatter: @escaping (Double) -> String = { String(format: "%.0f", $0) }) {
    self._value = value
    self.range = range
    self.step = step
    self.valueFormatter = valueFormatter
  }

  var body: some View {
    GeometryReader { geometry in
      let thumbSize: CGFloat = 16
      let halfThumb = thumbSize / 2
      let trackWidth = geometry.size.width - thumbSize
      ZStack(alignment: .leading) {
        Rectangle()
          .fill(Color.clear)
          .frame(height: 4)
        HStack(spacing: 0) {
          Spacer()
            .frame(width: halfThumb)
          ZStack(alignment: .leading) {
            Rectangle()
              .fill(Color.secondary.opacity(isEnabled ? 0.2 : 0.1))
              .frame(width: trackWidth, height: 4)
              .cornerRadius(2)
            Rectangle()
              .fill(isEnabled ? Color.primary : Color.secondary.opacity(0.3))
              .frame(width: max(0, CGFloat((value - range.lowerBound) / (range.upperBound - range.lowerBound)) * trackWidth), height: 4)
              .cornerRadius(2)
          }
          Spacer()
            .frame(width: halfThumb)
        }
        Circle()
          .fill(isEnabled ? Color.primary : Color.secondary.opacity(0.3))
          .frame(width: thumbSize, height: thumbSize)
          .offset(x: max(0, min(geometry.size.width - thumbSize, CGFloat((value - range.lowerBound) / (range.upperBound - range.lowerBound)) * geometry.size.width - halfThumb)))
      }
      .contentShape(Rectangle())
      .gesture(
        DragGesture(minimumDistance: 0)
          .onChanged { dragValue in
            let newValue = range.lowerBound + (range.upperBound - range.lowerBound) * Double(dragValue.location.x / geometry.size.width)
            let clampedValue = max(range.lowerBound, min(range.upperBound, newValue))
            let steppedValue = round(clampedValue / step) * step
            value = steppedValue
          }
      )
    }
    .frame(height: 16)
  }
}

extension CustomSlider {
  static func backgroundOpacity(value: Binding<Double>, in range: ClosedRange<Double> = 0...1, step: Double = 0.01) -> CustomSlider {
    CustomSlider(value: value, in: range, step: step) { value in
      "\(Int(round(value * 100)))%"
    }
  }
  static func blur(value: Binding<Double>, in range: ClosedRange<Double> = 0...1, step: Double = 0.01) -> CustomSlider {
    CustomSlider(value: value, in: range, step: step) { value in
      "\(Int(value * 100))"
    }
  }
  static func imageBlur(value: Binding<Double>, in range: ClosedRange<Double> = 0...50, step: Double = 1) -> CustomSlider {
    CustomSlider(value: value, in: range, step: step) { value in
      "\(Int(value))"
    }
  }
  static func panelWidth(value: Binding<Double>, in range: ClosedRange<Double> = 100...400, step: Double = 10) -> CustomSlider {
    CustomSlider(value: value, in: range, step: step) { value in
      "\(Int(value))"
    }
  }
}
