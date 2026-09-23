import SwiftUI

extension Effect {
    static let cardsFlip = Effect(
        id: "cards.flip",
        category: .cards,
        interaction: .tap,
        name: L("Flip Card", "翻转卡片"),
        summary: L("A card that turns over in 3D to reveal its back, lifting mid-flip.", "卡片在三维中翻面露出背面，翻转途中微微抬起。"),
        prompt: L(
            "A dark graphite payment card sits flat on the stage. On tap it flips 180° left-to-right around its vertical axis (or top-to-bottom around its horizontal axis) with strong perspective, driven by a soft spring (response ≈0.7 s, damping ≈0.78) that lands with a barely perceptible settle. The face swaps exactly at the 90° edge-on moment so the back — magnetic stripe, signature panel, CVV and a small iridescent hologram — reads correctly rather than mirrored. Mid-flip the card rises toward the viewer by ~8% and its shadow grows deeper and softer, then both relax as it lands. Each tap keeps turning in the same direction, like handling a real card, with a medium haptic tap.",
            "一张深石墨色支付卡平放在舞台上。点击后绕竖直轴左右翻转 180°（或绕水平轴上下翻转），带强透视，由柔和弹簧（响应约 0.7 秒、阻尼约 0.78）驱动，落定时仅有几乎察觉不到的回稳。正反面在卡片侧立的 90° 瞬间准确切换，背面的磁条、签名栏、CVV 与小块虹彩全息标都正向显示而非镜像。翻转过半时卡片向观者抬升约 8%，投影随之加深变柔，落下时再一起回落。每次点击都沿同一方向继续翻，像真实把玩一张卡，并伴随中等强度触感反馈。"
        ),
        implementation: L(
            "An Animatable view interpolates the rotation angle every frame, picks the front or the pre-rotated back face at 90°, and derives lift and shadow from |sin(angle)|.",
            "通过遵循 Animatable 的视图逐帧插值旋转角度，在 90° 时切换正面或预先旋转 180° 的背面，并用 |sin(角度)| 推导抬升与投影。"
        ),
        apis: ["Animatable", "rotation3DEffect", "spring(response:dampingFraction:)", "shadow"],
        tags: ["flip", "3D", "rotate", "card back", "翻转", "翻面", "三维", "卡片"],
        params: [
            .choice("axis", L("Flip direction", "翻转方向"), [L("Flip left-right", "左右翻转"), L("Flip top-bottom", "上下翻转")]),
            .slider("lift", L("Lift", "抬升"), 0...0.2, default: 0.08),
            .slider("response", L("Spring response", "弹簧响应"), 0.3...1.2, default: 0.7, unit: "s"),
            .slider("damping", L("Damping", "阻尼"), 0.5...1.0, default: 0.78),
        ]
    ) { ctx in
        CardsFlipDemo(ctx: ctx)
    }
}

private struct CardsFlipDemo: View {
    let ctx: DemoContext
    @State private var angle: Double = 0

    var body: some View {
        VStack(spacing: 28) {
            CardsFlipCard(angle: angle, vertical: ctx.int("axis") == 1, lift: ctx["lift"], language: ctx.language)
                .contentShape(Rectangle())
                .onTapGesture(perform: flip)
            DemoHint(text: L("Tap the card to flip it", "点击卡片翻面"), ctx: ctx)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 2.2) { flip() }
    }

    private func flip() {
        if !ctx.isPreview { Haptics.tap(.medium) }
        withAnimation(.spring(response: ctx["response"], dampingFraction: ctx["damping"])) {
            angle += 180
        }
    }
}

private struct CardsFlipCard: View, Animatable {
    var angle: Double
    let vertical: Bool
    let lift: Double
    let language: AppLanguage

    var animatableData: Double {
        get { angle }
        set { angle = newValue }
    }

    var body: some View {
        let remainder = angle.truncatingRemainder(dividingBy: 360)
        let normalized = remainder < 0 ? remainder + 360 : remainder
        let showBack = normalized > 90 && normalized < 270
        let rise = abs(sin(angle * .pi / 180))
        let axis: (x: CGFloat, y: CGFloat, z: CGFloat) = vertical ? (x: 1, y: 0, z: 0) : (x: 0, y: 1, z: 0)
        ZStack {
            CardsCreditCard(theme: 1, last4: "7310")
                .opacity(showBack ? 0 : 1)
            CardsFlipBack(language: language)
                .rotation3DEffect(.degrees(180), axis: axis)
                .opacity(showBack ? 1 : 0)
        }
        .rotation3DEffect(.degrees(angle), axis: axis, perspective: 0.45)
        .scaleEffect(1 + lift * rise)
        .shadow(color: .black.opacity(0.18 + 0.12 * rise), radius: 16 + 14 * rise, y: 12 + 16 * rise)
    }
}

private struct CardsFlipBack: View {
    let language: AppLanguage

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Rectangle()
                .fill(Color.black.opacity(0.85))
                .frame(height: 34)
                .padding(.top, 18)
            HStack(spacing: 10) {
                signature
                Text(verbatim: "382")
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color.black.opacity(0.8))
                    .frame(width: 44, height: 30)
                    .background(Color.white, in: RoundedRectangle(cornerRadius: 4, style: .continuous))
            }
            .padding(.horizontal, 18)
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(L("Authorized signature", "持卡人签名"), language)
                    Text(L("Customer care 800-555-0199", "客服热线 400-820-0199"), language)
                }
                .font(.system(size: 8, weight: .semibold))
                .foregroundStyle(Color.white.opacity(0.6))
                Spacer(minLength: 0)
                Circle()
                    .fill(AngularGradient(colors: Palette.spectrum + [Palette.indigo], center: .center, angle: .zero))
                    .frame(width: 30, height: 30)
                    .opacity(0.85)
            }
            .padding(.horizontal, 18)
            Spacer(minLength: 0)
        }
        .frame(width: 250, height: 158)
        .background(LinearGradient(colors: CardsArt.colors(1), startPoint: .topLeading, endPoint: .bottomTrailing))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(Color.white.opacity(0.2), lineWidth: 1))
    }

    private var signature: some View {
        RoundedRectangle(cornerRadius: 4, style: .continuous)
            .fill(Color.white.opacity(0.9))
            .frame(height: 30)
            .overlay(alignment: .leading) {
                Text(verbatim: "Alex Morgan")
                    .font(.system(size: 13, weight: .medium, design: .serif))
                    .italic()
                    .foregroundStyle(Color.black.opacity(0.7))
                    .padding(.leading, 10)
            }
    }
}
