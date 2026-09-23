import SwiftUI

extension Effect {
    static let navigationTabIndicator = Effect(
        id: "navigation.tab-indicator",
        category: .navigation,
        interaction: .tap,
        name: L("Sliding Tab Indicator", "滑动标签指示器"),
        summary: L(
            "A floating tab bar whose selection pill glides between tabs as icons bounce.",
            "悬浮标签栏：选中胶囊在标签间滑行，图标轻快弹跳。"
        ),
        prompt: L(
            "A floating, frosted capsule tab bar with four icon tabs. The selected tab sits on a gradient pill and reveals its label beside the icon. Tapping another tab slides the pill to it as one continuous shape on a spring (response ≈0.4 s, damping ≈0.78) — it stretches to fit the new label rather than jumping — while the old label collapses and the new one fades in from 80% scale anchored to the icon. The newly selected icon plays a single downward bounce, icon tints cross-fade between white and secondary grey, and a selection haptic fires. Page content above swaps with a soft blur-replace. Fluid, tactile and unmistakably iOS.",
            "一条悬浮的磨砂胶囊标签栏，包含四个图标标签。选中项位于渐变胶囊之上，并在图标旁显示文字。点击其他标签时，胶囊作为同一个连续形状以弹簧（响应约 0.4 秒、阻尼约 0.78）滑向目标，并伸缩以容纳新文字而非瞬移；旧标签文字收起，新文字以图标为锚点从 80% 缩放淡入。新选中的图标做一次向下弹跳，图标颜色在白色与次级灰之间过渡，并触发选择触觉。上方页面内容以柔和的模糊替换切换。流畅、有触感，极具 iOS 味道。"
        ),
        implementation: L(
            "The pill is a Capsule in the selected tab's background tagged with a single matchedGeometryEffect id, so it travels between tabs; icons use symbolEffect(.bounce, value:) driven by per-tab tap counters.",
            "胶囊位于选中标签的背景中，并使用同一个 matchedGeometryEffect ID，因此会在标签间移动；图标使用由每个标签点击计数驱动的 symbolEffect(.bounce, value:)。"
        ),
        apis: ["matchedGeometryEffect", "symbolEffect(.bounce, value:)", "transition(.blurReplace)", "UISelectionFeedbackGenerator"],
        tags: ["tab bar", "indicator", "pill", "bottom navigation", "标签栏", "指示器", "胶囊", "底部导航"],
        params: [
            .slider("response", L("Spring response", "弹簧响应"), 0.2...0.8, default: 0.4, unit: "s"),
            .slider("damping", L("Damping", "阻尼"), 0.5...1.0, default: 0.78),
            .choice("style", L("Indicator", "指示器样式"), [L("Pill + label", "胶囊 + 文字"), L("Dot", "圆点")], default: 0),
        ]
    ) { ctx in
        TabIndicatorDemo(ctx: ctx)
    }
}

private struct TabSpec {
    let symbol: String
    let title: LocalizedText
    let color: Color
}

private let tabSpecs: [TabSpec] = [
    TabSpec(symbol: "house.fill", title: L("Home", "首页"), color: Palette.indigo),
    TabSpec(symbol: "safari.fill", title: L("Explore", "发现"), color: Palette.sky),
    TabSpec(symbol: "heart.fill", title: L("Saved", "收藏"), color: Palette.pink),
    TabSpec(symbol: "person.fill", title: L("Profile", "我的"), color: Palette.amber),
]

private struct TabIndicatorDemo: View {
    let ctx: DemoContext
    @Namespace private var ns
    @State private var selected = 0
    @State private var bounces: [Int] = Array(repeating: 0, count: tabSpecs.count)

    private var pillStyle: Bool { ctx.int("style") == 0 }

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                page
                    .id(selected)
                    .transition(.blurReplace)
            }
            .frame(maxHeight: .infinity)
            tabBar
        }
        .padding(18)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 1.2) { select((selected + 1) % tabSpecs.count) }
    }

    private var page: some View {
        let tab = tabSpecs[selected]
        return VStack(spacing: 12) {
            Image(systemName: tab.symbol)
                .font(.system(size: 38, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 84, height: 84)
                .background(tab.color.gradient, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
                .shadow(color: tab.color.opacity(0.35), radius: 16, y: 8)
            Text(tab.title, ctx.language)
                .font(.title3.weight(.bold))
        }
    }

    private var tabBar: some View {
        HStack(spacing: pillStyle ? 2 : 10) {
            ForEach(0..<tabSpecs.count, id: \.self) { index in
                tabItem(index)
            }
        }
        .padding(6)
        .background(.regularMaterial, in: Capsule())
        .overlay(Capsule().strokeBorder(Palette.stroke))
        .shadow(color: .black.opacity(0.12), radius: 18, y: 8)
    }

    private func tabItem(_ index: Int) -> some View {
        let isSelected = selected == index
        return Button { select(index) } label: {
            HStack(spacing: 6) {
                Image(systemName: tabSpecs[index].symbol)
                    .font(.system(size: 17, weight: .semibold))
                    .symbolEffect(.bounce, value: bounces[index])
                if isSelected && pillStyle {
                    Text(tabSpecs[index].title, ctx.language)
                        .font(.subheadline.weight(.semibold))
                        .fixedSize()
                        .transition(.opacity.combined(with: .scale(scale: 0.8, anchor: .leading)))
                }
            }
            .foregroundStyle(foreground(isSelected))
            .padding(.horizontal, 16)
            .frame(height: 46)
            .background { indicator(isSelected) }
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func indicator(_ isSelected: Bool) -> some View {
        if isSelected {
            if pillStyle {
                Capsule()
                    .fill(Palette.primary)
                    .matchedGeometryEffect(id: "indicator", in: ns)
            } else {
                Circle()
                    .fill(Palette.indigo)
                    .frame(width: 5, height: 5)
                    .matchedGeometryEffect(id: "indicator", in: ns)
                    .frame(maxHeight: .infinity, alignment: .bottom)
                    .padding(.bottom, 2)
            }
        }
    }

    private func foreground(_ isSelected: Bool) -> Color {
        if isSelected { return pillStyle ? .white : Palette.indigo }
        return .secondary
    }

    private func select(_ index: Int) {
        guard index != selected else { return }
        if !ctx.isPreview { Haptics.selection() }
        bounces[index] += 1
        withAnimation(.spring(response: ctx["response"], dampingFraction: ctx["damping"])) {
            selected = index
        }
    }
}
