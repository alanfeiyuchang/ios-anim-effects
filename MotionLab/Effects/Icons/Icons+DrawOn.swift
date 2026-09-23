import SwiftUI

extension Effect {
    static let iconsDrawOn = Effect(
        id: "icons.draw-on",
        category: .icons,
        interaction: .state,
        name: L("Symbol Draw On", "符号笔绘"),
        summary: L("SF Symbols 7 glyphs draw themselves like a pen stroke.", "SF Symbols 7 图标像钢笔描画一样自行绘出。"),
        prompt: L(
            "Four line-art SF Symbols — a signature, wind, a checkmark seal and a sun — are drawn onto the stage as if by an invisible pen. Each path starts from its natural beginning and the stroke grows along the symbol's own drawing direction with a calligraphic ease-in-out, layers drawing one after another within each symbol (~0.6 s) while all four draw in unison, so the composition assembles in a single hand-written gesture. Toggling back erases the strokes in reverse, like ink being pulled back into the pen. Organic, handcrafted and delightfully precise; on systems before iOS 26 a fade-and-scale appear/disappear stands in.",
            "四个线稿风格的 SF Symbol——签名、风、带对勾的徽章与太阳——仿佛被一支看不见的钢笔描绘到舞台上。每条路径从其自然起点出发，笔触沿符号自身的书写方向以书法般的缓入缓出生长，每个符号内部各图层依次绘制（约 0.6 秒），四个符号同步进行，整个画面像一笔手写动作般组装完成。再次切换时笔画按相反顺序擦除，如同墨水被收回笔中。自然、手作感强又精准；在 iOS 26 之前的系统中以淡入缩放的出现/消失效果替代。"
        ),
        implementation: L(
            "On iOS 26, .symbolEffect(.drawOff…, isActive:) erases the symbol while active and draws it back on when inactive; guarded by #if compiler(>=6.2) and #available with an .appear/.disappear fallback.",
            "iOS 26 上，.symbolEffect(.drawOff…, isActive:) 在激活时擦除符号、取消激活时重新绘出；以 #if compiler(>=6.2) 与 #available 保护，并提供 .appear/.disappear 回退。"
        ),
        apis: ["symbolEffect(.drawOn / .drawOff)", "SF Symbols 7", "#available(iOS 26.0, *)", "DisappearSymbolEffect"],
        tags: ["draw", "draw on", "handwriting", "ios 26", "笔绘", "描边", "手写", "SF Symbols 7"],
        params: [
            .choice("playback", L("Playback", "播放方式"), [L("By layer", "按图层"), L("Whole symbol", "整体"), L("Individually", "逐个")], default: 0),
            .slider("speed", L("Speed", "速度"), 0.5...2, default: 1),
        ],
        requirement: "iOS 26"
    ) { ctx in
        DrawOnDemo(ctx: ctx)
    }
}

private struct DrawOnDemo: View {
    let ctx: DemoContext
    @State private var hidden = true

    private let symbols = ["signature", "wind", "checkmark.seal", "sun.max"]

    var body: some View {
        VStack(spacing: 24) {
            Grid(horizontalSpacing: 34, verticalSpacing: 30) {
                GridRow {
                    DrawSymbol(name: symbols[0], hidden: hidden, ctx: ctx)
                    DrawSymbol(name: symbols[1], hidden: hidden, ctx: ctx)
                }
                GridRow {
                    DrawSymbol(name: symbols[2], hidden: hidden, ctx: ctx)
                    DrawSymbol(name: symbols[3], hidden: hidden, ctx: ctx)
                }
            }
            .font(.system(size: 64, weight: .regular))
            .foregroundStyle(Palette.primary)
            DemoHint(text: L("Tap to draw / erase", "点击绘制 / 擦除"), ctx: ctx)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .onTapGesture { toggle() }
        .autoplay(ctx.isPreview, every: 2.4, delay: 0.3) { toggle() }
        .task {
            if !ctx.isPreview {
                try? await Task.sleep(for: .seconds(0.3))
                toggle()
            }
        }
    }

    private func toggle() {
        withAnimation(.smooth) { hidden.toggle() }
        if !ctx.isPreview && !hidden { Haptics.tap(.soft) }
    }
}

private struct DrawSymbol: View {
    let name: String
    let hidden: Bool
    let ctx: DemoContext

    var body: some View {
        content
            .frame(width: 96, height: 80)
    }

    @ViewBuilder
    private var content: some View {
        #if compiler(>=6.2)
        if #available(iOS 26.0, *) {
            Image(systemName: name)
                .symbolEffect(drawOff, options: .speed(ctx["speed"]), isActive: hidden)
        } else {
            fallback
        }
        #else
        fallback
        #endif
    }

    #if compiler(>=6.2)
    @available(iOS 26.0, *)
    private var drawOff: DrawOffSymbolEffect {
        switch ctx.int("playback") {
        case 1: return .drawOff.wholeSymbol
        case 2: return .drawOff.individually
        default: return .drawOff.byLayer
        }
    }
    #endif

    private var fallback: some View {
        Image(systemName: name)
            .symbolEffect(.disappear.down.byLayer, options: .speed(ctx["speed"]), isActive: hidden)
    }
}
