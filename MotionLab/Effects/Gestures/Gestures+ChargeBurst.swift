import SwiftUI

extension Effect {
    static let gesturesChargeBurst = Effect(
        id: "gestures.charge-burst",
        category: .gestures,
        interaction: .gesture,
        name: L("Hold to Charge & Burst", "长按蓄力爆发"),
        summary: L("Press and hold to fill the ring; release at full power for a particle burst.", "长按蓄满圆环，满格松手迸发粒子。"),
        prompt: L(
            "A 112 pt circular core (indigo-to-violet gradient, bolt glyph) sits inside a 168 pt track ring. Pressing and holding fills the ring clockwise from 12 o’clock with a mint → sky → violet → pink angular gradient over a linear 1.2 s, while the core sinks to 90% and its colored glow grows; a percentage counts up beneath in tabular digits. At 100% a heavy haptic fires and the core trembles with a fast 1.5 pt jitter to signal it is primed. Releasing early drains the ring on a smooth spring; releasing when full triggers a burst: a white flash blooms from the core and fades in 0.3 s, 14 capsule particles fly outward with ±10° angle jitter and 70–130% speed variance, arcing downward under light gravity while shrinking and fading, a shock-wave ring expands and dissolves over 0.8 s, and the core pops past 100% on a bouncy spring (damping 0.45). Suspense, then payoff.",
            "一个 112pt 的圆形核心（靛蓝到紫色渐变、闪电图标）位于 168pt 的轨道圆环中。长按时，圆环以薄荷绿 → 天蓝 → 紫 → 粉的角向渐变从 12 点方向顺时针线性填充（1.2 秒），同时核心下沉至 90%、彩色光晕逐渐增强，下方百分比以等宽数字同步递增。满格瞬间触发重触感，核心以 1.5pt 的高频抖动示意“已蓄满”。提前松手，圆环以平滑弹簧回落；满格松手则爆发：核心处先绽开一团白色闪光并在 0.3 秒内褪去，14 枚胶囊粒子带着 ±10° 的角度抖动与 70%～130% 的速度差异向外飞散，在轻微重力下划出下坠弧线并逐渐缩小淡出，一圈冲击波在 0.8 秒内扩散消散，核心以高弹性弹簧（阻尼 0.45）回弹并略微超过原尺寸。先蓄势，后释放，张力十足。"
        ),
        implementation: L(
            "A zero-distance DragGesture marks press and release; charge animates linearly and is interrupted by a spring on release. An Animatable ring view shows the live percentage, TimelineView drives the primed jitter, and a re-identified burst view animates its particles on appear.",
            "零距离 DragGesture 捕获按下与松开；蓄力值线性动画，松手时被弹簧动画打断。Animatable 圆环视图实时显示百分比，TimelineView 驱动蓄满后的抖动，爆发视图通过更换 id 重新出现并播放粒子动画。"
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
                .onChanged { _ in
                    if !isPressing {
                        simulated = false
                        beginPress()
                    }
                }
                .onEnded { _ in endPress() }
        )
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
        guard !isPressing else { return }
        simulated = true
        beginPress()
        let hold = ctx["duration"] + 0.35
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(hold))
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
            Text("\(Int((p * 100).rounded()))%")
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
            ForEach(0..<max(count, 1), id: \.self) { index in
                particle(index)
            }
        }
        .allowsHitTesting(false)
        .onAppear {
            withAnimation(.easeOut(duration: 0.3)) { flash = 1 }
            withAnimation(.easeOut(duration: 0.8)) { progress = 1 }
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
        let color = Palette.spectrum[index % Palette.spectrum.count]
        return Capsule()
            .fill(color)
            .frame(width: 4 + 12 * (1 - progress) * speed, height: 5)
            .rotationEffect(.radians(Double(angle)))
            .offset(x: cos(angle) * radius, y: sin(angle) * radius + drop)
            .opacity(Double(1 - progress))
    }
}
