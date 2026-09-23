import SwiftUI

extension Effect {
    static let chartsActivityRings = Effect(
        id: "charts.activity-rings",
        category: .charts,
        interaction: .tap,
        name: L("Activity Rings", "健身圆环"),
        summary: L("Three concentric gradient rings that close with springs and lap past 100% with a shadowed cap.", "三条同心渐变圆环以弹簧闭合，超额时带投影端帽继续绕圈。"),
        prompt: L(
            "Three concentric rings (22 pt stroke, 4 pt gaps, 210 pt outer diameter) in Move red-pink, Exercise lime and Stand cyan, each over a 20%-opacity track of its own color with a small bold glyph at 12 o’clock. On appear and on every tap the rings drain in 250 ms, then fill clockwise from the top, outer to inner, 150 ms apart, on a smooth spring (response ≈ 1.2 s, damping 0.82). Each arc carries an angular gradient from a darker start to a brighter tip, with a solid start-colored cap at 12 o’clock so there is no seam. Past 100% the ring keeps traveling: the gradient rotates so the bright end stays at the tip, and the round end cap casts a soft 3 pt shadow ahead of itself, fading in from 85%, so the overlap reads as a physical strap. Percentages below count up in step: rewarding, iconic.",
            "三条同心圆环（描边 22pt、间距 4pt、外径 210pt）依次为“活动”红粉、“锻炼”青柠、“站立”青蓝，下方各有 20% 透明度的同色轨道，12 点处嵌粗体小图标。出现与每次点击时，圆环先在 250ms 内清空，再从顶部顺时针填充，由外向内错开 150ms，采用平滑弹簧（响应约 1.2 秒、阻尼 0.82）。弧线为角向渐变，起点深、末端亮，起点端帽为纯色、不留接缝。超过 100% 时圆环继续前进：渐变整体旋转，亮端始终停在末端，端帽在前方投下 3pt 柔影（自 85% 起渐显），重叠处宛如真实表带。下方百分比同步递增。"
        ),
        implementation: L(
            "Each ring is an Animatable view: up to 100% it trims a Circle stroked with an AngularGradient; beyond 100% it draws the full ring rotated by the excess and adds a shadowed end-cap circle rotated to the tip angle.",
            "每条圆环都是 Animatable 视图：100% 以内用 AngularGradient 描边并 trim 的 Circle；超过 100% 时绘制整圈并按超出量旋转，再在末端角度叠加带阴影的端帽圆点。"
        ),
        apis: ["Animatable", "AngularGradient", "trim(from:to:)", "rotationEffect", "spring(response:dampingFraction:)"],
        tags: ["activity rings", "progress ring", "fitness", "apple watch", "健身圆环", "进度环", "运动", "目标"],
        params: [
            .slider("thickness", L("Ring thickness", "环宽"), 12...30, default: 22, step: 1, decimals: 0, unit: "pt"),
            .slider("response", L("Spring response", "弹簧响应"), 0.5...2.0, default: 1.2, unit: "s"),
            .slider("stagger", L("Stagger", "错峰间隔"), 0...0.4, default: 0.15, unit: "s"),
        ]
    ) { ctx in
        ActivityRingsDemo(ctx: ctx)
    }
}

private struct RingStyle {
    let name: LocalizedText
    let symbol: String
    let start: Color
    let end: Color
}

private let ringStyles: [RingStyle] = [
    RingStyle(name: L("Move", "活动"), symbol: "arrow.right", start: Color(hex: 0xE0004B), end: Color(hex: 0xFF4F9A)),
    RingStyle(name: L("Exercise", "锻炼"), symbol: "chevron.right.2", start: Color(hex: 0x6BD100), end: Color(hex: 0xC6FF3D)),
    RingStyle(name: L("Stand", "站立"), symbol: "arrow.up", start: Color(hex: 0x00B4D8), end: Color(hex: 0x3DF2F2)),
]

private struct ActivityRingsDemo: View {
    let ctx: DemoContext
    /// Seeded with a settled day so still snapshots show closed rings; `onAppear` rewinds and plays.
    @State private var progress: [Double] = [1.08, 0.82, 0.64]

    private let outer: CGFloat = 210

    var body: some View {
        let thickness = ctx.cg("thickness")
        VStack(spacing: 18) {
            ZStack {
                ForEach(ringStyles.indices, id: \.self) { index in
                    ActivityRing(
                        progress: progress[index],
                        style: ringStyles[index],
                        lineWidth: thickness,
                        diameter: outer - CGFloat(index) * 2 * (thickness + 4)
                    )
                }
            }
            .frame(width: outer + thickness, height: outer + thickness)
            HStack(spacing: 18) {
                ForEach(ringStyles.indices, id: \.self) { index in
                    RingLegend(value: progress[index], style: ringStyles[index], language: ctx.language)
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { play() }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            ChartEntrance.replay(reset: {
                progress = [0, 0, 0]
            }, then: {
                play(haptic: false)
            })
        }
        // The entrance already runs in onAppear, so the detail stage's one-shot intro is turned off.
        .autoplay(ctx.isPreview, every: 3.6, delay: 3.6, intro: false) { play() }
    }

    /// `haptic: false` for the silent arrival entrance; taps (and muted autoplay) keep the default.
    private func play(haptic: Bool = true) {
        withAnimation(.easeIn(duration: 0.25)) { progress = [0, 0, 0] }
        let targets = [Double.random(in: 0.7...1.35), Double.random(in: 0.55...1.2), Double.random(in: 0.4...1.0)]
        let spring = Animation.spring(response: ctx["response"], dampingFraction: 0.82)
        let stagger = ctx["stagger"]
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.28))
            for index in targets.indices {
                withAnimation(spring.delay(Double(index) * stagger)) {
                    progress[index] = targets[index]
                }
            }
            if haptic && !ctx.isPreview { Haptics.tap(.soft) }
        }
    }
}

private struct ActivityRing: View, Animatable {
    var progress: Double
    let style: RingStyle
    let lineWidth: CGFloat
    let diameter: CGFloat

    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    var body: some View {
        let p = max(progress, 0)
        ZStack {
            Circle()
                .stroke(style.start.opacity(0.2), lineWidth: lineWidth)
            arc(p)
            startCap(p)
            endCap(p)
            // Solid black on the filled start cap (≥ 4.4:1 on every ring color); ring-colored on the bare track.
            Image(systemName: style.symbol)
                .font(.system(size: lineWidth * 0.55, weight: .black))
                .foregroundStyle(p > 0.01 ? Color.black : style.start)
                .offset(y: -diameter / 2)
        }
        .frame(width: diameter, height: diameter)
    }

    @ViewBuilder
    private func arc(_ p: Double) -> some View {
        if p <= 1 {
            Circle()
                .trim(from: 0, to: p)
                .stroke(
                    AngularGradient(colors: [style.start, style.end], center: .center, startAngle: .degrees(0), endAngle: .degrees(max(360 * p, 1))),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
        } else {
            Circle()
                .stroke(
                    AngularGradient(colors: [style.start, style.end], center: .center, startAngle: .degrees(0), endAngle: .degrees(360)),
                    lineWidth: lineWidth
                )
                .rotationEffect(.degrees(-90 + 360 * (p - 1)))
        }
    }

    /// The trimmed arc's round start cap sits just before 0°, where the angular gradient resolves to the
    /// end color; a start-colored disc covers it so there is no seam at 12 o'clock.
    @ViewBuilder
    private func startCap(_ p: Double) -> some View {
        if p > 0.01 && p <= 1 {
            Circle()
                .fill(style.start)
                .frame(width: lineWidth, height: lineWidth)
                .offset(y: -diameter / 2)
        }
    }

    private func endCap(_ p: Double) -> some View {
        // Before rotation the cap sits at 3 o'clock, where clockwise travel points to +y, so a +y shadow
        // offset is cast along the tangent, ahead of the tip, onto the ring it overlaps. It fades in near 100%.
        let shade = min(max((p - 0.85) / 0.15, 0), 1)
        return Circle()
            .fill(style.end)
            .frame(width: lineWidth, height: lineWidth)
            .shadow(color: .black.opacity(0.45 * shade), radius: 3.5, x: 0, y: 3)
            .offset(x: diameter / 2)
            .frame(width: diameter, height: diameter)
            .rotationEffect(.degrees(-90 + 360 * p))
            .opacity(p > 0.01 ? 1 : 0)
    }
}

private struct RingLegend: View, Animatable {
    var value: Double
    let style: RingStyle
    let language: AppLanguage

    var animatableData: Double {
        get { value }
        set { value = newValue }
    }

    var body: some View {
        VStack(spacing: 2) {
            Text(style.name, language)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(verbatim: "\(Int((max(value, 0) * 100).rounded()))%")
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(style.start)
        }
        .frame(width: 70)
    }
}
