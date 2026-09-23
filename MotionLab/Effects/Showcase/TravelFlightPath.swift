import SwiftUI

extension Effect {
    static let showcaseFlightPath = Effect(
        id: "showcase.flight-path",
        category: .showcase,
        interaction: .tap,
        name: L("Flight Path", "航线飞行"),
        summary: L(
            "A plane follows a dashed Bézier route, leaving a glowing trail, and a pin drops at the destination.",
            "飞机沿虚线贝塞尔航线飞行并拖出发光尾迹，抵达后目的地图钉弹跳落下。"
        ),
        prompt: L(
            "On a dark night-landscape card under a bold “Your Next Adventure Starts Here” headline, a dotted white route (1.5 pt, 2/6 dash) arcs across the card as an S-shaped cubic Bézier. On tap, an airplane glyph flies the curve in ~3.2 s with smoothstep ease-in-out. It stays rotated to the curve’s tangent and swells to 125% mid-flight as if climbing, while a distance counter ticks up. Behind it, a 24-segment orange trail covers the last ~22% of the path and tapers in width (1→3.5 pt) and opacity toward the tail. On arrival the plane holds for 400 ms, then fades out over 400 ms. A map pin falls 70 pt with quadratic gravity in 280 ms, bounces back with an exponentially damped rebound (~13 pt at the default strength, decay 5/s) and sends out one expanding ripple ring. The feel is cinematic, aspirational and precise.",
            "暗色夜景卡片上压着一行粗体标题「你的下一场冒险，从这里出发」，一条白色点状航线（1.5pt，虚线 2/6）以 S 形三次贝塞尔曲线横跨卡片。点击后，飞机图标沿曲线飞行约 3.2 秒，采用 smoothstep 缓入缓出。机身始终对准曲线切线方向，飞到中段放大到 125%，像在爬升，同时里程数字不断累加。机尾拖着一条由 24 段组成的橙色尾迹，覆盖航线最后约 22%，越往后越细（3.5→1pt）、越透明。抵达后飞机停留 400 毫秒，再用 400 毫秒淡出。图钉从 70pt 高处按二次曲线下落（280 毫秒），再以指数衰减弹跳（默认强度下约 13pt，衰减 5/秒），同时扩散出一圈涟漪。整体有电影感，让人向往出发，而且每一步都精确可控。"
        ),
        implementation: L(
            "A TimelineView (paused after touchdown + 2.2 s) drives elapsed time; position and heading come from the parametric cubic Bézier and its derivative (atan2), the route and tapered trail are sampled polylines in a Canvas, and the pin's fall and bounce are closed-form functions of time.",
            "TimelineView 提供经过时间（落地 2.2 秒后暂停）；飞机位置与朝向由参数化三次贝塞尔及其导数（atan2）计算，航线与渐细尾迹在 Canvas 中以采样折线绘制，图钉下落与弹跳是关于时间的解析函数。"
        ),
        apis: ["TimelineView", "Canvas", "rotationEffect", "position", "StrokeStyle(dash:)"],
        tags: ["airplane", "flight", "route", "path", "trail", "飞机", "航线", "路径动画", "尾迹"],
        params: [
            .slider("duration", L("Flight time", "飞行时长"), 1.5...6, default: 3.2, decimals: 1, unit: "s"),
            .slider("trail", L("Trail length", "尾迹长度"), 0.05...0.5, default: 0.22),
            .slider("bounce", L("Pin bounce", "图钉弹跳"), 0...1, default: 0.7),
        ]
    ) { ctx in
        TravelFlightDemo(ctx: ctx)
    }
}

// MARK: - Geometry

/// S-shaped cubic Bézier in a fixed-size card.
private struct TravelFlightRoute {
    let width: Double
    let height: Double

    private static let xs: [Double] = [0.12, 0.30, 0.66, 0.84]
    private static let ys: [Double] = [0.84, 0.30, 0.98, 0.42]

    func point(_ t: Double) -> CGPoint {
        let u = 1 - t
        let w0 = u * u * u
        let w1 = 3 * u * u * t
        let w2 = 3 * u * t * t
        let w3 = t * t * t
        let x = w0 * Self.xs[0] + w1 * Self.xs[1] + w2 * Self.xs[2] + w3 * Self.xs[3]
        let y = w0 * Self.ys[0] + w1 * Self.ys[1] + w2 * Self.ys[2] + w3 * Self.ys[3]
        return CGPoint(x: x * width, y: y * height)
    }

    /// Heading (radians) of the tangent at `t`.
    func angle(_ t: Double) -> Double {
        let u = 1 - t
        let d0 = 3 * u * u
        let d1 = 6 * u * t
        let d2 = 3 * t * t
        let dx = d0 * (Self.xs[1] - Self.xs[0]) + d1 * (Self.xs[2] - Self.xs[1]) + d2 * (Self.xs[3] - Self.xs[2])
        let dy = d0 * (Self.ys[1] - Self.ys[0]) + d1 * (Self.ys[2] - Self.ys[1]) + d2 * (Self.ys[3] - Self.ys[2])
        return atan2(dy * height, dx * width)
    }
}

// MARK: - Demo

private struct TravelFlightDemo: View {
    let ctx: DemoContext
    @State private var launch = Date()
    /// The clock only ticks while something is moving; it pauses once the pin has settled.
    @State private var running = true

    var body: some View {
        SignatureStage {
            VStack(spacing: 12) {
                card
                DemoHint(text: L("Tap the card to fly again", "点击卡片重新起飞"), ctx: ctx)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .autoplay(ctx.isPreview, every: ctx["duration"] + 1.8, delay: 0.1) { launch = Date() }
        // The first flight already launches on appear, so the detail stage skips its one-shot intro replay.
        .environment(\.demoIntroPlay, false)
        .task(id: launch) {
            running = true
            try? await Task.sleep(for: .seconds(max(ctx["duration"], 0.1) + 2.2))
            guard !Task.isCancelled else { return }
            running = false
        }
    }

    private var card: some View {
        TimelineView(.animation(minimumInterval: MotionFrameRate.interval(preview: ctx.isPreview), paused: !running)) { timeline in
            TravelFlightScene(
                elapsed: timeline.date.timeIntervalSince(launch),
                duration: max(ctx["duration"], 0.1),
                trail: ctx["trail"],
                bounce: ctx["bounce"],
                zh: ctx.language == .zh
            )
        }
        .frame(width: 290, height: 290)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .signatureCard(cornerRadius: 28)
        .contentShape(Rectangle())
        .onTapGesture {
            Haptics.tap(.medium)
            launch = Date()
        }
    }
}

private struct TravelFlightScene: View {
    let elapsed: Double
    let duration: Double
    let trail: Double
    let bounce: Double
    let zh: Bool

    private let route = TravelFlightRoute(width: 290, height: 290)

    private var progress: Double {
        let t = min(max(elapsed / duration, 0), 1)
        return t * t * (3 - 2 * t)
    }

    /// Seconds since touchdown (negative while flying).
    private var landing: Double { elapsed - duration }

    private var trailFade: Double { landing <= 0 ? 1 : max(0, 1 - landing / 0.8) }

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Rendered wider than the card and pinned leading so the moon sits to the right of the headline.
            LandscapeArt(seed: 4)
                .frame(width: 520, height: 290)
                .frame(width: 290, height: 290, alignment: .leading)
                .clipped()
            LinearGradient(
                colors: [Color.black.opacity(0.6), .clear, Color.black.opacity(0.35)],
                startPoint: .top,
                endPoint: .bottom
            )
            TravelRouteCanvas(route: route, progress: progress, trail: trail, trailFade: trailFade)
            originDot
            TravelLandingPin(landing: landing, bounce: bounce)
                .position(route.point(1))
            plane
            header
        }
        .overlay(alignment: .bottomTrailing) { distance }
    }

    private var originDot: some View {
        Circle()
            .fill(Color.white)
            .frame(width: 8, height: 8)
            .background(Circle().stroke(Color.white.opacity(0.35), lineWidth: 6))
            .position(route.point(0))
    }

    private var plane: some View {
        let p = progress
        let heading = route.angle(min(max(p, 0.001), 0.999))
        let fadeOut = landing > 0.4 ? max(0, 1 - (landing - 0.4) / 0.4) : 1
        return Image(systemName: "airplane")
            .font(.system(size: 22, weight: .semibold))
            .foregroundStyle(Color.white)
            .shadow(color: Signature.accent.opacity(0.9), radius: 8)
            .rotationEffect(.radians(heading))
            .scaleEffect(CGFloat(1 + 0.25 * sin(p * .pi)))
            .position(route.point(p))
            .opacity(fadeOut)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(zh ? "旅行 · 灵感" : "Travel · Inspire")
                .signatureEyebrow()
            Text(zh ? "你的下一场冒险\n从这里出发" : "Your Next\nAdventure\nStarts Here")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(Color.white)
        }
        .padding(20)
    }

    private var distance: some View {
        HStack(spacing: 6) {
            Text("HGH → NCE")
                .signatureEyebrow()
            Text("\(Int(progress * 9_120)) km")
                .font(Signature.number(13))
                .foregroundStyle(Color.white)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.black.opacity(0.35), in: Capsule())
        .padding(14)
    }
}

// MARK: - Route & trail

private struct TravelRouteCanvas: View {
    let route: TravelFlightRoute
    let progress: Double
    let trail: Double
    let trailFade: Double

    var body: some View {
        Canvas { context, _ in
            context.stroke(
                polyline(from: 0, to: 1, steps: 60),
                with: .color(Color.white.opacity(0.45)),
                style: StrokeStyle(lineWidth: 1.5, lineCap: .round, dash: [2, 6])
            )
            let start = max(0, progress - trail)
            guard progress > start, trailFade > 0 else { return }
            let segments = 24
            for i in 0..<segments {
                let a = start + (progress - start) * Double(i) / Double(segments)
                let b = start + (progress - start) * Double(i + 1) / Double(segments)
                let fraction = Double(i + 1) / Double(segments)
                var segment = Path()
                segment.move(to: route.point(a))
                segment.addLine(to: route.point(b))
                context.stroke(
                    segment,
                    with: .color(Signature.accent.opacity(fraction * trailFade)),
                    style: StrokeStyle(lineWidth: CGFloat(1 + 2.5 * fraction), lineCap: .round)
                )
            }
        }
        .allowsHitTesting(false)
    }

    private func polyline(from a: Double, to b: Double, steps: Int) -> Path {
        var path = Path()
        path.move(to: route.point(a))
        for i in 1...steps {
            path.addLine(to: route.point(a + (b - a) * Double(i) / Double(steps)))
        }
        return path
    }
}

// MARK: - Destination pin

private struct TravelLandingPin: View {
    /// Seconds since touchdown (negative = still flying).
    let landing: Double
    let bounce: Double

    private static let fall = 0.28

    private var drop: CGFloat {
        guard landing >= 0 else { return -70 }
        if landing < Self.fall {
            let k = landing / Self.fall
            return CGFloat(-70 * (1 - k * k))
        }
        let s = landing - Self.fall
        return CGFloat(-abs(sin(s * 14)) * 18 * bounce * exp(-s * 5))
    }

    private var ripple: Double { max(0, landing - Self.fall) }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Signature.accent, lineWidth: 1.5)
                .frame(width: 16, height: 16)
                .scaleEffect(CGFloat(1 + ripple * 4))
                .opacity(landing < Self.fall ? 0 : max(0, 1 - ripple / 0.9))
            Ellipse()
                .fill(Color.black.opacity(0.4))
                .frame(width: 14, height: 5)
                .opacity(landing < 0 ? 0 : 1)
            Image(systemName: "mappin")
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(Signature.accentGradient)
                .shadow(color: Signature.accent.opacity(0.6), radius: 6)
                .offset(y: -15 + drop)
                .opacity(landing < 0 ? 0 : min(1, landing / 0.12))
        }
        .allowsHitTesting(false)
    }
}
