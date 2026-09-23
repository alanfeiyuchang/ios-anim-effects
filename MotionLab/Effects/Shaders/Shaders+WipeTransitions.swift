import SwiftUI

// Two more "Shader Transitions": a rising liquid wipe and a radial tile scatter.
// Both render the incoming scene underneath and run a layer shader on the outgoing one;
// when the animation completes the scenes swap without animation, so the loop is seamless.

extension Effect {
    static let shaderLiquidWipe = Effect(
        id: "shader.liquid-wipe",
        category: .shaders,
        interaction: .tap,
        name: L("Liquid Wipe", "液面擦除"),
        summary: L(
            "A wavy waterline rises through the card, washing the old scene away to reveal the next.",
            "一道起伏的水线从卡片底部升起，冲走旧画面，露出下一幕。"
        ),
        prompt: L(
            "Tapping the card floods it: a liquid surface rises from the bottom edge to past the top over 1.1 s (ease-in-out). The waterline is two summed sine waves drifting in opposite directions, and its height follows sin(π·progress) — flat as it enters, up to 14 pt tall mid-way, flat again as it leaves. Below the line the outgoing scene is gone and the incoming one shows through; just above it the old content is pulled down toward the surface like a meniscus (exponential falloff, 16 pt), and a bright 2 pt rim traces the waterline. At the end the scenes swap invisibly, ready for the next tap. Fluid, fresh and a little playful.",
            "点击卡片会让它“进水”：液面在 1.1 秒内（ease-in-out）从底边升起，直到越过顶部。水线由两道反向漂移的正弦波叠加而成，其波高遵循 sin(π·进度)——进入时平坦，中途最高约 14pt，离开时再次变平。水线以下旧画面消失、新画面透出；水线正上方的旧内容像弯月面一样被向下拉向液面（指数衰减，约 16pt），一条约 2pt 的明亮边缘勾勒出水线。结束时两幅画面无痕互换，等待下一次点击。流畅、清新，又带点俏皮。"
        ),
        implementation: L(
            "A [[stitchable]] layer shader on the top scene computes the wavy level, clears pixels below it, displaces samples just above it and adds an anti-aliased rim masked by the card's own alpha; progress is an Animatable value and withAnimation's completion swaps the scenes inside a no-animation Transaction.",
            "顶层画面上的 [[stitchable]] layerEffect 着色器计算起伏水位，清除水位以下的像素、偏移水位正上方的采样，并叠加由卡片自身 alpha 遮罩的抗锯齿亮边；进度是 Animatable 数值，withAnimation 的 completion 在禁用动画的 Transaction 中互换画面。"
        ),
        apis: ["layerEffect", "Animatable", "withAnimation(_:_:completion:)", "Transaction", "Metal"],
        tags: ["wipe", "liquid", "transition", "water", "擦除", "液体", "转场", "水面"],
        params: [
            .slider("amplitude", L("Wave height", "波高"), 2...28, default: 14, decimals: 0, unit: "pt"),
            .slider("duration", L("Duration", "时长"), 0.5...2.5, default: 1.1, unit: "s"),
        ]
    ) { ctx in
        LiquidWipeDemo(ctx: ctx)
    }

    static let shaderTileScatter = Effect(
        id: "shader.tile-scatter",
        category: .shaders,
        interaction: .tap,
        name: L("Tile Scatter", "方块散逸"),
        summary: L(
            "The card breaks into tiles that flash, twist and shrink away in a wave from your tap.",
            "卡片碎成方块，以点击处为中心一波波闪亮、扭转并缩小消失。"
        ),
        prompt: L(
            "Tapping the card cuts it into a grid of 22 pt tiles and dissolves them in a radial wave that starts at the finger. Each tile waits until the front reaches it (delay proportional to distance × spread), then runs its own smoothstep: it flashes about 35% brighter for the first moments, shrinks about its own center to nothing while turning in a random direction by up to ±1.2 rad at vanishing (rotation grows with the square of progress, so tiles never clip their cell), and fades as it goes. The next scene is revealed underneath, tile by tile. Total run ≈ 1.1 s with ease-in-out; the swap at the end is invisible. Digital, satisfying and precise.",
            "点击卡片后，它被切成 22pt 的方块网格，并以手指为起点呈放射状一波波散逸。每个方块会等到波前到达（延迟与距离 × 扩散系数成正比）才开始自己的 smoothstep：先短暂提亮约 35%，再围绕自身中心缩小至消失，同时向随机方向旋转，消失时最多 ±1.2 弧度（旋转随进度平方增长，因此方块不会超出自己的格子），并逐渐淡出。下一幕在下方逐块显现。整体约 1.1 秒、ease-in-out；结束时的画面互换完全无痕。数字感、满足感、精准。"
        ),
        implementation: L(
            "A [[stitchable]] layer shader finds each pixel's tile, computes that tile's delayed local progress from its distance to the tap, inverse-rotates and scales the pixel into tile space and samples the tile center region; progress is Animatable and the scenes swap on completion.",
            "[[stitchable]] layerEffect 着色器确定像素所在方块，依据方块到点击点的距离计算其延迟后的局部进度，再把像素逆旋转、缩放到方块空间并在格内采样；进度为 Animatable，完成时互换画面。"
        ),
        apis: ["layerEffect", "Animatable", "onTapGesture(coordinateSpace:perform:)", "withAnimation(_:_:completion:)", "Metal"],
        tags: ["tiles", "shatter", "mosaic", "transition", "方块", "碎裂", "马赛克", "转场"],
        params: [
            .slider("tile", L("Tile size", "方块尺寸"), 10...40, default: 22, decimals: 0, unit: "pt"),
            .slider("spread", L("Wave spread", "扩散系数"), 0.3...1.5, default: 0.9),
            .slider("duration", L("Duration", "时长"), 0.6...2.0, default: 1.1, unit: "s"),
        ]
    ) { ctx in
        TileScatterDemo(ctx: ctx)
    }
}

/// Artwork variants the transitions cycle through, and the fixed card size the shaders assume.
private enum SwapScenes {
    static let variants = [1, 5, 7, 3]
    static let size = CGSize(width: 260, height: 300)

    static func variant(_ index: Int) -> Int {
        variants[((index % variants.count) + variants.count) % variants.count]
    }
}

// MARK: - Liquid wipe

private struct LiquidWipeDemo: View {
    let ctx: DemoContext
    @State private var current = 0
    @State private var progress: Double = 0
    @State private var busy = false

    var body: some View {
        let amplitude = ctx["amplitude"]
        VStack(spacing: 14) {
            // The waves only show while the wipe runs, so the clock (and the two artworks) idle at rest.
            ShaderClock(paused: !busy, preview: ctx.isPreview) { time in
                ZStack {
                    ShaderArtwork(variant: SwapScenes.variant(current + 1))
                    ShaderArtwork(variant: SwapScenes.variant(current))
                        .modifier(LiquidWipeModifier(progress: progress, amplitude: amplitude, time: time))
                }
            }
            .frame(width: SwapScenes.size.width, height: SwapScenes.size.height)
            .contentShape(Rectangle())
            .onTapGesture { advance() }
            DemoHint(text: L("Tap to flood the card", "点击让卡片“进水”"), ctx: ctx)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: ctx["duration"] + 1.0, delay: 0.4) { advance() }
    }

    private func advance() {
        guard !busy else { return }
        busy = true
        Haptics.tap(.soft)
        withAnimation(.easeInOut(duration: ctx["duration"])) {
            progress = 1
        } completion: {
            var transaction = Transaction()
            transaction.disablesAnimations = true
            withTransaction(transaction) {
                current += 1
                progress = 0
            }
            busy = false
        }
    }
}

private struct LiquidWipeModifier: ViewModifier, Animatable {
    var progress: Double
    var amplitude: Double
    var time: Double

    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    func body(content: Content) -> some View {
        content.layerEffect(
            ShaderLibrary.mlLiquidWipe(.float2(SwapScenes.size), .float(progress), .float(amplitude), .float(time)),
            maxSampleOffset: CGSize(width: 0, height: amplitude + 2),
            isEnabled: progress > 0.0001
        )
    }
}

// MARK: - Tile scatter

private struct TileScatterDemo: View {
    let ctx: DemoContext
    @State private var current = 0
    @State private var progress: Double = 0
    @State private var origin = CGPoint(x: 130, y: 150)
    @State private var busy = false

    var body: some View {
        VStack(spacing: 14) {
            ZStack {
                ShaderArtwork(variant: SwapScenes.variant(current + 1))
                ShaderArtwork(variant: SwapScenes.variant(current))
                    .modifier(TileScatterModifier(progress: progress, origin: origin, tile: ctx["tile"], spread: ctx["spread"]))
            }
            .frame(width: SwapScenes.size.width, height: SwapScenes.size.height)
            .contentShape(Rectangle())
            .onTapGesture(coordinateSpace: .local) { location in scatter(from: location) }
            DemoHint(text: L("Tap anywhere on the card", "点击卡片任意位置"), ctx: ctx)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: ctx["duration"] + 1.0, delay: 0.4) {
            scatter(from: CGPoint(x: CGFloat.random(in: 40...220), y: CGFloat.random(in: 40...260)))
        }
    }

    private func scatter(from point: CGPoint) {
        guard !busy else { return }
        busy = true
        origin = point
        Haptics.tap(.rigid)
        withAnimation(.easeInOut(duration: ctx["duration"])) {
            progress = 1
        } completion: {
            var transaction = Transaction()
            transaction.disablesAnimations = true
            withTransaction(transaction) {
                current += 1
                progress = 0
            }
            busy = false
        }
    }
}

private struct TileScatterModifier: ViewModifier, Animatable {
    var progress: Double
    var origin: CGPoint
    var tile: Double
    var spread: Double

    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    func body(content: Content) -> some View {
        content.layerEffect(
            ShaderLibrary.mlTileScatter(
                .float2(SwapScenes.size),
                .float2(origin),
                .float(progress),
                .float(tile),
                .float(spread)
            ),
            maxSampleOffset: CGSize(width: tile * 1.5, height: tile * 1.5),
            isEnabled: progress > 0.0001
        )
    }
}
