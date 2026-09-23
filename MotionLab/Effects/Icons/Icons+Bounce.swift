import SwiftUI

extension Effect {
    static let iconsBounce = Effect(
        id: "icons.bounce",
        category: .icons,
        interaction: .tap,
        name: L("Symbol Bounce", "符号弹跳"),
        summary: L("SF Symbols hop layer by layer when tapped.", "点击时 SF Symbol 按图层依次弹跳。"),
        prompt: L(
            "A 2×2 grid of glossy, gradient app-style tiles, each holding a white multi-layer SF Symbol (bell with badge, download tray, add-person, paper plane). On tap the symbol performs a single elastic hop: it compresses slightly, springs up ~15% and settles, with each layer offset by a few milliseconds so badges and arrows follow the main shape like secondary motion. Simultaneously the tile dips to 92% and springs back. Snappy (≈0.3 s), friendly and unmistakably native iOS.",
            "2×2 排列的渐变光泽应用风格方块，每块中放置一个白色多图层 SF Symbol（带角标的铃铛、下载托盘、添加联系人、纸飞机）。点击时符号完成一次富有弹性的跳跃：先轻微压缩，再向上弹起约 15% 后回落稳定；各图层之间错开数毫秒，角标和箭头像次级动作一样跟随主体。与此同时方块下沉到 92% 再弹回。节奏利落（约 0.3 秒）、友好，是纯正的 iOS 原生手感。"
        ),
        implementation: L(
            "Image(systemName:) with .symbolEffect(.bounce.up.byLayer, options: .speed(_:), value: count) — a discrete effect that fires whenever the value changes.",
            "Image(systemName:) 配合 .symbolEffect(.bounce.up.byLayer, options: .speed(_:), value: count)——离散效果，每当 value 变化即触发一次。"
        ),
        apis: ["symbolEffect(_:options:value:)", "BounceSymbolEffect", "SymbolEffectOptions.speed", "scaleEffect"],
        tags: ["bounce", "sf symbols", "symbol effect", "icon", "弹跳", "符号动画", "图标", "SF Symbols"],
        params: [
            .choice("direction", L("Direction", "方向"), [L("Up", "向上"), L("Down", "向下")], default: 0),
            .toggle("byLayer", L("By layer", "按图层"), default: true),
            .slider("speed", L("Speed", "速度"), 0.5...2, default: 1),
        ]
    ) { ctx in
        BounceDemo(ctx: ctx)
    }
}

private struct BounceTileModel {
    let symbol: String
    let colors: [Color]
}

private struct BounceDemo: View {
    let ctx: DemoContext
    @State private var counts = [0, 0, 0, 0]
    /// Scripted press dips for simulated taps (real touches get theirs from `TilePressStyle`).
    @State private var pressed = [false, false, false, false]
    @State private var autoIndex = 0

    private let tiles: [BounceTileModel] = [
        BounceTileModel(symbol: "bell.badge.fill", colors: [Palette.coral, Palette.pink]),
        BounceTileModel(symbol: "square.and.arrow.down.fill", colors: [Palette.sky, Palette.blue]),
        BounceTileModel(symbol: "person.crop.circle.badge.plus", colors: [Palette.mint, Palette.green]),
        BounceTileModel(symbol: "paperplane.fill", colors: [Palette.indigo, Palette.violet]),
    ]

    private var effect: BounceSymbolEffect {
        let base: BounceSymbolEffect = ctx.int("direction") == 1 ? .bounce.down : .bounce.up
        return ctx.bool("byLayer") ? base.byLayer : base.wholeSymbol
    }

    var body: some View {
        VStack(spacing: 20) {
            LazyVGrid(columns: [GridItem(.fixed(96), spacing: 18), GridItem(.fixed(96), spacing: 18)], spacing: 18) {
                ForEach(0..<tiles.count, id: \.self) { i in
                    BounceTile(
                        model: tiles[i],
                        count: counts[i],
                        effect: effect,
                        speed: ctx["speed"],
                        pressed: pressed[i]
                    ) { tap(i) }
                }
            }
            DemoHint(text: L("Tap any tile", "点击任意图标"), ctx: ctx)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 0.7) {
            simulatePress(autoIndex % tiles.count)
            autoIndex += 1
        }
    }

    /// A simulated tap: dip the tile to 92% like a real press, then release and bounce the symbol.
    private func simulatePress(_ i: Int) {
        withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) { pressed[i] = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { pressed[i] = false }
            tap(i, haptic: false)
        }
    }

    private func tap(_ i: Int, haptic: Bool = true) {
        counts[i] += 1
        if haptic && !ctx.isPreview { Haptics.tap(.light) }
    }
}

private struct BounceTile: View {
    let model: BounceTileModel
    let count: Int
    let effect: BounceSymbolEffect
    let speed: Double
    let pressed: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: model.symbol)
                .font(.system(size: 38, weight: .semibold))
                .foregroundStyle(.white)
                .symbolEffect(effect, options: .speed(speed), value: count)
                .frame(width: 96, height: 96)
                .background(
                    LinearGradient(colors: model.colors, startPoint: .topLeading, endPoint: .bottomTrailing),
                    in: RoundedRectangle(cornerRadius: 26, style: .continuous)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .strokeBorder(.white.opacity(0.25), lineWidth: 1)
                )
                .shadow(color: (model.colors.last ?? .black).opacity(0.35), radius: 14, y: 8)
                .scaleEffect(pressed ? 0.92 : 1)
        }
        .buttonStyle(TilePressStyle())
    }
}

private struct TilePressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}
