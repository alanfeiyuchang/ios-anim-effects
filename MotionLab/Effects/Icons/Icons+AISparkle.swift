import SwiftUI

extension Effect {
    static let iconsAISparkle = Effect(
        id: "icons.ai-sparkle",
        category: .icons,
        interaction: .loop,
        name: L("AI Sparkle", "AI 星芒"),
        summary: L("A four-point star sways and breathes in shifting colour while two satellites twinkle.", "四角星芒摇曳呼吸、色彩流转，两颗小星在旁闪烁。"),
        prompt: L(
            "The now-familiar 'AI' mark: a large four-point star with concave, curved sides, filled with a conic gradient of violet, pink, amber and sky that rotates 60° per second so the colour appears to flow around the glyph. The star sways ±12° on a 4 s sine and breathes between 92% and 106% scale, over a blurred halo of the same gradient at 50% opacity. Two small satellite stars (top-right and bottom-left) twinkle in counter-phase: each pops from 30% to 100% scale while spinning 45°, then shrinks back, every 1.6 s. In Thinking mode everything runs 2.5× faster and a tiny spark orbits the star every 1.2 s. It feels intelligent, gentle and alive.",
            "如今常见的「AI」标志：一个四边内凹、呈弧形的四角大星芒，填充由紫、粉、琥珀、天蓝组成的锥形渐变，渐变每秒旋转60°，颜色仿佛绕着图形流动。星芒以4秒周期的正弦做±12°摇摆，并在92%到106%之间呼吸缩放，下方衬着一层同样渐变、50%透明度的模糊光晕。两颗小卫星星芒（右上与左下）反相闪烁：每1.6秒从30%放大到100%并旋转45°，再缩回。切到「思考中」时，所有节奏加快2.5倍，并有一粒小火花每1.2秒绕星芒转一圈。聪明、温柔、有生命力。"
        ),
        implementation: L(
            "A custom Shape draws the concave four-point star with quadratic curves; a TimelineView(.animation) drives its rotation, scale and the angle of an AngularGradient fill, plus the satellites' twinkle and the orbiting spark.",
            "自定义 Shape 用二次曲线绘制四边内凹的四角星；TimelineView(.animation) 驱动它的旋转、缩放与 AngularGradient 填充的角度，以及卫星星芒的闪烁和绕行火花。"
        ),
        apis: ["Shape", "Path.addQuadCurve", "AngularGradient", "TimelineView(.animation)", "blur(radius:)"],
        tags: ["AI", "sparkle", "star", "magic", "星芒", "人工智能", "闪烁", "智能"],
        params: [
            .choice("mode", L("Mode", "模式"), [L("Idle", "待机"), L("Thinking", "思考中")], default: 0),
            .slider("speed", L("Speed", "速度"), 0.3...2.0, default: 1.0, unit: "×"),
            .slider("glow", L("Halo", "光晕"), 0...1, default: 0.5),
        ]
    ) { ctx in
        AISparkleDemo(ctx: ctx)
    }
}

/// Four-point star with concave sides.
private struct SparkleStar: Shape {
    func path(in rect: CGRect) -> Path {
        let c = CGPoint(x: rect.midX, y: rect.midY)
        let r: CGFloat = min(rect.width, rect.height) / 2
        let k: CGFloat = r * 0.14
        let top = CGPoint(x: c.x, y: c.y - r)
        let right = CGPoint(x: c.x + r, y: c.y)
        let bottom = CGPoint(x: c.x, y: c.y + r)
        let left = CGPoint(x: c.x - r, y: c.y)
        var path = Path()
        path.move(to: top)
        path.addQuadCurve(to: right, control: CGPoint(x: c.x + k, y: c.y - k))
        path.addQuadCurve(to: bottom, control: CGPoint(x: c.x + k, y: c.y + k))
        path.addQuadCurve(to: left, control: CGPoint(x: c.x - k, y: c.y + k))
        path.addQuadCurve(to: top, control: CGPoint(x: c.x - k, y: c.y - k))
        path.closeSubpath()
        return path
    }
}

private struct AISparkleDemo: View {
    let ctx: DemoContext

    private let colors: [Color] = [Palette.violet, Palette.pink, Palette.amber, Palette.sky, Palette.violet]

    var body: some View {
        TimelineView(.animation(minimumInterval: MotionFrameRate.interval(preview: ctx.isPreview))) { timeline in
            let raw: Double = timeline.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 3_600)
            let thinking = ctx.int("mode") == 1
            let time: Double = raw * ctx["speed"] * (thinking ? 2.5 : 1)
            scene(time: time, thinking: thinking)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func scene(time: Double, thinking: Bool) -> some View {
        let fill = AngularGradient(colors: colors, center: .center, angle: .degrees(time * 60))
        let sway: Double = 12 * sin(time * 2 * Double.pi / 4)
        let breath: CGFloat = 0.99 + 0.07 * CGFloat(sin(time * 2 * Double.pi / 2.2))
        return ZStack {
            SparkleStar()
                .fill(fill)
                .frame(width: 130, height: 130)
                .blur(radius: 26)
                .opacity(ctx["glow"])
            SparkleStar()
                .fill(fill)
                .frame(width: 130, height: 130)
                .rotationEffect(.degrees(sway))
                .scaleEffect(breath)
            satellite(time: time, phase: 0, fill: fill)
                .offset(x: 78, y: -70)
            satellite(time: time, phase: 0.5, fill: fill)
                .offset(x: -74, y: 66)
            if thinking {
                spark(time: time)
            }
        }
        .frame(width: 260, height: 260)
    }

    private func satellite(time: Double, phase: Double, fill: AngularGradient) -> some View {
        let cycle: Double = (time / 1.6 + phase).truncatingRemainder(dividingBy: 1)
        let pulse: Double = sin(cycle * Double.pi)
        let scale: CGFloat = 0.3 + 0.7 * CGFloat(pulse * pulse)
        return SparkleStar()
            .fill(fill)
            .frame(width: 34, height: 34)
            .rotationEffect(.degrees(45 * cycle))
            .scaleEffect(scale)
    }

    private func spark(time: Double) -> some View {
        let angle: Double = (time / 1.2).truncatingRemainder(dividingBy: 1) * 2 * Double.pi
        let x: CGFloat = 92 * CGFloat(cos(angle))
        let y: CGFloat = 92 * CGFloat(sin(angle)) * 0.55
        return Circle()
            .fill(Color.white)
            .frame(width: 7, height: 7)
            .shadow(color: Palette.pink, radius: 6)
            .offset(x: x, y: y)
    }
}
