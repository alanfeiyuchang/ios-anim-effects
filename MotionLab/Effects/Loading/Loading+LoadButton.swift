import SwiftUI

extension Effect {
    static let loadingLoadButton = Effect(
        id: "loading.load-button",
        category: .loading,
        interaction: .tap,
        name: L("Load Button", "加载按钮"),
        summary: L("A pill that collapses into a spinner, then blooms into a success check.", "胶囊按钮收缩成旋转圆环，再绽放为成功对勾。"),
        prompt: L(
            "A 240×58 pt pill button with an indigo-to-violet gradient, a bold label and a trailing arrow. On tap it dips to 96%, then its width springs down into a 58 pt circle (response ≈0.5 s, damping 0.75) while the label blurs, fades and shrinks to 80%; a white 260° arc with a transparent comet tail scales in at the center and spins once every 0.9 s. When the work finishes, the fill cross-fades to green, the circle pops 86% → 114% → 100% on a bouncy spring, a thin green ring radiates out to 190% while fading, and a rounded checkmark draws itself in 0.35 s with a success haptic. After a 1.3 s hold the circle springs back into the full pill. It must read as one object changing state — continuous, confident and physical.",
            "一枚 240×58 pt 的胶囊主按钮，靛蓝到紫罗兰渐变，粗体文字后跟一个箭头。点击时先按压到 96%，随后宽度以弹簧（响应约 0.5 秒、阻尼 0.75）收拢成 58 pt 的正圆，文字同时模糊、淡出并缩小到 80%；圆心处缩放浮现一段 260° 的白色圆弧，尾部渐隐如彗星，每 0.9 秒匀速旋转一圈。任务完成时底色渐变为绿色，圆形沿弹性曲线“啵”地弹一下（86% → 114% → 100%），一圈细绿光环向外扩散到 190% 并消散，圆角对勾在 0.35 秒内被一笔画出，伴随成功触感。停留 1.3 秒后，圆形弹性舒展回完整胶囊。全程必须像同一个物体在连续变形，而非切换视图——连贯、笃定、有物理感。"
        ),
        implementation: L(
            "A three-phase state drives the capsule's frame width, a cross-faded green layer and a trimmed check path; a TimelineView spins the arc and a keyframeAnimator plays the success pop and ring.",
            "三段状态驱动胶囊宽度、绿色叠层的交叉淡入与对勾路径的 trim；TimelineView 负责圆弧旋转，keyframeAnimator 播放成功时的弹跳与光环。"
        ),
        apis: ["frame(width:height:)", "trim(from:to:)", "keyframeAnimator", "TimelineView", "AngularGradient"],
        tags: ["loading", "submit", "success", "spinner", "state button", "加载", "提交", "成功", "状态按钮"],
        params: [
            .slider("duration", L("Loading time", "加载时长"), 0.6...4, default: 1.8, decimals: 1, unit: "s"),
            .slider("response", L("Spring response", "弹簧响应"), 0.2...1.0, default: 0.5, unit: "s"),
            .slider("damping", L("Damping", "阻尼"), 0.4...1.0, default: 0.75),
            .toggle("ring", L("Success ring", "成功光环"), default: true),
        ]
    ) { ctx in
        LoadButtonDemo(ctx: ctx)
    }
}

private enum LoadPhase: Equatable {
    case idle
    case loading
    case success
}

private struct LoadPop {
    var scale: CGFloat = 1
    var ring: CGFloat = 1
    var ringOpacity: Double = 0
}

private struct LoadButtonDemo: View {
    let ctx: DemoContext
    @State private var phase: LoadPhase = .idle
    @State private var successCount = 0

    var body: some View {
        let showRing = ctx.bool("ring")
        VStack(spacing: 30) {
            Button(action: start) {
                LoadButtonFace(phase: phase, title: ctx.language == .zh ? "提交订单" : "Place Order")
            }
            .buttonStyle(LoadButtonPressStyle())
            .keyframeAnimator(initialValue: LoadPop(), trigger: successCount) { content, pop in
                content
                    .scaleEffect(pop.scale)
                    .background {
                        Circle()
                            .stroke(Palette.green, lineWidth: 2)
                            .frame(width: 58, height: 58)
                            .scaleEffect(pop.ring)
                            .opacity(showRing ? pop.ringOpacity : 0)
                    }
            } keyframes: { _ in
                KeyframeTrack(\.scale) {
                    CubicKeyframe(0.86, duration: 0.1)
                    CubicKeyframe(1.14, duration: 0.16)
                    SpringKeyframe(1.0, duration: 0.5, spring: .bouncy)
                }
                KeyframeTrack(\.ring) {
                    MoveKeyframe(1.0)
                    CubicKeyframe(1.9, duration: 0.7)
                }
                KeyframeTrack(\.ringOpacity) {
                    MoveKeyframe(0.8)
                    CubicKeyframe(0, duration: 0.7)
                }
            }
            DemoHint(text: L("Tap the button", "点击按钮"), ctx: ctx)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: ctx["duration"] + 3.0, delay: 0.5) { start() }
    }

    private func start() {
        guard phase == .idle else { return }
        let morph = Animation.spring(response: ctx["response"], dampingFraction: ctx["damping"])
        let wait = ctx["duration"]
        let live = !ctx.isPreview
        if live { Haptics.tap(.medium) }
        withAnimation(morph) { phase = .loading }
        Task {
            try? await Task.sleep(for: .seconds(wait))
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { phase = .success }
            successCount += 1
            if live { Haptics.success() }
            try? await Task.sleep(for: .seconds(1.3))
            withAnimation(morph) { phase = .idle }
        }
    }
}

private struct LoadButtonFace: View {
    let phase: LoadPhase
    let title: String

    private let side: CGFloat = 58
    private let successFill = LinearGradient(
        colors: [Color(hex: 0x4BE08F), Palette.green],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    var body: some View {
        let collapsed = phase != .idle
        ZStack {
            Capsule().fill(Palette.primary)
            Capsule()
                .fill(successFill)
                .opacity(phase == .success ? 1 : 0)
            label
                .opacity(collapsed ? 0 : 1)
                .scaleEffect(collapsed ? 0.8 : 1)
                .blur(radius: collapsed ? 8 : 0)
            if phase == .loading {
                LoadSpinnerArc()
                    .transition(AnyTransition.scale(scale: 0.3).combined(with: .opacity))
            }
            LoadCheckShape()
                .trim(from: 0, to: phase == .success ? 1 : 0)
                .stroke(Color.white, style: StrokeStyle(lineWidth: 3.5, lineCap: .round, lineJoin: .round))
                .frame(width: 22, height: 17)
                .animation(phase == .success ? .easeOut(duration: 0.35).delay(0.08) : .easeIn(duration: 0.12), value: phase)
        }
        .frame(width: collapsed ? side : 240, height: side)
        .clipShape(Capsule())
        .shadow(color: (phase == .success ? Palette.green : Palette.indigo).opacity(0.4), radius: 16, y: 9)
        .contentShape(Capsule())
    }

    private var label: some View {
        HStack(spacing: 8) {
            Text(title)
                .font(.headline)
            Image(systemName: "arrow.right")
                .font(.subheadline.weight(.bold))
        }
        .foregroundStyle(.white)
        .fixedSize()
    }
}

/// A 260° white arc with a transparent tail, spinning once every 0.9 s.
private struct LoadSpinnerArc: View {
    var body: some View {
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            let angle = t.truncatingRemainder(dividingBy: 0.9) / 0.9 * 360
            Circle()
                .trim(from: 0.03, to: 0.74)
                .stroke(
                    AngularGradient(
                        colors: [Color.white.opacity(0), Color.white],
                        center: .center,
                        startAngle: .degrees(0),
                        endAngle: .degrees(266)
                    ),
                    style: StrokeStyle(lineWidth: 3, lineCap: .round)
                )
                .rotationEffect(.degrees(angle))
        }
        .frame(width: 26, height: 26)
    }
}

private struct LoadCheckShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + rect.width * 0.04, y: rect.minY + rect.height * 0.55))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.37, y: rect.maxY - rect.height * 0.04))
        path.addLine(to: CGPoint(x: rect.maxX - rect.width * 0.03, y: rect.minY + rect.height * 0.06))
        return path
    }
}

private struct LoadButtonPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .brightness(configuration.isPressed ? -0.04 : 0)
            .animation(.spring(response: 0.28, dampingFraction: 0.6), value: configuration.isPressed)
    }
}
