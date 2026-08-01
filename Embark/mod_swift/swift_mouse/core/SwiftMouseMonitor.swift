import SwiftUI
import ApplicationServices

class SwiftMouseMonitor {
  static let s = SwiftMouseMonitor()
  private var dragState: SwiftMouseDragState = .idle
  private var mouseListener: MouseListener?
  private var targetWindow: WindowData?
  private var isSendingRightClickEvent: Bool = false

  private init() {}

  func Start() {
    startMouseMonitoring()
  }

  func Stop() {
    cleanup()
    cleanupMouseMonitoring()
  }

  private func startMouseMonitoring() {
    cleanupMouseMonitoring()
    mouseListener = InputEventManager.s.createMouseListener(eventTypes: [.rightDown, .rightDragged, .rightUp]) { [weak self] (type, event) -> Unmanaged<CGEvent>? in
      return self?.handleMouseEvent(type: type, event: event)
    }
  }

  private func cleanupMouseMonitoring() {
    if let listener = mouseListener {
      InputEventManager.s.unregisterListener(listener)
      mouseListener = nil
    }
  }

  private func handleMouseEvent(type: MouseEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
    let location = event.location
    switch type {
    case .rightDown:
      return handleRightMouseDown(at: location, event: event)
    case .rightDragged:
      return handleMouseDragged(to: location, event: event)
    case .rightUp:
      return handleRightMouseUp(at: location, event: event)
    default:
      return Unmanaged.passUnretained(event)
    }
  }

  private func handleMouseDragged(to point: CGPoint, event: CGEvent) -> Unmanaged<CGEvent>? {
    switch dragState {
    case .waiting(let startPoint, _):
      let distance = hypot(point.x - startPoint.x, point.y - startPoint.y)
      if distance >= SwiftMouseConfig.swiftMouseDistance {
        dragState = .dragging(startPoint: startPoint, currentPoint: point, path: [startPoint, point])
        SwiftMouseOverlayWin.s.show(at: startPoint)
        SwiftMouseOverlayWin.s.drawPath([startPoint, point])
      }
    case .dragging(let startPoint, _, let path):
      var newPath = path
      newPath.append(point)
      dragState = .dragging(startPoint: startPoint, currentPoint: point, path: newPath)
      SwiftMouseOverlayWin.s.drawPath(newPath)
      if SwitcherConfig.switcherMode == .switchMode && SwitcherConfig.switcher {
        if !SwitcherManager.s.isSwitcherVisible {
          let directions = analyzeDirections(path: newPath)
          if SwiftMouseConfig.swiftMouseSwitcher.matches(directions) {
            let lastDirection = directions.last?.rawValue
            SwitcherManager.s.ShowOrHide(animate: false, atMouse: true, point: point, direction: lastDirection)
          }
        } else {
          SwitcherManager.s.updateHover(at: point)
        }
      }
    case .idle:
      return Unmanaged.passUnretained(event)
    }
    return nil
  }

  private func handleRightMouseDown(at point: CGPoint, event: CGEvent) -> Unmanaged<CGEvent>? {
    if isSendingRightClickEvent {
      return Unmanaged.passUnretained(event)
    }
    NotificationCenter.default.post(name: NSNotification.Name("GestureStarted"), object: nil)
    targetWindow = WindowFind.FindWindowAtPoint(point)
    if let bundleId = targetWindow?.bundleIdentifier, SwiftMouseManager.s.isExcluded(bundleId: bundleId) {
      return Unmanaged.passUnretained(event)
    }
    dragState = .waiting(point: point, timestamp: ProcessInfo.processInfo.systemUptime)
    return nil
  }

  private func handleRightMouseUp(at point: CGPoint, event: CGEvent) -> Unmanaged<CGEvent>? {
    if isSendingRightClickEvent {
      return Unmanaged.passUnretained(event)
    }
    if SwitcherConfig.switcherMode == .switchMode && SwitcherManager.s.isSwitcherVisible {
      SwitcherManager.s.finishSwitchMode(at: point)
      SwiftMouseOverlayWin.s.hide()
      dragState = .idle
      return nil
    }
    switch dragState {
    case .waiting(_, _):
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) { [weak self] in
        self?.simulateRightClick(at: point, with: event.flags)
      }
    case .dragging(let startPoint, _, let path):
      SwiftMouseOverlayWin.s.hide()
      let directions = analyzeDirections(path: path)
      let distance = hypot(point.x - startPoint.x, point.y - startPoint.y)
      if distance >= SwiftMouseConfig.swiftMouseDistance || directions.count > 1 {
        if SwiftMouseConfig.swiftMouseMinimize.matches(directions) {
          NotificationCenter.default.post(name: NSNotification.Name("FunctionExecuted"), object: nil, userInfo: ["source": FeatureType.swift.title])
          SwiftManager.s.MinWindow(targetWindow: targetWindow)
        } else if SwiftMouseConfig.swiftMouseRestore.matches(directions) {
          NotificationCenter.default.post(name: NSNotification.Name("FunctionExecuted"), object: nil, userInfo: ["source": FeatureType.swift.title])
          SwiftManager.s.ReWindow()
        } else if SwiftMouseConfig.swiftMouseMaximize.matches(directions) {
          NotificationCenter.default.post(name: NSNotification.Name("FunctionExecuted"), object: nil, userInfo: ["source": FeatureType.swift.title])
          SwiftManager.s.MaxWindow(targetWindow: targetWindow, mode: SwiftMouseConfig.swiftMouseMaximizeMode)
        } else if SwiftMouseConfig.swiftMouseClose.matches(directions) {
          NotificationCenter.default.post(name: NSNotification.Name("FunctionExecuted"), object: nil, userInfo: ["source": FeatureType.swift.title])
          SwiftManager.s.CloseWindow(targetWindow: targetWindow, mode: SwiftMouseConfig.swiftMouseCloseMode)
        } else if SwiftMouseConfig.swiftMouseLauncher.matches(directions) {
          if LauncherConfig.launcher {
            NotificationCenter.default.post(name: NSNotification.Name("FunctionExecuted"), object: nil, userInfo: ["source": FeatureType.swift.title, "function": FeatureType.launcher.title])
            if DataManager.s.launcherMode == .search && LauncherWin.s.IsShow() {
              LauncherWin.s.Hide()
            } else {
              LauncherWin.s.ShowOrHide(mode: .launcher)
            }
          }
        } else if SwiftMouseConfig.swiftMouseSpace.matches(directions) {
          if SpaceConfig.space {
            NotificationCenter.default.post(name: NSNotification.Name("FunctionExecuted"), object: nil, userInfo: ["source": FeatureType.swift.title, "function": FeatureType.space.title])
            if DataManager.s.launcherMode == .search && LauncherWin.s.IsShow() {
              LauncherWin.s.Hide()
            } else {
              LauncherWin.s.ShowOrHide(mode: .space)
            }
          }
        } else if SwiftMouseConfig.swiftMouseFocus.matches(directions) {
          NotificationCenter.default.post(name: NSNotification.Name("FunctionExecuted"), object: nil, userInfo: ["source": FeatureType.swift.title])
          FocusConfig.focus.toggle()
          NotificationCenter.default.post(name: NSNotification.Name("FocusConfigChanged"), object: nil)
        } else if SwiftMouseConfig.swiftMouseSlide.matches(directions) {
          if SlideConfig.slide {
            NotificationCenter.default.post(name: NSNotification.Name("FunctionExecuted"), object: nil, userInfo: ["source": FeatureType.swift.title])
            SlideMonitor.s.ToggleDock(targetWindow: targetWindow)
          }
        } else if SwiftMouseConfig.swiftMouseSwitcher.matches(directions) {
          if SwitcherConfig.switcher {
            NotificationCenter.default.post(name: NSNotification.Name("FunctionExecuted"), object: nil, userInfo: ["source": FeatureType.swift.title])
            SwitcherManager.s.ShowOrHide(animate: false, atMouse: true, point: event.location)
          }
        } else {
          if let drawnGesture = SwiftMouseGesture.allCases.first(where: { $0.matches(directions) }) {
            if let linkId = SwiftMouseManager.s.getLinkForGesture(drawnGesture) {
              if let link = DataManager.s.linkData.values.first(where: { $0.id == linkId }) {
                NotificationCenter.default.post(name: NSNotification.Name("FunctionExecuted"), object: nil, userInfo: ["source": FeatureType.swift.title])
                Task {
                  _ = await DataManager.s.launchLinkWithValidation(path: link.path, linkName: link.name)
                }
              }
            }
          }
        }
      }
      dragState = .idle
      targetWindow = nil
    case .idle:
      return Unmanaged.passUnretained(event)
    }
    return nil
  }

  private func analyzeDirections(path: [CGPoint]) -> [SwiftMouseDirection] {
    guard path.count > 1 else { return [] }
    var rawSegments: [(dir: SwiftMouseDirection, length: CGFloat)] = []
    var lastPoint = path[0]
    for i in 1..<path.count {
      let point = path[i]
      let dist = hypot(point.x - lastPoint.x, point.y - lastPoint.y)
      if dist > SwiftMouseInfo.minSegmentLength {
        let dir = SwiftMouseDirection.from(deltaX: point.x - lastPoint.x, deltaY: point.y - lastPoint.y)
        if let lastIndex = rawSegments.indices.last, rawSegments[lastIndex].dir == dir {
          rawSegments[lastIndex].length += dist
        } else {
          rawSegments.append((dir, dist))
        }
        lastPoint = point
      }
    }
    let totalLength = rawSegments.reduce(0) { $0 + $1.length }
    let threshold = totalLength * SwiftMouseInfo.gestureIgnoreThreshold
    let absoluteThreshold = SwiftMouseConfig.swiftMouseDistance
    var filteredSegments = rawSegments.filter { $0.length >= threshold || $0.length >= absoluteThreshold }
    if filteredSegments.isEmpty && !rawSegments.isEmpty {
      if let maxSeg = rawSegments.max(by: { $0.length < $1.length }) {
        filteredSegments = [maxSeg]
      }
    }
    var directions: [SwiftMouseDirection] = []
    for seg in filteredSegments {
      if let last = directions.last {
        if last != seg.dir {
          directions.append(seg.dir)
        }
      } else {
        directions.append(seg.dir)
      }
    }
    return directions
  }

  private func simulateRightClick(at point: CGPoint, with flags: CGEventFlags) {
    isSendingRightClickEvent = true
    let rightDownEvent = CGEvent(mouseEventSource: nil, mouseType: .rightMouseDown, mouseCursorPosition: CGEvent(source: nil)?.location ?? point, mouseButton: .right)
    rightDownEvent?.flags = flags
    rightDownEvent?.post(tap: .cgSessionEventTap)
    let rightUpEvent = CGEvent(mouseEventSource: nil, mouseType: .rightMouseUp, mouseCursorPosition: CGEvent(source: nil)?.location ?? point, mouseButton: .right)
    rightUpEvent?.flags = flags
    rightUpEvent?.post(tap: .cgSessionEventTap)
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
      guard let self = self else { return }
      isSendingRightClickEvent = false
    }
  }

  private func cleanup() {
    SwiftMouseOverlayWin.s.hide()
    dragState = .idle
    isSendingRightClickEvent = false
  }
}
