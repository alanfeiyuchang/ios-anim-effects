import SwiftUI

extension Effect {
    static let navigationSearchTabMorph = Effect(
        id: "navigation.search-tab-morph",
        category: .navigation,
        interaction: .tap,
        name: L("Search Tab Morph", "搜索标签形变"),
        summary: L(
            "Tapping search folds the tab bar into a single bubble while the search button stretches into a field.",
            "点击搜索，标签栏折叠成一个圆泡，搜索按钮同时伸展为输入框。"
        ),
        prompt: L(
            "A floating bar made of two capsules: a 232 pt tab pill (Home, Library, Radio, with a gradient selection pill) and a separate 56 pt round search button. Tapping search trades their widths on one spring (response ≈0.45 s, damping 0.8): the tab pill collapses into a 56 pt bubble holding only the current tab's icon, its labels blurring out, while the search button stretches to 232 pt, its magnifier sliding to the leading edge and a placeholder with a blinking caret fading in. Three suggestion rows then rise above the bar, staggered ≈50 ms, from 16 pt below with a blur. Tapping the bubble reverses everything. It mirrors the iOS 26 tab-bar search role: one continuous piece of glass reshaping.",
            "悬浮栏由两枚胶囊组成：232pt 的标签胶囊（首页、资料库、电台，带渐变选中胶囊）与一枚独立的 56pt 圆形搜索按钮。点击搜索后，二者在同一个弹簧（响应约 0.45 秒、阻尼 0.8）中交换宽度：标签胶囊收拢成 56pt 的圆泡，只保留当前标签图标，文字模糊淡出；搜索按钮伸展到 232pt，放大镜滑到前端，占位文字和闪烁的光标淡入。随后三行搜索建议从栏上方 16pt 处带模糊依次升起，间隔约 50 毫秒。点击圆泡即全部复原。它复刻了 iOS 26 标签栏中的搜索角色：一整块连续变形的玻璃。"
        ),
        implementation: L(
            "Both capsules' frame widths swap inside one withAnimation spring; content inside each switches with blur/opacity transitions and a matchedGeometryEffect selection pill, and suggestion rows use animation(_:value:) with per-row delays.",
            "两枚胶囊的宽度在同一个 withAnimation 弹簧中交换；胶囊内的内容以模糊/透明度过渡切换，选中胶囊使用 matchedGeometryEffect，建议行通过 animation(_:value:) 按行设置延迟。"
        ),
        apis: ["frame(width:)", "matchedGeometryEffect", "transition(.blurReplace)", "phaseAnimator", "animation(_:value:)"],
        tags: ["tab bar", "search", "morph", "iOS 26", "标签栏", "搜索", "形变", "输入框"],
        params: [
            .slider("response", L("Spring response", "弹簧响应"), 0.25...0.8, default: 0.45, unit: "s"),
            .slider("damping", L("Damping", "阻尼"), 0.55...1.0, default: 0.8),
            .slider("stagger", L("Suggestion stagger", "建议行错峰"), 0.0...0.12, default: 0.05, unit: "s"),
        ]
    ) { ctx in
        SearchTabMorphDemo(ctx: ctx)
    }
}

private let searchTabSymbols: [String] = ["house.fill", "square.stack.fill", "dot.radiowaves.left.and.right"]
private let searchTabTitles: [LocalizedText] = [L("Home", "首页"), L("Library", "资料库"), L("Radio", "电台")]
private let searchSuggestions: [LocalizedText] = [L("Lo-fi focus", "专注低保真"), L("Morning jazz", "晨间爵士"), L("Rain sounds", "雨声白噪音")]

private struct SearchTabMorphDemo: View {
    let ctx: DemoContext
    @Namespace private var ns
    @State private var searching = false
    @State private var selected = 0

    var body: some View {
        VStack(spacing: 14) {
            Spacer(minLength: 0)
            suggestions
            bar
            DemoHint(text: L("Tap search, then the bubble", "点击搜索，再点击圆泡"), ctx: ctx)
                .padding(.bottom, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 1.8) { setSearching(!searching) }
    }

    private var spring: Animation {
        .spring(response: ctx["response"], dampingFraction: ctx["damping"])
    }

    private var bar: some View {
        HStack(spacing: 10) {
            tabPill
                .frame(width: searching ? 56 : 232, height: 56)
                .background(.regularMaterial, in: Capsule())
                .overlay(Capsule().strokeBorder(Palette.stroke))
                .clipShape(Capsule())
            searchPill
                .frame(width: searching ? 232 : 56, height: 56)
                .background(.regularMaterial, in: Capsule())
                .overlay(Capsule().strokeBorder(Palette.stroke))
                .clipShape(Capsule())
                .contentShape(Capsule())
                .onTapGesture { if !searching { setSearching(true) } }
        }
        .shadow(color: .black.opacity(0.12), radius: 16, y: 8)
    }

    @ViewBuilder
    private var tabPill: some View {
        if searching {
            Image(systemName: searchTabSymbols[selected])
                .font(.system(size: 19, weight: .semibold))
                .foregroundStyle(Palette.indigo)
                .frame(width: 56, height: 56)
                .contentShape(Circle())
                .onTapGesture { setSearching(false) }
                .transition(.blurReplace)
        } else {
            HStack(spacing: 2) {
                ForEach(0..<searchTabSymbols.count, id: \.self) { index in
                    tabItem(index)
                }
            }
            .padding(4)
            .transition(.blurReplace)
        }
    }

    private func tabItem(_ index: Int) -> some View {
        let isSelected = index == selected
        return VStack(spacing: 2) {
            Image(systemName: searchTabSymbols[index])
                .font(.system(size: 16, weight: .semibold))
            Text(searchTabTitles[index], ctx.language)
                .font(.system(size: 10, weight: .semibold))
                .lineLimit(1)
        }
        .foregroundStyle(isSelected ? Color.white : Color.secondary)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            if isSelected {
                Capsule()
                    .fill(Palette.primary)
                    .matchedGeometryEffect(id: "searchTabSelection", in: ns)
            }
        }
        .contentShape(Capsule())
        .onTapGesture {
            if !ctx.isPreview { Haptics.selection() }
            withAnimation(spring) { selected = index }
        }
    }

    @ViewBuilder
    private var searchPill: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(searching ? Color.secondary : Palette.indigo)
            if searching {
                Rectangle()
                    .fill(Palette.indigo)
                    .frame(width: 2, height: 20)
                    .phaseAnimator([1.0, 0.0]) { content, opacity in
                        content.opacity(opacity)
                    } animation: { _ in
                        .easeInOut(duration: 0.5)
                    }
                    .transition(.opacity)
                Text(L("Artists, songs, podcasts", "歌手、歌曲、播客"), ctx.language)
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
                    .fixedSize()
                    .transition(.opacity.combined(with: .offset(x: 12)))
                Spacer(minLength: 0)
            }
        }
        .padding(.horizontal, searching ? 18 : 19)
        .frame(maxWidth: .infinity, alignment: searching ? .leading : .center)
    }

    private var suggestions: some View {
        VStack(spacing: 8) {
            ForEach(0..<searchSuggestions.count, id: \.self) { index in
                let delay: Double = searching ? Double(index) * ctx["stagger"] + 0.12 : 0
                HStack(spacing: 10) {
                    Image(systemName: "arrow.up.right")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Palette.indigo)
                    Text(searchSuggestions[index], ctx.language)
                        .font(.subheadline.weight(.medium))
                    Spacer()
                }
                .padding(.horizontal, 16)
                .frame(width: 298, height: 44)
                .background(Palette.elevated, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .opacity(searching ? 1 : 0)
                .blur(radius: searching ? 0 : 6)
                .offset(y: searching ? 0 : 16)
                .animation(.spring(response: 0.4, dampingFraction: 0.85).delay(delay), value: searching)
            }
        }
        .allowsHitTesting(searching)
    }

    private func setSearching(_ value: Bool) {
        guard value != searching else { return }
        if !ctx.isPreview { Haptics.tap(value ? .medium : .light) }
        withAnimation(spring) { searching = value }
    }
}
