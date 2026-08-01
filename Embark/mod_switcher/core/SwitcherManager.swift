import Cocoa
import Carbon

class SwitcherManager: ObservableObject {
  static let s = SwitcherManager()
  @Published var selectedIndex = 0
  @Published var windows: [SwitcherWindowInfo] = []
  @Published var hoveredIndex: Int? = nil
  @Published var direction: String? = nil
  var itemFrames: [Int: CGRect] = [:]
  var currentMode: SwitcherMode = .selectMode
  var ignoreInitialHover = false
  var initialMouseLocation: CGPoint?
  var isLoading: Bool = false
  private var shouldAnimate: Bool = false
  private var currentLoadUUID: UUID?
  private var pendingFinish: Bool = false

  var isSwitcherVisible: Bool {
    return SwitcherWin.s.IsVisible()
  }

  private init() {}

  func ShowOrHide(animate: Bool, atMouse: Bool = false, forceSelectMode: Bool = false, point: CGPoint? = nil, direction: String? = nil) {
    if isSwitcherVisible {
      Hide()
    } else {
      if isLoading { return }
      let configMode = SwitcherConfig.switcherMode
      let mode: SwitcherMode = forceSelectMode ? .selectMode : (configMode == .selectMode ? .selectMode : .switchMode)
      let sortByMRU = false
      let autoSelect = (configMode == .switchMode) && !forceSelectMode && !atMouse
      self.shouldAnimate = animate
      showSwitcher(animate: animate, mode: mode, sortByMRU: sortByMRU, atMouse: atMouse, autoSelect: autoSelect, point: point, direction: direction)
    }
  }

  func Hide(animate: Bool? = nil, completion: (() -> Void)? = nil) {
    isLoading = false
    currentLoadUUID = nil
    pendingFinish = false
    SwitcherWin.s.Close(animate: animate ?? self.shouldAnimate, completion: completion)
    selectedIndex = -1
    hoveredIndex = nil
  }

  func showSwitcher(animate: Bool, mode: SwitcherMode, sortByMRU: Bool, atMouse: Bool, autoSelect: Bool, point: CGPoint? = nil, direction: String? = nil) {
    if isLoading { return }
    isLoading = true
    pendingFinish = false
    let uuid = UUID()
    self.currentLoadUUID = uuid
    self.currentMode = mode
    self.hoveredIndex = nil
    DispatchQueue.global(qos: .userInteractive).async {
      let windows = SwitcherWindowUtil.getAllWindows(sortByZOrder: sortByMRU)
      DispatchQueue.main.async {
        self.isLoading = false
        guard self.currentLoadUUID == uuid else { return }
        self.itemFrames.removeAll()
        self.windows = windows
        self.direction = direction
        if atMouse {
          self.selectedIndex = -1
          self.ignoreInitialHover = true
          self.initialMouseLocation = point ?? CGEvent(source: nil)?.location
        } else if autoSelect && !self.windows.isEmpty {
          self.selectedIndex = min(1, self.windows.count - 1)
          self.ignoreInitialHover = false
        } else {
          self.selectedIndex = -1
          self.ignoreInitialHover = false
        }
        if self.pendingFinish {
          let index = self.selectedIndex
          self.Hide(animate: false) {
            self.activateSelectedWindow(index)
          }
          return
        }
        SwitcherWin.s.Open(atMouse: atMouse, mouseLocation: point, animate: animate, direction: direction)
      }
    }
  }

  func finishSwitchMode(at point: CGPoint? = nil) {
    if isLoading {
      pendingFinish = true
      return
    }
    if let point = point, let index = calculateHoverIndex(at: point) {
      selectedIndex = index
    } else if let hovered = hoveredIndex {
      selectedIndex = hovered
    }
    let index = selectedIndex
    Hide(animate: false) {
      self.activateSelectedWindow(index)
    }
  }

  func activateSelectedWindow(_ index: Int? = nil) {
    let idx = index ?? selectedIndex
    guard idx >= 0 && idx < windows.count else { return }
    let window = windows[idx]
    let wd = WindowData(pid: window.ownerPID, wid: window.id, app: window.ownerName, bounds: window.frame, element: window.element, title: window.name, isMinimized: window.isMinimized, isTimeout: window.isTimeout)
    SwiftManager.s.ActivateWindow(wi: wd)
  }

  func updateItemFrame(index: Int, frame: CGRect) {
    itemFrames[index] = frame
  }

  func updateHover(at point: CGPoint) {
    if !Thread.isMainThread {
      DispatchQueue.main.async {
        self.updateHover(at: point)
      }
      return
    }
    let index = calculateHoverIndex(at: point)
    if hoveredIndex != index {
      self.hoveredIndex = index
    }
  }

  private func calculateHoverIndex(at point: CGPoint) -> Int? {
    guard let window = SwitcherWin.s.getWindow() else { return nil }
    let primaryScreenHeight = NSScreen.screens.first?.frame.height ?? NSScreen.main?.frame.height ?? 0
    let windowFrame = window.frame
    let windowY_TopLeft = primaryScreenHeight - (windowFrame.origin.y + windowFrame.height)
    let windowOrigin_TopLeft = CGPoint(x: windowFrame.origin.x, y: windowY_TopLeft)
    let pointInWindow = CGPoint(x: point.x - windowOrigin_TopLeft.x, y: point.y - windowOrigin_TopLeft.y)
    let tolerance: CGFloat = 5.0
    for (index, frame) in itemFrames {
      let expandedFrame = frame.insetBy(dx: -tolerance, dy: -tolerance)
      if expandedFrame.contains(pointInWindow) {
        return index
      }
    }
    return nil
  }
}
