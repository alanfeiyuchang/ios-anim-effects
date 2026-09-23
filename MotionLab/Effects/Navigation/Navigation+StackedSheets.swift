import SwiftUI

extension Effect {
    static let navigationStackedSheets = Effect(
        id: "navigation.stacked-sheets",
        category: .navigation,
        interaction: .tap,
        name: L("Stacked Sheets", "层叠模态面板"),
        summary: L(
            "Each new sheet slides up while everything beneath it shrinks back one step into a deck of cards.",
            "每弹出一层面板，下面的所有层级都向后缩一级，叠成一副卡片。"
        ),
        prompt: L(
            "A phone frame shows a root page. Presenting a sheet slides it up from the bottom to a 34 pt top inset on a spring (response ≈0.5 s, damping 0.86); at the same moment every layer beneath steps back one level — scaling to 93% per level, sheets lifting 10 pt so their top edge peeks above the new one (the root instead sinks 12 pt), rounding its corners and dimming by 12% — so the stack reads as a deck of cards. A second sheet can be pushed from the first, deepening the stack again; dismissing pops one level and every layer springs forward by one step. The root page never leaves; depth is shown purely through scale, offset and shade, exactly like iOS card-style modals.",
            "手机画框里是一张根页面。弹出面板时，面板从底部以弹簧（响应约 0.5 秒、阻尼 0.86）滑到距顶部 34pt 的位置；同时下面的每一层都后退一级——每级缩放到 93%，下层面板上移 10pt 让顶边从新面板上方露出（根页面则下沉 12pt）、圆角变大并变暗 12%——整个堆栈看起来像一副叠放的卡片。可以从第一层面板再推出第二层，堆叠进一步加深；关闭时弹出一层，所有层级再以弹簧前进一级。根页面始终不离开，层级完全通过缩放、位移与明暗表达，与 iOS 卡片式模态完全一致。"
        ),
        implementation: L(
            "Three layers in a ZStack each derive scale, y offset, corner radius and dimming from how many layers sit above them (depth − index); hidden sheets are offset below the frame, and one spring animates every change.",
            "ZStack 中的三层视图各自根据其上方的层数（depth − index）推导缩放、纵向位移、圆角与暗度；尚未弹出的面板位移到画框下方，所有变化由同一个弹簧驱动。"
        ),
        apis: ["ZStack", "scaleEffect(_:anchor:)", "offset(y:)", "spring(response:dampingFraction:)", "clipShape"],
        tags: ["sheet", "modal", "stack", "depth", "面板", "模态", "层叠", "景深"],
        params: [
            .slider("response", L("Spring response", "弹簧响应"), 0.25...0.8, default: 0.5, unit: "s"),
            .slider("damping", L("Damping", "阻尼"), 0.6...1.0, default: 0.86),
            .slider("scale", L("Scale per level", "每级缩放"), 0.85...0.98, default: 0.93),
        ]
    ) { ctx in
        StackedSheetsDemo(ctx: ctx)
    }
}

private struct StackedSheetsDemo: View {
    let ctx: DemoContext
    @State private var depth = 0
    @State private var autoStep = 0

    private let size = CGSize(width: 250, height: 330)
    private let titles: [LocalizedText] = [L("Library", "资料库"), L("Album", "专辑"), L("Share", "分享")]
    private let actions: [LocalizedText] = [L("Open album", "打开专辑"), L("Share…", "分享…"), L("Done", "完成")]
    private let tints: [Color] = [Palette.indigo, Palette.pink, Palette.mint]

    var body: some View {
        VStack(spacing: 14) {
            ZStack(alignment: .top) {
                Color.black
                ForEach(0..<3, id: \.self) { index in
                    layer(index)
                }
            }
            .frame(width: size.width, height: size.height)
            .clipShape(RoundedRectangle(cornerRadius: 34, style: .continuous))
            .shadow(color: .black.opacity(0.18), radius: 18, y: 10)
            DemoHint(text: L("Tap the buttons to push and pop", "点击按钮推入或关闭"), ctx: ctx)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 1.2) {
            let sequence: [Int] = [1, 2, 1, 0]
            setDepth(sequence[autoStep % sequence.count])
            autoStep += 1
        }
    }

    private func layer(_ index: Int) -> some View {
        let visible = index <= depth
        let behind: Int = max(depth - index, 0)
        let scale = CGFloat(pow(ctx["scale"], Double(behind)))
        let topInset: CGFloat = index == 0 ? 0 : 34
        // The root page sinks a little; sheets underneath lift so their top edge peeks out.
        let lift: CGFloat = index == 0 ? CGFloat(behind) * -12 : CGFloat(behind) * 10
        let y: CGFloat = visible ? topInset - lift : size.height + 20
        let radius: CGFloat = index == 0 && behind == 0 ? 34 : 24
        let dim: Double = min(Double(behind) * 0.12, 0.3)
        return content(index)
            .frame(width: size.width, height: size.height - topInset, alignment: .top)
            .background(index == 0 ? Palette.surface : Palette.elevated)
            .overlay(Color.black.opacity(dim).allowsHitTesting(false))
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
            .shadow(color: .black.opacity(index == 0 ? 0 : 0.2), radius: 12, y: -2)
            .scaleEffect(scale, anchor: .top)
            .offset(y: y)
            .allowsHitTesting(index == depth)
            .animation(.spring(response: ctx["response"], dampingFraction: ctx["damping"]), value: depth)
    }

    private func content(_ index: Int) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            if index > 0 {
                Capsule()
                    .fill(Color.secondary.opacity(0.4))
                    .frame(width: 36, height: 5)
                    .frame(maxWidth: .infinity)
            }
            HStack {
                Text(titles[index], ctx.language)
                    .font(.title3.weight(.bold))
                Spacer()
                if index > 0 {
                    Button { setDepth(index - 1) } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .bold))
                            .frame(width: 28, height: 28)
                            .background(Palette.surface, in: Circle())
                    }
                    .buttonStyle(.plain)
                }
            }
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(tints[index].gradient)
                .frame(height: 90)
            PlaceholderLines(count: 2)
            Button { setDepth(index < 2 ? index + 1 : index - 1) } label: {
                Text(actions[index], ctx.language)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 42)
                    .background(tints[index], in: Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 18)
        .padding(.top, index == 0 ? 26 : 10)
    }

    private func setDepth(_ value: Int) {
        let clamped = min(max(value, 0), 2)
        guard clamped != depth else { return }
        if !ctx.isPreview { Haptics.tap(clamped > depth ? .medium : .light) }
        depth = clamped
    }
}
