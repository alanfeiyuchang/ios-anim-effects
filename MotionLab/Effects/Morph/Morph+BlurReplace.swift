import SwiftUI

extension Effect {
    static let morphBlurReplace = Effect(
        id: "morph.blur-replace",
        category: .morph,
        interaction: .state,
        name: L("Blur Replace", "模糊替换"),
        summary: L(
            "Status content dissolves through a soft blur while its container reshapes.",
            "状态内容在柔和模糊中溶解替换，容器同步改变形状。"
        ),
        prompt: L(
            "A Dynamic Island–style black capsule and a large status tile below it cycle through live states — AirPods connected, timer running, payment complete, focus on. On each change the outgoing icon and label blur out while scaling down, and the incoming content resolves from a blur while scaling up into place (in the Up-Up style both scale up, so the old content seems to swell away), the two overlapping for a continuous dissolve instead of a hard cut. At the same time the capsule's width springs to the measured width of its new content (response ≈0.45 s, damping ≈0.8), clipping the dissolve inside it, the tile's SF Symbol swaps with a native replace effect, and the accent color tints across. The result reads like one living surface re-forming, not a slideshow.",
            "一枚类似灵动岛的黑色胶囊，以及其下方的大号状态卡片，依次循环展示实时状态：AirPods 已连接、计时进行中、支付完成、专注模式开启。每次切换时，旧的图标与文字在模糊中缩小消散，新内容则由模糊变清晰、同时放大落位（“始终放大”样式下两者都放大，旧内容像膨胀着散去），两者短暂重叠，形成连贯的溶解过渡而非生硬切换。同时胶囊宽度以灵敏的弹簧（响应约 0.45 秒、阻尼约 0.8）过渡到新内容的实测宽度，并把溶解过程裁切在胶囊内，卡片中的 SF Symbol 使用原生替换特效切换，强调色随之过渡。整体像同一块「活」的表面在重组，而非幻灯片翻页。"
        ),
        implementation: L(
            "Each state's content is keyed with .id and uses the built-in .blurReplace transition; the SF Symbol uses contentTransition(.symbolEffect(.replace)) and a hidden sizing copy of the next content is measured with onGeometryChange so the capsule's explicit width springs instead of snapping.",
            "每个状态的内容用 .id 标识并使用内置 .blurReplace 转场；SF Symbol 使用 contentTransition(.symbolEffect(.replace))，隐藏的“测量副本”经 onGeometryChange 读出新内容宽度，胶囊的显式宽度随之弹簧过渡而不会跳变。"
        ),
        apis: [".transition(.blurReplace)", "BlurReplaceTransition", "contentTransition(.symbolEffect(.replace))", "id(_:)"],
        tags: ["blur", "replace", "dynamic island", "content transition", "模糊", "替换", "灵动岛", "内容切换"],
        params: [
            .choice("style", L("Scale", "缩放方式"), [L("Down-Up", "先缩后放"), L("Up-Up", "始终放大")], default: 0),
            .slider("response", L("Spring response", "弹簧响应"), 0.2...1.0, default: 0.45, unit: "s"),
        ]
    ) { ctx in
        BlurReplaceDemo(ctx: ctx)
    }
}

private struct IslandState {
    let symbol: String
    let tint: Color
    let title: LocalizedText
    let detail: LocalizedText
}

private let islandStates: [IslandState] = [
    IslandState(symbol: "airpodspro", tint: .white, title: L("AirPods Pro", "AirPods Pro"), detail: L("Connected · 82%", "已连接 · 82%")),
    IslandState(symbol: "timer", tint: Palette.amber, title: L("Timer", "计时器"), detail: L("04:59 remaining", "剩余 04:59")),
    IslandState(symbol: "checkmark.circle.fill", tint: Palette.green, title: L("Payment complete", "支付完成"), detail: L("¥ 128.00 to Studio", "已向工作室支付 ¥128.00")),
    IslandState(symbol: "moon.fill", tint: Palette.violet, title: L("Focus on", "专注模式"), detail: L("Notifications silenced", "通知已静音")),
]

private struct BlurReplaceDemo: View {
    let ctx: DemoContext
    @State private var index = 0
    @State private var islandWidth: CGFloat?

    private var state: IslandState { islandStates[index % islandStates.count] }
    private var transition: BlurReplaceTransition {
        .blurReplace(ctx.int("style") == 0 ? .downUp : .upUp)
    }

    var body: some View {
        VStack(spacing: 34) {
            island
            tile
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .onTapGesture { advance() }
        .overlay(alignment: .bottom) {
            DemoHint(text: L("Tap to change state", "点击切换状态"), ctx: ctx)
                .padding(.bottom, 14)
        }
        .autoplay(ctx.isPreview, every: 1.6) { advance() }
    }

    private var island: some View {
        ZStack {
            islandContent(state)
                .id(index)
                .transition(transition)
        }
        .frame(width: islandWidth, height: 40)
        .background {
            // Invisible, non-transitioning copy of the current content: its measured width drives
            // the capsule's explicit width, so the capsule springs instead of snapping mid-dissolve.
            islandContent(state)
                .fixedSize()
                .hidden()
                .onGeometryChange(for: CGFloat.self) { proxy in
                    proxy.size.width
                } action: { newWidth in
                    withAnimation(.spring(response: ctx["response"], dampingFraction: 0.8)) {
                        islandWidth = newWidth
                    }
                }
        }
        .padding(.horizontal, 18)
        .background(.black, in: Capsule())
        .clipShape(Capsule())
        .shadow(color: .black.opacity(0.25), radius: 12, y: 6)
    }

    private func islandContent(_ state: IslandState) -> some View {
        HStack(spacing: 10) {
            Image(systemName: state.symbol)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(state.tint)
            Text(state.title, ctx.language)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .fixedSize()
        }
    }

    private var tile: some View {
        VStack(spacing: 14) {
            Image(systemName: state.symbol)
                .font(.system(size: 44, weight: .semibold))
                .foregroundStyle(state.tint == .white ? Palette.indigo : state.tint)
                .contentTransition(.symbolEffect(.replace))
                .frame(height: 56)
            ZStack {
                VStack(spacing: 4) {
                    Text(state.title, ctx.language)
                        .font(.headline)
                    Text(state.detail, ctx.language)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .id(index)
                .transition(transition)
            }
        }
        .frame(width: 230, height: 170)
        .demoCard(cornerRadius: 28)
    }

    private func advance() {
        if !ctx.isPreview { Haptics.selection() }
        withAnimation(.spring(response: ctx["response"], dampingFraction: 0.8)) {
            index += 1
        }
    }
}
