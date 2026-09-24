import SwiftUI

extension Effect {
    static let morphTileMosaic = Effect(
        id: "morph.tile-mosaic",
        category: .morph,
        interaction: .tap,
        name: L("Tile Mosaic Reveal", "瓷砖马赛克揭示"),
        summary: L(
            "The new image pops in as a grid of rounded tiles rippling out from where you tap.",
            "新画面以圆角瓷砖网格的形式，从触点向外波纹般逐块弹出。"
        ),
        prompt: L(
            "A 260 × 300 pt album-art card divided into an invisible grid of square tiles, 7 across and 9 rows deep (the last row partial). Tapping anywhere reveals the next cover tile by tile: each tile of the incoming art scales up from its own centre, starting after a delay proportional to its distance from the touch point (the ripple crosses the card in about 55% of the 0.9 s transition), and eases out with a back overshoot so every tile briefly pops to ≈110% before settling. Tiles begin as rounded squares (corner ≈25% of their side) and square off as they finish, so the mosaic fuses into one seamless image with no grout lines. A soft haptic marks the tap. Digital, tactile and rhythmic.",
            "一张 260 × 300pt 的专辑封面卡片，隐含每行 7 块的方形网格（共 9 行，末行不完整）。点击任意位置，下一张封面会逐块揭示：新图的每块瓷砖从自身中心放大出现，启动延迟与其到触点的距离成正比（波纹在 0.9 秒过渡的约 55% 时间内扫过整张卡片），并使用带回拉的缓出曲线，每块会先弹到约 110% 再回落。瓷砖起初是圆角方块（圆角约为边长的 25%），完成时变为直角，因此马赛克最终无缝融合成完整画面、没有砖缝。点击时伴随柔和触觉。数字感、可触、富有节奏。"
        ),
        implementation: L(
            "An Animatable stage view feeds the transition's fraction into a Shape that adds one rounded rect per grid cell, each scaled by a distance-delayed, back-eased local progress; that Shape masks the incoming art, and the tap location comes from onTapGesture(coordinateSpace:).",
            "可动画的舞台视图把过渡小数进度传给一个 Shape：每个网格单元添加一个圆角矩形，按距离延迟并经回拉缓动的局部进度缩放；该 Shape 作为新封面的遮罩，触点来自 onTapGesture(coordinateSpace:)。"
        ),
        apis: ["Animatable", "Shape", "mask", "onTapGesture(coordinateSpace:perform:)", "Path.addRoundedRect"],
        tags: ["mosaic", "tiles", "reveal", "ripple", "马赛克", "瓷砖", "揭示", "波纹"],
        params: [
            .slider("duration", L("Duration", "时长"), 0.4...1.8, default: 0.9, unit: "s"),
            .slider("spread", L("Ripple spread", "波纹扩散"), 0.1...0.8, default: 0.55),
            .slider("columns", L("Columns", "列数"), 4...12, default: 7, step: 1, decimals: 0),
            .slider("overshoot", L("Pop overshoot", "弹出过冲"), 0.0...3.0, default: 1.6),
        ]
    ) { ctx in
        TileMosaicDemo(ctx: ctx)
    }
}

private struct MosaicArt {
    let title: LocalizedText
    let symbol: String
    let colors: [Color]
}

private let mosaicArts: [MosaicArt] = [
    MosaicArt(title: L("Night Drive", "夜行"), symbol: "car.rear.fill", colors: [Color(hex: 0x7B61FF), Color(hex: 0x1B1464)]),
    MosaicArt(title: L("Tidal", "潮汐"), symbol: "water.waves", colors: [Color(hex: 0x21D4A8), Color(hex: 0x2A6DF4)]),
    MosaicArt(title: L("Ember", "余烬"), symbol: "flame.fill", colors: [Color(hex: 0xFFC247), Color(hex: 0xFF4D5E)]),
]

private struct TileMosaicDemo: View {
    let ctx: DemoContext
    @State private var step: Double = 0
    @State private var origin = CGPoint(x: 0.5, y: 0.5)
    @State private var autoIndex = 0

    private let size = CGSize(width: 260, height: 300)

    var body: some View {
        VStack(spacing: 18) {
            MosaicStage(
                step: step,
                origin: origin,
                columns: max(ctx.int("columns"), 2),
                spread: ctx["spread"],
                overshoot: ctx["overshoot"],
                language: ctx.language
            )
            .frame(width: size.width, height: size.height)
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            .shadow(color: .black.opacity(0.2), radius: 18, y: 10)
            .onTapGesture(coordinateSpace: .local) { location in
                reveal(from: CGPoint(x: location.x / size.width, y: location.y / size.height))
            }
            DemoHint(text: L("Tap anywhere on the cover", "点击封面任意位置"), ctx: ctx)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 1.6) {
            let corners: [CGPoint] = [CGPoint(x: 0, y: 0), CGPoint(x: 1, y: 1), CGPoint(x: 0.5, y: 0.5), CGPoint(x: 1, y: 0)]
            autoIndex += 1
            reveal(from: corners[autoIndex % corners.count])
        }
    }

    private func reveal(from point: CGPoint) {
        if !ctx.isPreview { Haptics.tap(.soft) }
        origin = point
        withAnimation(.linear(duration: ctx["duration"])) {
            step += 1
        }
    }
}

private struct MosaicStage: View, Animatable {
    var step: Double
    let origin: CGPoint
    let columns: Int
    let spread: Double
    let overshoot: Double
    let language: AppLanguage

    var animatableData: Double {
        get { step }
        set { step = newValue }
    }

    var body: some View {
        let base: Double = max(step, 0).rounded(.down)
        let t: Double = max(step, 0) - base
        let count = mosaicArts.count
        return ZStack {
            MosaicArtView(art: mosaicArts[Int(base) % count], language: language)
            MosaicArtView(art: mosaicArts[(Int(base) + 1) % count], language: language)
                .mask {
                    MosaicMask(progress: t, origin: origin, columns: columns, spread: spread, overshoot: overshoot)
                }
        }
    }
}

private struct MosaicArtView: View {
    let art: MosaicArt
    let language: AppLanguage

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(colors: art.colors, startPoint: .topLeading, endPoint: .bottomTrailing)
            Image(systemName: art.symbol)
                .font(.system(size: 110, weight: .bold))
                .foregroundStyle(.white.opacity(0.28))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            VStack(alignment: .leading, spacing: 4) {
                Text(art.title, language)
                    .font(.title2.weight(.heavy))
                Text(L("Motionary · EP", "Motionary · EP"), language)
                    .font(.caption.weight(.semibold))
                    .opacity(0.75)
            }
            .foregroundStyle(.white)
            .padding(20)
        }
    }
}

private struct MosaicMask: Shape {
    let progress: Double
    let origin: CGPoint
    let columns: Int
    let spread: Double
    let overshoot: Double

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let cell: CGFloat = rect.width / CGFloat(columns)
        let rows: Int = Int((rect.height / cell).rounded(.up))
        let ox: CGFloat = origin.x * rect.width
        let oy: CGFloat = origin.y * rect.height
        let maxDistance: CGFloat = max(hypot(rect.width, rect.height), 1)
        let span: Double = max(1 - spread, 0.1)
        for row in 0..<rows {
            for column in 0..<columns {
                let cx: CGFloat = rect.minX + (CGFloat(column) + 0.5) * cell
                let cy: CGFloat = rect.minY + (CGFloat(row) + 0.5) * cell
                let distance: CGFloat = hypot(cx - ox, cy - oy) / maxDistance
                let delay: Double = Double(distance) * spread
                let local: Double = min(max((progress - delay) / span, 0), 1)
                guard local > 0 else { continue }
                let scale = CGFloat(backOut(local))
                let side: CGFloat = cell * scale + (local >= 1 ? 1 : 0)
                let radius: CGFloat = max(cell * 0.25 * CGFloat(1 - local), 0)
                let tile = CGRect(x: cx - side / 2, y: cy - side / 2, width: side, height: side)
                path.addRoundedRect(in: tile, cornerSize: CGSize(width: radius, height: radius), style: .continuous)
            }
        }
        return path
    }

    private func backOut(_ x: Double) -> Double {
        let c1: Double = overshoot
        let c3: Double = c1 + 1
        let u: Double = x - 1
        return 1 + c3 * u * u * u + c1 * u * u
    }
}
