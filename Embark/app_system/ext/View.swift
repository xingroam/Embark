import SwiftUI

struct Line: View {
  var body: some View {
    Rectangle()
      .fill(Color.secondary.opacity(0.1))
      .frame(height: 1)
  }
}

extension View {
  @ViewBuilder
  func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
    if condition {
      transform(self)
    } else {
      self
    }
  }

  func cardStyle(bg: Color = Color.secondary, padding: CGFloat = 10) -> some View {
    self
      .frame(maxWidth: .infinity)
      .padding(padding)
      .background(bg.opacity(0.05))
      .cornerRadius(6)
  }

  func panelStyle(padding: CGFloat = 15) -> some View {
    self
      .frame(maxWidth: .infinity)
      .padding(padding)
      .background(Color.secondary.opacity(0.05))
      .overlay(
        RoundedRectangle(cornerRadius: 6)
          .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
      )
      .cornerRadius(6)
  }

  func settingStyle() -> some View {
    self
      .frame(maxWidth: .infinity)
      .background(Color.secondary.opacity(0.05))
      .overlay(
        RoundedRectangle(cornerRadius: 6)
          .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
      )
      .cornerRadius(6)
  }

  func titleStyle(fz: CGFloat) -> some View {
    self
      .font(.system(size: fz))
      .frame(maxWidth: .infinity, alignment: .leading)
  }

  func nodeStyle(fz: CGFloat) -> some View {
    self
      .font(.system(size: fz - 2))
      .foregroundColor(.secondary)
  }

  // MARK: - 动画扩展

  /// 设置模式图标动画 (缩放+透明度)
  func settingsIconAnimation(_ isVisible: Bool, duration: Double = 0) -> some View {
    self
      .transition(AnyTransition.asymmetric(
        insertion: AnyTransition.scale.combined(with: AnyTransition.opacity),
        removal: AnyTransition.scale.combined(with: AnyTransition.opacity)
      ))
      .if(duration > 0) { view in
        view.animation(.easeInOut(duration: duration), value: isVisible)
      }
  }

  /// 面板滑入动画 (左侧滑入+透明度)
  func panelSlideAnimation(_ isVisible: Bool, duration: Double = 0) -> some View {
    self
      .transition(AnyTransition.asymmetric(
        insertion: AnyTransition.move(edge: .leading).combined(with: AnyTransition.opacity),
        removal: AnyTransition.move(edge: .leading).combined(with: AnyTransition.opacity)
      ))
      .if(duration > 0) { view in
        view.animation(.easeInOut(duration: duration), value: isVisible)
      }
  }

  /// 按钮悬停动画 (缩放效果)
  func hoverAnimation(_ isHovered: Bool, duration: Double = 0) -> some View {
    self
      .scaleEffect(isHovered ? 1.05 : 1.0)
      .if(duration > 0) { view in
        view.animation(.easeInOut(duration: duration), value: isHovered)
      }
  }

  /// 轻微悬停动画 (轻微缩放)
  func subtleHoverAnimation(_ isHovered: Bool, duration: Double = 0) -> some View {
    self
      .scaleEffect(isHovered ? 1.02 : 1.0)
      .if(duration > 0) { view in
        view.animation(.easeInOut(duration: duration), value: isHovered)
      }
  }

  /// 背景色渐变动画
  func backgroundTransitionAnimation<T: Equatable>(_ value: T, duration: Double = 0) -> some View {
    self
      .if(duration > 0) { view in
        view.animation(.easeInOut(duration: duration), value: value)
      }
  }

  /// 状态切换动画 (缩放+透明度+居中移动)
  func stateTransitionAnimation<T: Equatable>(_ value: T, duration: Double = 0) -> some View {
    self
      .transition(AnyTransition.asymmetric(
        insertion: AnyTransition.scale.combined(with: AnyTransition.opacity).combined(with: AnyTransition.move(edge: .top)),
        removal: AnyTransition.scale.combined(with: AnyTransition.opacity).combined(with: AnyTransition.move(edge: .top))
      ))
      .if(duration > 0) { view in
        view.animation(.easeInOut(duration: duration), value: value)
      }
  }
}
