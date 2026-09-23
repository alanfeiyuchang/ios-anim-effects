import SwiftUI

extension Effect {
    static let gesturesFling = Effect(
        id: "gestures.fling-inertia",
        category: .gestures,
        interaction: .gesture,
        name: L("Fling & Wall Bounce", "惯性甩动与撞墙反弹"),
        summary: L("Throw a puck; it glides with real momentum and ricochets off the walls.", "甩出圆球，带着真实惯性滑行并在四壁间反弹。"),
        prompt: L(
            "A glossy 64 pt puck (mint-to-sky gradient, inner highlight, coloured drop shadow) sits inside a 290 pt rounded arena with a subtle dot grid. The puck follows the finger 1:1 and swells to 108% while held. On release, the lift-off velocity is projected forward (distance = v × glide factor) and the puck decelerates along that line on an ease-out curve whose initial slope matches the release speed, so there is no jump in velocity. Whenever the projected path crosses a wall it is mirrored, producing perfectly elastic ricochets that keep decaying until rest after 1–2 s. Motion is continuous and physical: a hard flick bounces several times, a gentle toss barely drifts.",
            "一个 64pt 的光泽圆球（薄荷绿到天蓝渐变、内高光、同色投影）置于 290pt 的圆角场地中，场地铺有淡淡的点阵。按住时圆球 1:1 跟手并放大到 108%。松手后，将离手速度向前投影（距离 = 速度 × 滑行系数），圆球沿该方向以 ease-out 曲线减速，曲线初始斜率与离手速度一致，速度衔接毫无跳变。投影路径每次越过墙壁都做镜像折返，形成完全弹性的反弹，并在 1–2 秒内逐渐衰减至静止。轻甩只滑出一小段，重甩则会连续撞墙数次，运动连贯而真实。"
        ),
        implementation: L(
            "The unfolded end point is animated with a timing curve whose first control point matches the release velocity; an Animatable modifier folds that coordinate into the arena with a triangle wave, which yields the wall bounces.",
            "用初始斜率与离手速度匹配的 timingCurve 动画驱动“展开后”的终点坐标；自定义 Animatable 修饰器用三角波把坐标折叠回场地内，自然得到撞墙反弹。"
        ),
        apis: ["DragGesture.Value.velocity", "Animatable", "ViewModifier", "timingCurve"],
        tags: ["fling", "inertia", "momentum", "bounce", "velocity", "惯性", "甩动", "反弹", "动量"],
        params: [
            .slider("glide", L("Glide factor", "滑行系数"), 0.15...0.6, default: 0.3),
            .slider("size", L("Puck size", "圆球尺寸"), 44...90, default: 64, step: 1, decimals: 0, unit: "pt"),
        ]
    ) { ctx in
        FlingDemo(ctx: ctx)
    }
}

private func fold(_ value: CGFloat, _ length: CGFloat) -> CGFloat {
    guard length > 0 else { return 0 }
    let period = length * 2
    var m = value.truncatingRemainder(dividingBy: period)
    if m < 0 { m += period }
    return m <= length ? m : period - m
}

/// Folds an unbounded coordinate into [0, bounds] so a straight path becomes wall bounces.
private struct FoldedOffset: ViewModifier, Animatable {
    var x: CGFloat
    var y: CGFloat
    let bounds: CGSize

    var animatableData: AnimatablePair<CGFloat, CGFloat> {
        get { AnimatablePair(x, y) }
        set {
            x = newValue.first
            y = newValue.second
        }
    }

    func body(content: Content) -> some View {
        content.offset(x: fold(x, bounds.width), y: fold(y, bounds.height))
    }
}

private struct FlingDemo: View {
    let ctx: DemoContext
    @State private var position = CGPoint(x: 113, y: 113)
    @State private var dragStart: CGPoint?
    @State private var isDragging = false

    private let arena: CGFloat = 290

    var body: some View {
        let puck = ctx.cg("size")
        let bounds = CGSize(width: arena - puck, height: arena - puck)

        VStack(spacing: 14) {
            ZStack(alignment: .topLeading) {
                ArenaBackground()
                PuckView(isDragging: isDragging)
                    .frame(width: puck, height: puck)
                    .modifier(FoldedOffset(x: position.x, y: position.y, bounds: bounds))
                    .gesture(dragGesture(bounds: bounds))
            }
            .frame(width: arena, height: arena)
            DemoHint(text: L("Flick the puck", "甩动圆球"), ctx: ctx)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 2.4, delay: 0.3) { randomFling(bounds: bounds) }
    }

    private func dragGesture(bounds: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                let start = dragStart ?? CGPoint(x: fold(position.x, bounds.width), y: fold(position.y, bounds.height))
                if dragStart == nil {
                    dragStart = start
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) { isDragging = true }
                }
                position = CGPoint(
                    x: (start.x + value.translation.width).clamped(to: 0...bounds.width),
                    y: (start.y + value.translation.height).clamped(to: 0...bounds.height)
                )
            }
            .onEnded { value in
                dragStart = nil
                fling(velocity: value.velocity)
            }
    }

    private func fling(velocity: CGSize) {
        let glide = ctx["glide"]
        let vx = Double(velocity.width).clamped(to: -4000...4000)
        let vy = Double(velocity.height).clamped(to: -4000...4000)
        // The curve's first control point has slope 0.72 / 0.12 = 6, so duration = 6 × glide keeps the
        // initial animated speed equal to the release speed.
        let duration = max(glide * 6, 0.3)
        withAnimation(.timingCurve(0.12, 0.72, 0.18, 1, duration: duration)) {
            position = CGPoint(x: position.x + CGFloat(vx * glide), y: position.y + CGFloat(vy * glide))
            isDragging = false
        }
        if !ctx.isPreview && hypot(vx, vy) > 600 { Haptics.tap(.light) }
    }

    private func randomFling(bounds: CGSize) {
        position = CGPoint(x: fold(position.x, bounds.width), y: fold(position.y, bounds.height))
        let angle = Double.random(in: 0..<(2 * Double.pi))
        let speed = Double.random(in: 1400...2600)
        fling(velocity: CGSize(width: cos(angle) * speed, height: sin(angle) * speed))
    }
}

private struct ArenaBackground: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 34, style: .continuous)
            .fill(Palette.elevated)
            .overlay {
                Canvas { context, size in
                    let spacing: CGFloat = 22
                    var y = spacing / 2
                    while y < size.height {
                        var x = spacing / 2
                        while x < size.width {
                            context.fill(Path(ellipseIn: CGRect(x: x - 1, y: y - 1, width: 2, height: 2)), with: .color(.primary.opacity(0.12)))
                            x += spacing
                        }
                        y += spacing
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 34, style: .continuous))
            }
            .overlay(RoundedRectangle(cornerRadius: 34, style: .continuous).strokeBorder(Palette.stroke, lineWidth: 1))
            .shadow(color: .black.opacity(0.08), radius: 16, y: 8)
    }
}

private struct PuckView: View {
    let isDragging: Bool

    var body: some View {
        Circle()
            .fill(LinearGradient(colors: [Palette.mint, Palette.sky], startPoint: .topLeading, endPoint: .bottomTrailing))
            .overlay {
                Circle()
                    .fill(LinearGradient(colors: [.white.opacity(0.55), .clear], startPoint: .top, endPoint: .center))
                    .padding(5)
            }
            .overlay(Circle().strokeBorder(.white.opacity(0.35), lineWidth: 1))
            .shadow(color: Palette.sky.opacity(isDragging ? 0.55 : 0.35), radius: isDragging ? 18 : 10, y: isDragging ? 10 : 5)
            .scaleEffect(isDragging ? 1.08 : 1)
    }
}
