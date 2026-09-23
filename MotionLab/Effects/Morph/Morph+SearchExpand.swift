import SwiftUI

extension Effect {
    static let morphSearchExpand = Effect(
        id: "morph.search-expand",
        category: .morph,
        interaction: .tap,
        name: L("Search Expand", "搜索栏展开"),
        summary: L(
            "A compact search pill stretches into a field and unfolds a live results panel.",
            "紧凑的搜索胶囊伸展为输入框，并展开实时结果面板。"
        ),
        prompt: L(
            "A frosted 50 pt search pill with a magnifier sits at the bottom of the screen. Tapping it stretches the same capsule to full width on a spring (response ≈0.45 s, damping ≈0.85) — the magnifier slides to the leading edge, a blinking caret appears and a clear button fades in — while the content behind blurs to 8 pt and dims. A frosted results panel grows upward from the field, scaling from 94% at its bottom edge. As the query is typed, results rise into the panel with a 45 ms stagger, the typed prefix highlighted in the brand colour, while the 'Recent' header rolls into a result count with a numeric text transition. Closing collapses the field back to the pill and folds the panel into it.",
            "屏幕底部是一枚高 50pt、带放大镜的磨砂搜索胶囊。点击后同一个胶囊以弹簧（响应约 0.45 秒、阻尼约 0.85）伸展到整行宽度——放大镜滑到最左侧，出现闪烁的光标，清除按钮淡入；背后的内容同步模糊到 8pt 并变暗。一块磨砂结果面板从输入框向上生长，以底边为锚点从 94% 放大。随着输入，结果行以 45 毫秒间隔依次升入面板，已输入的前缀以品牌色高亮，面板标题也从“最近搜索”以数字滚动过渡切换为结果数量。关闭时输入框收回为胶囊，面板一并折叠进去。"
        ),
        implementation: L(
            "Pill and field share matchedGeometryEffect ids for their material capsule and magnifier; the panel uses an asymmetric scale transition anchored at the bottom, and a task keyed on the expanded state simulates typing.",
            "胶囊与输入框的磨砂背景和放大镜共享 matchedGeometryEffect ID；结果面板使用以底边为锚点的非对称缩放转场，以展开状态为 key 的 task 模拟逐字输入。"
        ),
        apis: ["matchedGeometryEffect", "transition(.scale(scale:anchor:))", "task(id:)", "phaseAnimator", "contentTransition(.numericText())"],
        tags: ["search", "expand", "search bar", "results", "搜索", "搜索栏", "展开", "结果面板"],
        params: [
            .slider("response", L("Spring response", "弹簧响应"), 0.2...1.0, default: 0.45, unit: "s"),
            .slider("damping", L("Damping", "阻尼"), 0.5...1.0, default: 0.85),
            .slider("stagger", L("Result stagger", "结果错开"), 0.0...0.12, default: 0.045, decimals: 3, unit: "s"),
        ]
    ) { ctx in
        SearchExpandDemo(ctx: ctx)
    }
}

private struct SearchResult {
    let symbol: String
    let title: LocalizedText
}

private let searchResults: [SearchResult] = [
    SearchResult(symbol: "hand.tap.fill", title: L("Spring Button", "弹簧按钮")),
    SearchResult(symbol: "dock.rectangle", title: L("Springy Tab Bar", "弹簧标签栏")),
    SearchResult(symbol: "atom", title: L("Spring Physics", "弹簧物理")),
    SearchResult(symbol: "rectangle.bottomhalf.filled", title: L("Spring-loaded Sheet", "弹簧面板")),
]

private struct SearchExpandDemo: View {
    let ctx: DemoContext
    @Namespace private var ns
    @State private var expanded = false
    @State private var query = ""

    private var zh: Bool { ctx.language == .zh }

    var body: some View {
        ZStack(alignment: .bottom) {
            SearchBackdrop(language: ctx.language)
                .blur(radius: expanded ? 8 : 0)
                .opacity(expanded ? 0.5 : 1)
            VStack(spacing: 10) {
                if expanded {
                    SearchPanel(query: query, language: ctx.language, stagger: ctx["stagger"])
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.94, anchor: .bottom).combined(with: .opacity),
                            removal: .scale(scale: 0.9, anchor: .bottom).combined(with: .opacity)
                        ))
                    field
                } else {
                    pill
                }
            }
            .padding(16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task(id: expanded) { await typeQuery() }
        .autoplay(ctx.isPreview, every: 2.8) { toggle() }
    }

    private var pill: some View {
        Button(action: toggle) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .matchedGeometryEffect(id: "icon", in: ns)
                Text(zh ? "搜索" : "Search")
            }
            .font(.headline)
            .foregroundStyle(.primary)
            .padding(.horizontal, 22)
            .frame(height: 50)
            .background {
                Capsule()
                    .fill(.regularMaterial)
                    .overlay(Capsule().strokeBorder(Palette.stroke))
                    .shadow(color: .black.opacity(0.12), radius: 14, y: 6)
                    .matchedGeometryEffect(id: "bg", in: ns)
            }
        }
        .buttonStyle(.plain)
    }

    private var field: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.headline)
                .matchedGeometryEffect(id: "icon", in: ns)
            HStack(spacing: 1) {
                Text(query.isEmpty ? (zh ? "搜索动效" : "Search effects") : query)
                    .foregroundStyle(query.isEmpty ? Color.secondary : Color.primary)
                Capsule()
                    .fill(Palette.indigo)
                    .frame(width: 2, height: 20)
                    .phaseAnimator([1.0, 0.0]) { content, phase in
                        content.opacity(phase)
                    } animation: { _ in
                        .easeInOut(duration: 0.45)
                    }
            }
            Spacer(minLength: 0)
            Button(action: toggle) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .transition(.opacity)
        }
        .padding(.horizontal, 16)
        .frame(height: 50)
        .background {
            Capsule()
                .fill(.regularMaterial)
                .overlay(Capsule().strokeBorder(Palette.stroke))
                .shadow(color: .black.opacity(0.12), radius: 14, y: 6)
                .matchedGeometryEffect(id: "bg", in: ns)
        }
    }

    private func toggle() {
        if !ctx.isPreview { Haptics.tap() }
        withAnimation(.spring(response: ctx["response"], dampingFraction: ctx["damping"])) {
            expanded.toggle()
        }
    }

    private func typeQuery() async {
        guard expanded else {
            query = ""
            return
        }
        let target = zh ? "弹簧" : "spring"
        try? await Task.sleep(for: .seconds(0.4))
        for count in 1...target.count {
            guard !Task.isCancelled else { return }
            withAnimation(.snappy) { query = String(target.prefix(count)) }
            try? await Task.sleep(for: .milliseconds(zh ? 220 : 90))
        }
    }
}

private struct SearchPanel: View {
    let query: String
    let language: AppLanguage
    let stagger: Double

    private var hasQuery: Bool { !query.isEmpty }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(headline)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .contentTransition(.numericText())
                .padding(.bottom, 6)
            ForEach(0..<searchResults.count, id: \.self) { index in
                resultRow(searchResults[index])
                    .opacity(hasQuery ? 1 : 0)
                    .offset(y: hasQuery ? 0 : 10)
                    .animation(
                        hasQuery ? .spring(response: 0.4, dampingFraction: 0.85).delay(Double(index) * stagger) : .easeOut(duration: 0.1),
                        value: hasQuery
                    )
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).strokeBorder(Palette.stroke))
        .shadow(color: .black.opacity(0.1), radius: 18, y: 8)
    }

    private var headline: String {
        if !hasQuery { return language == .zh ? "最近搜索" : "RECENT" }
        return language == .zh ? "\(searchResults.count) 个结果" : "\(searchResults.count) RESULTS"
    }

    private func resultRow(_ result: SearchResult) -> some View {
        let title = result.title(language)
        let matched = String(title.prefix(query.count))
        let rest = String(title.dropFirst(query.count))
        return HStack(spacing: 12) {
            Image(systemName: result.symbol)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Palette.indigo)
                .frame(width: 30, height: 30)
                .background(Palette.indigo.opacity(0.12), in: Circle())
            Text("\(Text(matched).foregroundStyle(Palette.indigo).bold())\(Text(rest))")
                .font(.subheadline)
            Spacer(minLength: 0)
            Image(systemName: "arrow.up.left")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .frame(height: 42)
    }
}

/// A "Browse" grid of category tiles so the blur has real content to soften.
private struct SearchBackdrop: View {
    let language: AppLanguage

    private let tiles: [(String, [Color], LocalizedText)] = [
        ("hand.tap.fill", [Palette.indigo, Palette.violet], L("Buttons", "按钮")),
        ("rectangle.stack.fill", [Palette.pink, Palette.coral], L("Cards", "卡片")),
        ("hourglass", [Palette.mint, Palette.sky], L("Loading", "加载")),
        ("textformat", [Palette.amber, Palette.coral], L("Text", "文字")),
    ]

    var body: some View {
        let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]
        return LazyVGrid(columns: columns, spacing: 12) {
            ForEach(0..<tiles.count, id: \.self) { index in
                let tile = tiles[index]
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(LinearGradient(colors: tile.1, startPoint: .topLeading, endPoint: .bottomTrailing))
                    .overlay(alignment: .bottomLeading) {
                        VStack(alignment: .leading, spacing: 6) {
                            Image(systemName: tile.0)
                                .font(.system(size: 20, weight: .semibold))
                            Text(tile.2, language)
                                .font(.subheadline.weight(.bold))
                        }
                        .foregroundStyle(.white)
                        .padding(12)
                    }
                    .frame(height: 100)
                    .shadow(color: tile.1[0].opacity(0.25), radius: 10, y: 5)
            }
        }
        .padding(18)
        .padding(.top, 32) // clear the stage's reset button
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}
