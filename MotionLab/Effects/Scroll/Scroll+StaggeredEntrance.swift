import SwiftUI

extension Effect {
    static let scrollStaggeredEntrance = Effect(
        id: "scroll.staggered-entrance",
        category: .scroll,
        interaction: .state,
        name: L("Staggered Entrance", "错峰入场列表"),
        summary: L("List rows rise, sharpen and fade in one after another when content loads.", "内容加载时，列表行依次上浮、由模糊变清晰并淡入。"),
        prompt: L(
            "When a list of rounded rows loads, each row starts 28 pt below its resting position at 0% opacity, 96% scale and a 6 pt blur, then springs into place (response ≈0.55 s, damping 0.82) as it sharpens and fades up. Rows enter in reading order with a 60 ms stagger, so the content cascades down the screen like a deck being dealt rather than popping in at once; only the rows in the first screenful are staggered — rows scrolled into view later run the same entrance immediately, with no delay, so long lists stay snappy. Calm, polished and confidence-inspiring.",
            "圆角列表加载时，每一行从静止位置下方 28 pt 处开始，透明度 0%、缩放 96%、模糊 6 pt，随后以弹簧（响应约 0.55 秒、阻尼 0.82）归位，同时变清晰并淡入。各行按阅读顺序错开 60 毫秒依次入场，内容像发牌一样沿屏幕向下倾泻，而不是一次性全部弹出；只有首屏内的行参与错峰——之后滚动进入视野的行会立即执行同样的入场动画、不再等待延迟，保证长列表依旧利落。沉稳、精致，令人信赖。"
        ),
        implementation: L(
            "Each row owns an @State `visible` flag flipped in onAppear inside withAnimation(.spring.delay(index × stagger)) — the delay drops to 0 once the first screen has settled; bumping an .id on the ScrollView recreates the rows to replay the entrance.",
            "每一行持有自己的 @State `visible`，在 onAppear 中于 withAnimation(.spring.delay(序号 × 间隔)) 内切换，首屏布局完成后延迟归零；改变 ScrollView 的 .id 即可重建各行以重播入场。"
        ),
        apis: ["onAppear", "withAnimation", "Animation.delay", "blur", "id(_:)"],
        tags: ["stagger", "entrance", "cascade", "list", "错峰", "入场", "依次出现", "列表"],
        params: [
            .slider("stagger", L("Stagger", "错峰间隔"), 0.02...0.15, default: 0.06, unit: "s"),
            .slider("distance", L("Travel distance", "位移距离"), 0...60, default: 28, step: 1, decimals: 0, unit: "pt"),
            .slider("response", L("Spring response", "弹簧响应"), 0.3...1.0, default: 0.55, unit: "s"),
        ]
    ) { ctx in
        ScrollStaggerDemo(ctx: ctx)
    }
}

private struct ScrollStaggerDemo: View {
    let ctx: DemoContext
    @State private var generation = 0
    /// True once the first screenful has been laid out; rows appearing after that
    /// (scrolled into view) enter immediately instead of waiting for their stagger slot.
    @State private var settled = false

    var body: some View {
        VStack(spacing: 10) {
            ScrollView {
                LazyVStack(spacing: 10) {
                    ForEach(0..<14, id: \.self) { i in
                        ScrollStaggerRow(
                            index: i,
                            language: ctx.language,
                            delay: settled ? 0 : Double(i) * ctx["stagger"],
                            distance: ctx.cg("distance"),
                            response: ctx["response"]
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 14)
            }
            .id(generation)
            .scrollIndicators(.hidden)
            if !ctx.isPreview {
                Button {
                    Haptics.tap()
                    replay()
                } label: {
                    Label(L("Replay", "重播")(ctx.language), systemImage: "arrow.clockwise")
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 9)
                        .background(Palette.elevated, in: Capsule())
                        .overlay(Capsule().strokeBorder(Palette.stroke))
                }
                .buttonStyle(.plain)
                .padding(.bottom, 12)
            }
        }
        .task(id: generation) {
            try? await Task.sleep(for: .seconds(0.35))
            guard !Task.isCancelled else { return }
            settled = true
        }
        .autoplay(ctx.isPreview, every: 3.2) { replay() }
    }

    private func replay() {
        settled = false
        generation += 1
    }
}

private struct ScrollStaggerRow: View {
    let index: Int
    let language: AppLanguage
    let delay: Double
    let distance: CGFloat
    let response: Double
    @State private var visible = false

    var body: some View {
        ScrollKitRow(index: index, language: language)
            .opacity(visible ? 1 : 0)
            .scaleEffect(visible ? 1 : 0.96)
            .blur(radius: visible ? 0 : 6)
            .offset(y: visible ? 0 : distance)
            .onAppear {
                withAnimation(.spring(response: response, dampingFraction: 0.82).delay(delay)) {
                    visible = true
                }
            }
    }
}
