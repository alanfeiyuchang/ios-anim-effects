import SwiftUI

extension Effect {
    static let inputsExpandingSearch = Effect(
        id: "inputs.expanding-search",
        category: .inputs,
        interaction: .tap,
        name: L("Expanding Search", "展开式搜索框"),
        summary: L("A round search button unfurls into a field with suggestions.", "圆形搜索按钮展开为输入框，并依次浮现推荐项。"),
        prompt: L(
            "A 54 pt circular search button with a magnifying-glass glyph on an elevated surface. On tap it stretches horizontally into a 280 pt capsule field on a spring (response 0.45 s, damping 0.8), keeping its vertical center; the glyph glides to the leading edge, the text field fades and slides in from the left, a clear button appears at the trailing edge and the keyboard is focused right after. Below, three recent-search rows drop in with a 50 ms stagger, each fading in while sliding down 8 pt. Tapping the clear button reverses the sequence: suggestions vanish, the field collapses back into the circle. Compact at rest, generous when needed.",
            "浮起表面上一个 54pt 的圆形搜索按钮，中间是放大镜图标。点击后以弹簧（响应 0.45 秒、阻尼 0.8）横向拉伸为 280pt 的胶囊输入框，垂直中心保持不变；放大镜滑到左侧，输入框从左侧淡入滑入，右侧出现清除按钮，随后自动聚焦弹出键盘。下方三条最近搜索以 50 毫秒错峰依次出现，每条一边淡入一边下滑 8pt。点击清除按钮则反向播放：推荐项消失，输入框收回为圆形按钮。静止时紧凑，需要时舒展。"
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

    private var suggestions: [LocalizedText] {
        [
            L("Spring animations", "弹簧动画"),
            L("Matched geometry", "几何匹配"),
            L("Mesh gradients", "网格渐变"),
        ]
    }

    private var spring: Animation { .spring(response: ctx["response"], dampingFraction: 0.8) }

    var body: some View {
        VStack(spacing: 14) {
            searchBar
            VStack(alignment: .leading, spacing: 8) {
                if expanded && ctx.bool("suggestions") {
                    ForEach(suggestions.indices, id: \.self) { index in
                        suggestionRow(index)
                    }
                }
            }
            .frame(width: ctx.cg("width"), height: 150, alignment: .top)
        }
        .padding(.top, 70)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .autoplay(ctx.isPreview, every: 2.0, delay: 0.5) { expanded ? collapse() : expand() }
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
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(.tertiary)
                }
                .buttonStyle(.plain)
                .transition(.scale(scale: 0.3).combined(with: .opacity))
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
        .transition(
            AnyTransition.opacity
                .combined(with: .offset(y: -8))
                .animation(.spring(response: 0.4, dampingFraction: 0.8).delay(0.12 + Double(index) * 0.05))
        )
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
