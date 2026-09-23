import SwiftUI

extension Effect {
    static let scrollStickySections = Effect(
        id: "scroll.sticky-sections",
        category: .scroll,
        interaction: .scroll,
        name: L("Sticky Section Headers", "吸顶分组标题"),
        summary: L("Section headers pin, frost over the content, and get pushed away by the next one.", "分组标题滚动吸顶、覆上磨砂材质，并被下一个标题顶出。"),
        prompt: L(
            "A grouped list — Today, Yesterday, This week — whose section headers rest as large, airy titles with a count pill. When a header reaches the top it pins: in ~300 ms on a snappy spring its title eases from 22 pt to 16 pt, a frosted bar material and hairline fade in behind it, and the count pill tints with the section colour, while rows scroll underneath, softly blurred by the material. As the next section arrives, its header physically pushes the pinned one up and out, then performs the same condensing as it takes over, with a light selection tick. Orderly, native and quietly polished.",
            "分组列表——今天、昨天、本周——各分组标题静止时是大号、疏朗的标题，右侧带数量胶囊。标题滚到顶部即吸顶：约 300 毫秒内以干脆的弹簧从 22 pt 收缩到 16 pt，背后淡入磨砂栏材质与细分隔线，数量胶囊染上分组主题色；列表行从其下方滚过，被材质柔和模糊。下一个分组到来时，其标题会把已吸顶的标题物理地“顶”出屏幕，随后自己完成同样的收缩并接管顶部，伴随一次轻微的选择触感。有序、原生、低调而精致。"
        ),
        implementation: L(
            "LazyVStack(pinnedViews: .sectionHeaders) pins the headers natively; each header measures its own minY in the .scrollView space with onGeometryChange and animates a `pinned` state that drives font size, material and tint.",
            "LazyVStack(pinnedViews: .sectionHeaders) 原生实现吸顶；每个标题通过 onGeometryChange 读取自身在 .scrollView 坐标空间中的 minY，并以动画切换 `pinned` 状态，驱动字号、材质与着色。"
        ),
        apis: ["LazyVStack(pinnedViews:)", "Section", "onGeometryChange", "Material.bar", "ScrollPosition"],
        tags: ["sticky", "section header", "pinned", "grouped list", "吸顶", "分组", "标题", "列表"],
        params: [
            .slider("collapsed", L("Pinned title size", "吸顶字号"), 13...22, default: 16, step: 1, decimals: 0, unit: "pt"),
            .toggle("material", L("Frosted bar", "磨砂背景"), default: true),
            .toggle("tint", L("Tint count pill", "胶囊着色"), default: true),
        ]
    ) { ctx in
        ScrollStickyDemo(ctx: ctx)
    }
}

private struct ScrollStickySection {
    let title: LocalizedText
    let rows: [Int]
    let tint: Color
}

private let scrollStickySections: [ScrollStickySection] = [
    ScrollStickySection(title: L("Today", "今天"), rows: [0, 1, 2, 3], tint: Palette.indigo),
    ScrollStickySection(title: L("Yesterday", "昨天"), rows: [4, 5, 6, 7, 8], tint: Palette.coral),
    ScrollStickySection(title: L("This week", "本周"), rows: [9, 10, 11, 2, 5, 7], tint: Palette.mint),
]

private struct ScrollStickyDemo: View {
    let ctx: DemoContext
    @State private var position = ScrollPosition(edge: .top)
    @State private var step = 0
    @State private var pinnedSection = 0
    /// True while autoplay (or the detail intro) scrolls, so scripted pins stay silent.
    @State private var scripted = false

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 10, pinnedViews: .sectionHeaders) {
                ForEach(scrollStickySections.indices, id: \.self) { s in
                    Section {
                        ForEach(scrollStickySections[s].rows.indices, id: \.self) { r in
                            ScrollKitRow(index: scrollStickySections[s].rows[r], language: ctx.language)
                                .padding(.horizontal, 20)
                        }
                    } header: {
                        ScrollStickyHeader(
                            section: scrollStickySections[s],
                            language: ctx.language,
                            collapsedSize: ctx.cg("collapsed"),
                            material: ctx.bool("material"),
                            tint: ctx.bool("tint"),
                            onPin: { pinnedSection = s }
                        )
                    }
                }
            }
            // A little air above the first header so it starts un-pinned and condenses on the first scroll.
            .padding(.top, 12)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .scrollPosition($position)
        .onScrollPhaseChange { _, newPhase in
            if newPhase == .interacting { scripted = false }
        }
        .sensoryFeedback(.selection, trigger: pinnedSection) { _, _ in !ctx.isPreview && !scripted }
        .autoplay(ctx.isPreview, every: 2.0) { advance() }
    }

    private func advance() {
        let stops: [CGFloat] = [0, 170, 400, 700, 400]
        step = (step + 1) % stops.count
        scripted = true
        withAnimation(.smooth(duration: 1.5)) {
            position.scrollTo(y: stops[step])
        }
    }
}

private struct ScrollStickyHeader: View {
    let section: ScrollStickySection
    let language: AppLanguage
    let collapsedSize: CGFloat
    let material: Bool
    let tint: Bool
    let onPin: () -> Void
    @State private var pinned = false

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(section.title, language)
                .font(.system(size: pinned ? collapsedSize : 22, weight: .bold, design: .rounded))
            Spacer(minLength: 0)
            Text(verbatim: "\(section.rows.count)")
                .font(.caption.weight(.bold))
                .monospacedDigit()
                .foregroundStyle(pinned && tint ? Color.white : Color.secondary)
                .padding(.horizontal, 9)
                .padding(.vertical, 3)
                .background(pinned && tint ? AnyShapeStyle(section.tint) : AnyShapeStyle(Color.primary.opacity(0.07)), in: Capsule())
        }
        .padding(.horizontal, 22)
        // Fixed height: the title condenses inside the bar, so pinning never reflows the rows below.
        .frame(height: 48)
        .background {
            Rectangle()
                .fill(.bar)
                .overlay(alignment: .bottom) {
                    Rectangle().fill(Color.primary.opacity(0.08)).frame(height: 0.5)
                }
                .opacity(pinned && material ? 1 : 0)
        }
        .onGeometryChange(for: Bool.self, of: { proxy in
            proxy.frame(in: .scrollView).minY <= 0.5
        }, action: { isPinned in
            withAnimation(.snappy(duration: 0.3)) { pinned = isPinned }
            if isPinned { onPin() }
        })
    }
}
