import SwiftUI
import AppKit

class Tooltip {
  static let s = Tooltip()
  private var tooltipWindow: NSWindow?
  private var showTimer: Timer?

  private init() {}

  func IsWindow(_ wid: CGWindowID) -> Bool {
    var result = false
    if Thread.isMainThread {
      result = tooltipWindow != nil && tooltipWindow?.windowNumber == Int(wid)
    } else {
      DispatchQueue.main.sync {
        result = tooltipWindow != nil && tooltipWindow?.windowNumber == Int(wid)
      }
    }
    return result
  }

  func Show(text: String, sourceFrameInWindow: NSRect, windowFrameOnScreen: NSRect, edge: TooltipEdge, delay: TimeInterval, animationDuration: TimeInterval, fontSize: CGFloat) {
    showTimer?.invalidate()
    showTimer = nil
    showTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
      self?.showImmediate(text: text, sourceFrameInWindow: sourceFrameInWindow, windowFrameOnScreen: windowFrameOnScreen, edge: edge, animationDuration: animationDuration, fontSize: fontSize)
    }
  }

  func Hide() {
    showTimer?.invalidate()
    showTimer = nil
    DispatchQueue.main.async { [weak self] in
      self?.hideImmediate(animationDuration: 0)
    }
  }

  func Hide(animationDuration: TimeInterval) {
    showTimer?.invalidate()
    showTimer = nil
    DispatchQueue.main.async { [weak self] in
      self?.hideImmediate(animationDuration: animationDuration)
    }
  }

  private func showImmediate(text: String, sourceFrameInWindow: NSRect, windowFrameOnScreen: NSRect, edge: TooltipEdge, animationDuration: TimeInterval, fontSize: CGFloat) {
    DispatchQueue.main.async { [weak self] in
      self?.hideImmediate(animationDuration: 0)
      guard NSScreen.main != nil else { return }
      let tooltipView = TooltipContentView(text: text, fontSize: fontSize)
      let hostingView = NSHostingView(rootView: tooltipView)
      let size = hostingView.fittingSize
      hostingView.frame = NSRect(origin: .zero, size: size)
      let buttonYFromBottom = windowFrameOnScreen.height - sourceFrameInWindow.origin.y - sourceFrameInWindow.height
      let buttonScreenFrame = NSRect(
        x: windowFrameOnScreen.origin.x + sourceFrameInWindow.origin.x,
        y: windowFrameOnScreen.origin.y + buttonYFromBottom,
        width: sourceFrameInWindow.width,
        height: sourceFrameInWindow.height
      )
      var windowOrigin: NSPoint
      switch edge {
      case .left:
        windowOrigin = NSPoint(
          x: buttonScreenFrame.minX - size.width - 6,
          y: buttonScreenFrame.midY - size.height / 2,
        )
      case .right:
        windowOrigin = NSPoint(
          x: buttonScreenFrame.maxX + 6,
          y: buttonScreenFrame.midY - size.height / 2,
        )
      case .top:
        windowOrigin = NSPoint(
          x: buttonScreenFrame.midX - size.width / 2,
          y: buttonScreenFrame.maxY + 6,
        )
      case .bottom:
        windowOrigin = NSPoint(
          x: buttonScreenFrame.midX - size.width / 2,
          y: buttonScreenFrame.minY - size.height - 6,
        )
      }
      let window = NSWindow(contentRect: NSRect(origin: windowOrigin, size: size), styleMask: [.borderless], backing: .buffered, defer: false)
      window.contentView = hostingView
      window.backgroundColor = .clear
      window.isOpaque = false
      window.level = .popUpMenu
      window.ignoresMouseEvents = true
      window.hasShadow = false
      window.collectionBehavior = [.canJoinAllSpaces, .stationary]
      window.isReleasedWhenClosed = false
      window.alphaValue = 0
      window.titlebarAppearsTransparent = true
      window.titleVisibility = .hidden
      self?.tooltipWindow = window
      window.orderFront(nil)
      NSAnimationContext.runAnimationGroup({ context in
        context.duration = animationDuration
        window.animator().alphaValue = 1.0
      })
    }
  }

  private func hideImmediate(animationDuration: TimeInterval) {
    guard let window = tooltipWindow else { return }
    if animationDuration > 0 {
      NSAnimationContext.runAnimationGroup({ context in
        context.duration = animationDuration
        window.animator().alphaValue = 0
      }, completionHandler: { [weak self] in
        window.orderOut(nil)
        self?.tooltipWindow = nil
      })
    } else {
      window.orderOut(nil)
      tooltipWindow = nil
    }
  }
}

struct TooltipContentView: View {
  let text: String
  let fontSize: CGFloat

  var body: some View {
    Text(text)
      .font(.system(size: fontSize))
      .fixedSize()
      .padding(.horizontal, 8)
      .padding(.vertical, 4)
      .background(
        RoundedRectangle(cornerRadius: 5)
          .fill(Color(NSColor.controlBackgroundColor))
          .shadow(color: Color.black.opacity(0.2), radius: 2, x: 0, y: 1)
      )
      .foregroundColor(Color.primary)
  }
}

enum TooltipEdge {
  case left, right, top, bottom
}

struct TooltipModifier: ViewModifier {
  let text: String
  let edge: TooltipEdge
  let coordinateSpaceName: String
  let getWindowFrame: () -> NSRect?
  let delay: TimeInterval
  let animationDuration: TimeInterval
  let fontSize: CGFloat
  @State private var isHovering = false
  @State private var currentFrame: NSRect = .zero

  func body(content: Content) -> some View {
    content
      .background(
        GeometryReader { geometry in
          Color.clear.preference(
            key: FramePreferenceKey.self,
            value: geometry.frame(in: .named(coordinateSpaceName))
          )
        }
      )
      .onPreferenceChange(FramePreferenceKey.self) { frame in
        currentFrame = frame
      }
      .onHover { hovering in
        isHovering = hovering
        if hovering, let windowFrame = getWindowFrame() {
          Tooltip.s.Show(text: text, sourceFrameInWindow: currentFrame, windowFrameOnScreen: windowFrame, edge: edge, delay: delay, animationDuration: animationDuration, fontSize: fontSize)
        } else {
          Tooltip.s.Hide(animationDuration: animationDuration)
        }
      }
  }
}

struct FramePreferenceKey: PreferenceKey {
  static var defaultValue: NSRect = .zero

  static func reduce(value: inout NSRect, nextValue: () -> NSRect) {
    value = nextValue()
  }
}

extension View {
  func tooltip(
    _ text: String,
    edge: TooltipEdge = .top,
    coordinateSpaceName: String,
    delay: TimeInterval = 0.3,
    animationDuration: TimeInterval = 0.1,
    fontSize: CGFloat = 11,
    getWindowFrame: @escaping () -> NSRect?
  ) -> some View {
    self.modifier(TooltipModifier(text: text, edge: edge, coordinateSpaceName: coordinateSpaceName, getWindowFrame: getWindowFrame, delay: delay, animationDuration: animationDuration, fontSize: fontSize))
  }
}

struct ConditionalTooltip: ViewModifier {
  let show: Bool
  let text: String
  let edge: TooltipEdge
  let coordinateSpaceName: String
  let getWindowFrame: () -> NSRect?
  let delay: TimeInterval
  let animationDuration: TimeInterval
  let fontSize: CGFloat

  init(show: Bool, text: String, edge: TooltipEdge = .top, coordinateSpaceName: String, delay: TimeInterval = 0.3, animationDuration: TimeInterval = 0.1, fontSize: CGFloat = 11, getWindowFrame: @escaping () -> NSRect?) {
    self.show = show
    self.text = text
    self.edge = edge
    self.coordinateSpaceName = coordinateSpaceName
    self.getWindowFrame = getWindowFrame
    self.delay = delay
    self.animationDuration = animationDuration
    self.fontSize = fontSize
  }

  func body(content: Content) -> some View {
    if show {
      content.tooltip(text, edge: edge, coordinateSpaceName: coordinateSpaceName, delay: delay, animationDuration: animationDuration, fontSize: fontSize, getWindowFrame: getWindowFrame)
    } else {
      content
    }
  }
}
