import SwiftUI

extension Effect {
    static let cardsScrubFlip = Effect(
        id: "cards.scrub-flip",
        category: .cards,
        interaction: .gesture,
        name: L("Scrub & Spin Flip", "拨动旋转翻面"),
        summary: L("Scrub a card's rotation with your finger, then flick it to spin like a coin and land on a face.", "用手指拨动卡片的旋转角度，甩一下就会像硬币一样旋转并落在某一面。"),
        prompt: L(
            "A 250×158 pt card can be turned directly: horizontal drag scrubs its rotation around the vertical axis at 0.9° per point, 1:1 with the finger and in perspective, while vertical drag adds up to ±14° of pitch. Whichever face points at the viewer is drawn, and the card lifts up to 6% and deepens its shadow as it passes edge-on. On release, 60% of the gesture's predicted travel is added as momentum and the angle is rounded to the nearest face (at most three half-turns per flick), so a quick flick spins it like a coin before it lands on a spring (response 0.6 s, damping 0.72) with a light haptic. A slow release simply settles to the closest face. Direct, tactile and toy-like.",
            "一张250×158 pt的卡片可以被直接转动：水平拖动以每点0.9°的比例拨动它绕竖直轴的透视旋转，与手指1:1同步；竖直拖动额外带来最多±14°的俯仰。朝向观者的那一面会被绘制出来，卡片侧立经过时最多抬起6%，阴影随之加深。松手时，手势预测位移的60%被当作惯性叠加，并把角度取整到最近的一面（每次甩动最多三个半圈），因此快速一甩会让它像硬币一样旋转，最后以弹簧（响应0.6秒、阻尼0.72）落定并伴随轻触感；慢慢松手则直接回到最近的一面。直接可触，像玩具。"
        ),
        implementation: L(
            "DragGesture sets the angle without animation while dragging; onEnded projects predictedEndTranslation, rounds to a multiple of 180° and springs there. An Animatable card view picks the visible face from the interpolated angle.",
            "拖动时 DragGesture 无动画地直接设置角度；onEnded 根据 predictedEndTranslation 推算落点，取整到 180° 的倍数后以弹簧过渡。Animatable 卡片视图根据插值后的角度决定显示哪一面。"
        ),
        apis: ["DragGesture", "predictedEndTranslation", "rotation3DEffect", "Animatable", "spring(response:dampingFraction:)"],
        tags: ["flip", "spin", "coin", "momentum", "翻面", "旋转", "硬币", "惯性"],
        params: [
            .slider("sensitivity", L("Sensitivity", "灵敏度"), 0.4...1.5, default: 0.9, unit: "°/pt"),
            .slider("momentum", L("Momentum", "惯性"), 0...1, default: 0.6),
            .slider("damping", L("Landing damping", "落定阻尼"), 0.4...1.0, default: 0.72),
        ]
    ) { ctx in
        CardsScrubFlipDemo(ctx: ctx)
    }
}

private struct CardsScrubFlipDemo: View {
    let ctx: DemoContext
    @State private var angle: Double = 0
    @State private var pitch: Double = 0
    @State private var base: Double?
    @State private var direction: Double = 1

    var body: some View {
        VStack(spacing: 30) {
            CardsSpinCard(angle: angle, pitch: pitch, language: ctx.language)
                .contentShape(Rectangle())
                .gesture(drag)
            DemoHint(text: L("Drag sideways, or flick to spin", "左右拖动，或快速甩动让它旋转"), ctx: ctx)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 2.2) { autoSpin() }
    }

    private var drag: some Gesture {
        DragGesture(minimumDistance: 2)
            .onChanged { value in
                let start = base ?? angle
                if base == nil { base = angle }
                var transaction = Transaction()
                transaction.disablesAnimations = true
                withTransaction(transaction) {
                    angle = start + Double(value.translation.width) * ctx["sensitivity"]
                    pitch = (-Double(value.translation.height) * 0.12).clamped(to: -14...14)
                }
            }
            .onEnded { value in
                let start = base ?? angle
                base = nil
                let extra = Double(value.predictedEndTranslation.width - value.translation.width) * ctx["momentum"]
                let projected = angle + extra * ctx["sensitivity"]
                land(on: projected, from: start)
            }
    }

    /// Rounds to the nearest face, at most three half-turns away from where the drag began.
    private func land(on projected: Double, from start: Double, haptic: Bool = true) {
        let startFace = (start / 180).rounded()
        let face = ((projected / 180).rounded()).clamped(to: (startFace - 3)...(startFace + 3))
        if haptic && !ctx.isPreview { Haptics.tap(.light) }
        withAnimation(.spring(response: 0.6, dampingFraction: ctx["damping"])) {
            angle = face * 180
            pitch = 0
        }
    }

    private func autoSpin() {
        direction = -direction
        let start = angle
        let dir = direction
        let muted = Haptics.isMuted || ctx.isPreview
        withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
            angle = start + 55 * dir
            pitch = 8
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
            land(on: start + 470 * dir, from: start, haptic: !muted)
        }
    }
}

private struct CardsSpinCard: View, Animatable {
    var angle: Double
    var pitch: Double
    let language: AppLanguage

    var animatableData: AnimatablePair<Double, Double> {
        get { AnimatablePair(angle, pitch) }
        set {
            angle = newValue.first
            pitch = newValue.second
        }
    }

    var body: some View {
        let remainder = angle.truncatingRemainder(dividingBy: 360)
        let normalized = remainder < 0 ? remainder + 360 : remainder
        let showBack = normalized > 90 && normalized < 270
        let edge: CGFloat = CGFloat(abs(sin(angle * .pi / 180)))
        let lifted: CGFloat = 1 + 0.06 * edge
        let shadowOpacity: Double = 0.18 + 0.12 * Double(edge)
        let shadowRadius: CGFloat = 16 + 12 * edge
        let shadowY: CGFloat = 12 + 12 * edge
        ZStack {
            CardsCreditCard(theme: 4, last4: "8812")
                .opacity(showBack ? 0 : 1)
            CardsSpinBack(language: language)
                .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
                .opacity(showBack ? 1 : 0)
        }
        .rotation3DEffect(.degrees(pitch), axis: (x: 1, y: 0, z: 0), perspective: 0.5)
        .rotation3DEffect(.degrees(angle), axis: (x: 0, y: 1, z: 0), perspective: 0.5)
        .scaleEffect(lifted)
        .shadow(color: .black.opacity(shadowOpacity), radius: shadowRadius, y: shadowY)
    }
}

private struct CardsSpinBack: View {
    let language: AppLanguage

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "qrcode")
                .font(.system(size: 54, weight: .regular))
                .foregroundStyle(Color.white.opacity(0.92))
            Text(L("Scan to pay", "扫码支付"), language)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.white.opacity(0.8))
        }
        .frame(width: 250, height: 158)
        .background(LinearGradient(colors: CardsArt.colors(3), startPoint: .topLeading, endPoint: .bottomTrailing))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(Color.white.opacity(0.2), lineWidth: 1))
    }
}
