import SwiftUI

extension Effect {
    static let showcaseDestinationCarousel = Effect(
        id: "showcase.destination-carousel",
        category: .showcase,
        interaction: .scroll,
        name: L("Destination Carousel", "目的地轮播"),
        summary: L(
            "Swipeable photo cards that scale, tilt and parallax with scroll position, with a stretching page indicator.",
            "可滑动的目的地照片卡片，随滚动位置缩放、倾斜并产生视差，页码点会拉伸变形。"
        ),
        prompt: L(
            "A horizontal carousel of tall destination cards (200×240 pt, 24 pt corners) with a scrim, a country eyebrow, a bold place name and a “126 shots” caption. The centered card sits at 100% scale. As a card moves toward the edge it shrinks to ~86%, rotates up to 5° in the scroll direction and fades to 65% opacity, all mapped directly to scroll offset. Inside each card the photo is 72 pt wider than its frame and shifts opposite to the scroll by up to 36 pt, giving a window-like parallax. Paging snaps card by card with view-aligned targeting. Below, the active page dot stretches into a 22 pt orange capsule while the others shrink to 6 pt dots on a spring (response 0.35 s, damping 0.7), with a selection haptic per page. It feels deep, tactile and editorial.",
            "横向轮播一排竖版目的地卡片（200×240pt，圆角 24pt），卡片上有渐变遮罩、国家小标题、粗体地名和「126 张照片」说明。居中卡片保持 100% 缩放。卡片往边缘移动时，会按滚动偏移直接映射，缩小到约 86%，朝滚动方向最多倾斜 5°，透明度降到 65%。每张卡片里的照片比卡框宽 72pt，随滚动反向最多平移 36pt，像透过窗户看风景一样产生视差。翻页按视图对齐逐张吸附。下方当前页码点以弹簧（响应 0.35 秒、阻尼 0.7）拉伸成 22pt 的橙色胶囊，其余收缩为 6pt 圆点，每翻一页有一下选择触感。整体有纵深、有手感，像翻阅一本旅行杂志。"
        ),
        implementation: L(
            "ScrollView + LazyHStack with scrollTargetLayout, viewAligned target behavior, scrollPosition(id:) and contentMargins of (measured width − 200) / 2 so the snapped card is exactly centred; scrollTransition maps phase.value to scale, rotation and opacity on the card and to an x-offset on the oversized image inside it.",
            "ScrollView + LazyHStack 配合 scrollTargetLayout、viewAligned 吸附与 scrollPosition(id:)，contentMargins 取（实测宽度 − 200）/ 2，保证吸附后的卡片精确居中；scrollTransition 把 phase.value 映射为卡片的缩放、旋转和透明度，并映射为卡内超宽图片的横向偏移。"
        ),
        apis: ["scrollTransition", "scrollTargetBehavior(.viewAligned)", "scrollPosition(id:)", "contentMargins", "onGeometryChange", "LazyHStack"],
        tags: ["carousel", "parallax", "paging", "cards", "轮播", "视差", "分页", "卡片"],
        params: [
            .slider("tilt", L("Edge tilt", "边缘倾斜"), 0...12, default: 5, decimals: 0, unit: "°"),
            .slider("parallax", L("Parallax", "视差距离"), 0...60, default: 36, decimals: 0, unit: "pt"),
            .slider("minScale", L("Edge scale", "边缘缩放"), 0.7...1, default: 0.86),
        ]
    ) { ctx in
        TravelCarouselDemo(ctx: ctx)
    }
}

// MARK: - Model

private struct TravelCarouselSpot {
    let country: LocalizedText
    let name: LocalizedText
    let shots: Int
    let seed: Int

    static let all: [TravelCarouselSpot] = [
        TravelCarouselSpot(country: L("Italy", "意大利"), name: L("Lago di Braies", "布拉耶斯湖"), shots: 126, seed: 2),
        TravelCarouselSpot(country: L("France", "法国"), name: L("Azure Coast", "蔚蓝海岸"), shots: 98, seed: 1),
        TravelCarouselSpot(country: L("Austria", "奥地利"), name: L("Nordkette", "北链山"), shots: 211, seed: 0),
        TravelCarouselSpot(country: L("Jordan", "约旦"), name: L("Wadi Rum", "瓦迪拉姆"), shots: 74, seed: 3),
        TravelCarouselSpot(country: L("Norway", "挪威"), name: L("Lofoten Nights", "罗弗敦之夜"), shots: 143, seed: 4),
    ]
}

// MARK: - Demo

private struct TravelCarouselDemo: View {
    let ctx: DemoContext
    @State private var current: Int? = 0
    /// Measured scroll-view width, so the side margins centre a 200 pt card on any stage size.
    @State private var viewportWidth: CGFloat = 340
    /// Programmatic advances (autoplay, the detail intro) set this so they don't tick the selection haptic.
    @State private var quietUntil = Date.distantPast

    private var count: Int { TravelCarouselSpot.all.count }

    var body: some View {
        SignatureStage {
            VStack(spacing: 14) {
                header
                carousel
                dots
                DemoHint(text: L("Swipe the cards", "左右滑动卡片"), ctx: ctx)
                    .padding(.top, 4)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .autoplay(ctx.isPreview, every: 1.8) { advance() }
        .onChange(of: current) { _, _ in
            if !ctx.isPreview && Date.now >= quietUntil { Haptics.selection() }
        }
    }

    private var header: some View {
        HStack {
            Text(ctx.language == .zh ? "热门目的地" : "Trending destinations")
                .signatureEyebrow()
            Spacer(minLength: 0)
            Text(ctx.language == .zh ? "查看全部" : "See all")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(Signature.accent)
        }
        .padding(.horizontal, 28)
    }

    private var carousel: some View {
        let tilt = ctx["tilt"]
        let shrink = 1 - ctx.cg("minScale")
        let parallax = ctx.cg("parallax")
        return ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 14) {
                ForEach(0..<count, id: \.self) { index in
                    TravelCarouselCard(spot: TravelCarouselSpot.all[index], language: ctx.language, parallax: parallax)
                        .scrollTransition(.interactive, axis: .horizontal) { content, phase in
                            content
                                .scaleEffect(1 - CGFloat(abs(phase.value)) * shrink)
                                .rotationEffect(.degrees(phase.value * tilt))
                                .opacity(1 - abs(phase.value) * 0.35)
                        }
                }
            }
            .scrollTargetLayout()
        }
        .contentMargins(.horizontal, max((viewportWidth - 200) / 2, 0), for: .scrollContent)
        .scrollTargetBehavior(.viewAligned)
        .scrollPosition(id: $current)
        .frame(height: 250)
        .onGeometryChange(for: CGFloat.self) { proxy in
            proxy.size.width
        } action: { width in
            viewportWidth = width
        }
    }

    private var dots: some View {
        HStack(spacing: 6) {
            ForEach(0..<count, id: \.self) { index in
                let active = index == (current ?? 0)
                Capsule()
                    .fill(active ? AnyShapeStyle(Signature.accentGradient) : AnyShapeStyle(Color.white.opacity(0.25)))
                    .frame(width: active ? 22 : 6, height: 6)
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: current)
    }

    private func advance() {
        quietUntil = Date.now.addingTimeInterval(0.8)
        withAnimation(.spring(response: 0.55, dampingFraction: 0.85)) {
            current = ((current ?? 0) + 1) % count
        }
    }
}

// MARK: - Card

private struct TravelCarouselCard: View {
    let spot: TravelCarouselSpot
    let language: AppLanguage
    let parallax: CGFloat

    private static let size = CGSize(width: 200, height: 240)

    var body: some View {
        photo
            .overlay(
                LinearGradient(colors: [.clear, Color.black.opacity(0.72)], startPoint: .center, endPoint: .bottom)
            )
            .overlay(alignment: .topTrailing) {
                Image(systemName: "heart")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color.white)
                    .frame(width: 32, height: 32)
                    .background(.ultraThinMaterial, in: Circle())
                    .padding(12)
            }
            .overlay(alignment: .bottomLeading) { caption }
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.14))
            )
            .shadow(color: Color.black.opacity(0.45), radius: 16, y: 10)
    }

    private var photo: some View {
        let amount = parallax
        return LandscapeArt(seed: spot.seed)
            .frame(width: Self.size.width + amount * 2, height: Self.size.height)
            .scrollTransition(.interactive, axis: .horizontal) { content, phase in
                content.offset(x: -CGFloat(phase.value) * amount)
            }
            .frame(width: Self.size.width, height: Self.size.height)
            .clipped()
    }

    private var caption: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(spot.country(language))
                .signatureEyebrow()
            Text(spot.name(language))
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(Color.white)
                .lineLimit(1)
            HStack(spacing: 4) {
                Image(systemName: "camera.fill")
                Text(language == .zh ? "\(spot.shots) 张照片" : "\(spot.shots) shots")
            }
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(Color.white.opacity(0.7))
        }
        .padding(16)
    }
}
