import SwiftUI

extension Effect {
    static let cardsHingeReveal = Effect(
        id: "cards.hinge-reveal",
        category: .cards,
        interaction: .tap,
        name: L("Hinged Cover", "铰链翻盖"),
        summary: L("A cover hinged on its left edge swings open like a door, sways and settles on the reveal.", "以左边为铰链的封面像门一样甩开，来回摆动后停在揭晓内容上。"),
        prompt: L(
            "A 210×140 pt gift card sits closed under a gradient cover with a ribbon and an \"Open me\" label. Tapping swings the cover open around its left edge in 3D perspective to about 108°, driven by a loose spring (response 0.8 s, damping 0.42), so it overshoots and sways on its hinge two or three times before coming to rest. As it turns, the cover darkens toward edge-on, flips to its paper-white inside past 90°, and casts a soft shadow across the revealed code that fades as it opens; the whole card drifts 30 pt right to keep the open door on stage. Tapping again closes it with a firmer, well-damped spring. Physical, suspenseful and satisfying.",
            "一张210×140 pt的礼品卡被带丝带和「打开我」字样的渐变封面盖住。点击后，封面以左边为铰链在三维透视中甩开到约108°，由松弛的弹簧（响应0.8秒、阻尼0.42）驱动，因此会越过终点，在铰链上来回摆动两三次后才停稳。转动过程中，封面接近侧立时逐渐变暗，超过90°后翻出纸白色内侧，并在下方露出的兑换码上投下随开启而淡去的柔和阴影；整张卡同时向右平移30 pt，让打开的门留在舞台内。再次点击则以更硬、阻尼充分的弹簧合上。真实、带悬念、令人满足。"
        ),
        implementation: L(
            "An Animatable view interpolates the hinge angle and applies rotation3DEffect(anchor: .leading); inside it the angle picks the front or back face, the shading and the inner shadow, so every frame of the spring is consistent.",
            "Animatable 视图插值铰链角度，并应用 rotation3DEffect(anchor: .leading)；视图内部根据角度选择正反面、明暗与内侧阴影，保证弹簧的每一帧都一致。"
        ),
        apis: ["rotation3DEffect(_:axis:anchor:perspective:)", "Animatable", "spring(response:dampingFraction:)", "LinearGradient"],
        tags: ["hinge", "door", "reveal", "gift card", "铰链", "开门", "揭晓", "礼品卡"],
        params: [
            .slider("openAngle", L("Open angle", "开启角度"), 70...150, default: 108, step: 1, decimals: 0, unit: "°"),
            .slider("response", L("Swing response", "摆动响应"), 0.4...1.2, default: 0.8, unit: "s"),
            .slider("damping", L("Swing damping", "摆动阻尼"), 0.2...0.9, default: 0.42),
        ]
    ) { ctx in
        CardsHingeDemo(ctx: ctx)
    }
}

private struct CardsHingeDemo: View {
    let ctx: DemoContext
    @State private var open = false

    var body: some View {
        let target = open ? ctx["openAngle"] : 0
        VStack(spacing: 30) {
            CardsHingeCard(angle: target, openAngle: max(ctx["openAngle"], 1), language: ctx.language)
                .contentShape(Rectangle())
                .onTapGesture(perform: toggle)
            DemoHint(text: L("Tap to open the cover", "点击打开封面"), ctx: ctx)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 2.4) { toggle() }
    }

    private func toggle() {
        Haptics.tap(open ? .rigid : .medium)
        if open {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.86)) { open = false }
        } else {
            withAnimation(.spring(response: ctx["response"], dampingFraction: ctx["damping"])) { open = true }
        }
    }
}

private struct CardsHingeCard: View, Animatable {
    /// Current hinge angle in degrees (0 = closed).
    var angle: Double
    let openAngle: Double
    let language: AppLanguage

    var animatableData: Double {
        get { angle }
        set { angle = newValue }
    }

    private let size = CGSize(width: 210, height: 140)
    private var shape: RoundedRectangle { RoundedRectangle(cornerRadius: 18, style: .continuous) }

    var body: some View {
        let fraction = (angle / openAngle).clamped(to: 0...1.2)
        let showsInside = angle > 90
        let edgeOn = abs(sin(angle * .pi / 180))
        ZStack {
            inside(fraction: fraction)
            cover(showsInside: showsInside, shade: edgeOn)
                .rotation3DEffect(.degrees(-angle), axis: (x: 0, y: 1, z: 0), anchor: .leading, perspective: 0.6)
        }
        .frame(width: size.width, height: size.height)
        .offset(x: 30 * CGFloat(min(fraction, 1)))
    }

    private func inside(fraction: Double) -> some View {
        VStack(spacing: 8) {
            Image(systemName: "gift.fill")
                .font(.system(size: 26, weight: .semibold))
                .foregroundStyle(Palette.sunset)
            Text(L("$50 for you", "送你 ¥300"), language)
                .font(.headline.weight(.bold))
            Text(verbatim: "MOTION-2026")
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                .tracking(1.5)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.primary.opacity(0.07), in: Capsule())
        }
        .frame(width: size.width, height: size.height)
        .background(Palette.elevated, in: shape)
        .overlay {
            // Shadow cast by the cover, strongest while it still hangs over the card.
            LinearGradient(colors: [Color.black.opacity(0.35), .clear], startPoint: .leading, endPoint: .init(x: 0.7, y: 0.5))
                .clipShape(shape)
                .opacity(max(1 - fraction, 0))
        }
        .overlay(shape.strokeBorder(Palette.stroke))
        .shadow(color: .black.opacity(0.14), radius: 14, y: 8)
    }

    @ViewBuilder
    private func cover(showsInside: Bool, shade: Double) -> some View {
        if showsInside {
            shape
                .fill(Color(hex: 0xF4F1EA))
                .overlay(shape.fill(Color.black.opacity(0.25 * shade)))
                .frame(width: size.width, height: size.height)
        } else {
            coverFront
                .overlay(shape.fill(Color.black.opacity(0.35 * shade)))
                .frame(width: size.width, height: size.height)
        }
    }

    private var coverFront: some View {
        ZStack {
            LinearGradient(colors: CardsArt.colors(2), startPoint: .topLeading, endPoint: .bottomTrailing)
            Rectangle()
                .fill(Color.white.opacity(0.85))
                .frame(width: 14)
                .offset(x: 50)
            Text(L("Open me", "打开我"), language)
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .offset(x: -24)
        }
        .clipShape(shape)
        .overlay(shape.strokeBorder(Color.white.opacity(0.25), lineWidth: 1))
    }
}
