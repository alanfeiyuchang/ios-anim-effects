import SwiftUI

extension Effect {
    static let gesturesArcSlide = Effect(
        id: "gestures.arc-slide",
        category: .gestures,
        interaction: .gesture,
        name: L("Arc Slide to Unlock", "弧形滑动解锁"),
        summary: L("Drag a knob around a 240° arc, ticking past detents, until the lock at the centre springs open.", "沿 240° 弧线拖动滑块、依次越过刻度，直到中心的锁弹开。"),
        prompt: L(
            "A 220 pt arc track (14 pt stroke, 240° sweep open at the bottom) circles a padlock, with a 40 pt white knob at its lower-left end. Dragging moves the knob by the finger's angle around the centre, never in a straight line, while a mint-to-indigo angular gradient fills the arc behind it and eight detent ticks brighten as they are passed, each with a selection haptic; jumps across the gap are ignored so the knob never teleports. Reaching the end commits: the track flashes green, a ring pulses outward, the padlock swaps open with a symbol replace and bounces, and a success haptic fires. Releasing early sends the knob back along the arc on a spring (response 0.6 s, damping 0.8), unwinding the fill with it.",
            "一条直径220 pt的弧形轨道（描边14 pt，底部开口，共240°）环绕着中央的挂锁，40 pt的白色滑块停在左下端。拖动时滑块按手指相对圆心的角度移动，始终贴着弧线走，身后被薄荷绿到靛蓝的角向渐变填满；八个刻度被越过时依次点亮，各有一下选择触感，跨越底部缺口的大跳会被忽略，滑块不会瞬移。到达终点即提交：轨道闪成绿色，一圈光环向外扩散，挂锁以符号替换打开并弹跳，同时触发成功触感。中途松手，滑块以弹簧（响应0.6秒、阻尼0.8）沿弧线退回，填充随之倒卷。"
        ),
        implementation: L(
            "The knob's angle is atan2 of its start point on the arc plus the drag translation; a GeometryEffect whose animatableData is the progress places it on the arc, so springs travel along the curve, and trim(from:to:) draws the fill.",
            "滑块角度由“起始点在弧上的位置 + 拖动位移”的 atan2 求得；以进度为 animatableData 的 GeometryEffect 把它放在弧线上，因此弹簧动画沿曲线运动；填充用 trim(from:to:) 绘制。"
        ),
        apis: ["GeometryEffect", "trim(from:to:)", "AngularGradient", "atan2", "DragGesture", "contentTransition(.symbolEffect(.replace))"],
        tags: ["arc", "unlock", "circular slider", "confirm", "弧形", "解锁", "圆形滑块", "确认"],
        params: [
            .slider("detents", L("Detents", "刻度数"), 4...16, default: 8, step: 1, decimals: 0),
            .slider("damping", L("Return damping", "回弹阻尼"), 0.4...1.0, default: 0.8),
        ]
    ) { ctx in
        ArcSlideDemo(ctx: ctx)
    }
}

private let arcStart: Double = 150
private let arcSweep: Double = 240
private let arcRadius: CGFloat = 110
private let arcSide: CGFloat = 300

/// Places the knob on the arc from an animatable progress so springs follow the curve.
private struct ArcPlacement: GeometryEffect {
    var progress: CGFloat

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    func effectValue(size: CGSize) -> ProjectionTransform {
        let radians = (arcStart + arcSweep * Double(progress)) * .pi / 180
        let x = arcRadius * CGFloat(cos(radians))
        let y = arcRadius * CGFloat(sin(radians))
        return ProjectionTransform(CGAffineTransform(translationX: x, y: y))
    }
}

private struct ArcSlideDemo: View {
    let ctx: DemoContext
    @State private var progress: CGFloat = 0
    @State private var unlocked = false
    @State private var dragging = false
    @State private var pulse = false
    @State private var dragStart: CGFloat?
    /// The auto-relock came due while the finger was still down; it runs on release instead,
    /// so the knob is never reset out from under a held drag.
    @State private var relockPending = false
    /// The scripted slide, cancelled on the first real touch.
    @State private var script: Task<Void, Never>?
    /// Resets on system cancellation too, so a stolen touch never leaves the knob mid-arc.
    @GestureState private var pressing = false

    var body: some View {
        let detents = max(ctx.int("detents"), 2)
        let fraction = arcSweep / 360
        ZStack {
            Circle()
                .trim(from: 0, to: fraction)
                .stroke(Color.primary.opacity(0.08), style: StrokeStyle(lineWidth: 14, lineCap: .round))
                .rotationEffect(.degrees(arcStart))
            Circle()
                .trim(from: 0, to: fraction * Double(progress))
                .stroke(fillStyle, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                .rotationEffect(.degrees(arcStart))
            ForEach(0..<detents, id: \.self) { index in
                ArcTick(index: index, count: detents, lit: Double(progress) >= Double(index + 1) / Double(detents + 1))
            }
            Circle()
                .strokeBorder(Palette.green.opacity(pulse ? 0 : 0.6), lineWidth: 3)
                .frame(width: arcRadius * 2 + 30, height: arcRadius * 2 + 30)
                .scaleEffect(pulse ? 1.18 : 0.95)
                .opacity(unlocked ? 1 : 0)
            lockBadge
            knob
                .modifier(ArcPlacement(progress: progress))
        }
        .frame(width: arcRadius * 2, height: arcRadius * 2)
        .frame(width: arcSide, height: arcSide)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(alignment: .bottom) {
            DemoHint(text: L("Drag the knob around the arc", "沿弧线拖动滑块"), ctx: ctx)
                .padding(.bottom, 4)
        }
        .autoplay(ctx.isPreview, every: 3.6, delay: 0.6) { simulate() }
        .onChange(of: pressing) { _, isPressing in
            if !isPressing { endHold() }
        }
        .onDisappear { script?.cancel() }
    }

    private var fillStyle: AnyShapeStyle {
        if unlocked { return AnyShapeStyle(Palette.green) }
        return AnyShapeStyle(AngularGradient(colors: [Palette.mint, Palette.sky, Palette.indigo], center: .center, startAngle: .degrees(0), endAngle: .degrees(arcSweep)))
    }

    private var lockBadge: some View {
        VStack(spacing: 8) {
            Image(systemName: unlocked ? "lock.open.fill" : "lock.fill")
                .font(.system(size: 40, weight: .semibold))
                .foregroundStyle(unlocked ? AnyShapeStyle(Palette.green) : AnyShapeStyle(Color.primary.opacity(0.7)))
                .contentTransition(.symbolEffect(.replace))
                .symbolEffect(.bounce, value: unlocked)
            Text(unlocked ? L("Unlocked", "已解锁") : L("Slide to unlock", "滑动解锁"), ctx.language)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
                .contentTransition(.opacity)
        }
    }

    private var knob: some View {
        Circle()
            .fill(.white)
            .frame(width: 40, height: 40)
            .overlay {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .heavy))
                    .foregroundStyle(Palette.indigo)
            }
            .shadow(color: .black.opacity(0.2), radius: dragging ? 10 : 6, y: 3)
            .scaleEffect(dragging ? 1.12 : 1)
            .gesture(dragGesture)
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .global)
            .updating($pressing) { _, state, _ in state = true }
            .onChanged { value in
                guard !unlocked else { return }
                if dragStart == nil {
                    dragStart = progress
                    script?.cancel()
                    script = nil
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) { dragging = true }
                }
                let startRadians = (arcStart + arcSweep * Double(dragStart ?? progress)) * .pi / 180
                let dx = Double(arcRadius) * cos(startRadians) + Double(value.translation.width)
                let dy = Double(arcRadius) * sin(startRadians) + Double(value.translation.height)
                var relative = atan2(dy, dx) * 180 / .pi - arcStart
                relative = relative.truncatingRemainder(dividingBy: 360)
                if relative < 0 { relative += 360 }
                if relative > arcSweep { relative = relative > (arcSweep + 360) / 2 ? 0 : arcSweep }
                let next = CGFloat(relative / arcSweep)
                // Ignore jumps across the open gap so the knob never teleports.
                guard abs(next - progress) < 0.3 else { return }
                tick(from: progress, to: next)
                progress = next
                if next >= 0.995 { unlock(haptic: true) }
            }
            .onEnded { _ in endHold() }
    }

    /// Release or system cancellation: drop the anchor and, unless unlocked, spring the knob home.
    private func endHold() {
        guard dragStart != nil else { return }
        dragStart = nil
        withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) { dragging = false }
        if relockPending {
            relock()
            return
        }
        guard !unlocked else { return }
        withAnimation(.spring(response: 0.6, dampingFraction: ctx["damping"])) { progress = 0 }
    }

    private func tick(from old: CGFloat, to new: CGFloat) {
        guard !ctx.isPreview else { return }
        let slots = CGFloat(max(ctx.int("detents"), 2) + 1)
        if Int(old * slots) != Int(new * slots) { Haptics.selection() }
    }

    private func unlock(haptic: Bool) {
        guard !unlocked else { return }
        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
            progress = 1
            unlocked = true
        }
        pulse = false
        withAnimation(.easeOut(duration: 0.7)) { pulse = true }
        if haptic && !ctx.isPreview { Haptics.success() }
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(1.6))
            // Still holding the knob at the end: wait for the lift (endHold) instead.
            if dragStart != nil {
                relockPending = true
                return
            }
            relock()
        }
    }

    private func relock() {
        relockPending = false
        withAnimation(.spring(response: 0.6, dampingFraction: 0.85)) {
            unlocked = false
            progress = 0
            dragging = false
        }
        pulse = false
    }

    private func simulate() {
        guard !unlocked, dragStart == nil else { return }
        withAnimation(.easeInOut(duration: 1.1)) {
            progress = 0.96
            dragging = true
        }
        script?.cancel()
        script = Task { @MainActor in
            try? await Task.sleep(for: .seconds(1.15))
            guard !Task.isCancelled else { return }
            unlock(haptic: false)
        }
    }
}

private struct ArcTick: View {
    let index: Int
    let count: Int
    let lit: Bool

    var body: some View {
        let fraction = Double(index + 1) / Double(count + 1)
        let degrees = arcStart + arcSweep * fraction
        Capsule()
            .fill(lit ? AnyShapeStyle(Color.white) : AnyShapeStyle(Color.primary.opacity(0.25)))
            .frame(width: lit ? 9 : 6, height: 3)
            .offset(x: arcRadius)
            .rotationEffect(.degrees(degrees))
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: lit)
    }
}
