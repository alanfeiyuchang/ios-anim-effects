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
            "A floating frosted tab bar with four tabs plus a separate circular search button hovers over a scrolling feed. Once the user has scrolled about 24 pt of net downward travel since the last change of direction, the bar minimizes: unselected tabs scale to 60% and fade out while the capsule contracts around the selected icon, all on a smooth spring (response ≈0.4 s, damping ≈0.85), giving the content more room. About 12 pt of net upward travel, a tap on the minimized pill, or returning to the top expands it again with the tabs popping back in, so slow deliberate scrolls work too. The search button stays put as an anchor. Direction-aware and unobtrusive — the chrome gets out of the way while reading and is instantly available when you reach for it.",
            "一条磨砂质感的悬浮标签栏（四个标签，外加独立的圆形搜索按钮）浮在可滚动的信息流之上。自上次换向起累计向下滚动约 24pt 后，标签栏最小化：未选中的标签缩小到 60% 并淡出，胶囊收拢到只包住当前选中的图标，全部采用平滑的弹簧（响应约 0.4 秒、阻尼约 0.85），为内容腾出空间。累计向上约 12pt、轻点收起的胶囊或回到顶部时，标签栏重新展开，各标签依次弹回；缓慢滚动同样灵敏。搜索按钮始终保持原位作为锚点。它能感知滚动方向且不打扰：阅读时自动让位，需要时随手可得。"
        ),
        implementation: L(
            "onScrollGeometryChange reports the content offset and accumulates the net travel since the last direction reversal (collapse after the threshold down, expand after half of it up); a collapsed flag toggles inside withAnimation, removing unselected tabs with a scale-and-fade transition. Previews drive a ScrollPosition.",
            "onScrollGeometryChange 提供内容偏移，累计自上次换向以来的净滚动距离（向下超过阈值收起，向上超过一半展开）；在 withAnimation 中切换收起状态，以缩放加淡出的转场移除未选中标签。预览模式通过 ScrollPosition 自动滚动。"
        ),
        apis: ["onScrollGeometryChange", "ScrollPosition", "scrollPosition(_:)", "transition(.scale.combined(with: .opacity))"],
        tags: ["tab bar", "minimize", "scroll", "hide on scroll", "标签栏", "最小化", "滚动隐藏", "悬浮"],
        params: [
            .slider("response", L("Spring response", "弹簧响应"), 0.2...0.8, default: 0.4, unit: "s"),
            .slider("sensitivity", L("Collapse distance", "收起距离"), 8...60, default: 24, decimals: 0, unit: "pt"),
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
    /// Signed scroll travel since the last direction reversal, so slow scrolls add up (and 120 Hz frames don't
    /// halve the sensitivity).
    @State private var travel: CGFloat = 0

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(ctx.language == .zh ? "为你推荐" : "For You")
                        .font(.title2.weight(.bold))
                    DemoHint(text: L("Scroll down to shrink the bar, up to restore it", "向下滚动收起标签栏，向上滚动恢复"), ctx: ctx)
                }
                .padding(.horizontal, 4)
                ForEach(0..<14, id: \.self) { index in
                    FeedCard(index: index, language: ctx.language)
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
            .demoGlass(Capsule(), material: .regularMaterial)
            .overlay(Capsule().strokeBorder(Palette.stroke))
            .shadow(color: .black.opacity(0.12), radius: 16, y: 8)

            Spacer(minLength: 0)

            Image(systemName: "magnifyingglass")
                .font(.system(size: 18, weight: .semibold))
                .frame(width: 56, height: 56)
                .demoGlass(Circle(), material: .regularMaterial)
                .overlay(Circle().strokeBorder(Palette.stroke))
                .shadow(color: .black.opacity(0.12), radius: 16, y: 8)
        }
        .padding(.horizontal, 20)
    }

    private func tabButton(_ index: Int) -> some View {
        let isSelected = index == selected
        return Button {
            if !ctx.isPreview { Haptics.selection() }
            if collapsed {
                // Tapping the minimized pill brings the full bar back, as on iOS 26.
                travel = 0
                setCollapsed(false)
            } else {
                withAnimation(.snappy) { selected = index }
            }
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
        let delta: CGFloat = newValue - oldValue
        guard newValue >= 24 else {
            travel = 0
            setCollapsed(false)
            return
        }
        guard delta != 0 else { return }
        // A change of direction starts a fresh tally.
        if travel != 0 && (delta > 0) != (travel > 0) { travel = 0 }
        travel += delta
        let collapseAfter: CGFloat = ctx.cg("sensitivity")
        if travel > collapseAfter {
            setCollapsed(true)
        } else if travel < -collapseAfter / 2 {
            setCollapsed(false)
        }
    }

    private func setCollapsed(_ target: Bool) {
        guard target != collapsed else { return }
        withAnimation(.spring(response: ctx["response"], dampingFraction: 0.85)) {
            collapsed = target
        }
    }
}

private struct FeedPost {
    let symbol: String
    let title: LocalizedText
    let meta: LocalizedText
}

private let feedPosts: [FeedPost] = [
    FeedPost(symbol: "sun.horizon.fill", title: L("Chasing golden hour", "追逐黄金时刻"), meta: L("Mia · Photography · 4 min", "米娅 · 摄影 · 4 分钟")),
    FeedPost(symbol: "fork.knife", title: L("Five-minute breakfast bowls", "五分钟早餐碗"), meta: L("Kai · Food · 3 min", "凯 · 美食 · 3 分钟")),
    FeedPost(symbol: "figure.hiking", title: L("A weekend on the ridge", "山脊上的周末"), meta: L("Lena · Travel · 6 min", "莉娜 · 旅行 · 6 分钟")),
    FeedPost(symbol: "paintbrush.pointed.fill", title: L("Color theory for UI", "界面色彩理论"), meta: L("Sam · Design · 8 min", "萨姆 · 设计 · 8 分钟")),
    FeedPost(symbol: "music.note", title: L("Songs for deep focus", "深度专注歌单"), meta: L("Noor · Music · 2 min", "努尔 · 音乐 · 2 分钟")),
    FeedPost(symbol: "leaf.fill", title: L("Keeping ferns alive", "养活蕨类的秘诀"), meta: L("Ava · Home · 5 min", "艾娃 · 家居 · 5 分钟")),
    FeedPost(symbol: "bicycle", title: L("Commuting by bike", "骑车通勤这一年"), meta: L("Leo · City · 7 min", "利奥 · 城市 · 7 分钟")),
]

private struct FeedCard: View {
    let index: Int
    let language: AppLanguage

    var body: some View {
        let post = feedPosts[index % feedPosts.count]
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Palette.spectrum[index % Palette.spectrum.count].gradient)
                .frame(width: 56, height: 56)
                .overlay {
                    Image(systemName: post.symbol)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(.white)
                }
            VStack(alignment: .leading, spacing: 3) {
                Text(post.title, language)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                Text(post.meta, language)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .demoCard(cornerRadius: 20)
    }
}
