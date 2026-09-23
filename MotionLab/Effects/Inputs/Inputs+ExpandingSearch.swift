import SwiftUI

extension Effect {
    static let inputsExpandingSearch = Effect(
        id: "inputs.expanding-search",
        category: .inputs,
        interaction: .tap,
        name: L("Expanding Search", "展开式搜索框"),
        summary: L("A round search button unfurls into a field with suggestions.", "圆形搜索按钮展开为输入框，并依次浮现推荐项。"),
        prompt: L(
            "A 54 pt circular search button with a magnifying-glass glyph sits at the trailing edge of a \"Library\" page header, above gradient category tiles and a \"Recently viewed\" row. On tap it stretches horizontally into a 280 pt capsule field on a spring (response 0.45 s, damping 0.8), keeping its vertical center and sliding over the page title, which blurs 6 pt and drifts 18 pt left as it fades; the browse content recedes (94%, 4 pt blur, fade out). The glyph glides to the leading edge, the text field slides in from the left, a tinted \"Cancel\" control appears at the trailing edge and the keyboard is focused right after. Below, three recent-search rows and a \"Trending\" chip row drop in with a 50 ms stagger, each fading in while sliding down 8 pt. Cancel reverses the sequence and the field collapses back into the circle. Compact at rest, generous when needed.",
            "“资源库”页面标题的右侧是一枚 54pt 的圆形搜索按钮，下方是渐变分类卡片与一条“最近浏览”。点击后以弹簧（响应 0.45 秒、阻尼 0.8）横向拉伸为 280pt 的胶囊输入框，垂直中心保持不变，并向左盖过页面标题——标题模糊 6pt、向左漂移 18pt 并淡出，浏览内容同时后退（缩到 94%、模糊 4pt、淡出）；放大镜滑到左侧，输入框从左侧滑入，右侧出现带主题色的“取消”按钮，随后自动聚焦弹出键盘。下方三条最近搜索和一行“热门”标签以 50 毫秒错峰依次出现，每项一边淡入一边下滑 8pt。点击“取消”则反向播放，输入框收回为圆形按钮。静止时紧凑，需要时舒展。"
        ),
        implementation: L(
            "One expanded flag animates the capsule's frame width inside a spring; the text field and suggestion rows are inserted with combined opacity/move transitions, the rows each carrying their own delayed animation.",
            "单个展开状态在弹簧中驱动胶囊的 frame 宽度；输入框与推荐项通过组合的透明度/位移过渡插入，每一行推荐项携带各自的延迟动画。"
        ),
        apis: ["frame(width:)", "transition", "AnyTransition.animation(_:)", "@FocusState"],
        tags: ["search", "expand", "field", "morph", "搜索", "展开", "输入框", "形变"],
        params: [
            .slider("response", L("Spring response", "弹簧响应"), 0.2...0.9, default: 0.45, unit: "s"),
            .slider("width", L("Expanded width", "展开宽度"), 180...300, default: 280, decimals: 0, unit: "pt"),
            .toggle("suggestions", L("Suggestions", "推荐项"), default: true),
        ]
    ) { ctx in
        InputExpandingSearchDemo(ctx: ctx)
    }
}

private struct InputExpandingSearchDemo: View {
    let ctx: DemoContext
    @State private var expanded = false
    @State private var query = ""
    @FocusState private var focused: Bool

    private var trending: [LocalizedText] {
        [L("Glass", "玻璃"), L("Haptics", "触感"), L("Scroll", "滚动")]
    }

    private var suggestions: [LocalizedText] {
        [
            L("Spring animations", "弹簧动画"),
            L("Matched geometry", "几何匹配"),
            L("Mesh gradients", "网格渐变"),
        ]
    }

    private var spring: Animation { .spring(response: ctx["response"], dampingFraction: 0.8) }

    var body: some View {
        let width = ctx.cg("width")
        VStack(spacing: 14) {
            ZStack(alignment: .trailing) {
                header
                    .opacity(expanded ? 0 : 1)
                    .blur(radius: expanded ? 6 : 0)
                    .offset(x: expanded ? -18 : 0)
                searchBar
            }
            .frame(width: width, height: 54)
            ZStack(alignment: .top) {
                browse(width: width)
                    .opacity(expanded ? 0 : 1)
                    .scaleEffect(expanded ? 0.94 : 1, anchor: .top)
                    .blur(radius: expanded ? 4 : 0)
                VStack(alignment: .leading, spacing: 8) {
                    if expanded && ctx.bool("suggestions") {
                        ForEach(suggestions.indices, id: \.self) { index in
                            suggestionRow(index)
                        }
                        trendingRow
                            .padding(.top, 6)
                            .transition(Self.dropIn(delay: 0.12 + Double(suggestions.count) * 0.05))
                    }
                }
                .frame(width: width, alignment: .top)
            }
            .frame(width: width, height: 212, alignment: .top)
            Spacer(minLength: 0)
            DemoHint(text: L("Tap the search button", "点击搜索按钮"), ctx: ctx)
                .frame(maxWidth: .infinity)
                .padding(.bottom, 16)
        }
        .padding(.top, ctx.isPreview ? 24 : 34)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .autoplay(ctx.isPreview, every: 2.4, delay: 0.5) { expanded ? collapse() : expand() }
    }

    /// Page title that the expanding field slides over.
    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 0) {
                Text(L("Motion Lexicon", "动效词典"), ctx.language)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(L("Library", "资源库"), ctx.language)
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
            }
            Spacer(minLength: 0)
        }
    }

    private static func dropIn(delay: Double) -> AnyTransition {
        AnyTransition.opacity
            .combined(with: .offset(y: -8))
            .animation(.spring(response: 0.4, dampingFraction: 0.8).delay(delay))
    }

    private func browse(width: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            tiles(width: width)
            Text(L("Recently viewed", "最近浏览"), ctx.language)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.top, 4)
            HStack(spacing: 12) {
                Image(systemName: "hand.tap.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 34, height: 34)
                    .background(Palette.primary, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                VStack(alignment: .leading, spacing: 1) {
                    Text(L("Magnetic Button", "磁吸按钮"), ctx.language)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                    Text(L("Buttons · 2 min ago", "按钮 · 2 分钟前"), ctx.language)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 10)
            .frame(height: 48)
            .background(Palette.elevated.opacity(0.7), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }

    private var trendingRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L("Trending", "热门"), ctx.language)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)
            HStack(spacing: 8) {
                ForEach(trending.indices, id: \.self) { index in
                    Text(trending[index], ctx.language)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(Palette.indigo)
                        .lineLimit(1)
                        .padding(.horizontal, 12)
                        .frame(height: 30)
                        .background(Palette.indigo.opacity(0.12), in: Capsule())
                }
            }
        }
    }

    private func tiles(width: CGFloat) -> some View {
        let items: [(String, LocalizedText, LinearGradient)] = [
            ("hand.tap.fill", L("Buttons", "按钮"), Palette.primary),
            ("slider.horizontal.3", L("Inputs", "控件"), Palette.ocean),
            ("sparkles", L("Ambience", "氛围"), Palette.sunset),
            ("chart.bar.fill", L("Charts", "图表"), Palette.aurora),
        ]
        let tileWidth = (width - 10) / 2
        return LazyVGrid(columns: [GridItem(.fixed(tileWidth), spacing: 10), GridItem(.fixed(tileWidth), spacing: 10)], spacing: 10) {
            ForEach(items.indices, id: \.self) { index in
                HStack(spacing: 8) {
                    Image(systemName: items[index].0)
                        .font(.system(size: 14, weight: .semibold))
                    Text(items[index].1, ctx.language)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)
                    Spacer(minLength: 0)
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .frame(width: tileWidth, height: 52)
                .background(items[index].2, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }
    }

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 19, weight: .semibold))
                .foregroundStyle(expanded ? Color.secondary : Color.primary)
            if expanded {
                TextField(ctx.language == .zh ? "搜索动效" : "Search effects", text: $query)
                    .focused($focused)
                    .submitLabel(.search)
                    .transition(.opacity.combined(with: .move(edge: .leading)))
                Button(action: collapse) {
                    Text(L("Cancel", "取消"), ctx.language)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Palette.indigo)
                        .fixedSize()
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .padding(.horizontal, 17)
        .frame(width: expanded ? ctx.cg("width") : 54, height: 54, alignment: .leading)
        .background(Palette.elevated, in: Capsule())
        .overlay(Capsule().strokeBorder(expanded ? Palette.indigo.opacity(0.5) : Palette.stroke, lineWidth: expanded ? 1.5 : 1))
        .shadow(color: .black.opacity(expanded ? 0.12 : 0.08), radius: expanded ? 18 : 10, y: 8)
        .contentShape(Capsule())
        .onTapGesture {
            if !expanded { expand() }
        }
    }

    private func suggestionRow(_ index: Int) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "clock.arrow.circlepath")
                .foregroundStyle(.secondary)
            Text(suggestions[index], ctx.language)
                .foregroundStyle(.primary)
            Spacer(minLength: 0)
            Image(systemName: "arrow.up.left")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .font(.subheadline)
        .padding(.horizontal, 14)
        .frame(height: 40)
        .background(Palette.elevated.opacity(0.7), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .transition(Self.dropIn(delay: 0.12 + Double(index) * 0.05))
    }

    private func expand() {
        if !ctx.isPreview { Haptics.tap() }
        withAnimation(spring) { expanded = true }
        if ctx.isPreview {
            query = ctx.language == .zh ? "弹簧" : "Spring"
        } else {
            Task {
                try? await Task.sleep(for: .seconds(0.25))
                focused = true
            }
        }
    }

    private func collapse() {
        focused = false
        withAnimation(spring) {
            expanded = false
            query = ""
        }
    }
}
