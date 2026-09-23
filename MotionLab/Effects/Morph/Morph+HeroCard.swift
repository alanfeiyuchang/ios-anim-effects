import SwiftUI

extension Effect {
    static let morphHeroCard = Effect(
        id: "morph.hero-card",
        category: .morph,
        interaction: .tap,
        name: L("Hero Card Expand", "卡片展开转场"),
        summary: L(
            "App Store–style story cards that open into a full article.",
            "App Store 式故事卡片，点击展开为完整文章。"
        ),
        prompt: L(
            "A feed of rounded story cards (22 pt continuous corners), each with a bold gradient artwork, eyebrow label and headline. Touch-down sinks the card to about 96% scale; on release the card lifts out of the feed and expands to fill the whole screen, its frame, corner radius and artwork re-flowing on one spring (response ≈0.55 s, damping ≈0.8) while the headline stays locked to the artwork. The remaining cards dim and recede to 92%, and the article — a byline and two paragraphs — fades up 12 pt in a 50 ms stagger about 150 ms after the expansion begins. A circular close button fades in top-left; closing reverses the morph back into the exact slot the card came from, leaving an empty placeholder in the feed while open.",
            "信息流中是一组连续圆角（22pt）的故事卡片，每张有醒目的渐变插图、小标签与大标题。手指按下时卡片下沉到约 96%；松手后卡片从列表中「浮起」并展开铺满整个屏幕，外框、圆角与插图区域在同一条弹簧（响应约 0.55 秒、阻尼约 0.8）中重新排版，标题始终贴合插图。其余卡片变暗并缩小到 92%，文章署名与两段正文在展开开始约 150 毫秒后上浮 12pt 依次淡入，每段错开 50 毫秒。左上角圆形关闭按钮随之出现；关闭时反向形变，精准回到原来的位置，展开期间原位只留下空槽。"
        ),
        implementation: L(
            "Each card is swapped for an expanded twin sharing a matchedGeometryEffect id, so the frame interpolates while the content re-lays out; a custom ButtonStyle provides the press sink.",
            "列表中的卡片与展开态共享 matchedGeometryEffect ID，外框插值的同时内容实时重排；自定义 ButtonStyle 提供按压下沉。"
        ),
        apis: ["matchedGeometryEffect", "ButtonStyle", "zIndex", "spring(response:dampingFraction:)"],
        tags: ["app store", "today card", "hero", "expand", "卡片转场", "卡片展开", "今日卡片", "转场"],
        params: [
            .slider("response", L("Spring response", "弹簧响应"), 0.25...1.0, default: 0.55, unit: "s"),
            .slider("damping", L("Damping", "阻尼"), 0.5...1.0, default: 0.8),
            .slider("press", L("Press scale", "按压缩放"), 0.9...1.0, default: 0.96),
        ]
    ) { ctx in
        HeroCardDemo(ctx: ctx)
    }
}

private struct HeroStory: Identifiable {
    let id: Int
    let symbol: String
    let colors: [Color]
    let eyebrow: LocalizedText
    let title: LocalizedText
    let paragraphs: [LocalizedText]
}

private let heroStories: [HeroStory] = [
    HeroStory(id: 0, symbol: "wind", colors: [Palette.amber, Palette.coral, Palette.pink],
              eyebrow: L("MOTION OF THE DAY", "今日动效"), title: L("Designing with springs", "用弹簧做设计"),
              paragraphs: [
                  L("Springs don't have a duration — they have a feel. Response sets how quickly a view reaches its target; damping decides whether it overshoots.",
                    "弹簧没有“时长”，只有“手感”。响应决定视图多快抵达目标，阻尼决定它是否冲过头。"),
                  L("Start near 0.5 s and 0.8, then tune by hand: a card that lands with a whisper of bounce feels caught, not placed.",
                    "从 0.5 秒、0.8 起步再亲手微调：带一丝回弹落定的卡片，像被稳稳接住，而不是被摆放。"),
              ]),
    HeroStory(id: 1, symbol: "sparkles", colors: [Palette.sky, Palette.blue, Palette.violet],
              eyebrow: L("STUDIO NOTES", "设计札记"), title: L("The art of easing", "缓动的艺术"),
              paragraphs: [
                  L("Easing is how motion breathes. Ease-out feels responsive because it starts fast and settles gently, like a ball caught in a glove.",
                    "缓动是动效的呼吸。缓出曲线起步快、收尾柔，像被手套稳稳接住的球，所以显得灵敏。"),
                  L("Save ease-in for exits, and never use linear timing for anything that travels across the screen.",
                    "缓入留给退场；任何横穿屏幕的运动，都别用线性曲线。"),
              ]),
]

private struct HeroCardDemo: View {
    let ctx: DemoContext
    @Namespace private var ns
    @State private var selected: Int?
    @State private var showBody = false
    @State private var autoIndex = 0

    private var spring: Animation {
        .spring(response: ctx["response"], dampingFraction: ctx["damping"])
    }

    var body: some View {
        ZStack {
            feed
            if let id = selected, let story = heroStories.first(where: { $0.id == id }) {
                HeroExpanded(story: story, language: ctx.language, showBody: showBody, onClose: close)
                    .matchedGeometryEffect(id: story.id, in: ns)
                    .zIndex(1)
                    .onAppear { showBody = true }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(alignment: .bottom) {
            DemoHint(text: L("Tap a story card", "点击一张故事卡片"), ctx: ctx)
            .padding(.bottom, 12)
            .opacity(selected == nil ? 1 : 0)
            .allowsHitTesting(false)
        }
        .autoplay(ctx.isPreview, every: 2.2) {
            if selected == nil {
                open(heroStories[autoIndex % heroStories.count].id)
                autoIndex += 1
            } else {
                close()
            }
        }
    }

    private var feed: some View {
        VStack(spacing: 14) {
            ForEach(heroStories) { story in
                if selected == story.id {
                    Color.clear.frame(height: 132)
                } else {
                    Button { open(story.id) } label: {
                        HeroArtwork(story: story, language: ctx.language, expanded: false)
                            .frame(height: 132)
                            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                    }
                    .buttonStyle(HeroPressStyle(scale: ctx.cg("press")))
                    .matchedGeometryEffect(id: story.id, in: ns)
                    .shadow(color: .black.opacity(0.14), radius: 14, y: 8)
                }
            }
        }
        .padding(.horizontal, 22)
        .scaleEffect(selected == nil ? 1 : 0.92)
        .opacity(selected == nil ? 1 : 0.4)
    }

    private func open(_ id: Int) {
        if !ctx.isPreview { Haptics.tap(.medium) }
        withAnimation(spring) { selected = id }
    }

    private func close() {
        if !ctx.isPreview { Haptics.tap() }
        showBody = false
        withAnimation(spring) { selected = nil }
    }
}

private struct HeroArtwork: View {
    let story: HeroStory
    let language: AppLanguage
    let expanded: Bool

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(colors: story.colors, startPoint: .topLeading, endPoint: .bottomTrailing)
            Image(systemName: story.symbol)
                .font(.system(size: expanded ? 96 : 64, weight: .semibold))
                .foregroundStyle(.white.opacity(0.35))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .padding(expanded ? 26 : 16)
            VStack(alignment: .leading, spacing: 4) {
                Text(story.eyebrow, language)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.white.opacity(0.8))
                Text(story.title, language)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.white)
            }
            .padding(18)
        }
    }
}

private struct HeroExpanded: View {
    let story: HeroStory
    let language: AppLanguage
    let showBody: Bool
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HeroArtwork(story: story, language: language, expanded: true)
                .frame(height: 190)
            VStack(alignment: .leading, spacing: 10) {
                Text(language == .zh ? "阅读 3 分钟 · 动效词典编辑部" : "3 min read · Motion Lexicon Editors")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .modifier(HeroBodyReveal(visible: showBody, index: 0))
                ForEach(Array(story.paragraphs.enumerated()), id: \.offset) { index, paragraph in
                    Text(paragraph, language)
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                        .modifier(HeroBodyReveal(visible: showBody, index: index + 1))
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Palette.elevated)
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .overlay(alignment: .topLeading) {
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.footnote.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(width: 32, height: 32)
                    .background(.black.opacity(0.25), in: Circle())
            }
            .buttonStyle(.plain)
            .padding(14)
            .opacity(showBody ? 1 : 0)
            .animation(.easeOut(duration: 0.2).delay(showBody ? 0.2 : 0), value: showBody)
        }
    }
}

/// Article lines fade up ~150 ms after the expansion starts, 50 ms apart; they vanish at once on close.
private struct HeroBodyReveal: ViewModifier {
    let visible: Bool
    let index: Int

    func body(content: Content) -> some View {
        content
            .opacity(visible ? 1 : 0)
            .offset(y: visible ? 0 : 12)
            .animation(
                visible ? .spring(response: 0.5, dampingFraction: 0.9).delay(0.15 + Double(index) * 0.05) : .easeOut(duration: 0.1),
                value: visible
            )
    }
}

private struct HeroPressStyle: ButtonStyle {
    let scale: CGFloat

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}
