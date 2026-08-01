import AppKit
import SwiftUI

public class ToastWin: @unchecked Sendable {
  static let s = ToastWin()

  private var panel: NSPanel?
  private var currentIsPersistent: Bool = false

  public enum ToastPosition {
    case topLeft(CGFloat)
    case topRight(CGFloat)
    case topCenter(CGFloat)
    case center
    case bottomLeft(CGFloat)
    case bottomRight(CGFloat)
    case bottomCenter(CGFloat)
  }

  public init() {}

  func IsWindow(_ wid: CGWindowID) -> Bool {
    var result = false
    if Thread.isMainThread {
      result = panel != nil && panel?.windowNumber == Int(wid)
    } else {
      DispatchQueue.main.sync {
        result = panel != nil && panel?.windowNumber == Int(wid)
      }
    }
    return result
  }

  @MainActor
  public func showToast(message: String, icon: Image? = nil, duration: TimeInterval? = nil, position: ToastPosition = .bottomCenter(100), isPersistent: Bool = false) {
    currentIsPersistent = isPersistent
    if panel == nil {
      let toastView = ToastView(message: message, icon: icon, panel: nil)
      let hostingView = NSHostingView(rootView: toastView)
      hostingView.frame = NSRect(x: 0, y: 0, width: 300, height: 50)
      panel = NSPanel(contentRect: hostingView.frame, styleMask: [.nonactivatingPanel], backing: .buffered, defer: false)
      if let panel = panel {
        panel.contentView = hostingView
        panel.isFloatingPanel = true
        panel.level = .popUpMenu
        panel.title = EmbarkInfo.name + "Toast"
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        panel.ignoresMouseEvents = false
        panel.hidesOnDeactivate = false
        panel.collectionBehavior = [.canJoinAllSpaces, .transient, .ignoresCycle]
      }
    }
    if let panel = panel, let hostingView = panel.contentView as? NSHostingView<ToastView> {
      hostingView.rootView = ToastView(message: message, icon: icon, panel: panel)
      hostingView.layoutSubtreeIfNeeded()
      let fittingSize = hostingView.fittingSize
      panel.setContentSize(fittingSize)
    }
    if let screenFrame = NSScreen.main?.visibleFrame, let panel = panel {
      let x: CGFloat
      let y: CGFloat
      switch position {
      case .topLeft(let offset):
        x = screenFrame.minX + offset
        y = screenFrame.maxY - panel.frame.height - offset
      case .topCenter(let offset):
        x = screenFrame.midX - panel.frame.width / 2
        y = screenFrame.maxY - panel.frame.height - offset
      case .topRight(let offset):
        x = screenFrame.maxX - panel.frame.width - offset
        y = screenFrame.maxY - panel.frame.height - offset
      case .center:
        x = screenFrame.midX - panel.frame.width / 2
        y = screenFrame.midY - panel.frame.height / 2
      case .bottomLeft(let offset):
        x = screenFrame.minX + offset
        y = screenFrame.minY + offset
      case .bottomCenter(let offset):
        x = screenFrame.midX - panel.frame.width / 2
        y = screenFrame.minY + offset
      case .bottomRight(let offset):
        x = screenFrame.maxX - panel.frame.width - offset
        y = screenFrame.minY + offset
      }
      panel.setFrameOrigin(NSPoint(x: x, y: y))
      panel.alphaValue = 0
      panel.orderFrontRegardless()
      let displayDuration = duration ?? 3
      let animateDuration = 0.05
      NSAnimationContext.runAnimationGroup({ context in
        context.duration = animateDuration
        context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        panel.animator().alphaValue = 1
      }, completionHandler: {
        if !isPersistent {
          DispatchQueue.main.asyncAfter(deadline: .now() + displayDuration) { [weak self] in
            guard let self = self else { return }
            if currentIsPersistent {
              return
            }
            NSAnimationContext.runAnimationGroup({ context in
              context.duration = animateDuration
              context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
              panel.animator().alphaValue = 0
            }, completionHandler: {
              panel.orderOut(nil)
            })
          }
        }
      })
    }
  }

  @MainActor
  public func hideToast() {
    if let panel = panel {
      let animateDuration = 0.05
      NSAnimationContext.runAnimationGroup({ context in
        context.duration = animateDuration
        context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        panel.animator().alphaValue = 0
      }, completionHandler: {
        panel.orderOut(nil)
      })
    }
  }
}
