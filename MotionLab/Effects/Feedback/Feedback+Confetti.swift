import SwiftUI

extension Effect {
    static let feedbackConfetti = Effect(
        id: "feedback.confetti",
        category: .feedback,
        interaction: .tap,
        name: L("Confetti Burst", "彩纸礼花"),
        summary: L("A physics-based shower of fluttering paper bursts from the button.", "基于物理的彩纸从按钮处迸发、翻飞飘落。"),
        prompt: L(
            "Tapping a gradient 'Celebrate' pill (which pops 90% → 108% → 100%) fires about 110 pieces of confetti from its center in an upward cone of ±55°. Each piece — a small rectangle, dot or streamer in the brand spectrum — launches at 300–700 pt/s, decelerates with air drag, then falls under gravity toward a ~320 pt/s terminal velocity, spinning on its own axis and fluttering in 3D by squashing its width with a cosine. Pieces live 2.6 s and fade over their last 0.6 s. Multiple bursts can overlap. It feels joyful, weighty and real, never cartoonish.",
            "点击一枚渐变“庆祝”胶囊按钮（按钮先缩到 90% 再弹到 108% 后回到 100%），约 110 片彩纸从按钮中心向上以 ±55° 锥形迸发。每一片——小长方形、圆点或纸带，颜色取自品牌色谱——以 300–700 pt/s 的初速射出，受空气阻力减速，再在重力作用下下落，趋近约 320 pt/s 的终端速度；同时绕自身旋转，并用余弦压缩宽度模拟三维翻飞。每片存活 2.6 秒，最后 0.6 秒淡出，多次迸发可以叠加。欢快、有分量、真实，而不卡通。"
        ),
        implementation: L(
            "Particles are generated once per burst; a TimelineView redraws a Canvas each frame using the closed-form solution of drag + gravity, and pauses when no burst is alive.",
            "每次迸发一次性生成粒子；TimelineView 每帧重绘 Canvas，位置由阻力 + 重力的解析解计算，无存活粒子时暂停。"
        ),
        apis: ["Canvas", "TimelineView(.animation(paused:))", "GraphicsContext", "keyframeAnimator"],
        tags: ["confetti", "celebration", "particles", "burst", "彩纸", "庆祝", "粒子", "礼花"],
        params: [
            .slider("count", L("Pieces", "数量"), 30...220, default: 110, step: 1, decimals: 0),
            .slider("spread", L("Spread", "扩散角"), 15...90, default: 55, decimals: 0, unit: "°"),
            .slider("gravity", L("Gravity", "重力"), 0.3...2.0, default: 1.0, unit: "×"),
        ]
    ) { ctx in
        ConfettiDemo(ctx: ctx)
    }
}

private struct ConfettiPiece {
    let vx: Double
    let vy: Double
    let color: Color
    let width: Double
    let height: Double
    let spin: Double
    let flutter: Double
    let phase: Double
    let kind: Int
}

private struct ConfettiPop {
    var scale: CGFloat = 1
}

private struct ConfettiBurst: Identifiable {
    let id: Int
    let start: Date
    let gravity: Double
    let pieces: [ConfettiPiece]
}

private enum ConfettiPhysics {
    static let drag = 2.2
    static let life = 2.6
    static let colors: [Color] = [Palette.indigo, Palette.violet, Palette.pink, Palette.coral, Palette.amber, Palette.mint, Palette.sky]

    static func makePieces(count: Int, spreadDegrees: Double) -> [ConfettiPiece] {
        let spread = spreadDegrees * .pi / 180
        return (0..<max(count, 1)).map { _ in
            let angle = -Double.pi / 2 + Double.random(in: -spread...spread)
            let speed = Double.random(in: 300...700)
            let kind = Int.random(in: 0...2)
            return ConfettiPiece(
                vx: cos(angle) * speed,
                vy: sin(angle) * speed,
                color: colors.randomElement() ?? Palette.pink,
                width: kind == 1 ? 7 : Double.random(in: 6...9),
                height: kind == 1 ? 7 : (kind == 2 ? Double.random(in: 12...16) : Double.random(in: 8...11)),
                spin: Double.random(in: -9...9),
                flutter: Double.random(in: 6...14),
                phase: Double.random(in: 0...(2 * .pi)),
                kind: kind
            )
        }
    }

    static func draw(_ burst: ConfettiBurst, in context: inout GraphicsContext, origin: CGPoint, now: Date) {
        let age = now.timeIntervalSince(burst.start)
        guard age >= 0, age < ConfettiPhysics.life else { return }
        let k = ConfettiPhysics.drag
        let g = burst.gravity
        let decay = 1 - exp(-k * age)
        let fade = min(1, (ConfettiPhysics.life - age) / 0.6)
        for piece in burst.pieces {
            let x = Double(origin.x) + piece.vx / k * decay
            let y = Double(origin.y) + g / k * age + (piece.vy - g / k) / k * decay
            var layer = context
            layer.opacity = fade
            layer.translateBy(x: x, y: y)
            layer.rotate(by: .radians(piece.spin * age + piece.phase))
            layer.scaleBy(x: cos(piece.flutter * age + piece.phase), y: 1)
            let rect = CGRect(x: -piece.width / 2, y: -piece.height / 2, width: piece.width, height: piece.height)
            let path: Path
            switch piece.kind {
            case 1: path = Path(ellipseIn: rect)
            case 2: path = Path(roundedRect: rect, cornerRadius: 2)
            default: path = Path(rect)
            }
            layer.fill(path, with: .color(piece.color))
        }
    }
}

private struct ConfettiDemo: View {
    let ctx: DemoContext
    @State private var bursts: [ConfettiBurst] = []
    @State private var nextID = 0
    @State private var pops = 0

    var body: some View {
        ZStack {
            TimelineView(.animation(minimumInterval: nil, paused: bursts.isEmpty)) { timeline in
                let now = timeline.date
                let live = bursts
                Canvas { context, size in
                    let origin = CGPoint(x: size.width / 2, y: size.height / 2 + 40)
                    for burst in live {
                        ConfettiPhysics.draw(burst, in: &context, origin: origin, now: now)
                    }
                }
            }
            .allowsHitTesting(false)
            celebrateButton
                .offset(y: 40)
        }
        .overlay(alignment: .bottom) {
            DemoHint(text: L("Tap Celebrate", "点击“庆祝”"), ctx: ctx)
                .padding(.bottom, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 2.6, delay: 0.4) { fire() }
    }

    private var celebrateButton: some View {
        Button(action: fire) {
            Label(ctx.language == .zh ? "庆祝一下" : "Celebrate", systemImage: "sparkles")
                .font(.headline)
                .foregroundStyle(.white)
                .padding(.horizontal, 24)
                .frame(height: 52)
                .background(Palette.sunset, in: Capsule())
                .shadow(color: Palette.coral.opacity(0.4), radius: 14, y: 7)
        }
        .buttonStyle(.plain)
        .keyframeAnimator(initialValue: ConfettiPop(), trigger: pops) { content, pop in
            content.scaleEffect(pop.scale)
        } keyframes: { _ in
            KeyframeTrack(\.scale) {
                CubicKeyframe(0.9, duration: 0.08)
                CubicKeyframe(1.08, duration: 0.14)
                SpringKeyframe(1.0, duration: 0.4, spring: .bouncy)
            }
        }
    }

    private func fire() {
        let now = Date()
        let burst = ConfettiBurst(
            id: nextID,
            start: now,
            gravity: 800 * ctx["gravity"],
            pieces: ConfettiPhysics.makePieces(count: ctx.int("count"), spreadDegrees: ctx["spread"])
        )
        nextID += 1
        pops += 1
        bursts = bursts.filter { now.timeIntervalSince($0.start) < ConfettiPhysics.life } + [burst]
        if !ctx.isPreview { Haptics.tap(.heavy) }
        let id = burst.id
        Task {
            try? await Task.sleep(for: .seconds(ConfettiPhysics.life + 0.1))
            bursts.removeAll { $0.id == id }
        }
    }
}
