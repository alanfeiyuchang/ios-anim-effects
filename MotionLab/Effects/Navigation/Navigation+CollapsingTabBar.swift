import SwiftUI

extension Effect {
    static let navigationCollapsingTabBar = Effect(
        id: "navigation.collapsing-tab-bar",
        category: .navigation,
        interaction: .scroll,
        name: L("Collapsing Tab Bar", "滚动收起标签栏"),
        summary: L(
            "A floating tab bar shrinks to a single pill as you scroll down and returns when you scroll up.",
            "向下滚动时悬浮标签栏收缩为一枚小胶囊，向上滚动即恢复。"
        ),
        prompt: L(
            "A floating frosted tab bar with four tabs plus a separate circular search button hovers over a scrolling feed. When the user scrolls down past ~24 pt with intent (more than 4 pt per frame), the bar minimises: unselected tabs scale to 60% and fade out while the capsule contracts around the selected icon, all on a smooth spring (response ≈0.4 s, damping ≈0.85), giving the content more room. Any upward scroll, or returning to the top, expands it again with the tabs popping back in. The search button stays put as an anchor. Direction-aware and unobtrusive — the chrome gets out of the way while reading and is instantly available when you reach for it.",
            "一条磨砂质感的悬浮标签栏（四个标签，外加独立的圆形搜索按钮）浮在可滚动的信息流之上。当用户向下滚动超过约 24pt 且意图明确（每帧超过 4pt）时，标签栏最小化：未选中的标签缩小到 60% 并淡出，胶囊收拢到只包住当前选中的图标，全部采用平滑的弹簧（响应约 0.4 秒、阻尼约 0.85），为内容腾出空间。任何向上滚动或回到顶部时，标签栏重新展开，各标签依次弹回。搜索按钮始终保持原位作为锚点。它能感知滚动方向且不打扰：阅读时自动让位，需要时随手可得。"
        ),
        implementation: L(
            "onScrollGeometryChange reports the content offset and compares old/new values to detect direction; a collapsed flag toggles inside withAnimation, removing unselected tabs with a scale-and-fade transition. Previews drive a ScrollPosition.",
            "onScrollGeometryChange 提供内容偏移，比较新旧值判断滚动方向；在 withAnimation 中切换收起状态，以缩放加淡出的转场移除未选中标签。预览模式通过 ScrollPosition 自动滚动。"
        ),
        apis: ["onScrollGeometryChange", "ScrollPosition", "scrollPosition(_:)", "transition(.scale.combined(with: .opacity))"],
        tags: ["tab bar", "minimize", "scroll", "hide on scroll", "标签栏", "最小化", "滚动隐藏", "悬浮"],
        params: [
            .slider("response", L("Spring response", "弹簧响应"), 0.2...0.8, default: 0.4, unit: "s"),
            .slider("sensitivity", L("Direction threshold", "方向阈值"), 1...12, default: 4, decimals: 0, unit: "pt"),
        ]
    ) { ctx in
        CollapsingTabBarDemo(ctx: ctx)
    }
}

private let collapsingTabs: [String] = ["house.fill", "play.square.stack.fill", "bell.fill", "person.fill"]

private struct CollapsingTabBarDemo: View {
    let ctx: DemoContext
    @State private var collapsed = false
    @State private var selected = 0
    @State private var position = ScrollPosition(edge: .top)
    @State private var autoDown = true

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(0..<14, id: \.self) { index in
                    FeedCard(index: index)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
        }
        .scrollIndicators(.hidden)
        .contentMargins(.bottom, 90, for: .scrollContent)
        .scrollPosition($position)
        .onScrollGeometryChange(for: CGFloat.self) { geometry in
            geometry.contentOffset.y + geometry.contentInsets.top
        } action: { oldValue, newValue in
            handleScroll(from: oldValue, to: newValue)
        }
        .overlay(alignment: .bottom) {
            bar.padding(.bottom, 16)
        }
        .autoplay(ctx.isPreview, every: 2.0) {
            withAnimation(.smooth(duration: 1.1)) {
                position.scrollTo(y: autoDown ? 420 : 0)
            }
            autoDown.toggle()
        }
    }

    private var bar: some View {
        HStack(spacing: 10) {
            HStack(spacing: 0) {
                ForEach(0..<collapsingTabs.count, id: \.self) { index in
                    if !collapsed || index == selected {
                        tabButton(index)
                            .transition(.scale(scale: 0.6).combined(with: .opacity))
                    }
                }
            }
            .padding(.horizontal, 6)
            .frame(height: 56)
            .background(.regularMaterial, in: Capsule())
            .overlay(Capsule().strokeBorder(Palette.stroke))
            .shadow(color: .black.opacity(0.12), radius: 16, y: 8)

            Spacer(minLength: 0)

            Image(systemName: "magnifyingglass")
                .font(.system(size: 18, weight: .semibold))
                .frame(width: 56, height: 56)
                .background(.regularMaterial, in: Circle())
                .overlay(Circle().strokeBorder(Palette.stroke))
                .shadow(color: .black.opacity(0.12), radius: 16, y: 8)
        }
        .padding(.horizontal, 20)
    }

    private func tabButton(_ index: Int) -> some View {
        let isSelected = index == selected
        return Button {
            if !ctx.isPreview { Haptics.selection() }
            withAnimation(.snappy) { selected = index }
        } label: {
            Image(systemName: collapsingTabs[index])
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(isSelected ? Palette.indigo : Color.secondary)
                .frame(width: 52, height: 44)
                .background {
                    if isSelected {
                        Capsule().fill(Palette.indigo.opacity(0.14))
                    }
                }
        }
        .buttonStyle(.plain)
    }

    private func handleScroll(from oldValue: CGFloat, to newValue: CGFloat) {
        let delta = newValue - oldValue
        let threshold = ctx.cg("sensitivity")
        var target = collapsed
        if newValue < 24 {
            target = false
        } else if delta > threshold {
            target = true
        } else if delta < -threshold {
            target = false
        }
        guard target != collapsed else { return }
        withAnimation(.spring(response: ctx["response"], dampingFraction: 0.85)) {
            collapsed = target
        }
    }
}

private struct FeedCard: View {
    let index: Int

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Palette.spectrum[index % Palette.spectrum.count].gradient)
                .frame(width: 56, height: 56)
            PlaceholderLines(count: 2)
        }
        .padding(12)
        .demoCard(cornerRadius: 20)
    }
}
