import SwiftUI

extension Effect {
    static let backgroundsLavaLamp = Effect(
        id: "backgrounds.lava-lamp",
        category: .backgrounds,
        interaction: .loop,
        name: L("Lava Lamp", "熔岩灯"),
        summary: L(
            "Warm wax blobs rise, stretch, merge and sink in a slow retro loop.",
            "温暖的蜡滴缓缓升起、拉伸、融合又沉落，复古而悠长。"
        ),
        prompt: L(
            "A deep aubergine backdrop with a soft warm glow at the base. Molten wax — a vertical gradient from butter yellow through tangerine to hot rose — pools along the bottom and ceiling while several free blobs heave up and sink down on long, uneven sine cycles (roughly 10–25 s), drifting gently sideways. Blobs stretch vertically in proportion to their speed and relax back to round as they turn around at the top and bottom, and whenever they meet the pools or each other they neck, fuse into one glossy surface and tear apart again. Each blob carries a soft, blurred specular highlight at its upper left, clipped to the wax so merged shapes stay glossy, and an outer orange bloom haloes the liquid. Movement is slow, heavy and viscous — nostalgic, warm and hypnotic.",
            "深茄紫色背景，底部泛着柔和暖光。熔化的蜡——自奶油黄经橘红到玫瑰红的纵向渐变——在底部与顶部各积成一池，数颗游离的蜡滴沿漫长而不规则的正弦周期（约 10–25 秒）上浮、下沉，并轻微左右漂移。蜡滴按速度比例纵向拉长，在顶部和底部折返时减速并恢复圆润；每当与蜡池或彼此相遇，便拉出细颈、融为一块光润曲面，再重新撕裂分开。每颗蜡滴左上方都有一抹柔和模糊的镜面高光，并被裁切在蜡体之内，融合后的形状依然油亮；液体外缘带一圈橙色辉光。运动缓慢、沉重、黏稠——怀旧、温暖、令人着迷。"
        ),
        implementation: L(
            "Ellipses for blobs and pools are drawn inside a Canvas that stacks alphaThreshold on blur, producing a merged silhouette that masks both a vertical LinearGradient and a blurred specular Canvas; the bloom is a blurred Canvas behind it, all flattened with drawingGroup() instead of a view shadow. Stretch comes from each blob's sine velocity.",
            "蜡滴与蜡池以椭圆绘制在叠加 alphaThreshold 与 blur 滤镜的 Canvas 中，生成的融合轮廓同时遮罩纵向 LinearGradient 与模糊高光 Canvas；辉光由其后方的模糊 Canvas 绘制，整体用 drawingGroup() 合成，取代视图阴影。拉伸量取自每个蜡滴的正弦速度。"
        ),
        apis: ["Canvas", "GraphicsContext.Filter.alphaThreshold", "GraphicsContext.Filter.blur", "mask", "TimelineView(.animation)"],
        tags: ["lava lamp", "blob", "retro", "liquid", "熔岩灯", "液滴", "复古", "流体"],
        params: [
            .slider("count", L("Blobs", "蜡滴数量"), 3...8, default: 5, step: 1, decimals: 0),
            .slider("speed", L("Speed", "速度"), 0.3...3.0, default: 1.0, unit: "×"),
            .slider("goo", L("Viscosity", "黏稠度"), 8...30, default: 18, decimals: 0, unit: "pt"),
        ]
    ) { ctx in
        LavaLampDemo(ctx: ctx)
    }
}

private struct LavaLampDemo: View {
    let ctx: DemoContext
    @State private var clock = BackgroundClock()

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(hex: 0x1C0826), Color(hex: 0x2B0A3D), Color(hex: 0x4A1040)], startPoint: .top, endPoint: .bottom)
            RadialGradient(
                colors: [Color(hex: 0xFF7A3D).opacity(0.35), .clear],
                center: .bottom,
                startRadius: 0,
                endRadius: 280
            )
            TimelineView(.animation(minimumInterval: MotionFrameRate.interval(preview: ctx.isPreview))) { timeline in
                let t = clock.advance(to: timeline.date.timeIntervalSinceReferenceDate, speed: ctx["speed"])
                let count = ctx.int("count")
                let goo = ctx.cg("goo")
                ZStack {
                    LavaBloom(t: t, count: count, goo: goo)
                    ZStack {
                        LinearGradient(
                            colors: [Color(hex: 0xFFD36B), Color(hex: 0xFF8A3D), Color(hex: 0xFF3C7A)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        LavaGloss(t: t, count: count)
                    }
                    .mask {
                        LavaCanvas(t: t, count: count, goo: goo)
                    }
                }
                // One offscreen pass for bloom + wax + gloss, far cheaper than a view shadow on a moving mask.
                .drawingGroup()
            }
        }
    }
}

private struct LavaCanvas: View {
    let t: Double
    let count: Int
    let goo: CGFloat

    var body: some View {
        Canvas { context, size in
            context.addFilter(.alphaThreshold(min: 0.5, color: .white))
            context.addFilter(.blur(radius: goo))
            context.drawLayer { layer in
                for rect in LavaCanvas.shapes(size: size, t: t, count: count) {
                    layer.fill(Path(ellipseIn: rect), with: .color(.white))
                }
            }
        }
    }

    /// Pools first (two), then one rect per free blob.
    fileprivate static func shapes(size: CGSize, t: Double, count: Int) -> [CGRect] {
        let w = size.width
        let h = size.height
        var rects: [CGRect] = [
            CGRect(x: -w * 0.1, y: h * 0.86, width: w * 1.2, height: h * 0.3),
            CGRect(x: w * 0.15, y: -h * 0.12, width: w * 0.7, height: h * 0.18),
        ]
        let side = min(w, h)
        for i in 0..<max(count, 0) {
            let rate = 0.25 + 0.35 * BackgroundMath.rand(i, 1)
            let phase = BackgroundMath.rand(i, 2) * BackgroundMath.tau
            let wave = sin(t * rate + phase)
            let velocity = cos(t * rate + phase)
            let radius = side * CGFloat(0.08 + 0.07 * BackgroundMath.rand(i, 3))
            let stretch = CGFloat(0.16 * abs(velocity))
            let rx = radius * (1 - stretch * 0.6)
            let ry = radius * (1 + stretch)
            let x = w * (0.18 + 0.64 * BackgroundMath.unit(i, 4)) + CGFloat(18 * sin(t * 0.3 + Double(i)))
            let y = h * (0.5 + 0.42 * CGFloat(wave))
            rects.append(CGRect(x: x - rx, y: y - ry, width: rx * 2, height: ry * 2))
        }
        return rects
    }
}

/// Orange halo behind the wax: the same shapes, heavily blurred, without the threshold.
private struct LavaBloom: View {
    let t: Double
    let count: Int
    let goo: CGFloat

    var body: some View {
        Canvas { context, size in
            context.addFilter(.blur(radius: goo + 16))
            for rect in LavaCanvas.shapes(size: size, t: t, count: count) {
                context.fill(Path(ellipseIn: rect.insetBy(dx: -6, dy: -6)), with: .color(Color(hex: 0xFF7A3D).opacity(0.5)))
            }
        }
    }
}

/// Soft specular highlights at the upper left of each free blob (the pools get a long sheen).
private struct LavaGloss: View {
    let t: Double
    let count: Int

    var body: some View {
        Canvas { context, size in
            context.addFilter(.blur(radius: 5))
            context.blendMode = .plusLighter
            let shapes = LavaCanvas.shapes(size: size, t: t, count: count)
            for (index, rect) in shapes.enumerated() {
                let spot: CGRect
                if index < 2 {
                    spot = CGRect(x: rect.minX + rect.width * 0.2, y: rect.minY + rect.height * 0.12, width: rect.width * 0.4, height: 6)
                } else {
                    spot = CGRect(
                        x: rect.minX + rect.width * 0.2,
                        y: rect.minY + rect.height * 0.16,
                        width: rect.width * 0.34,
                        height: rect.height * 0.24
                    )
                }
                context.fill(Path(ellipseIn: spot), with: .color(.white.opacity(0.55)))
            }
        }
    }
}
