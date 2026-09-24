import SwiftUI

extension Effect {
    static let gesturesChargeBurst = Effect(
        id: "gestures.charge-burst",
        category: .gestures,
        interaction: .gesture,
        name: L("Hold to Charge & Burst", "长按蓄力爆发"),
        summary: L("Press and hold to fill the ring; release at full power for a particle burst.", "长按蓄满圆环，满格松手迸发粒子。"),
        prompt: L(
            "A 112 pt indigo-to-violet core with a bolt glyph sits inside a 168 pt track ring. Pressing and holding fills the ring clockwise from 12 o'clock with a mint-sky-violet-pink angular gradient over a linear 1.2 s while the core sinks to 90%, its glow grows and a tabular percentage counts up beneath. At 100% a heavy haptic fires and the core trembles with a fast 1.5 pt jitter to show it is primed; releasing early just drains the ring on a smooth spring. Releasing when full bursts: a white flash blooms and fades in 0.3 s, 14 capsule particles fly out with ±10° angle and 70–130% speed jitter, arcing down under light gravity as they shrink and fade, a shock-wave ring dissolves over 0.8 s, and the core pops back past full size on a bouncy spring (damping 0.45).",
            "112 pt的靛蓝紫渐变核心（闪电图标）嵌在168 pt的轨道圆环中。长按时，圆环以薄荷、天蓝、紫、粉角向渐变从12点顺时针用1.2秒线性填满；核心下沉到90%，光晕渐强，百分比同步递增。满格时一下重触感，核心以1.5 pt高频抖动；提前松手则圆环平滑回落。满格松手则爆发：白光绽开、0.3秒褪去，14枚胶囊粒子带着±10°角度与70%–130%速度差异飞散，受重力下坠并缩小淡出，冲击波0.8秒内消散，核心以高弹性弹簧（阻尼0.45）弹回并略超原尺寸。"
        ),
        implementation: L(
            "A zero-distance DragGesture marks press and release; charge animates linearly and is interrupted by a spring on release. An Animatable ring view shows the live percentage, TimelineView drives the primed jitter, and a re-identified burst view animates an Animatable particle field on appear, so the gravity drop is evaluated every frame and the paths curve.",
            "零距离 DragGesture 捕获按下与松开；蓄力值线性动画，松手时被弹簧动画打断。Animatable 圆环视图实时显示百分比，TimelineView 驱动蓄满后的抖动；爆发视图通过更换 id 重新出现，其粒子层遵循 Animatable，每帧计算重力下坠，使轨迹呈弧线。"
        ),
        apis: ["DragGesture", "Animatable", "TimelineView", "trim(from:to:)", "AngularGradient", "id(_:)"],
        tags: ["long press", "hold", "charge", "burst", "particles", "长按", "蓄力", "爆发", "粒子"],
        params: [
            .slider("duration", L("Charge time", "蓄力时长"), 0.5...2.5, default: 1.2, unit: "s"),
            .slider("particles", L("Particles", "粒子数量"), 8...24, default: 14, step: 1, decimals: 0),
        ]
    ) { ctx in
        ChargeBurstDemo(ctx: ctx)
    }
}

private struct ChargeBurstDemo: View {
    let ctx: DemoContext
    @State private var charge: Double = 0
    @State private var isPressing = false
    @State private var isFull = false
    @State private var pressStart = Date()
    @State private var pressID = 0
    @State private var burstCount = 0
    /// True during a scripted charge (previews, arrival intro), whose delayed haptics must stay silent.
    @State private var simulated = false
    /// True while a real finger holds the core.
    @State private var held = false
    /// The scripted charge-and-release, cancelled on the first real touch.
    @State private var script: Task<Void, Never>?
    /// Resets on system cancellation too, so a stolen touch never leaves the ring primed.
    @GestureState private var pressing = false

    private var quiet: Bool { ctx.isPreview || simulated }

    var body: some View {
        VStack(spacing: 22) {
            ZStack {
                if burstCount > 0 {
                    BurstView(count: ctx.int("particles"), seed: burstCount)
                        .id(burstCount)
                }
                ChargeRing(progress: charge)
                    .frame(width: 168, height: 168)
                core
            }
            .frame(width: 240, height: 240)
            DemoHint(text: L("Press and hold, release when full", "长按蓄力，满格后松手"), ctx: ctx)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: ctx["duration"] + 1.6, delay: 0.4) { autoCharge() }
        .onChange(of: pressing) { _, isDown in
            if !isDown { endHold() }
        }
        .onDisappear { script?.cancel() }
    }

    private var core: some View {
        TimelineView(.animation(minimumInterval: nil, paused: !isFull)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            CoreButton(charge: charge)
                .offset(
                    x: isFull ? CGFloat(sin(t * 73)) * 1.5 : 0,
                    y: isFull ? CGFloat(cos(t * 61)) * 1.2 : 0
                )
        }
        .gesture(
            DragGesture(minimumDistance: 0)
                .updating($pressing) { _, state, _ in state = true }
                .onChanged { _ in
                    guard !held else { return }
                    held = true
                    // A real press takes over from a scripted charge and starts a fresh one.
                    script?.cancel()
                    script = nil
                    isPressing = false
                    isFull = false
                    if simulated {
                        var transaction = Transaction()
                        transaction.disablesAnimations = true
                        withTransaction(transaction) { charge = 0 }
                    }
                    simulated = false
                    beginPress()
                }
                .onEnded { _ in
                    guard held else { return }
                    held = false
                    endPress()
                }
        )
    }

    /// System cancellation (no `onEnded`): an early release that drains the ring without a burst.
    private func endHold() {
        guard held else { return }
        held = false
        guard isPressing else { return }
        isPressing = false
        isFull = false
        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) { charge = 0 }
    }

    private func beginPress() {
        isPressing = true
        pressStart = Date()
        pressID += 1
        let id = pressID
        let duration = ctx["duration"]
        withAnimation(.linear(duration: duration)) { charge = 1 }
        if !quiet { Haptics.tap(.soft) }
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(duration))
            guard isPressing, pressID == id else { return }
            isFull = true
            if !quiet { Haptics.tap(.heavy) }
        }
    }

    private func endPress() {
        guard isPressing else { return }
        isPressing = false
        let elapsed = Date().timeIntervalSince(pressStart)
        isFull = false
        if elapsed >= ctx["duration"] - 0.02 {
            burstCount += 1
            if !quiet { Haptics.success() }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.45)) { charge = 0 }
        } else {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) { charge = 0 }
        }
    }

    private func autoCharge() {
        guard !isPressing, !held else { return }
        simulated = true
        beginPress()
        let hold = ctx["duration"] + 0.35
        script?.cancel()
        script = Task { @MainActor in
            try? await Task.sleep(for: .seconds(hold))
            guard !Task.isCancelled else { return }
            endPress()
        }
    }
}

private struct CoreButton: View {
    let charge: Double

    var body: some View {
        Circle()
            .fill(Palette.primary)
            .overlay {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 38, weight: .bold))
                    .foregroundStyle(.white)
            }
            .overlay(Circle().strokeBorder(.white.opacity(0.25), lineWidth: 1))
            .frame(width: 112, height: 112)
            .shadow(color: Palette.violet.opacity(0.3 + 0.4 * charge), radius: 12 + 18 * charge, y: 8)
            .scaleEffect(1 - 0.1 * charge)
    }
}

/// Animatable so the percentage label counts in sync with the ring.
private struct ChargeRing: View, Animatable {
    var progress: Double

    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    var body: some View {
        let p = min(max(progress, 0), 1)
        ZStack {
            Circle()
                .stroke(Color.primary.opacity(0.08), lineWidth: 8)
            Circle()
                .trim(from: 0, to: p)
                .stroke(
                    AngularGradient(colors: [Palette.mint, Palette.sky, Palette.violet, Palette.pink], center: .center),
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
        }
        .overlay(alignment: .bottom) {
            Text(verbatim: "\(Int((p * 100).rounded()))%")
                .font(.system(size: 13, weight: .semibold, design: .rounded).monospacedDigit())
                .foregroundStyle(.secondary)
                .offset(y: 30)
        }
    }
}

private struct BurstView: View {
    let count: Int
    /// Varies the jitter pattern from one burst to the next.
    let seed: Int
    @State private var progress: CGFloat = 0
    @State private var flash: CGFloat = 0

    var body: some View {
        ZStack {
            Circle()
                .fill(RadialGradient(colors: [.white, .white.opacity(0)], center: .center, startRadius: 0, endRadius: 80))
                .frame(width: 160, height: 160)
                .scaleEffect(0.6 + 0.8 * flash)
                .opacity(Double(1 - flash))
                .blendMode(.plusLighter)
            Circle()
                .stroke(Palette.sky.opacity(Double(1 - progress)), lineWidth: 1 + 6 * (1 - progress))
                .frame(width: 120 + 220 * progress, height: 120 + 220 * progress)
            BurstParticles(count: count, seed: seed, progress: progress)
        }
        .allowsHitTesting(false)
        .onAppear {
            withAnimation(.easeOut(duration: 0.3)) { flash = 1 }
            withAnimation(.easeOut(duration: 0.8)) { progress = 1 }
        }
    }
}

/// Animatable, so each particle's position is evaluated on every frame: the radius grows with
/// `progress` while gravity pulls with `progress²`, which curves the paths instead of
/// interpolating straight between the two end offsets.
private struct BurstParticles: View, Animatable {
    let count: Int
    let seed: Int
    var progress: CGFloat

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    var body: some View {
        ZStack {
            ForEach(0..<max(count, 1), id: \.self) { index in
                particle(index)
            }
        }
    }

    /// Stable 0..<1 pseudo-random value per particle and burst.
    private func random(_ index: Int, _ salt: Int) -> CGFloat {
        let x = sin(Double(index * 131 + seed * 977 + salt * 53) * 12.9898) * 43758.5453
        return CGFloat(x - x.rounded(.down))
    }

    private func particle(_ index: Int) -> some View {
        let base = CGFloat(index) / CGFloat(max(count, 1)) * 2 * .pi
        let angle = base + (random(index, 1) - 0.5) * 0.35
        let speed = 0.7 + 0.6 * random(index, 2)
        let radius = 60 + 110 * progress * speed
        // Light gravity: a downward drift that grows with the square of time.
        let drop = 70 * progress * progress
        // Point each capsule along its current heading (derivative of the path).
        let heading = atan2(Double(sin(angle) * 110 * speed + 140 * progress), Double(cos(angle) * 110 * speed))
        let color = Palette.spectrum[index % Palette.spectrum.count]
        return Capsule()
            .fill(color)
            .frame(width: 4 + 12 * (1 - progress) * speed, height: 5)
            .rotationEffect(.radians(heading))
            .offset(x: cos(angle) * radius, y: sin(angle) * radius + drop)
            .opacity(Double(1 - progress))
    }
}
