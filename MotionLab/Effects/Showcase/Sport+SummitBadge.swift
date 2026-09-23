import SwiftUI

extension Effect {
    static let showcaseSummitBadge = Effect(
        id: "showcase.summit-badge",
        category: .showcase,
        interaction: .tap,
        name: L("Summit Badge Unlock", "登顶徽章解锁"),
        summary: L(
            "An achievement badge drops in spinning, lands with a thud while rays fan out behind it.",
            "成就徽章旋转着从天而降，落地一震，身后光芒徐徐展开。"
        ),
        prompt: L(
            "A dark achievement card. On tap an orange hexagonal badge with a mountain glyph and \"3,798 m\" drops from 160 pt above on a spring (response 0.55 s, damping 0.6) while spinning two full turns around its vertical axis on a decelerating curve (1.2 s, fast start, soft finish), its glossy highlight flashing as each face turns toward you. It lands at 100% with a slight overshoot and a medium haptic. Behind it, twelve soft sunburst rays scale in from 60% and fade up over 0.6 s, then rotate slowly (12°/s) forever, while four sparkles twinkle on staggered loops. The title \"Summit reached\" and a caption rise 12 pt into place 150 ms apart after the landing, with a success haptic. Tapping replays the unlock. Triumphant, warm and collectible.",
            "暗色成就卡片。点击后，刻有山峰与“3,798 m”的橙色六边形徽章从 160pt 高处以弹簧（响应 0.55 秒、阻尼 0.6）落下，同时以先快后缓的 1.2 秒曲线绕竖轴转两圈，每次转回正面高光一闪；落地轻微过冲，伴随中等触感。身后十二道柔和光芒 0.6 秒内从 60% 放大淡入，随后以每秒 12° 永久缓转，四颗星光错开闪烁。落地后标题“登顶成功”与说明相隔 150 毫秒上浮 12pt 就位，并触发成功触感。点击可重播。胜利而温暖。"
        ),
        implementation: L(
            "An async sequence resets the badge instantly, then springs its drop offset and runs a timingCurve animation on an accumulated rotation3DEffect angle; the rays are a TimelineView-rotated ForEach of capsules, and the texts use delayed springs keyed on the revealed flag.",
            "异步序列先瞬间重置徽章，再以弹簧驱动下落偏移，并用 timingCurve 动画驱动累加的 rotation3DEffect 角度；光芒是由 TimelineView 旋转的一组胶囊，文字则由以揭示状态为 key 的延迟弹簧驱动。"
        ),
        apis: ["rotation3DEffect", "timingCurve", "TimelineView", "withTransaction", "task(id:)"],
        tags: ["badge", "achievement", "unlock", "summit", "徽章", "成就", "解锁", "登顶"],
        params: [
            .slider("spins", L("Spins", "旋转圈数"), 0...4, default: 2, step: 1, decimals: 0),
            .slider("drop", L("Drop height", "下落高度"), 60...220, default: 160, decimals: 0, unit: "pt"),
            .toggle("rays", L("Sunburst rays", "放射光芒"), default: true),
        ]
    ) { ctx in
        SportSummitBadgeDemo(ctx: ctx)
    }
}

private struct SportHexagon: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        for index in 0..<6 {
            let angle = (Double(index) * 60 - 90) * Double.pi / 180
            let point = CGPoint(x: center.x + CGFloat(cos(angle)) * radius, y: center.y + CGFloat(sin(angle)) * radius)
            if index == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        path.closeSubpath()
        return path
    }
}

private struct SportSummitBadgeDemo: View {
    let ctx: DemoContext
    @State private var drop: CGFloat = 0
    @State private var spin: Double = 0
    @State private var revealed = true
    @State private var runID = 0
    /// Set when autoplay or the detail intro starts the run, so the simulated unlock stays silent.
    @State private var silentRun = false

    private var zh: Bool { ctx.language == .zh }

    var body: some View {
        SignatureStage {
            VStack(spacing: 0) {
                Spacer(minLength: 0)
                card
                Spacer(minLength: 0)
                DemoHint(text: L("Tap to replay the unlock", "点击重播解锁"), ctx: ctx)
                    .padding(.bottom, 14)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .task(id: runID) {
            guard runID > 0 else { return }
            await play()
        }
        .autoplay(ctx.isPreview, every: 4.0, delay: 0.5) {
            silentRun = true
            runID += 1
        }
    }

    private var card: some View {
        VStack(spacing: 14) {
            ZStack {
                if ctx.bool("rays") {
                    SportSummitRays(visible: revealed, preview: ctx.isPreview)
                }
                SportSummitSparkles(visible: revealed, preview: ctx.isPreview)
                badge
            }
            .frame(width: 220, height: 170)
            VStack(spacing: 4) {
                Text(zh ? "登顶成功" : "Summit reached")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.white)
                    .offset(y: revealed ? 0 : 12)
                    .opacity(revealed ? 1 : 0)
                    .animation(.spring(response: 0.45, dampingFraction: 0.8).delay(revealed ? 0.1 : 0), value: revealed)
                Text(zh ? "Zugspitze · 本季第 3 座高峰" : "Zugspitze · 3rd peak this season")
                    .signatureEyebrow()
                    .offset(y: revealed ? 0 : 12)
                    .opacity(revealed ? 1 : 0)
                    .animation(.spring(response: 0.45, dampingFraction: 0.8).delay(revealed ? 0.25 : 0), value: revealed)
            }
        }
        .padding(.vertical, 20)
        .frame(width: 280)
        .signatureCard()
        .contentShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .onTapGesture {
            silentRun = false
            runID += 1
        }
    }

    private var badge: some View {
        ZStack {
            SportHexagon()
                .fill(Signature.accentGradient)
                .overlay(SportHexagon().stroke(Signature.accentSoft, lineWidth: 3))
                .overlay {
                    SportHexagon()
                        .fill(LinearGradient(colors: [Color.white.opacity(0.45), .clear], startPoint: .topLeading, endPoint: .center))
                }
            VStack(spacing: 2) {
                Image(systemName: "mountain.2.fill")
                    .font(.system(size: 30, weight: .semibold))
                Text(verbatim: "3,798 m")
                    .font(Signature.number(14))
            }
            .foregroundStyle(Color.white)
        }
        .frame(width: 118, height: 118)
        .shadow(color: Signature.accent.opacity(0.5), radius: 16, y: 8)
        .rotation3DEffect(.degrees(spin), axis: (x: 0, y: 1, z: 0), perspective: 0.5)
        .offset(y: -drop)
    }

    private func play() async {
        let height = ctx.cg("drop")
        let spins = Double(max(ctx.int("spins"), 0))
        let muted = ctx.isPreview || silentRun
        var instant = Transaction()
        instant.disablesAnimations = true
        withTransaction(instant) {
            drop = height
            revealed = false
        }
        try? await Task.sleep(for: .milliseconds(40))
        guard !Task.isCancelled else { return }
        withAnimation(.spring(response: 0.55, dampingFraction: 0.6)) { drop = 0 }
        withAnimation(.timingCurve(0.15, 0.85, 0.3, 1, duration: 1.2)) { spin += 360 * spins }
        try? await Task.sleep(for: .milliseconds(420))
        guard !Task.isCancelled else { return }
        if !muted { Haptics.tap(.medium) }
        withAnimation(.easeOut(duration: 0.6)) { revealed = true }
        try? await Task.sleep(for: .milliseconds(300))
        if !muted { Haptics.success() }
    }
}

/// Twelve soft rays that fan in behind the badge and then rotate slowly forever.
private struct SportSummitRays: View {
    let visible: Bool
    let preview: Bool

    var body: some View {
        TimelineView(.animation(minimumInterval: MotionFrameRate.interval(preview: preview))) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 30)
            ZStack {
                ForEach(0..<12, id: \.self) { index in
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [Signature.accent.opacity(0.55), Signature.accent.opacity(0)],
                                startPoint: .bottom,
                                endPoint: .top
                            )
                        )
                        .frame(width: 10, height: 82)
                        .offset(y: -41)
                        .rotationEffect(.degrees(Double(index) * 30))
                }
            }
            .rotationEffect(.degrees(t * 12))
        }
        .blur(radius: 2)
        .scaleEffect(visible ? 1 : 0.6)
        .opacity(visible ? 1 : 0)
        .animation(.easeOut(duration: 0.6), value: visible)
        .allowsHitTesting(false)
    }
}

/// Four sparkles twinkling on staggered loops around the badge.
private struct SportSummitSparkles: View {
    let visible: Bool
    let preview: Bool

    private static let spots: [CGPoint] = [
        CGPoint(x: -84, y: -50), CGPoint(x: 88, y: -34), CGPoint(x: -70, y: 56), CGPoint(x: 76, y: 60),
    ]

    var body: some View {
        TimelineView(.animation(minimumInterval: MotionFrameRate.interval(preview: preview))) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            ZStack {
                ForEach(Self.spots.indices, id: \.self) { index in
                    let phase: Double = sin(t * 3 + Double(index) * 1.7)
                    let glow = CGFloat(0.5 + 0.5 * phase)
                    Image(systemName: "sparkle")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Signature.accentSoft)
                        .scaleEffect(0.5 + 0.6 * glow)
                        .opacity(Double(0.3 + 0.7 * glow))
                        .offset(x: Self.spots[index].x, y: Self.spots[index].y)
                }
            }
        }
        .opacity(visible ? 1 : 0)
        .animation(.easeOut(duration: 0.5), value: visible)
        .allowsHitTesting(false)
    }
}
