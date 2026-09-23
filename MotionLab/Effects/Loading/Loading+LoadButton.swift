import SwiftUI

extension Effect {
    static let loadingLoadButton = Effect(
        id: "loading.load-button",
        category: .loading,
        interaction: .tap,
        name: L("Load Button", "加载按钮"),
        summary: L("A pill that collapses into a spinner, then blooms into a success check.", "胶囊按钮收缩成旋转圆环，再绽放为成功对勾。"),
        prompt: L(
            "A 240 × 58 pt indigo-to-violet pill with a bold label and trailing arrow. On tap it dips to 96%, then its width springs into a 58 pt circle (response 0.5 s, damping 0.75) as the label blurs, fades and shrinks to 80%; a white 260° arc with a comet tail scales in and spins once every 0.9 s. When the work finishes the fill cross-fades to green, the circle pops 86% → 114% → 100% on a bouncy spring, a thin ring radiates to 190% and fades, and a rounded check draws in 0.35 s with a success haptic. After 1.3 s it springs back into the pill. One object changing state, never a view swap.",
            "靛蓝到紫罗兰渐变的 240 × 58 pt 胶囊按钮，粗体文字后跟箭头。点击先压到 96%，宽度随即以弹簧（响应 0.5 秒、阻尼 0.75）收成 58 pt 正圆，文字边模糊边淡出、缩到 80%；圆心浮现一段带彗尾的 260° 白色圆弧，每 0.9 秒转一圈。完成时底色渐变为绿，圆形按弹性曲线 86% → 114% → 100% 一弹，细光环外扩到 190% 后消散，圆角对勾 0.35 秒一笔画出，伴随成功触感。停 1.3 秒再舒展回胶囊。始终是同一个物体在变形，而非换视图。"
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
    @State private var token = 0
    @State private var task: Task<Void, Never>?

    var body: some View {
        let showRing = ctx.bool("ring")
        VStack(spacing: 30) {
            Button(action: start) {
                LoadButtonFace(phase: phase, title: ctx.language == .zh ? "提交订单" : "Place Order", preview: ctx.isPreview)
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
        .onDisappear {
            // A cancelled run would otherwise leave the button stuck mid-load when it reappears.
            task?.cancel()
            phase = .idle
        }
    }

    private func start() {
        guard phase == .idle else { return }
        let morph = Animation.spring(response: ctx["response"], dampingFraction: ctx["damping"])
        let wait = ctx["duration"]
        let live = !ctx.isPreview
        token += 1
        let current = token
        if live { Haptics.tap(.medium) }
        withAnimation(morph) { phase = .loading }
        task?.cancel()
        task = Task { @MainActor in
            try? await Task.sleep(for: .seconds(wait))
            guard !Task.isCancelled, token == current else { return }
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { phase = .success }
            successCount += 1
            if live { Haptics.success() }
            try? await Task.sleep(for: .seconds(1.3))
            guard !Task.isCancelled, token == current else { return }
            withAnimation(morph) { phase = .idle }
        }
    }
}

private struct LoadButtonFace: View {
    let phase: LoadPhase
    let title: String
    let preview: Bool

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
                LoadSpinnerArc(preview: preview)
                    .transition(AnyTransition.scale(scale: 0.3).combined(with: .opacity))
            }
            LoadCheckShape()
                .trim(from: 0, to: phase == .success ? 1 : 0)
                .stroke(Color.white, style: StrokeStyle(lineWidth: 3.5, lineCap: .round, lineJoin: .round))
                .frame(width: 22, height: 17)
                .animation(phase == .success ? Animation.easeOut(duration: 0.35).delay(0.08) : Animation.easeIn(duration: 0.12), value: phase)
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
    let preview: Bool

    var body: some View {
        TimelineView(.animation(minimumInterval: MotionFrameRate.interval(preview: preview))) { timeline in
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
