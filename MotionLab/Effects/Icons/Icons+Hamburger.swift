import SwiftUI

extension Effect {
    static let iconsHamburger = Effect(
        id: "icons.hamburger-morph",
        category: .icons,
        interaction: .tap,
        name: L("Hamburger ↔ Close", "菜单 ↔ 关闭形变"),
        summary: L("Three bars collapse and rotate into an X as a menu cascades open.", "三条横线收拢并旋转成 X，同时菜单级联展开。"),
        prompt: L(
            "In the top bar of a small app screen (title, date, avatar, a feed of cards beneath), a frosted 52 pt circular menu button holds three rounded 24×3 pt bars spaced 7 pt apart. On open the morph runs in two beats: the top and bottom bars slide to the centre line while the middle bar shrinks horizontally to zero and fades; 120 ms later the outer bars rotate ±45° into a crisp X, optionally spinning the whole icon a half turn. Meanwhile the feed dims to 35% with a 2 pt blur and a four-row menu cascades down over it, each row un-blurring and dropping into place 45 ms after the last. Closing plays the exact reverse. Snappy springs (≈0.4 s, damping 0.7) and a light haptic make it feel mechanical and deliberate.",
            "一个小型 App 页面的顶栏中（标题、日期、头像，下方是信息流卡片），52 pt 的磨砂圆形菜单按钮内有三条 24×3 pt 的圆角横线，间距 7 pt。打开时形变分两拍：上下两条先滑向中线，中间一条沿水平方向缩为零并淡出；120 毫秒后外侧两条分别旋转 ±45°，组成利落的 X，可选整体同步旋转半圈。与此同时信息流变暗至 35% 并模糊 2 pt，四行菜单覆盖其上依次以 45 毫秒间隔由模糊变清晰、下落就位。关闭时严格倒放。干脆的弹簧（约 0.4 秒、阻尼 0.7）配合轻触感，让形变机械、明确而不拖泥带水。"
        ),
        implementation: L(
            "Three Capsules with separate .animation(_:value:) modifiers wrapping rotation and offset, so each property gets its own delay depending on direction; menu rows use per-index delayed springs for the cascade.",
            "三个 Capsule，分别用独立的 .animation(_:value:) 包裹旋转与位移，使每个属性可根据开合方向拥有各自的延迟；菜单行按索引使用带延迟的弹簧形成级联。"
        ),
        apis: ["Capsule", "rotationEffect", "animation(_:value:)", "Animation.delay"],
        tags: ["hamburger", "menu", "close", "morph", "dropdown", "汉堡菜单", "菜单", "关闭", "图标形变", "下拉"],
        params: [
            .slider("response", L("Spring response", "弹簧响应"), 0.2...0.8, default: 0.4, unit: "s"),
            .slider("damping", L("Damping", "阻尼"), 0.4...1, default: 0.7),
            .toggle("sequenced", L("Two-step sequence", "两段式"), default: true),
            .toggle("spin", L("Spin icon", "整体旋转"), default: false),
        ]
    ) { ctx in
        HamburgerDemo(ctx: ctx)
    }
}

private struct HamburgerDemo: View {
    let ctx: DemoContext
    @State private var open = false

    private var items: [(title: LocalizedText, symbol: String, tint: Color)] {
        [
            (L("Home", "首页"), "house.fill", Palette.indigo),
            (L("Library", "资料库"), "books.vertical.fill", Palette.violet),
            (L("Favorites", "收藏"), "heart.fill", Palette.pink),
            (L("Settings", "设置"), "gearshape.fill", Palette.sky),
        ]
    }

    var body: some View {
        VStack(spacing: 14) {
            screen
            DemoHint(text: L("Tap the menu button", "点击菜单按钮"), ctx: ctx)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 1.6) { toggle() }
    }

    /// A small mock app: top bar with the menu button, a feed underneath, and the menu dropping over it.
    private var screen: some View {
        VStack(alignment: .leading, spacing: 12) {
            appBar
            ZStack(alignment: .topLeading) {
                HamburgerFeed(language: ctx.language)
                    .opacity(open ? 0.35 : 1)
                    .blur(radius: open ? 2 : 0)
                    .animation(.easeOut(duration: 0.25), value: open)
                    .allowsHitTesting(false)
                menu
            }
        }
        .padding(14)
        .frame(width: 300, height: 318, alignment: .top)
        .background(Palette.surface, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 28, style: .continuous).strokeBorder(Palette.stroke))
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: .black.opacity(0.12), radius: 18, y: 10)
    }

    private var appBar: some View {
        HStack(spacing: 12) {
            Button { toggle() } label: {
                HamburgerIcon(
                    open: open,
                    response: ctx["response"],
                    damping: ctx["damping"],
                    sequenced: ctx.bool("sequenced"),
                    spin: ctx.bool("spin")
                )
                .frame(width: 52, height: 52)
                .background(.regularMaterial, in: Circle())
                .overlay(Circle().strokeBorder(Palette.stroke))
                .shadow(color: .black.opacity(open ? 0.16 : 0.08), radius: open ? 12 : 8, y: open ? 6 : 4)
            }
            .buttonStyle(.plain)
            VStack(alignment: .leading, spacing: 1) {
                Text(L("Today", "今天"), ctx.language)
                    .font(.title3.weight(.bold))
                Text(L("Tuesday, June 9", "6月9日 星期二"), ctx.language)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
            Circle()
                .fill(Palette.sunset)
                .frame(width: 34, height: 34)
                .overlay(Text(verbatim: "M").font(.subheadline.weight(.bold)).foregroundStyle(.white))
        }
    }

    private var menu: some View {
        VStack(spacing: 6) {
            ForEach(items.indices, id: \.self) { i in
                HamburgerMenuRow(title: items[i].title, symbol: items[i].symbol, tint: items[i].tint, language: ctx.language)
                    .opacity(open ? 1 : 0)
                    .blur(radius: open ? 0 : 4)
                    .scaleEffect(open ? 1 : 0.9, anchor: .top)
                    .offset(y: open ? 0 : -14 - CGFloat(i) * 8)
                    .animation(rowAnimation(i), value: open)
                    .onTapGesture { toggle() }
            }
        }
        .frame(width: 210)
        .allowsHitTesting(open)
    }

    /// Rows cascade in top-to-bottom after the bars have met, and leave bottom-to-top before the X unwinds.
    private func rowAnimation(_ i: Int) -> Animation {
        let order = open ? i : items.count - 1 - i
        let lead = open ? 0.1 : 0
        return .spring(response: ctx["response"], dampingFraction: 0.8).delay(lead + Double(order) * 0.045)
    }

    private func toggle() {
        open.toggle()
        if !ctx.isPreview { Haptics.tap(.light) }
    }
}

/// The screen's content the menu drops over.
private struct HamburgerFeed: View {
    let language: AppLanguage

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack(alignment: .bottomLeading) {
                LinearGradient(colors: [Palette.indigo, Palette.violet], startPoint: .topLeading, endPoint: .bottomTrailing)
                Image(systemName: "figure.run")
                    .font(.system(size: 54, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.25))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
                    .padding(.trailing, 16)
                VStack(alignment: .leading, spacing: 2) {
                    Text(L("Morning run", "晨跑"), language)
                        .font(.headline)
                    Text(L("5.2 km · 28 min · new best", "5.2 公里 · 28 分钟 · 新纪录"), language)
                        .font(.caption.weight(.medium))
                        .opacity(0.85)
                }
                .foregroundStyle(.white)
                .padding(14)
            }
            .frame(height: 104)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            row(L("Design review", "设计评审"), L("10:30 · Studio B", "10:30 · B 工作室"), "calendar", Palette.coral)
            row(L("Lunch with Mia", "和 Mia 午餐"), L("12:45 · Terrace", "12:45 · 露台"), "fork.knife", Palette.mint)
        }
    }

    private func row(_ title: LocalizedText, _ detail: LocalizedText, _ symbol: String, _ tint: Color) -> some View {
        HStack(spacing: 10) {
            Image(systemName: symbol)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 30, height: 30)
                .background(tint.gradient, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
            VStack(alignment: .leading, spacing: 1) {
                Text(title, language)
                    .font(.subheadline.weight(.semibold))
                Text(detail, language)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding(8)
        .background(Palette.elevated, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

private struct HamburgerMenuRow: View {
    let title: LocalizedText
    let symbol: String
    let tint: Color
    let language: AppLanguage

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(tint.gradient, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            Text(title, language)
                .font(.subheadline.weight(.semibold))
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.caption2.weight(.bold))
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 10)
        .frame(height: 42)
        .background(Palette.elevated, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 13, style: .continuous).strokeBorder(Palette.stroke))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
    }
}

private struct HamburgerIcon: View {
    let open: Bool
    let response: Double
    let damping: Double
    let sequenced: Bool
    let spin: Bool

    private let spacing: CGFloat = 7
    private let barWidth: CGFloat = 24
    private let barHeight: CGFloat = 3
    private var gap: Double { sequenced ? 0.12 : 0 }

    private var spring: Animation {
        .spring(response: response, dampingFraction: damping)
    }

    var body: some View {
        ZStack {
            bar(rotation: 45, offset: -spacing)
            Capsule()
                .frame(width: barWidth, height: barHeight)
                .scaleEffect(x: open ? 0.01 : 1, y: 1)
                .opacity(open ? 0 : 1)
                .animation(spring, value: open)
            bar(rotation: -45, offset: spacing)
        }
        .foregroundStyle(.primary)
        .rotationEffect(.degrees(spin && open ? 180 : 0))
        .animation(spring.delay(open ? gap : 0), value: open)
    }

    private func bar(rotation: Double, offset: CGFloat) -> some View {
        Capsule()
            .frame(width: barWidth, height: barHeight)
            .rotationEffect(.degrees(open ? rotation : 0))
            .animation(spring.delay(open ? gap : 0), value: open)
            .offset(y: open ? 0 : offset)
            .animation(spring.delay(open ? 0 : gap), value: open)
    }
}
