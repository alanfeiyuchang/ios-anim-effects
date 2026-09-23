import SwiftUI

// MARK: - Badge bounce

extension Effect {
    static let feedbackBadgeBounce = Effect(
        id: "feedback.badge-bounce",
        category: .feedback,
        interaction: .tap,
        name: L("Badge Bounce", "角标弹跳"),
        summary: L("A notification badge that hops and rolls its number on every change.", "通知角标随数字变化弹跳并滚动计数。"),
        prompt: L(
            "An 84 pt app tile with a white bell glyph carries a red capsule badge at its top-right corner, outlined by a 2.5 pt ring in the background color so it cuts cleanly out of the tile. Each new notification makes the bell wiggle, the badge hop up 6 pt and swell to 135% in 120 ms, then drop back with a bouncy spring while a thin red ring radiates from it to 210% and fades over 0.55 s; the digits roll vertically to the new value and the capsule widens smoothly for two-digit counts. Clearing scales the badge down to nothing; the first notification pops it back in from zero. Playful, legible and instantly noticeable.",
            "一枚 84 pt 的应用图块，中间是白色铃铛图标，右上角挂着红色胶囊角标，外圈有一道 2.5 pt 的背景色描边，使其干净地“切”出图块。每来一条新通知，铃铛左右摇晃，角标在 120 毫秒内上跳 6 pt 并膨胀到 135%，再以弹性弹簧落回，同时一圈细红光环从角标向外扩散到 210% 并在 0.55 秒内消散；数字纵向滚动到新值，两位数时胶囊宽度平滑变宽。清零时角标缩小至消失，第一条通知到来时再从零弹出。俏皮、清晰、一眼可见。"
        ),
        implementation: L(
            "keyframeAnimator keyed on the count drives the hop and swell; contentTransition(.numericText) rolls the digits and symbolEffect(.wiggle) shakes the bell.",
            "以计数为触发器的 keyframeAnimator 驱动弹跳与膨胀；contentTransition(.numericText) 滚动数字，symbolEffect(.wiggle) 摇动铃铛。"
        ),
        apis: ["keyframeAnimator", "contentTransition(.numericText)", "symbolEffect(.wiggle)", "Spring(duration:bounce:)"],
        tags: ["badge", "notification", "count", "bounce", "角标", "通知", "计数", "弹跳"],
        params: [
            .slider("swell", L("Swell", "膨胀"), 1.0...1.6, default: 1.35, unit: "×"),
            .slider("bounce", L("Bounce", "弹性"), 0...0.8, default: 0.5),
        ]
    ) { ctx in
        BadgeDemo(ctx: ctx)
    }
}

private struct BadgePop {
    var scale: CGFloat = 1
    var y: CGFloat = 0
    var ring: CGFloat = 1
    var ringOpacity: Double = 0
}

private struct BadgeDemo: View {
    let ctx: DemoContext
    @State private var count = 3
    @State private var rings = 0

    var body: some View {
        VStack(spacing: 30) {
            BadgeTile(count: count, rings: rings, swell: ctx.cg("swell"), bounce: ctx["bounce"])
                .onTapGesture { add() }
            HStack(spacing: 14) {
                roundButton("minus") { remove() }
                roundButton("plus") { add() }
            }
            DemoHint(text: L("Tap + or the app tile", "点击 + 或应用图块"), ctx: ctx)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 1.1, delay: 0.5) {
            if count >= 12 {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { count = 0 }
            } else {
                add()
            }
        }
    }

    private func roundButton(_ symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.headline)
                .foregroundStyle(.primary)
                .frame(width: 48, height: 48)
                .background(Palette.elevated, in: Circle())
                .overlay { Circle().strokeBorder(Palette.stroke) }
                .shadow(color: .black.opacity(0.08), radius: 8, y: 4)
        }
        .buttonStyle(.plain)
    }

    private func add() {
        if !ctx.isPreview { Haptics.tap() }
        rings += 1
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { count += 1 }
    }

    private func remove() {
        guard count > 0 else { return }
        if !ctx.isPreview { Haptics.selection() }
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { count -= 1 }
    }
}

private struct BadgeTile: View {
    let count: Int
    let rings: Int
    let swell: CGFloat
    let bounce: Double

    var body: some View {
        RoundedRectangle(cornerRadius: 22, style: .continuous)
            .fill(Palette.sunset)
            .frame(width: 84, height: 84)
            .overlay {
                Image(systemName: "bell.fill")
                    .font(.system(size: 34, weight: .semibold))
                    .foregroundStyle(.white)
                    .symbolEffect(.wiggle, value: rings)
            }
            .shadow(color: Palette.coral.opacity(0.35), radius: 14, y: 8)
            .overlay(alignment: .topTrailing) {
                if count > 0 {
                    badge
                        .alignmentGuide(.top) { d in d[VerticalAlignment.center] }
                        .alignmentGuide(.trailing) { d in d[HorizontalAlignment.center] + 4 }
                        .transition(AnyTransition.scale.combined(with: .opacity))
                }
            }
    }

    private var badge: some View {
        Text(count > 99 ? "99+" : "\(count)")
            .font(.system(size: 15, weight: .bold, design: .rounded).monospacedDigit())
            .foregroundStyle(.white)
            .contentTransition(.numericText(value: Double(count)))
            .padding(.horizontal, 8)
            .frame(minWidth: 28, minHeight: 28)
            .background(Palette.red, in: Capsule())
            .overlay { Capsule().strokeBorder(Palette.surface, lineWidth: 2.5) }
            .keyframeAnimator(initialValue: BadgePop(), trigger: rings) { content, pop in
                content
                    .scaleEffect(pop.scale)
                    .offset(y: pop.y)
                    .background {
                        Capsule()
                            .stroke(Palette.red, lineWidth: 2)
                            .scaleEffect(pop.ring)
                            .opacity(pop.ringOpacity)
                    }
            } keyframes: { _ in
                KeyframeTrack(\.scale) {
                    CubicKeyframe(swell, duration: 0.12)
                    SpringKeyframe(1, duration: 0.5, spring: Spring(duration: 0.5, bounce: bounce))
                }
                KeyframeTrack(\.y) {
                    CubicKeyframe(-6, duration: 0.12)
                    SpringKeyframe(0, duration: 0.5, spring: Spring(duration: 0.5, bounce: bounce))
                }
                KeyframeTrack(\.ring) {
                    MoveKeyframe(1)
                    CubicKeyframe(2.1, duration: 0.55)
                }
                KeyframeTrack(\.ringOpacity) {
                    MoveKeyframe(0.7)
                    CubicKeyframe(0, duration: 0.55)
                }
            }
    }
}

// MARK: - Stacked notification banners

extension Effect {
    static let feedbackStackedBanners = Effect(
        id: "feedback.stacked-banners",
        category: .feedback,
        interaction: .tap,
        name: L("Stacked Notifications", "堆叠通知"),
        summary: L("New banners drop onto a depth stack that fans out when tapped.", "新通知落入有纵深的堆叠，点击即展开成列表。"),
        prompt: L(
            "Notification banners (18 pt continuous-corner cards with app glyph, name, 'now' and a one-line message) rest in a collapsed stack: each card behind the front one sits 11 pt lower, 5% smaller and 7% darker, never transparent, so only solid slivers peek out. A new banner drops in from 80 pt above, scaling up from 92% and fading in on a spring (response 0.5 s, damping 0.78) as it pushes the others one step back; beyond three, the oldest dissolves. Tapping the stack fans the cards into a list with 10 pt gaps on the same spring, the container growing so the controls below glide down; tapping again folds them back. Layered, orderly, tactile.",
            "通知横幅（18 pt 连续圆角卡片：应用图标、名称、“现在”与一行消息）平时收成一叠：前卡之后的每张下移 11 pt、缩小 5%、压暗 7%，从不变透明，只露出一道道实色边。新横幅从上方 80 pt 落下，从 92% 放大并淡入，弹簧响应 0.5 秒、阻尼 0.78，把其余卡片各往后推一层；超过三张，最旧的一张悄然溶解。点一下，整叠以同样的弹簧展开成间距 10 pt 的列表，容器随之长高，下方按钮顺势滑下；再点一次便收拢回去。层次分明，井然有序，触感十足。"
        ),
        implementation: L(
            "A ZStack of cards derives offset, scale, a dark tint overlay and zIndex from each card's index; insertion uses an asymmetric offset + scale + opacity transition.",
            "ZStack 中每张卡片依据索引计算偏移、缩放、暗色叠层与 zIndex；插入使用由位移、缩放与淡入组合的非对称过渡。"
        ),
        apis: ["ZStack", "zIndex", "AnyTransition.asymmetric", "spring(response:dampingFraction:)"],
        tags: ["notifications", "stack", "banner", "lock screen", "通知", "堆叠", "横幅", "锁屏"],
        params: [
            .slider("response", L("Spring response", "弹簧响应"), 0.25...0.9, default: 0.5, unit: "s"),
            .slider("damping", L("Damping", "阻尼"), 0.5...1.0, default: 0.78),
            .slider("peek", L("Stack peek", "露出高度"), 4...20, default: 11, decimals: 0, unit: "pt"),
        ]
    ) { ctx in
        StackedBannersDemo(ctx: ctx)
    }
}

private struct BannerSample {
    let symbol: String
    let tint: Color
    let app: LocalizedText
    let message: LocalizedText

    static let all: [BannerSample] = [
        BannerSample(symbol: "message.fill", tint: Palette.green, app: L("Messages", "信息"), message: L("Mia: Dinner at 8 tonight?", "米娅：今晚 8 点吃饭？")),
        BannerSample(symbol: "calendar", tint: Palette.red, app: L("Calendar", "日历"), message: L("Design review in 10 minutes", "10 分钟后开设计评审")),
        BannerSample(symbol: "flame.fill", tint: Palette.coral, app: L("Fitness", "健身"), message: L("You closed all your rings!", "今日圆环全部合拢！")),
        BannerSample(symbol: "envelope.fill", tint: Palette.blue, app: L("Mail", "邮件"), message: L("Invoice #2041 is ready", "发票 #2041 已开具")),
        BannerSample(symbol: "shippingbox.fill", tint: Palette.amber, app: L("Orders", "订单"), message: L("Your package is out for delivery", "您的包裹正在派送")),
    ]
}

private struct BannerItem: Identifiable, Equatable {
    let id: Int
}

private struct StackedBannersDemo: View {
    let ctx: DemoContext
    @State private var items: [BannerItem] = [BannerItem(id: 2), BannerItem(id: 1), BannerItem(id: 0)]
    @State private var nextID = 3
    @State private var expanded = false
    @State private var tick = 0

    private let cardHeight: CGFloat = 64

    private var spring: Animation {
        .spring(response: ctx["response"], dampingFraction: ctx["damping"])
    }

    var body: some View {
        VStack(spacing: 18) {
            stack
                // The frame grows with the fan-out, so the button below reflows on the same spring.
                .frame(width: 300, height: expanded ? cardHeight * 3 + 24 : cardHeight + ctx.cg("peek") * 2 + 10, alignment: .top)
                .contentShape(Rectangle())
                .onTapGesture { toggle() }
            HStack(spacing: 12) {
                Button(action: push) {
                    Label(ctx.language == .zh ? "新通知" : "New", systemImage: "plus")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .frame(height: 38)
                        .background(Palette.primary, in: Capsule())
                }
                .buttonStyle(.plain)
                DemoHint(text: L("Tap the stack", "点击堆叠"), ctx: ctx)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 1.5, delay: 0.5) {
            tick += 1
            if tick % 4 == 0 { toggle() } else { push() }
        }
    }

    private var stack: some View {
        ZStack(alignment: .top) {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                BannerCard(
                    sample: BannerSample.all[item.id % BannerSample.all.count],
                    language: ctx.language,
                    // Collapsed back cards are blank plates; otherwise their icons peek out under the front card.
                    showsContent: expanded || index == 0,
                    // Back cards recede by darkening, never by transparency, so cards behind don't show through.
                    dim: expanded ? 0 : 0.07 * Double(index)
                )
                    .frame(height: cardHeight)
                    .scaleEffect(expanded ? 1 : 1 - 0.05 * CGFloat(index), anchor: .top)
                    .offset(y: expanded ? CGFloat(index) * (cardHeight + 10) : CGFloat(index) * ctx.cg("peek"))
                    .zIndex(Double(-index))
                    .transition(
                        AnyTransition.asymmetric(
                            insertion: AnyTransition.offset(y: -80).combined(with: .scale(scale: 0.92)).combined(with: .opacity),
                            removal: .opacity
                        )
                    )
            }
        }
    }

    private func push() {
        if !ctx.isPreview { Haptics.tap(.soft) }
        withAnimation(spring) {
            items.insert(BannerItem(id: nextID), at: 0)
            if items.count > 3 { items.removeLast() }
        }
        nextID += 1
    }

    private func toggle() {
        if !ctx.isPreview { Haptics.selection() }
        withAnimation(spring) { expanded.toggle() }
    }
}

private struct BannerCard: View {
    let sample: BannerSample
    let language: AppLanguage
    var showsContent: Bool = true
    var dim: Double = 0

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: sample.symbol)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 38, height: 38)
                .background(sample.tint.gradient, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(sample.app, language)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(language == .zh ? "现在" : "now")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                Text(sample.message, language)
                    .font(.subheadline.weight(.medium))
                    .lineLimit(1)
            }
        }
        .opacity(showsContent ? 1 : 0)
        .padding(.horizontal, 13)
        .frame(maxHeight: .infinity)
        .background(Palette.elevated, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.black.opacity(dim))
                .allowsHitTesting(false)
        }
        .overlay { RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(Palette.stroke) }
        .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
    }
}
