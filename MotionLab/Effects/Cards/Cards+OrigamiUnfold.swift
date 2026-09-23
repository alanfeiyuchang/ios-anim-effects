import SwiftUI

extension Effect {
    static let cardsOrigamiUnfold = Effect(
        id: "cards.origami-unfold",
        category: .cards,
        interaction: .tap,
        name: L("Origami Unfold", "折纸展开"),
        summary: L("A card unfolds downward panel by panel like folded paper, each fold catching the light.", "卡片像折叠的纸一样逐片向下展开，每一道折痕都有明暗变化。"),
        prompt: L(
            "A 270 pt-wide boarding card shows a 78 pt header; beneath it three 58 pt panels are folded flat against it. Tapping unfolds them one after another: each panel swings down from 90° to flat around its top edge in perspective on a spring (response 0.5 s, damping 0.72), starting 120 ms after the previous one, and the card's height grows with the projected height of every panel so the layout below follows the paper. While a panel is still angled a shade darkens it by up to 45%, so each crease reads as a fold catching the light. Tapping again folds them back up in reverse order, bottom panel first. Crafted, tactile and a little magical.",
            "一张270 pt宽的登机卡片，顶部是78 pt高的抬头，下面三块58 pt高的面板折叠贴合在它背后。点击后面板依次展开：每块都以自己的上边为轴，在透视中从90°摆到平展，使用弹簧（响应0.5秒、阻尼0.72），并比上一块晚120毫秒开始；卡片高度随每块面板的投影高度增长，下方布局也跟着纸面移动。面板仍有角度时会被最多45%的阴影压暗，每道折痕都像纸张在接住光线。再次点击则按相反顺序从最下面一块开始折回。精致、可触，带一点魔法感。"
        ),
        implementation: L(
            "Each panel is an Animatable view: rotation3DEffect(anchor: .top) turns the content while the frame height follows cos(angle), so the VStack reflows every frame; per-panel .animation(spring.delay(…), value: open) sequences the folds.",
            "每块面板是一个 Animatable 视图：rotation3DEffect(anchor: .top) 旋转内容，同时 frame 高度跟随 cos(角度) 变化，让 VStack 每帧重新布局；每块面板各自的 .animation(spring.delay(…), value: open) 串联出折叠顺序。"
        ),
        apis: ["Animatable", "rotation3DEffect(_:axis:anchor:perspective:)", "frame(height:)", "animation(_:value:)", "Animation.delay"],
        tags: ["origami", "unfold", "fold", "paper", "折纸", "展开", "折叠", "纸张"],
        params: [
            .slider("stagger", L("Fold stagger", "折叠间隔"), 0...0.3, default: 0.12, unit: "s"),
            .slider("response", L("Spring response", "弹簧响应"), 0.25...1.0, default: 0.5, unit: "s"),
            .slider("shade", L("Crease shade", "折痕阴影"), 0...0.8, default: 0.45),
        ]
    ) { ctx in
        CardsOrigamiDemo(ctx: ctx)
    }
}

private struct CardsOrigamiDemo: View {
    let ctx: DemoContext
    @State private var open: Bool

    init(ctx: DemoContext) {
        self.ctx = ctx
        // A still thumbnail shows the unfolded boarding card, not just its header strip.
        _open = State(initialValue: ctx.isStill)
    }

    private let panelCount = 3

    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 0) {
                CardsOrigamiHeader(open: open, language: ctx.language)
                    .animation(.spring(response: ctx["response"], dampingFraction: 0.72).delay(firstPanelDelay), value: open)
                ForEach(0..<panelCount, id: \.self) { i in
                    panel(i)
                }
            }
            .frame(width: 270)
            .shadow(color: .black.opacity(0.14), radius: 16, y: 10)
            .contentShape(Rectangle())
            .onTapGesture(perform: toggle)
            .frame(height: 270, alignment: .top)
            DemoHint(text: L("Tap to unfold", "点击展开"), ctx: ctx)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 2.1) { toggle() }
    }

    /// The header's bottom corners follow the first panel: square while it hangs below, round once it is folded away.
    private var firstPanelDelay: Double {
        open ? 0 : Double(panelCount - 1) * ctx["stagger"]
    }

    private func panel(_ i: Int) -> some View {
        let stagger = ctx["stagger"]
        let delay = open ? Double(i) * stagger : Double(panelCount - 1 - i) * stagger
        return CardsOrigamiPanel(
            angle: open ? 0 : 90,
            index: i,
            shade: ctx["shade"],
            language: ctx.language
        )
        .animation(.spring(response: ctx["response"], dampingFraction: 0.72).delay(delay), value: open)
    }

    private func toggle() {
        Haptics.tap(.soft)
        open.toggle()
    }
}

private struct CardsOrigamiHeader: View {
    let open: Bool
    let language: AppLanguage

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(verbatim: "SFO")
                    .font(.system(size: 26, weight: .heavy, design: .rounded))
                Text(L("San Francisco", "旧金山"), language)
                    .font(.caption2.weight(.semibold))
                    .opacity(0.8)
            }
            Spacer(minLength: 0)
            Image(systemName: "airplane")
                .font(.system(size: 18, weight: .bold))
            Spacer(minLength: 0)
            VStack(alignment: .trailing, spacing: 2) {
                Text(verbatim: "HND")
                    .font(.system(size: 26, weight: .heavy, design: .rounded))
                Text(L("Tokyo", "东京"), language)
                    .font(.caption2.weight(.semibold))
                    .opacity(0.8)
            }
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 18)
        .frame(height: 78)
        .background(Palette.ocean)
        .clipShape(UnevenRoundedRectangle(topLeadingRadius: 18, bottomLeadingRadius: open ? 4 : 18, bottomTrailingRadius: open ? 4 : 18, topTrailingRadius: 18, style: .continuous))
    }
}

private struct CardsOrigamiPanel: View, Animatable {
    /// Fold angle in degrees: 90 = folded away, 0 = flat.
    var angle: Double
    let index: Int
    let shade: Double
    let language: AppLanguage

    var animatableData: Double {
        get { angle }
        set { angle = newValue }
    }

    private let height: CGFloat = 58

    private static let rows: [(label: LocalizedText, value: LocalizedText)] = [
        (L("Boarding", "登机"), L("10:25 · Gate 42", "10:25 · 42 号登机口")),
        (L("Seat", "座位"), L("14A · Window", "14A · 靠窗")),
        (L("Group", "登机组"), L("2 · Priority", "2 · 优先")),
    ]

    var body: some View {
        let folded = abs(sin(angle * .pi / 180))
        let visible = CGFloat(max(cos(angle * .pi / 180), 0))
        let row = Self.rows[index % Self.rows.count]
        let isLast = index == Self.rows.count - 1
        HStack {
            Text(row.label, language)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)
            Spacer(minLength: 0)
            Text(row.value, language)
                .font(.footnote.weight(.semibold).monospacedDigit())
        }
        .padding(.horizontal, 18)
        .frame(width: 270, height: height)
        .background(Palette.elevated)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Palette.stroke)
                .frame(height: 1)
        }
        .overlay(Color.black.opacity(shade * folded))
        .clipShape(UnevenRoundedRectangle(topLeadingRadius: 4, bottomLeadingRadius: isLast ? 18 : 4, bottomTrailingRadius: isLast ? 18 : 4, topTrailingRadius: 4, style: .continuous))
        .rotation3DEffect(.degrees(angle), axis: (x: 1, y: 0, z: 0), anchor: .top, perspective: 0.45)
        .frame(height: height * visible, alignment: .top)
        .opacity(angle > 89 ? 0 : 1)
    }
}
