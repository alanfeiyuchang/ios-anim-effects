import SwiftUI

extension Effect {
    static let scrollCollapsingHeader = Effect(
        id: "scroll.collapsing-header",
        category: .scroll,
        interaction: .scroll,
        name: L("Collapsing Header", "折叠标题栏"),
        summary: L("A large title with avatar that morphs into a compact frosted bar as you scroll.", "带头像的大标题随滚动形变为紧凑的磨砂导航栏。"),
        prompt: L(
            "A screen opens with a 150 pt expanded header: a 64 pt gradient avatar, a 30 pt bold large title and a secondary subtitle. As the content scrolls up, the header is scrubbed continuously over the first 90 pt: its height shrinks to 60 pt, the avatar shrinks to 30 pt, the title scales down to ~57% while sliding up and right to sit beside the avatar, and the subtitle fades out twice as fast as the scroll. In parallel a frosted material background and a hairline divider fade in underneath so the rows passing beneath stay legible. Scrolling back down reverses everything exactly. No timers — pure geometry — so it feels glued to the finger, like a native iOS navigation bar with more character.",
            "页面顶部是一个 150 pt 的展开式标题区：64 pt 渐变头像、30 pt 粗体大标题与次级副标题。内容上滑时，标题区在前 90 pt 的滚动内被连续驱动：高度收缩到 60 pt，头像缩小到 30 pt，标题缩小到约 57% 并向右上滑动到头像旁边，副标题以两倍于滚动的速度淡出。与此同时，磨砂材质背景与细分隔线在下方淡入，让从下面经过的列表行依旧清晰可读。向下滚动时所有变化精确反向。没有任何计时器——纯几何驱动——因此如同黏在指尖，像原生 iOS 导航栏，却更有个性。"
        ),
        implementation: L(
            "onScrollGeometryChange publishes the content offset; a 0…1 progress interpolates the header's height, avatar size, title scale/offset and the material opacity in an overlay above the ScrollView.",
            "onScrollGeometryChange 发布内容偏移量；由 0…1 的进度插值计算 ScrollView 上方叠加层中标题栏的高度、头像尺寸、标题缩放/位移与材质透明度。"
        ),
        apis: ["onScrollGeometryChange", "scaleEffect(_:anchor:)", "Material", "overlay(alignment:)"],
        tags: ["collapsing header", "large title", "navigation bar", "morph", "折叠标题", "大标题", "导航栏", "形变"],
        params: [
            .toggle("divider", L("Hairline divider", "细分隔线"), default: true),
            .toggle("snap", L("Snap to state", "自动吸附"), default: true),
        ]
    ) { ctx in
        ScrollCollapsingDemo(ctx: ctx)
    }
}

private func scrollLerp(_ a: CGFloat, _ b: CGFloat, _ t: CGFloat) -> CGFloat { a + (b - a) * t }

private struct ScrollCollapsingDemo: View {
    let ctx: DemoContext
    @State private var offset: CGFloat = 0
    @State private var position = ScrollPosition(edge: .top)
    @State private var down = false

    private let range: CGFloat = 90

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                Color.clear.frame(height: 150)
                ForEach(0..<14, id: \.self) { i in
                    ScrollKitRow(index: i + 4, language: ctx.language)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .scrollIndicators(.hidden)
        .scrollPosition($position)
        .onScrollGeometryChange(for: CGFloat.self, of: { geometry in
            geometry.contentOffset.y + geometry.contentInsets.top
        }, action: { _, newValue in
            offset = newValue
        })
        .onScrollPhaseChange { _, newPhase in
            if newPhase == .idle { snapIfNeeded() }
        }
        .overlay(alignment: .top) {
            ScrollCollapsingBar(
                progress: (offset / range).clamped(to: 0...1),
                showsDivider: ctx.bool("divider"),
                language: ctx.language
            )
        }
        .autoplay(ctx.isPreview, every: 2.2) {
            down.toggle()
            withAnimation(.smooth(duration: 1.4)) {
                position.scrollTo(y: down ? 220 : 0)
            }
        }
    }

    /// Avoid resting half-collapsed: settle to fully expanded or collapsed.
    private func snapIfNeeded() {
        guard ctx.bool("snap"), offset > 0, offset < range else { return }
        withAnimation(.smooth(duration: 0.35)) {
            position.scrollTo(y: offset < range / 2 ? 0 : range)
        }
    }
}

private struct ScrollCollapsingBar: View {
    let progress: CGFloat
    let showsDivider: Bool
    let language: AppLanguage

    var body: some View {
        let p = progress
        let avatar = scrollLerp(64, 30, p)
        ZStack(alignment: .topLeading) {
            Circle()
                .fill(LinearGradient(colors: [Palette.coral, Palette.pink, Palette.violet], startPoint: .topLeading, endPoint: .bottomTrailing))
                .overlay {
                    Image(systemName: "music.note")
                        .font(.system(size: avatar * 0.42, weight: .bold))
                        .foregroundStyle(.white)
                }
                .frame(width: avatar, height: avatar)
                .offset(x: 16, y: scrollLerp(16, 15, p))
            Text(L("Library", "资料库"), language)
                .font(.system(size: 30, weight: .bold))
                .fixedSize()
                .scaleEffect(scrollLerp(1, 0.57, p), anchor: .topLeading)
                .offset(x: scrollLerp(16, 56, p), y: scrollLerp(88, 20, p))
            Text(L("128 items · Synced just now", "128 项 · 刚刚同步"), language)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize()
                .opacity(Double(max(1 - p * 2, 0)))
                .offset(x: 16, y: scrollLerp(126, 90, p))
            Image(systemName: "plus")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 30, height: 30)
                .background(Palette.primary, in: Circle())
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.trailing, 16)
                .offset(y: 15)
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .frame(height: scrollLerp(150, 60, p), alignment: .top)
        .clipped()
        .background {
            Rectangle()
                .fill(.regularMaterial)
                .opacity(Double(p))
        }
        .overlay(alignment: .bottom) {
            if showsDivider {
                Rectangle()
                    .fill(Color.primary.opacity(0.12 * Double(p)))
                    .frame(height: 0.5)
            }
        }
    }
}
