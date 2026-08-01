import SwiftUI

struct SwitcherView: View {
  @ObservedObject var manager = SwitcherManager.s
  @ObservedObject var tm = LauncherThemeManager.s
  @AppStorage(SwitcherConfig.switcherWidthKey) private var width = SwitcherDefine.switcherWidth
  @AppStorage(SwitcherConfig.switcherMaxItemsPerColumnKey) private var maxItemsPerColumnDouble = SwitcherDefine.switcherMaxItemsPerColumn
  @AppStorage(SwitcherConfig.switcherSizeKey) private var switcherSize: SwitcherSize = SwitcherDefine.switcherSize
  private let minCircleSize: CGFloat = 0.25

  var body: some View {
    let windows = Array(manager.windows.enumerated())
    let maxItemsPerColumn = Int(maxItemsPerColumnDouble)
    var columns = stride(from: 0, to: windows.count, by: maxItemsPerColumn).map {
      Array(windows[$0 ..< min($0 + maxItemsPerColumn, windows.count)])
    }
    if manager.direction == "Left" {
      columns.reverse()
    }
    return Group {
      if windows.isEmpty {
        Text(NSLocalizedString("system.message.not_found", comment: ""))
          .font(.system(size: switcherSize.textSize))
          .foregroundColor(tm.currentTheme.panelTextColor)
          .frame(width: width)
          .padding(.vertical, switcherSize.padding)
      } else {
        let alignment: VerticalAlignment = manager.direction == "Up" ? .bottom : .top
        HStack(alignment: alignment, spacing: 0) {
          ForEach(0..<columns.count, id: \.self) { columnIndex in
            let column = manager.direction == "Up" ? Array(columns[columnIndex].reversed()) : columns[columnIndex]
            VStack(spacing: 0) {
              ForEach(column, id: \.element.id) { window in
                let globalIndex = window.offset
                HStack(spacing: switcherSize.padding * 0.8) {
                  ZStack(alignment: .bottomTrailing) {
                    if let icon = window.element.icon {
                      Image(nsImage: icon)
                        .resizable()
                        .frame(width: switcherSize.iconSize, height: switcherSize.iconSize)
                    } else {
                      Image(systemName: "app.window")
                        .resizable()
                        .frame(width: switcherSize.iconSize, height: switcherSize.iconSize)
                    }
                    if window.element.isTimeout {
                      Circle()
                        .fill(Color.orange)
                        .frame(width: switcherSize.iconSize * minCircleSize, height: switcherSize.iconSize * minCircleSize)
                    } else if window.element.isMinimized {
                      Circle()
                        .fill(Color.green)
                        .frame(width: switcherSize.iconSize * minCircleSize, height: switcherSize.iconSize * minCircleSize)
                    }
                  }
                  VStack(alignment: .leading, spacing: 1) {
                    if !window.element.name.isEmpty && !window.element.isTimeout {
                      Text(window.element.name)
                        .font(.system(size: switcherSize.textSize, weight: .medium))
                        .foregroundColor(tm.currentTheme.linkTextColor)
                        .lineLimit(1)
                    } else {
                      Text(window.element.ownerName)
                        .font(.system(size: switcherSize.textSize, weight: .medium))
                        .foregroundColor(tm.currentTheme.linkTextColor)
                        .lineLimit(1)
                    }
                  }
                  Spacer()
                }
                .padding(switcherSize.padding * 0.2)
                .background(
                  (manager.selectedIndex == globalIndex || manager.hoveredIndex == globalIndex) ?
                  tm.currentTheme.linkBackgroundColor.opacity(tm.currentTheme.linkBackgroundOpacity) :
                  Color.clear
                )
                .cornerRadius(8)
                .background(
                  GeometryReader { geo in
                    Color.clear
                      .onAppear {
                        let frame = geo.frame(in: .global)
                        manager.updateItemFrame(index: globalIndex, frame: frame)
                      }
                      .onChange(of: geo.frame(in: .global)) { newFrame in
                        manager.updateItemFrame(index: globalIndex, frame: newFrame)
                      }
                  }
                )
                .contentShape(Rectangle())
                .onHover { hovering in
                  guard manager.currentMode != .shortcutMode else { return }
                  if hovering {
                    manager.hoveredIndex = globalIndex
                  } else if manager.hoveredIndex == globalIndex {
                    manager.hoveredIndex = nil
                  }
                }
                .onTapGesture {
                  guard manager.currentMode != .shortcutMode else { return }
                  let index = globalIndex
                  manager.Hide(animate: false) {
                    manager.activateSelectedWindow(index)
                  }
                }
              }
            }
            .frame(width: width)
          }
        }
      }
    }
    .padding(switcherSize.padding)
    .background(tm.currentTheme.backgroundColor.opacity(tm.currentTheme.backgroundColorOpacity))
    .background(tm.currentTheme.backgroundBlur > 0 ? SwiftBlurBackground(opacity: tm.currentTheme.backgroundBlur) : nil)
    .cornerRadius(8)
    .fixedSize()
  }
}
