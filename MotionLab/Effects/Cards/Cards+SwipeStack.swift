import SwiftUI

extension Effect {
    static let cardsSwipeStack = Effect(
        id: "cards.swipe-stack",
        category: .cards,
        interaction: .gesture,
        name: L("Swipe Deck", "左右滑卡"),
        summary: L("A Tinder-style stack: fling cards left or right with rotation and stamps.", "探探式卡片堆：左右甩出卡片，带旋转与印章反馈。"),
        prompt: L(
            "A deck of 200×250 pt profile cards with 26 pt corners; the two behind step down to 94% and 88% scale and sit 22 pt lower each, so their edges read as a pile. The top card follows the finger 1:1 and pivots on its bottom edge, about 14° per 220 pt of travel; a green LIKE or red NOPE stamp inks in between 60% and 100% of the 110 pt threshold, the matching round button swells to 118%, and the cards behind slide forward into the next slot. Releasing past the threshold or flicking hard throws the card away along its path on a quick spring (response 0.4 s, damping 0.86) with a success or medium haptic; otherwise it snaps back on a bouncy spring (response 0.45 s, damping 0.62). Playful and decisive.",
            "一叠 200×250 pt、26 pt 圆角的人物卡，后面两张依次缩到 94%、88%，并各下移 22 pt，底边错落成一叠。顶部卡片 1:1 跟手，以底边为轴旋转，每 220 pt 位移约 14°；拖到 110 pt 阈值的 60%–100% 时，绿色「喜欢」或红色「无感」印章逐渐盖实，对应的圆形按钮放大到 118%，后方卡片同步前移补位。越过阈值或用力一甩再松手，卡片以快速弹簧（响应 0.4 秒、阻尼 0.86）沿轨迹飞走，并伴随成功或中等触感；否则以弹性弹簧（响应 0.45 秒、阻尼 0.62）回弹。俏皮又果断。"
        ),
        implementation: L(
            "The top card's drag offset drives offset + rotationEffect(anchor: .bottom) and the stamp opacities; the drag progress also interpolates the depth of the cards behind. A flung card is recycled to the back without animation.",
            "顶部卡片的拖动位移驱动 offset、以底部为锚点的 rotationEffect 和印章透明度；拖动进度同时插值后方卡片的层级位置。甩出的卡片在无动画事务中移到队尾循环使用。"
        ),
        apis: ["DragGesture", "rotationEffect(_:anchor:)", "predictedEndTranslation", "zIndex", "withTransaction"],
        tags: ["swipe", "tinder", "deck", "stack", "滑动", "卡片堆", "左滑右滑", "探探"],
        params: [
            .slider("threshold", L("Swipe threshold", "甩出阈值"), 60...180, default: 110, step: 5, decimals: 0, unit: "pt"),
            .slider("rotation", L("Max rotation", "最大旋转"), 0...30, default: 14, step: 1, decimals: 0, unit: "°"),
            .slider("response", L("Throw response", "甩出响应"), 0.2...0.8, default: 0.4, unit: "s"),
            .slider("snap", L("Snap-back damping", "回弹阻尼"), 0.4...1.0, default: 0.62),
        ]
    ) { ctx in
        CardsSwipeDemo(ctx: ctx)
    }
}

private struct CardsSwipeProfile {
    let name: String
    let detail: LocalizedText
    let symbol: String
    let colors: [Color]
}

private let cardsSwipeProfiles: [CardsSwipeProfile] = [
    CardsSwipeProfile(name: "Maya, 27", detail: L("Product designer · 2 km", "产品设计师 · 2 公里"), symbol: "camera.macro", colors: [Color(hex: 0xFFB36B), Color(hex: 0xFF5F8F)]),
    CardsSwipeProfile(name: "Leo, 31", detail: L("Climber · 5 km", "攀岩爱好者 · 5 公里"), symbol: "mountain.2.fill", colors: [Color(hex: 0x4ED6A0), Color(hex: 0x2A9DF4)]),
    CardsSwipeProfile(name: "Iris, 25", detail: L("Musician · 1 km", "音乐人 · 1 公里"), symbol: "music.note", colors: [Color(hex: 0xA46BFF), Color(hex: 0x6E7BFF)]),
    CardsSwipeProfile(name: "Kai, 29", detail: L("Surfer · 8 km", "冲浪者 · 8 公里"), symbol: "figure.surfing", colors: [Color(hex: 0x3AC4FF), Color(hex: 0x4F7CFF)]),
    CardsSwipeProfile(name: "Nora, 33", detail: L("Chef · 3 km", "主厨 · 3 公里"), symbol: "fork.knife", colors: [Color(hex: 0xFFC247), Color(hex: 0xFF7A45)]),
]

private struct CardsSwipeDemo: View {
    let ctx: DemoContext
    @State private var order: [Int] = Array(0..<5)
    @State private var offset: CGSize = .zero
    @State private var autoDirection: CGFloat = -1
    /// True while a card is flying off, so a quick second tap can't skip an unseen card.
    @State private var flinging = false

    var body: some View {
        let threshold = ctx.cg("threshold")
        let progress = min(abs(offset.width) / threshold, 1)
        VStack(spacing: 16) {
            ZStack {
                ForEach(order, id: \.self) { id in
                    card(id: id, progress: progress, threshold: threshold)
                }
            }
            .frame(height: 284, alignment: .top)
            HStack(spacing: 36) {
                actionButton("xmark", color: Palette.red, amount: offset.width < 0 ? progress : 0) { fling(direction: -1) }
                actionButton("heart.fill", color: Palette.green, amount: offset.width > 0 ? progress : 0) { fling(direction: 1) }
            }
            DemoHint(text: L("Swipe the card or tap a button", "滑动卡片或点按钮"), ctx: ctx)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 1.7) { autoSwipe() }
    }

    private func card(id: Int, progress: CGFloat, threshold: CGFloat) -> some View {
        let depth = order.firstIndex(of: id) ?? 0
        let isTop = depth == 0
        let slot = max(CGFloat(depth) - progress, 0)
        let maxRotation = ctx["rotation"]
        let rotation = isTop ? Double(offset.width / 220) * maxRotation : 0
        let appear: Double = depth < 3 ? 1 : (depth == 3 ? Double(progress) : 0)
        return CardsSwipeCard(
            profile: cardsSwipeProfiles[id],
            like: isTop ? offset.width / threshold : 0,
            language: ctx.language
        )
        .scaleEffect(isTop ? 1 : 1 - slot * 0.06)
        .offset(y: isTop ? 0 : slot * 22)
        .rotationEffect(.degrees(rotation), anchor: .bottom)
        .offset(isTop ? offset : .zero)
        .opacity(appear)
        .zIndex(Double(order.count - depth))
        .allowsHitTesting(isTop)
        .gesture(drag)
    }

    private func actionButton(_ symbol: String, color: Color, amount: CGFloat, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(amount > 0.99 ? Color.white : color)
                .frame(width: 50, height: 50)
                .background(Circle().fill(color.opacity(Double(amount))))
                .background(Circle().fill(Palette.elevated))
                .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
        }
        .buttonStyle(.plain)
        .scaleEffect(1 + amount * 0.18)
    }

    private var drag: some Gesture {
        DragGesture()
            .onChanged { value in
                offset = value.translation
            }
            .onEnded { value in
                let threshold = ctx.cg("threshold")
                let predicted = value.predictedEndTranslation.width
                if abs(value.translation.width) > threshold || abs(predicted) > threshold * 2 {
                    fling(direction: predicted >= 0 ? 1 : -1)
                } else {
                    withAnimation(.spring(response: 0.45, dampingFraction: ctx["snap"])) {
                        offset = .zero
                    }
                }
            }
    }

    private func fling(direction: CGFloat, haptic: Bool = true) {
        guard !flinging else { return }
        flinging = true
        if haptic && !ctx.isPreview {
            if direction > 0 { Haptics.success() } else { Haptics.tap(.medium) }
        }
        withAnimation(.spring(response: ctx["response"], dampingFraction: 0.86)) {
            offset = CGSize(width: direction * 520, height: offset.height + 60)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.32) {
            var transaction = Transaction()
            transaction.disablesAnimations = true
            withTransaction(transaction) {
                let first = order.removeFirst()
                order.append(first)
                offset = .zero
            }
            flinging = false
        }
    }

    private func autoSwipe() {
        autoDirection *= -1
        let direction = autoDirection
        let muted = Haptics.isMuted || ctx.isPreview
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            offset = CGSize(width: direction * 80, height: -6)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
            fling(direction: direction, haptic: !muted)
        }
    }
}

private struct CardsSwipeCard: View {
    let profile: CardsSwipeProfile
    /// Signed drag progress: positive = like, negative = nope.
    let like: CGFloat
    let language: AppLanguage

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(colors: profile.colors, startPoint: .topLeading, endPoint: .bottomTrailing)
            Image(systemName: profile.symbol)
                .font(.system(size: 80, weight: .light))
                .foregroundStyle(Color.white.opacity(0.92))
                .shadow(color: .black.opacity(0.12), radius: 10, y: 6)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .offset(y: -26)
            LinearGradient(colors: [.clear, .black.opacity(0.5)], startPoint: .center, endPoint: .bottom)
            info
        }
        .frame(width: 200, height: 250)
        .overlay(alignment: .topLeading) {
            stamp(L("LIKE", "喜欢"), color: Palette.green, angle: -14)
                .opacity(stampOpacity(like))
                .padding(18)
        }
        .overlay(alignment: .topTrailing) {
            stamp(L("NOPE", "无感"), color: Palette.red, angle: 14)
                .opacity(stampOpacity(-like))
                .padding(18)
        }
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .shadow(color: .black.opacity(0.16), radius: 14, y: 8)
    }

    /// Fades the stamp in between 60% and 100% of the swipe threshold.
    private func stampOpacity(_ amount: CGFloat) -> Double {
        Double(((amount - 0.6) / 0.4).clamped(to: 0...1))
    }

    private var info: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(verbatim: profile.name)
                .font(.title3.weight(.bold))
            Text(profile.detail, language)
                .font(.footnote.weight(.medium))
                .opacity(0.85)
        }
        .foregroundStyle(.white)
        .padding(16)
    }

    private func stamp(_ text: LocalizedText, color: Color, angle: Double) -> some View {
        Text(text, language)
            .font(.system(size: 24, weight: .heavy, design: .rounded))
            .tracking(2)
            .foregroundStyle(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 3)
            .background(Color.white.opacity(0.18), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).strokeBorder(color, lineWidth: 3.5))
            .rotationEffect(.degrees(angle))
    }
}
