import SwiftUI

extension Effect {
    static let chartsLiquidBars = Effect(
        id: "charts.liquid-bars",
        category: .charts,
        interaction: .tap,
        name: L("Liquid Fill Bars", "液态柱状图"),
        summary: L("Glass tubes that fill with a sloshing, wavy liquid and overshoot like water poured too fast.", "玻璃管柱中的液体晃荡着灌满，像倒得太急的水一样先冲过头。"),
        prompt: L(
            "A “Water intake” card with seven 28 × 170 pt glass tubes (capsule outline, faint inner highlight), one per weekday. Each tube holds a sky-to-blue liquid whose surface is a travelling sine wave (wavelength ≈ tube width × 1.6, phase offset per tube). On appear and on every tap the levels spring to new values on an under-damped spring (response 0.9 s, damping 0.55), 60 ms apart left to right, so each column overshoots and sloshes back; at the same moment the wave amplitude kicks from 1.5 pt to 6 pt and decays exponentially over ~1 s, as if the liquid were disturbed. Litre labels above roll to their new values with a numeric transition. Refreshing, tactile and a little playful.",
            "一张“每日饮水”卡片，包含七根 28 × 170pt 的玻璃管（胶囊描边、内侧淡淡高光），每根代表一天。管中是天蓝到蓝色的液体，液面是一道行进中的正弦波（波长约为管宽的 1.6 倍，每根管相位错开）。出现时以及每次点击时，液位以欠阻尼弹簧（响应 0.9 秒、阻尼 0.55）弹到新数值，从左到右错开 60ms，因此每根液柱都会冲过头再晃回；与此同时波幅从 1.5pt 猛增到 6pt，再在约 1 秒内指数衰减，仿佛液体被晃动过。上方的升数标签以数字转场滚动到新值。清爽、可触，又带点俏皮。"
        ),
        implementation: L(
            "A Shape whose animatableData is the fill level draws the wavy surface from a phase supplied by a TimelineView; springs animate the level while the timeline keeps the wave moving, and the amplitude decays from the time of the last kick.",
            "以液位为 animatableData 的 Shape 根据 TimelineView 提供的相位绘制波浪液面；弹簧负责液位动画，时间线让波浪持续流动，波幅从最近一次扰动开始指数衰减。"
        ),
        apis: ["Shape", "animatableData", "TimelineView(.animation)", "clipShape(Capsule())", "contentTransition(.numericText)"],
        tags: ["liquid", "bar chart", "wave", "slosh", "water", "液体", "柱状图", "波浪", "晃动"],
        params: [
            .slider("damping", L("Slosh damping", "晃动阻尼"), 0.3...1.0, default: 0.55),
            .slider("stagger", L("Stagger", "错峰间隔"), 0...0.15, default: 0.06, unit: "s"),
            .slider("wave", L("Wave kick", "扰动波幅"), 0...10, default: 6, step: 0.5, decimals: 1, unit: "pt"),
        ]
    ) { ctx in
        LiquidBarsDemo(ctx: ctx)
    }
}

private struct LiquidSurface: Shape {
    var level: CGFloat
    let phase: Double
    let amplitude: CGFloat

    var animatableData: CGFloat {
        get { level }
        set { level = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let surface: CGFloat = rect.maxY - rect.height * min(max(level, 0), 1.05)
        let wavelength: CGFloat = rect.width * 1.6
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        var x: CGFloat = rect.minX
        while x <= rect.maxX {
            let angle = Double(x / wavelength) * 2 * .pi + phase
            let y: CGFloat = surface + amplitude * CGFloat(sin(angle))
            path.addLine(to: CGPoint(x: x, y: y))
            x += 2
        }
        path.addLine(to: CGPoint(x: rect.maxX, y: surface))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

private let liquidDaysEN = ["M", "T", "W", "T", "F", "S", "S"]
private let liquidDaysZH = ["一", "二", "三", "四", "五", "六", "日"]

private struct LiquidBarsDemo: View {
    let ctx: DemoContext
    @State private var levels: [CGFloat] = Array(repeating: 0, count: 7)
    @State private var kick = Date.distantPast

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            TimelineView(.animation(minimumInterval: MotionFrameRate.interval(preview: ctx.isPreview))) { timeline in
                tubes(date: timeline.date)
            }
            .frame(height: 214)
        }
        .padding(18)
        .frame(width: 300)
        .demoCard()
        .contentShape(Rectangle())
        .onTapGesture { refill(haptic: true) }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(alignment: .bottom) {
            DemoHint(text: L("Tap to pour new data", "点击倒入新数据"), ctx: ctx)
                .padding(.bottom, 6)
        }
        .onAppear { refill(haptic: false) }
        .autoplay(ctx.isPreview, every: 3.0, delay: 3.0) { refill(haptic: false) }
    }

    private var header: some View {
        let total = levels.reduce(0, +) * 3
        return HStack(alignment: .firstTextBaseline) {
            Text(ctx.language == .zh ? "每日饮水" : "Water intake")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Spacer()
            Text(String(format: "%.1f L", Double(total)))
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .monospacedDigit()
                .contentTransition(.numericText(value: Double(total)))
        }
    }

    private func tubes(date: Date) -> some View {
        let t = date.timeIntervalSinceReferenceDate
        let since = max(date.timeIntervalSince(kick), 0)
        let amplitude = CGFloat(1.5 + ctx["wave"] * exp(-since * 2.5))
        let labels = ctx.language == .zh ? liquidDaysZH : liquidDaysEN
        return HStack(alignment: .bottom, spacing: 10) {
            ForEach(0..<7, id: \.self) { index in
                VStack(spacing: 6) {
                    Text(String(format: "%.1f", Double(levels[index]) * 3))
                        .font(.system(size: 9, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                        .contentTransition(.numericText(value: Double(levels[index])))
                    LiquidTube(level: levels[index], phase: t * 3 + Double(index) * 0.9, amplitude: amplitude)
                        .frame(width: 28, height: 170)
                    Text(labels[index])
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func refill(haptic: Bool) {
        kick = Date()
        let stagger = ctx["stagger"]
        let spring = Animation.spring(response: 0.9, dampingFraction: ctx["damping"])
        for index in levels.indices {
            let next = CGFloat.random(in: 0.25...0.95)
            withAnimation(spring.delay(Double(index) * stagger)) { levels[index] = next }
        }
        if haptic && !ctx.isPreview { Haptics.tap(.soft) }
    }
}

private struct LiquidTube: View {
    let level: CGFloat
    let phase: Double
    let amplitude: CGFloat

    var body: some View {
        ZStack {
            Capsule()
                .fill(Color.primary.opacity(0.05))
            LiquidSurface(level: level, phase: phase, amplitude: amplitude)
                .fill(LinearGradient(colors: [Palette.sky, Palette.blue], startPoint: .top, endPoint: .bottom))
            Capsule()
                .fill(LinearGradient(colors: [.white.opacity(0.35), .clear], startPoint: .leading, endPoint: .center))
                .padding(.vertical, 6)
                .frame(width: 8)
                .offset(x: -7)
        }
        .clipShape(Capsule())
        .overlay(Capsule().strokeBorder(Color.primary.opacity(0.12), lineWidth: 1))
    }
}
