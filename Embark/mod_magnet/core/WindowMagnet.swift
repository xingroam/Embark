import SwiftUI
import ApplicationServices

class WindowMagnet {
  static let s = WindowMagnet()
  var isMagnetEnabled: Bool {
    return MagnetConfig.magnet2x2 || MagnetConfig.magnet3x2 || MagnetConfig.magnet3x3 ||  MagnetConfig.magnet4x2 || MagnetConfig.magnet4x4 || MagnetConfig.magnet6x6 || MagnetConfig.magnet8x8 || MagnetConfig.magnet10x10 || MagnetConfig.magnet12x12
  }

  private init() {}

  func dragMagnet(for window: WindowData, targetScreen: NSScreen) -> DragMagnetResult {
    let effectiveFrame = getEffectiveScreenFrame(for: targetScreen)
    let referencePoints = calculateReferencePoints(for: effectiveFrame)
    let threshold = min(effectiveFrame.width, effectiveFrame.height) * MagnetInfo.magnetThreshold
    let topLeftPoint = window.bounds.origin
    let bottomRightPoint = CGPoint(x: window.bounds.origin.x + window.bounds.size.width, y: window.bounds.origin.y + window.bounds.size.height)
    var targetPosition = window.bounds.origin
    var shouldSnap = false
    let topLeftSnapX = checkSnapUnified(topLeftPoint.x, referencePoints: referencePoints.x, threshold: threshold)
    let bottomRightSnapX = checkSnapUnified(bottomRightPoint.x, referencePoints: referencePoints.x, threshold: threshold)
    if topLeftSnapX.shouldSnap || bottomRightSnapX.shouldSnap {
      shouldSnap = true
      targetPosition.x = topLeftSnapX.shouldSnap ? topLeftSnapX.targetPosition : bottomRightSnapX.targetPosition - window.bounds.size.width
    }
    let topLeftSnapY = checkSnapUnified(topLeftPoint.y, referencePoints: referencePoints.y, threshold: threshold)
    let bottomRightSnapY = checkSnapUnified(bottomRightPoint.y, referencePoints: referencePoints.y, threshold: threshold)
    if topLeftSnapY.shouldSnap || bottomRightSnapY.shouldSnap {
      shouldSnap = true
      targetPosition.y = topLeftSnapY.shouldSnap ? topLeftSnapY.targetPosition : bottomRightSnapY.targetPosition - window.bounds.size.height
    }
    return DragMagnetResult(targetPosition: targetPosition, shouldSnap: shouldSnap)
  }

  func resizeMagnet(for window: WindowData, targetScreen: NSScreen) -> ResizeMagnetResult {
    let effectiveFrame = getEffectiveScreenFrame(for: targetScreen)
    let referencePoints = calculateReferencePoints(for: effectiveFrame)
    let threshold = min(effectiveFrame.width, effectiveFrame.height) * MagnetInfo.magnetThreshold
    var shouldSnapX = false
    var shouldSnapY = false
    var targetWidth = window.bounds.size.width
    var targetHeight = window.bounds.size.height
    let windowRightX = window.bounds.origin.x + window.bounds.size.width
    let rightSnapX = checkSnapUnified(windowRightX, referencePoints: referencePoints.x, threshold: threshold)
    if rightSnapX.shouldSnap {
      shouldSnapX = true
      targetWidth = rightSnapX.targetPosition - window.bounds.origin.x
    }
    let windowBottomY = window.bounds.origin.y + window.bounds.size.height
    let bottomSnapY = checkSnapUnified(windowBottomY, referencePoints: referencePoints.y, threshold: threshold)
    if bottomSnapY.shouldSnap {
      shouldSnapY = true
      targetHeight = bottomSnapY.targetPosition - window.bounds.origin.y
    }
    return ResizeMagnetResult(targetSize: CGSize(width: targetWidth, height: targetHeight), shouldSnapX: shouldSnapX, shouldSnapY: shouldSnapY, shouldSnap: shouldSnapX || shouldSnapY)
  }

  func applyDragMagnetResult(_ result: DragMagnetResult, to window: WindowData) {
    guard result.shouldSnap else { return }
    SwiftManager.s.moveWindow(wi: window, to: result.targetPosition)
  }

  private func calculateReferencePoints(for frame: CGRect) -> ReferencePoints {
    let leftX = frame.minX
    let rightX = frame.maxX
    let topY = frame.maxY
    let bottomY = frame.minY
    var xReferencePoints: [CGFloat] = [leftX, rightX]
    var yReferencePoints: [CGFloat] = [topY, bottomY]
    // 1/2 分割线
    if MagnetConfig.magnet2x2 || MagnetConfig.magnet4x2 || MagnetConfig.magnet4x4 || MagnetConfig.magnet6x6 || MagnetConfig.magnet8x8 || MagnetConfig.magnet10x10 || MagnetConfig.magnet12x12 {
      xReferencePoints.append(leftX + frame.width / 2)
    }
    if MagnetConfig.magnet2x2 || MagnetConfig.magnet3x2 || MagnetConfig.magnet4x2 || MagnetConfig.magnet4x4 || MagnetConfig.magnet6x6 || MagnetConfig.magnet8x8 || MagnetConfig.magnet10x10 || MagnetConfig.magnet12x12 {
      yReferencePoints.append(bottomY + frame.height / 2)
    }
    // 1/3, 2/3 分割线
    if MagnetConfig.magnet3x2 || MagnetConfig.magnet3x3 || MagnetConfig.magnet6x6 || MagnetConfig.magnet12x12 {
      xReferencePoints.append(contentsOf: [leftX + frame.width / 3, leftX + frame.width * 2 / 3])
    }
    if MagnetConfig.magnet3x3 || MagnetConfig.magnet6x6 || MagnetConfig.magnet12x12 {
      yReferencePoints.append(contentsOf: [bottomY + frame.height / 3, bottomY + frame.height * 2 / 3])
    }
    // 1/4, 3/4 分割线
    if MagnetConfig.magnet4x2 || MagnetConfig.magnet4x4 || MagnetConfig.magnet8x8 || MagnetConfig.magnet12x12 {
      xReferencePoints.append(contentsOf: [leftX + frame.width / 4, leftX + frame.width * 3 / 4])
    }
    if MagnetConfig.magnet4x4 || MagnetConfig.magnet8x8 || MagnetConfig.magnet12x12 {
      yReferencePoints.append(contentsOf: [bottomY + frame.height / 4, bottomY + frame.height * 3 / 4])
    }
    // 1/6, 5/6 分割线
    if MagnetConfig.magnet6x6 || MagnetConfig.magnet12x12 {
      xReferencePoints.append(contentsOf: [leftX + frame.width / 6, leftX + frame.width * 5 / 6])
      yReferencePoints.append(contentsOf: [bottomY + frame.height / 6, bottomY + frame.height * 5 / 6])
    }
    // 8x8 特有: 1/8, 3/8, 5/8, 7/8
    if MagnetConfig.magnet8x8 {
      xReferencePoints.append(contentsOf: [leftX + frame.width / 8, leftX + frame.width * 3 / 8, leftX + frame.width * 5 / 8, leftX + frame.width * 7 / 8])
      yReferencePoints.append(contentsOf: [bottomY + frame.height / 8, bottomY + frame.height * 3 / 8, bottomY + frame.height * 5 / 8, bottomY + frame.height * 7 / 8])
    }
    // 10x10 特有: 1/10, 2/10, 3/10, 4/10, 6/10, 7/10, 8/10, 9/10 (1/2已复用)
    if MagnetConfig.magnet10x10 {
      xReferencePoints.append(contentsOf: [leftX + frame.width / 10, leftX + frame.width * 2 / 10, leftX + frame.width * 3 / 10, leftX + frame.width * 4 / 10, leftX + frame.width * 6 / 10, leftX + frame.width * 7 / 10, leftX + frame.width * 8 / 10, leftX + frame.width * 9 / 10])
      yReferencePoints.append(contentsOf: [bottomY + frame.height / 10, bottomY + frame.height * 2 / 10, bottomY + frame.height * 3 / 10, bottomY + frame.height * 4 / 10, bottomY + frame.height * 6 / 10, bottomY + frame.height * 7 / 10, bottomY + frame.height * 8 / 10, bottomY + frame.height * 9 / 10])
    }
    // 12x12 特有: 1/12, 5/12, 7/12, 11/12 (1/2, 1/3, 2/3, 1/4, 3/4, 1/6, 5/6 已复用)
    if MagnetConfig.magnet12x12 {
      xReferencePoints.append(contentsOf: [leftX + frame.width / 12, leftX + frame.width * 5 / 12, leftX + frame.width * 7 / 12, leftX + frame.width * 11 / 12])
      yReferencePoints.append(contentsOf: [bottomY + frame.height / 12, bottomY + frame.height * 5 / 12, bottomY + frame.height * 7 / 12, bottomY + frame.height * 11 / 12])
    }
    return ReferencePoints(x: Array(Set(xReferencePoints)).sorted(), y: Array(Set(yReferencePoints)).sorted())
  }

  private func checkSnapUnified(_ windowValue: CGFloat, referencePoints: [CGFloat], threshold: CGFloat) -> (targetPosition: CGFloat, shouldSnap: Bool) {
    for referencePoint in referencePoints {
      if abs(windowValue - referencePoint) <= threshold {
        return (referencePoint, true)
      }
    }
    return (windowValue, false)
  }

  private func getEffectiveScreenFrame(for screen: NSScreen) -> CGRect {
    let visibleFrame = screen.visibleFrame
    let effectiveOrigin = CGPoint(
      x: visibleFrame.origin.x,
      y: screen.frame.maxY - visibleFrame.maxY
    )
    return CGRect(origin: effectiveOrigin, size: visibleFrame.size)
  }
}
