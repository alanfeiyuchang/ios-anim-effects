import SwiftUI

extension Effect {
    static let chartsLiquidFill = Effect(
        id: "charts.liquid-fill",
        category: .charts,
        interaction: .tap,
        name: L("Liquid Fill Gauge", "液位进度球"),
        summary: L("A glass sphere whose water level springs to the value, sloshes and settles, with text that inverts underwater.", "玻璃球中的水位弹性升至目标值，晃荡后回稳，没入水中的文字自动反色。"),
        prompt: L(
            "A 200 pt circular gauge with a hairline glass rim holds two layered sine waves — a pale back wave and a sky-to-blue front wave travelling in opposite directions (≈ 3 s and 2.2 s periods) — filled up to the current value. Setting a new value moves the level on a spring (response ≈ 0.8 s, damping ≈ 0.7) while a second, lightly damped oscillator driven by the level's acceleration tilts the surface up to ±18 pt, so the water visibly sloshes against the walls and rocks back and forth before calming; wave height also swells briefly with the level's speed. Small bubbles rise and wobble inside. The large rounded percentage sits on top in the primary colour and switches to white exactly where it is submerged. Tap for a new value or drag vertically to pour. Physical, calm and quietly satisfying.",
            "一个 200pt 的圆形仪表，外圈是发丝般的玻璃描边，内部两层正弦波——浅色后浪与天蓝到深蓝的前浪以相反方向流动（周期约 3 秒与 2.2 秒）——填充到当前数值。设定新值时，水位以弹簧（响应约 0.8 秒、阻尼约 0.7）移动；同时由水位加速度驱动的第二个弱阻尼振子让水面最多倾斜 ±18pt，水体明显拍向球壁、来回摇晃后才平静下来，波高也随水位速度短暂增大。细小气泡在水中摇曳上升。大号圆体百分比叠在最上层，平时为主文字色，没入水中的部分精确地变为白色。点击设置新值，或上下拖动“倒水”。真实、安静，令人满足。"
        ),
        implementation: L(
            "A reference-type model integrates the level spring and a slosh oscillator inside TimelineView; a wave Shape (built per frame from level, phase, amplitude and tilt) fills the sphere, and the white copy of the label is masked by the same Shape.",
            "引用类型模型在 TimelineView 中积分水位弹簧与晃荡振子；波浪 Shape 每帧依据水位、相位、振幅与倾斜构建并填充球体，白色标签副本以同一 Shape 作为遮罩。"
        ),
        apis: ["TimelineView(.animation)", "Shape", "mask", "Canvas", "DragGesture"],
        tags: ["liquid", "progress", "gauge", "water", "wave", "slosh", "液体", "进度", "水位", "波浪", "仪表"],
        params: [
            .slider("amplitude", L("Wave height", "波浪高度"), 2...14, default: 6, decimals: 0, unit: "pt"),
            .slider("slosh", L("Slosh damping", "晃荡阻尼"), 0.05...0.6, default: 0.14),
            .choice("style", L("Liquid", "液体"), [L("Ocean", "海水"), L("Matcha", "抹茶"), L("Sunset", "日落")]),
        ]
    ) { ctx in
        LiquidFillDemo(ctx: ctx)
    }
}

private final class LiquidModel {
    var target: Double = 0.62
    private(set) var level: Double = 0
    private(set) var velocity: Double = 0
    /// Tilt oscillator, in -1...1-ish.
    private(set) var tilt: Double = 0
    private var tiltVelocity: Double = 0
    private(set) var time: Double = 0
    private var lastDate: Date?

    func step(to date: Date, slosh: Double) {
        let raw = lastDate.map { date.timeIntervalSince($0) } ?? 0
        lastDate = date
        let dt = min(max(raw, 0), 1.0 / 20.0)
        guard dt > 0 else { return }
        time += dt
        let substeps = 4
        let h = dt / Double(substeps)
        let omega = 2 * Double.pi / 0.8
        let tiltOmega = 2 * Double.pi / 0.9
        for _ in 0..<substeps {
            let acceleration = omega * omega * (target - level) - 2 * 0.7 * omega * velocity
            velocity += acceleration * h
            level += velocity * h
            let force = -acceleration * 0.6 - tiltOmega * tiltOmega * tilt - 2 * slosh * tiltOmega * tiltVelocity
            tiltVelocity += force * h
            tilt += tiltVelocity * h
        }
        tilt = tilt.clamped(to: -1...1)
    }
}

private struct LiquidStyle {
    let back: Color
    let front: [Color]

    static let all: [LiquidStyle] = [
        LiquidStyle(back: Palette.sky.opacity(0.35), front: [Palette.sky, Palette.blue]),
        LiquidStyle(back: Palette.mint.opacity(0.35), front: [Color(hex: 0x7BE36B), Palette.green]),
        LiquidStyle(back: Palette.amber.opacity(0.4), front: [Palette.amber, Palette.coral]),
    ]
}

private struct LiquidFillDemo: View {
    let ctx: DemoContext
    @State private var model = LiquidModel()

    private let diameter: CGFloat = 200

    var body: some View {
        let style = LiquidStyle.all[ctx.int("style").clamped(to: 0...(LiquidStyle.all.count - 1))]
        let amplitude = ctx.cg("amplitude")
        let slosh = ctx["slosh"]
        VStack(spacing: 16) {
            TimelineView(.animation(minimumInterval: MotionFrameRate.interval(preview: ctx.isPreview))) { timeline in
                let _ = model.step(to: timeline.date, slosh: slosh)
                LiquidSphere(
                    level: model.level,
                    time: model.time,
                    amplitude: amplitude * CGFloat(1 + min(abs(model.velocity) * 2.5, 1.2)),
                    tilt: CGFloat(model.tilt) * 18,
                    style: style,
                    diameter: diameter
                )
            }
            .frame(width: diameter, height: diameter)
            .contentShape(Circle())
            .gesture(pour)
            .simultaneousGesture(TapGesture().onEnded { randomize() })
            DemoHint(text: L("Tap for a new value, or drag to pour", "点击设置新值，或上下拖动倒水"), ctx: ctx)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 2.2, delay: 0.2) { randomize() }
    }

    private var pour: some Gesture {
        DragGesture(minimumDistance: 8)
            .onChanged { value in
                model.target = (1 - Double(value.location.y / diameter)).clamped(to: 0.02...0.98)
            }
            .onEnded { _ in
                if !ctx.isPreview { Haptics.tap(.soft) }
            }
    }

    private func randomize() {
        var next = Double.random(in: 0.12...0.92)
        if abs(next - model.target) < 0.2 { next = model.target > 0.5 ? next * 0.4 : min(next + 0.4, 0.92) }
        model.target = next
        if !ctx.isPreview { Haptics.tap(.light) }
    }
}

/// Water surface: a sine wave at `level`, tilted linearly across the width, closed along the bottom.
private struct WaveSurface: Shape {
    var level: Double
    var phase: Double
    var amplitude: CGFloat
    var wavelength: CGFloat
    var tilt: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let baseY = rect.maxY - rect.height * CGFloat(level)
        let step: CGFloat = 4
        var x = rect.minX
        path.move(to: CGPoint(x: x, y: rect.maxY))
        while x <= rect.maxX + step {
            let u = (x - rect.midX) / max(rect.width / 2, 1)
            let y = baseY + tilt * u + amplitude * CGFloat(sin(Double(x / wavelength) * 2 * .pi + phase))
            path.addLine(to: CGPoint(x: x, y: y))
            x += step
        }
        path.addLine(to: CGPoint(x: rect.maxX + step, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

private struct LiquidSphere: View {
    let level: Double
    let time: Double
    let amplitude: CGFloat
    let tilt: CGFloat
    let style: LiquidStyle
    let diameter: CGFloat

    var body: some View {
        let front = WaveSurface(level: level, phase: -time * 2 * .pi / 2.2, amplitude: amplitude, wavelength: diameter * 0.9, tilt: tilt)
        let back = WaveSurface(level: level + 0.02, phase: time * 2 * .pi / 3 + 1.4, amplitude: amplitude * 0.8, wavelength: diameter * 1.2, tilt: tilt * 0.8)
        let label = Text("\(Int((min(max(level, 0), 1) * 100).rounded()))%")
            .font(.system(size: 44, weight: .bold, design: .rounded))
            .monospacedDigit()

        ZStack {
            Circle().fill(Palette.surface)
            back.fill(style.back)
            front.fill(LinearGradient(colors: style.front, startPoint: .top, endPoint: .bottom))
            Bubbles(time: time, level: level)
                .mask { front }
            label.foregroundStyle(.primary)
            label.foregroundStyle(.white).mask { front }
        }
        .frame(width: diameter, height: diameter)
        .clipShape(Circle())
        .overlay(Circle().strokeBorder(Color.primary.opacity(0.1), lineWidth: 1))
        .overlay(alignment: .topLeading) {
            Ellipse()
                .fill(.white.opacity(0.35))
                .frame(width: diameter * 0.28, height: diameter * 0.12)
                .rotationEffect(.degrees(-35))
                .offset(x: diameter * 0.16, y: diameter * 0.14)
                .blur(radius: 2)
        }
        .shadow(color: style.front[0].opacity(0.3), radius: 22, y: 12)
    }
}

private struct Bubbles: View {
    let time: Double
    let level: Double

    var body: some View {
        Canvas { context, size in
            for index in 0..<7 {
                let seed = Double(index)
                let rise = (time * (0.12 + 0.05 * sin(seed * 3.1)) + seed * 0.17).truncatingRemainder(dividingBy: 1)
                let y = size.height * CGFloat(1 - rise * max(level, 0.05))
                let x = size.width * CGFloat(0.22 + 0.56 * ((seed * 0.618).truncatingRemainder(dividingBy: 1))) + CGFloat(sin(time * 2.4 + seed) * 4)
                let r = CGFloat(2 + (index % 3))
                context.stroke(
                    Path(ellipseIn: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)),
                    with: .color(.white.opacity(0.55 * (1 - rise * 0.6))),
                    lineWidth: 1
                )
            }
        }
    }
}
