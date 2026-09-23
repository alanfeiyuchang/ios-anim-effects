import SwiftUI

extension Effect {
    static let cardsCascadeSpread = Effect(
        id: "cards.cascade-spread",
        category: .cards,
        interaction: .tap,
        name: L("Cascade Spread", "阶梯展开"),
        summary: L("A tight pile of cards tips back in 3D and spreads into an app-switcher-style cascade.", "紧凑的卡堆在三维中向后倾倒，展开成应用切换器式的阶梯。"),
        prompt: L(
            "Four 220×139 pt payment cards sit in a tight pile, each one behind peeking out 8 pt higher and 5% smaller. Tapping tips the whole pile back by 32° around the horizontal axis in perspective and spreads it into a vertical cascade with 54 pt steps, the rear cards getting progressively smaller (88% → 100%), like the iOS app switcher seen from above. Each card travels on its own spring (response 0.5 s, damping 0.76) with a 60 ms stagger — the front card leads when spreading, the rear card leads when collapsing — so the stack unfurls and gathers like a deck being fanned on a table. Shadows grow with height. Architectural, calm and satisfying.",
            "四张 220×139 pt 的支付卡紧紧叠成一摞，后面每张都向上露出 8 pt，并依次缩小 5%。点击后整摞卡片绕水平轴以透视向后倾倒 32°，并展开成纵向阶梯，每级间隔 54 pt，越靠后的卡片越小（88% → 100%），就像俯视 iOS 的应用切换器。每张卡片各自使用弹簧（响应 0.5 秒、阻尼 0.76），并以 60 毫秒错开——展开时最前面的卡片先动，收拢时最后面的卡片先动——整摞卡片像在桌面上摊开又收起的牌。阴影随高度增大。富有秩序感、沉静、令人满足。"
        ),
        implementation: L(
            "Each card derives its offset, scale and rotation3DEffect from a single spread flag; a per-card .animation(spring.delay(…), value: spread) staggers them, with the delay order reversed depending on the direction.",
            "每张卡片由同一个展开标志推导出偏移、缩放与 rotation3DEffect；每张卡片各自带 .animation(spring.delay(…), value: spread) 实现错落，延迟顺序随展开或收拢方向反转。"
        ),
        apis: ["rotation3DEffect", "animation(_:value:)", "Animation.delay", "zIndex", "shadow"],
        tags: ["stack", "cascade", "spread", "app switcher", "堆叠", "阶梯", "展开", "切换器"],
        params: [
            .slider("tilt", L("Tilt", "倾倒角度"), 0...55, default: 32, step: 1, decimals: 0, unit: "°"),
            .slider("gap", L("Step", "阶梯间距"), 30...62, default: 54, step: 1, decimals: 0, unit: "pt"),
            .slider("stagger", L("Stagger", "错落间隔"), 0...0.15, default: 0.06, unit: "s"),
        ]
    ) { ctx in
        CardsCascadeDemo(ctx: ctx)
    }
}

private struct CardsCascadeDemo: View {
    let ctx: DemoContext
    @State private var spread = false

    private let themes = [3, 4, 2, 0]
    private let numbers = ["1180", "6621", "3047", "4821"]

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                ForEach(0..<4, id: \.self) { i in
                    card(i)
                }
            }
            // Room for the full cascade: three steps plus one card.
            .frame(height: 3 * ctx.cg("gap") + 150)
            .contentShape(Rectangle())
            .onTapGesture(perform: toggle)
            DemoHint(text: L("Tap to spread the pile", "点击展开卡堆"), ctx: ctx)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 1.9) { toggle() }
    }

    /// `i == 3` is the front card.
    private func card(_ i: Int) -> some View {
        let fromFront = CGFloat(3 - i)
        let gap = ctx.cg("gap")
        let y: CGFloat = spread ? (CGFloat(i) - 1.5) * gap : 30 - fromFront * 8
        let scale: CGFloat = spread ? 0.88 + CGFloat(i) * 0.04 : 1 - fromFront * 0.05
        let tilt: Double = spread ? ctx["tilt"] : 0
        let stagger = ctx["stagger"]
        let delay = spread ? Double(3 - i) * stagger : Double(i) * stagger
        return CardsCreditCard(theme: themes[i], width: 220, last4: numbers[i])
            .shadow(color: .black.opacity(spread ? 0.22 : 0.14), radius: spread ? 16 : 8, y: spread ? 12 : 5)
            .rotation3DEffect(.degrees(tilt), axis: (x: 1, y: 0, z: 0), perspective: 0.6)
            .scaleEffect(scale)
            .offset(y: y)
            .zIndex(Double(i))
            .animation(.spring(response: 0.5, dampingFraction: 0.76).delay(delay), value: spread)
    }

    private func toggle() {
        Haptics.tap(.soft)
        spread.toggle()
    }
}
