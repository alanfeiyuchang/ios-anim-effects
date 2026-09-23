import SwiftUI

extension Effect {
    static let backgroundsMetaballs = Effect(
        id: "backgrounds.metaballs",
        category: .backgrounds,
        interaction: .gesture,
        name: L("Liquid Metaballs", "液态融球"),
        summary: L(
            "Iridescent goo blobs orbit and fuse — your finger becomes one of them.",
            "虹彩液滴环绕流动、彼此融合，手指也会变成其中一滴。"
        ),
        prompt: L(
            "On a near-black plum canvas, several liquid blobs (seven by default) orbit a central pulsing drop along slow Lissajous paths (roughly 7–15 s periods). Whenever two blobs approach they stretch a viscous neck, merge into one smooth surface and pinch apart again, like mercury or a lava lamp seen from above. The liquid is filled with an iridescent pink → violet → sky gradient whose direction slowly rotates, and carries a soft violet bloom around its silhouette. Tapping or dragging sideways across the canvas spawns a finger blob that grows in over ~200 ms and trails the finger with a gentle lag, gooping into any drop it passes; lifting (or ~0.45 s after a tap) shrinks it away. Organic, playful, tactile.",
            "近黑的梅子色画布上，数个液滴（默认七个）绕着一颗中心脉动的主液滴，沿缓慢的李萨如轨迹（周期约 7–15 秒）环绕。两滴靠近时会拉出黏稠的“颈部”，融合成一整块光滑曲面，再缓缓断开，宛如俯视水银或熔岩灯。液体填充粉 → 紫 → 天蓝的虹彩渐变，渐变方向缓慢旋转，轮廓外带一圈柔和紫色辉光。点击或横向拖过画布时，会在约 200 毫秒内长出一个跟随手指、略带延迟的液滴，经过之处与其他液滴黏连融合；松手（或点击约 0.45 秒后）液滴收缩消失。有机、灵动、富有触感。"
        ),
        implementation: L(
            "Canvas with an alphaThreshold filter stacked on a blur filter turns overlapping white circles into a single gooey silhouette, which masks an animated LinearGradient; the bloom is a second, blurred Canvas of the same blobs and the stack renders through drawingGroup() rather than a view shadow. A small model smooths the finger blob.",
            "Canvas 叠加 alphaThreshold 与 blur 滤镜，使重叠的白色圆形变成连续黏稠的轮廓，再作为遮罩显示动态 LinearGradient；辉光由绘制相同液滴的第二个模糊 Canvas 提供，整体经 drawingGroup() 渲染而非视图阴影。小型模型负责平滑手指液滴。"
        ),
        apis: ["Canvas", "GraphicsContext.Filter.alphaThreshold", "GraphicsContext.Filter.blur", "mask", "DragGesture"],
        tags: ["metaball", "goo", "liquid", "blob", "融球", "液态", "黏液", "流体"],
        params: [
            .slider("count", L("Blobs", "液滴数量"), 3...10, default: 7, step: 1, decimals: 0),
            .slider("goo", L("Gooeyness", "黏稠度"), 6...30, default: 16, decimals: 0, unit: "pt"),
            .slider("speed", L("Orbit speed", "环绕速度"), 0.2...2.0, default: 0.8, unit: "×"),
        ]
    ) { ctx in
        MetaballsDemo(ctx: ctx)
    }
}

private final class GooModel {
    let clock = BackgroundClock()
    var touch: CGPoint?
    private(set) var finger: CGPoint?
    private(set) var fingerScale: Double = 0
    /// Speed-scaled time of the last step, read by the bloom layer.
    private(set) var time: Double = 0

    /// Advances time and the smoothed finger blob. `simulated` replaces the touch in previews.
    func step(now: Double, speed: Double, simulated: CGPoint?) -> Double {
        let t = clock.advance(to: now, speed: speed)
        let target = touch ?? simulated
        if let target = target {
            if let current = finger {
                let k = CGFloat(clock.follow(rate: 10))
                finger = CGPoint(x: current.x + (target.x - current.x) * k, y: current.y + (target.y - current.y) * k)
            } else {
                finger = target
            }
        }
        fingerScale += ((target == nil ? 0 : 1) - fingerScale) * clock.follow(rate: 12)
        time = t
        return t
    }

    static func blobs(count: Int, size: CGSize, t: Double) -> [CGRect] {
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let side = min(size.width, size.height)
        let orbit = side * 0.34
        var rects: [CGRect] = []
        let coreRadius = side * CGFloat(0.13 + 0.015 * sin(t * 1.7))
        rects.append(CGRect(x: center.x - coreRadius, y: center.y - coreRadius, width: coreRadius * 2, height: coreRadius * 2))
        for i in 0..<max(count, 0) {
            let a = 0.5 + BackgroundMath.rand(i, 1) * 0.7
            let b = 0.5 + BackgroundMath.rand(i, 2) * 0.7
            let p = BackgroundMath.rand(i, 3) * BackgroundMath.tau
            let x = center.x + orbit * CGFloat(sin(t * a + p))
            let y = center.y + orbit * CGFloat(cos(t * b + p * 1.3))
            let r = side * CGFloat(0.06 + BackgroundMath.rand(i, 4) * 0.06)
            rects.append(CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2))
        }
        return rects
    }
}

private struct MetaballsDemo: View {
    let ctx: DemoContext
    @State private var model = GooModel()
    @State private var size = CGSize(width: 340, height: 340)

    var body: some View {
        TimelineView(.animation(minimumInterval: MotionFrameRate.interval(preview: ctx.isPreview))) { timeline in
            let now = timeline.date.timeIntervalSinceReferenceDate
            // Step once per frame, before either canvas draws, so bloom and goo share the same instant.
            let t = model.step(now: now, speed: ctx["speed"], simulated: simulatedTouch(now: now))
            let spin = now * 0.35
            let dx = CGFloat(0.5 * cos(spin))
            let dy = CGFloat(0.5 * sin(spin))
            ZStack {
                MetaBloom(model: model, t: t, count: ctx.int("count"))
                LinearGradient(
                    colors: [Palette.pink, Palette.violet, Palette.sky],
                    startPoint: UnitPoint(x: 0.5 + dx, y: 0.5 + dy),
                    endPoint: UnitPoint(x: 0.5 - dx, y: 0.5 - dy)
                )
                .mask {
                    GooCanvas(model: model, t: t, ctx: ctx)
                }
            }
            // Bloom comes from a blurred Canvas, and the whole stack renders in one Metal pass
            // instead of an offscreen view shadow on a mask that changes every frame.
            .drawingGroup()
        }
        .background(Color(hex: 0x0D0A1A))
        .onGeometryChange(for: CGSize.self) { proxy in
            proxy.size
        } action: { newSize in
            size = newSize
        }
        .backgroundsTouch { location in model.touch = location } onEnded: { model.touch = nil }
        .backgroundsHint(L("Tap or drag sideways through the liquid", "点击或横向拖过液体"), ctx)
    }

    /// Previews can't be touched, so a Lissajous "finger" wanders through the goo instead.
    private func simulatedTouch(now: Double) -> CGPoint? {
        guard ctx.isPreview else { return nil }
        return CGPoint(
            x: size.width * CGFloat(0.5 + 0.34 * sin(now * 0.8)),
            y: size.height * CGFloat(0.5 + 0.3 * sin(now * 1.15))
        )
    }
}

private struct GooCanvas: View {
    let model: GooModel
    let t: Double
    let ctx: DemoContext

    var body: some View {
        Canvas { context, size in
            context.addFilter(.alphaThreshold(min: 0.5, color: .white))
            context.addFilter(.blur(radius: ctx.cg("goo")))
            context.drawLayer { layer in
                for rect in GooModel.blobs(count: ctx.int("count"), size: size, t: t) {
                    layer.fill(Path(ellipseIn: rect), with: .color(.white))
                }
                if let finger = model.finger, model.fingerScale > 0.01 {
                    let r = min(size.width, size.height) * 0.11 * CGFloat(model.fingerScale)
                    let rect = CGRect(x: finger.x - r, y: finger.y - r, width: r * 2, height: r * 2)
                    layer.fill(Path(ellipseIn: rect), with: .color(.white))
                }
            }
        }
    }
}

/// Violet glow behind the goo: the same blobs, blurred, no threshold, at the frame's shared time `t`.
private struct MetaBloom: View {
    let model: GooModel
    let t: Double
    let count: Int

    var body: some View {
        Canvas { context, size in
            context.addFilter(.blur(radius: 24))
            let color = GraphicsContext.Shading.color(Palette.violet.opacity(0.55))
            for rect in GooModel.blobs(count: count, size: size, t: t) {
                context.fill(Path(ellipseIn: rect.insetBy(dx: -4, dy: -4)), with: color)
            }
            if let finger = model.finger, model.fingerScale > 0.01 {
                let r = min(size.width, size.height) * 0.11 * CGFloat(model.fingerScale) + 4
                context.fill(Path(ellipseIn: CGRect(x: finger.x - r, y: finger.y - r, width: r * 2, height: r * 2)), with: color)
            }
        }
    }
}
