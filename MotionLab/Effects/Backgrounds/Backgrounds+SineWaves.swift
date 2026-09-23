import SwiftUI

extension Effect {
    static let backgroundsSineWaves = Effect(
        id: "backgrounds.sine-waves",
        category: .backgrounds,
        interaction: .loop,
        name: L("Layered Waves", "层叠波浪"),
        summary: L(
            "Translucent sine waves roll past each other in soft parallax.",
            "半透明正弦波层层叠叠，以柔和视差缓缓起伏。"
        ),
        prompt: L(
            "A calm horizon: a pastel peach-to-lilac-to-periwinkle sky (deep navy-indigo in dark mode) with a soft blurred sun glow, over a stack of five translucent wave bands filling the lower half. Each band is a filled curve built from a primary sine plus a finer counter-moving harmonic; bands further back are lighter, flatter and slower, bands in front are deeper indigo-violet, taller and faster (roughly 5 s to 12 s cycles), creating gentle parallax as they slide against one another. Every band carries a vertical gradient that darkens toward the bottom. Motion is continuous and unhurried — the mood is meditative, like breathing or a slow tide.",
            "宁静的地平线：天空为桃色 → 淡紫 → 长春花蓝的柔和渐变（深色模式下为深海军蓝与靛蓝），带一团柔和模糊的太阳光晕；下半部分由五层半透明波带堆叠。每层是一条主正弦波叠加一条反向运动的细小谐波后填充而成；越靠后的波带越浅、越平、越慢，越靠前则越深（靛紫）、越高、越快（周期约 5–12 秒），彼此滑动形成柔和视差。每层自带由上至下逐渐加深的纵向渐变。运动连续而从容，氛围如呼吸或缓慢潮汐般冥想安宁。"
        ),
        implementation: L(
            "A Canvas driven by TimelineView fills one closed wave Path per layer (sampled every 6 pt) with a vertical linear gradient; the sky adapts to the colour scheme.",
            "由 TimelineView 驱动的 Canvas 为每层填充一条闭合波形 Path（每 6pt 采样），并施以纵向线性渐变；天空颜色随深浅色模式切换。"
        ),
        apis: ["Canvas", "TimelineView(.animation)", "Path", "GraphicsContext.Shading.linearGradient", "colorScheme"],
        tags: ["wave", "sine", "ocean", "parallax", "波浪", "正弦", "海浪", "视差"],
        params: [
            .slider("layers", L("Layers", "层数"), 2...7, default: 5, step: 1, decimals: 0),
            .slider("amplitude", L("Amplitude", "振幅"), 4...40, default: 16, decimals: 0, unit: "pt"),
            .slider("speed", L("Speed", "速度"), 0.2...2.5, default: 0.9, unit: "×"),
        ]
    ) { ctx in
        SineWavesDemo(ctx: ctx)
    }
}

private struct SineWavesDemo: View {
    let ctx: DemoContext
    @State private var clock = BackgroundClock()
    @Environment(\.colorScheme) private var scheme

    private var sky: [Color] {
        scheme == .dark
            ? [Color(hex: 0x0B1026), Color(hex: 0x1B1F4A), Color(hex: 0x2A2360)]
            : [Color(hex: 0xFFE3D3), Color(hex: 0xEBD8FF), Color(hex: 0xCFE0FF)]
    }

    var body: some View {
        ZStack {
            LinearGradient(colors: sky, startPoint: .top, endPoint: .bottom)
            TimelineView(.animation) { timeline in
                let t = clock.advance(to: timeline.date.timeIntervalSinceReferenceDate, speed: ctx["speed"])
                WaveCanvas(t: t, layers: ctx.int("layers"), amplitude: ctx.cg("amplitude"), dark: scheme == .dark)
            }
            BackgroundSampleTitle(
                title: L("Breathe", "呼吸"),
                subtitle: L("4 · 7 · 8 rhythm", "4 · 7 · 8 呼吸法"),
                language: ctx.language,
                color: scheme == .dark ? .white : Color(hex: 0x2A1F5C)
            )
            .frame(maxHeight: .infinity, alignment: .top)
            .padding(.top, 46)
        }
    }
}

private struct WaveCanvas: View {
    let t: Double
    let layers: Int
    let amplitude: CGFloat
    let dark: Bool

    private static let colors: [UInt32] = [0xB9D3FF, 0x9CB8FF, 0x7F9BFF, 0x6E7BFF, 0x7B61FF, 0x5B45D6, 0x3E2FA8]

    var body: some View {
        Canvas { context, size in
            WaveCanvas.drawSun(&context, size: size, dark: dark)
            let count = min(max(layers, 1), WaveCanvas.colors.count)
            for i in 0..<count {
                let depth = CGFloat(i + 1) / CGFloat(count)
                let baseline = size.height * (0.5 + 0.4 * CGFloat(i) / CGFloat(count))
                let path = WaveCanvas.wavePath(size: size, baseline: baseline, amplitude: amplitude * (0.55 + 0.6 * depth), t: t, index: i)
                let colorIndex = (WaveCanvas.colors.count - count) + i
                let color = Color(hex: WaveCanvas.colors[colorIndex])
                let gradient = Gradient(colors: [color.opacity(dark ? 0.55 : 0.75), color.opacity(dark ? 0.9 : 0.95)])
                context.fill(
                    path,
                    with: .linearGradient(
                        gradient,
                        startPoint: CGPoint(x: 0, y: baseline - amplitude),
                        endPoint: CGPoint(x: 0, y: size.height)
                    )
                )
            }
        }
    }

    private static func drawSun(_ context: inout GraphicsContext, size: CGSize, dark: Bool) {
        let center = CGPoint(x: size.width * 0.72, y: size.height * 0.36)
        let radius = min(size.width, size.height) * 0.42
        let tint = dark ? Color(hex: 0xA46BFF) : Color(hex: 0xFFB38A)
        let gradient = Gradient(colors: [tint.opacity(dark ? 0.45 : 0.8), tint.opacity(0)])
        let rect = CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)
        context.fill(Path(ellipseIn: rect), with: .radialGradient(gradient, center: center, startRadius: 0, endRadius: radius))
    }

    private static func wavePath(size: CGSize, baseline: CGFloat, amplitude: CGFloat, t: Double, index i: Int) -> Path {
        let di = Double(i)
        let k1 = 1.4 + di * 0.3
        let k2 = 3.6 + di * 0.45
        let s1 = 0.5 + di * 0.16
        let s2 = 0.35 + di * 0.1
        var path = Path()
        path.move(to: CGPoint(x: 0, y: size.height))
        var x: CGFloat = 0
        while x <= size.width + 6 {
            let u = Double(x / max(size.width, 1)) * BackgroundMath.tau
            let s = sin(u * k1 + t * s1 + di * 1.3) * 0.72 + sin(u * k2 - t * s2 + di) * 0.28
            path.addLine(to: CGPoint(x: x, y: baseline + amplitude * CGFloat(s)))
            x += 6
        }
        path.addLine(to: CGPoint(x: size.width + 6, y: size.height))
        path.closeSubpath()
        return path
    }
}
