import SwiftUI

extension Effect {
    static let scrollPillHeader = Effect(
        id: "scroll.pill-header",
        category: .scroll,
        interaction: .scroll,
        name: L("Floating Pill Header", "悬浮胶囊头部"),
        summary: L("A full-width header detaches into a floating frosted capsule with a springy morph once you scroll.", "滚动后，通栏头部以弹性形变脱离成一枚悬浮的磨砂胶囊。"),
        prompt: L(
            "A page opens with a full-bleed 64 pt header: large \"Discover\" title, a search field and a profile button, flush with the top edge and square-cornered. As soon as the content scrolls past 40 pt the header detaches in one bouncy morph (spring response 0.45 s, damping 0.7): it insets 24 pt from each side, drops 10 pt, shrinks to 46 pt tall, rounds into a full capsule, gains a soft 16 pt shadow, and its title scales to 80% while the search field collapses into a magnifier icon. Scrolling back above the threshold springs it back into the bar. The content keeps scrolling underneath the frosted material. Modern, lightweight and dynamic, like the Dynamic Island meeting a navigation bar.",
            "页面顶部是一条64 pt高的通栏头部：大号「发现」标题、搜索框和个人头像按钮，紧贴顶边、直角。内容一旦滚动超过40 pt，头部便以一次富有弹性的形变（弹簧响应0.45秒、阻尼0.7）脱离出来：左右各内缩24 pt、下移10 pt、高度缩到46 pt、圆角变为完整胶囊，并带上16 pt的柔和阴影；标题缩小到80%，搜索框收拢成一个放大镜图标。滚回阈值以上时，它又弹回通栏。内容始终在磨砂材质下方滚动。现代、轻盈、富有动感，就像灵动岛遇上了导航栏。"
        ),
        implementation: L(
            "onScrollGeometryChange maps the offset to a Bool (past 40 pt), so the action only fires on crossings; one spring animates padding, height, corner radius, shadow and the search field's swap, which uses a matchedGeometryEffect between the field and the icon.",
            "onScrollGeometryChange 把偏移映射为布尔值（是否超过 40 pt），因此回调只在越过阈值时触发；同一个弹簧同时驱动内边距、高度、圆角、阴影以及搜索框的切换，后者在输入框与图标之间使用 matchedGeometryEffect。"
        ),
        apis: ["onScrollGeometryChange", "matchedGeometryEffect", "RoundedRectangle(cornerRadius:)", "Material", "spring(response:dampingFraction:)"],
        tags: ["header", "floating", "capsule", "morph", "头部", "悬浮", "胶囊", "形变"],
        params: [
            .slider("inset", L("Side inset", "两侧内缩"), 8...48, default: 24, step: 1, decimals: 0, unit: "pt"),
            .slider("damping", L("Morph damping", "形变阻尼"), 0.4...1.0, default: 0.7),
        ]
    ) { ctx in
        ScrollPillHeaderDemo(ctx: ctx)
    }
}

private struct ScrollPillHeaderDemo: View {
    let ctx: DemoContext
    @State private var position = ScrollPosition(edge: .top)
    @State private var floating = false
    @State private var down = false
    /// True while autoplay (or the detail intro) scrolls, so the scripted float stays silent.
    @State private var scripted = false
    @Namespace private var search

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                ForEach(0..<5, id: \.self) { i in
                    ScrollPillTile(index: i, language: ctx.language)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 76)
            .padding(.bottom, 20)
        }
        .scrollIndicators(.hidden)
        .scrollPosition($position)
        .onScrollGeometryChange(for: Bool.self, of: { geometry in
            geometry.contentOffset.y + geometry.contentInsets.top > 40
        }, action: { _, newValue in
            if newValue && !ctx.isPreview && !scripted { Haptics.tap(.soft) }
            withAnimation(.spring(response: 0.45, dampingFraction: ctx["damping"])) {
                floating = newValue
            }
        })
        .onScrollPhaseChange { _, newPhase in
            if newPhase == .interacting { scripted = false }
        }
        .overlay(alignment: .top) { header }
        .clipped()
        .autoplay(ctx.isPreview, every: 1.8) {
            scripted = true
            down.toggle()
            withAnimation(.smooth(duration: 1.1)) {
                position.scrollTo(y: down ? 260 : 0)
            }
        }
    }

    private var header: some View {
        let radius: CGFloat = floating ? 23 : 0
        let inset: CGFloat = floating ? ctx.cg("inset") : 0
        return HStack(spacing: 10) {
            Text(L("Discover", "发现"), ctx.language)
                .font(.system(size: 22, weight: .bold))
                .scaleEffect(floating ? 0.8 : 1, anchor: .leading)
                .fixedSize()
            Spacer(minLength: 0)
            if floating {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 14, weight: .semibold))
                    .frame(width: 30, height: 30)
                    .background(Color.primary.opacity(0.08), in: Circle())
                    .matchedGeometryEffect(id: "search", in: search)
            } else {
                HStack(spacing: 6) {
                    Image(systemName: "magnifyingglass")
                    Text(L("Search", "搜索"), ctx.language)
                    Spacer(minLength: 0)
                }
                .font(.footnote)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 10)
                .frame(width: 118, height: 32)
                .background(Color.primary.opacity(0.07), in: Capsule())
                .matchedGeometryEffect(id: "search", in: search)
            }
            ScrollKitIcon(index: 4, size: floating ? 30 : 34)
                .clipShape(Circle())
        }
        .padding(.horizontal, floating ? 12 : 16)
        .frame(height: floating ? 46 : 64)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: radius, style: .continuous).strokeBorder(Color.primary.opacity(floating ? 0.08 : 0)))
        .shadow(color: .black.opacity(floating ? 0.16 : 0), radius: 16, y: 6)
        .padding(.horizontal, inset)
        .padding(.top, floating ? 10 : 0)
    }
}

private struct ScrollPillTile: View {
    let index: Int
    let language: AppLanguage

    var body: some View {
        ScrollKitArt(index: index + 5, language: language)
            .frame(height: 150)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}
