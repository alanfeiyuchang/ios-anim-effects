import SwiftUI

extension Effect {
    static let showcaseBoardCard = Effect(
        id: "showcase.board-card",
        category: .showcase,
        interaction: .gesture,
        name: L("My Board Flip", "我的雪板翻转"),
        summary: L("A glossy snowboard that flips to its base in 3D on tap and tilts under your finger.", "带光泽的雪板：点击时 3D 翻转露出板底，拖动时随手指倾斜。"),
        prompt: L(
            "A \"My Board\" widget shows a capsule-shaped snowboard lying at −10°: a charcoal top sheet with an orange diagonal band, a lime pinstripe and two bindings. A tap flips the board around its long axis with a spring (≈0.7 s response, damping 0.72) and a slight 3D perspective; at the 90° edge-on moment it swaps to the base graphic — an orange gradient with topographic contour rings and a large \"156\" — so the flip reads as a real object turning over. Dragging tilts it up to ~25° on both axes with a diagonal sheen sliding across the gloss, and on release it wobbles back to rest on a bouncy spring. A medium haptic marks each flip. Tangible, collectible and a little playful.",
            "“我的雪板”小组件中，一块胶囊形雪板以 −10° 斜躺：炭黑色板面、橙色斜向色带、一道青柠细线和两个固定器。点击后雪板沿长轴翻转（弹簧响应约 0.7 秒、阻尼 0.72，带轻微 3D 透视）；在 90° 侧立的瞬间切换为板底图形——橙色渐变、等高线圈纹和大号“156”——让翻转像真实物体翻面一样可信。拖动时雪板在两个轴向上最多倾斜约 25°，一道斜向高光随之滑过光泽表面；松手后以弹性弹簧晃动回正。每次翻转伴随一次中等强度触感。有实物感、收藏感，也带点俏皮。"
        ),
        implementation: L(
            "An Animatable view receives the interpolated flip angle each frame, picks the front or mirrored back face from it, and applies rotation3DEffect for the flip plus drag-driven tilt; a masked gradient stripe provides the sheen.",
            "自定义 Animatable 视图逐帧获取插值后的翻转角度，据此选择正面或镜像后的背面，并用 rotation3DEffect 叠加翻转与拖动倾斜；遮罩内的渐变条纹形成高光。"
        ),
        apis: ["Animatable", "rotation3DEffect", "DragGesture", "AnimatablePair", "blendMode(.plusLighter)"],
        tags: ["3d flip", "card flip", "tilt", "snowboard", "3D 翻转", "倾斜", "雪板", "光泽"],
        params: [
            .choice("mode", L("Tap motion", "点击动作"), [L("Flip 180°", "翻面 180°"), L("Spin 360°", "旋转 360°")], default: 0),
            .slider("response", L("Flip spring response", "翻转弹簧响应"), 0.3...1.2, default: 0.7, unit: "s"),
            .slider("tilt", L("Tilt intensity", "倾斜强度"), 0...1.5, default: 1.0),
        ]
    ) { ctx in
        SportBoardDemo(ctx: ctx)
    }
}

private struct SportBoardDemo: View {
    let ctx: DemoContext
    @State private var angle: Double = 0
    @State private var tilt: CGSize = .zero

    var body: some View {
        SignatureStage {
            VStack(spacing: 0) {
                Spacer()
                card
                Spacer()
                DemoHint(text: L("Tap to flip, drag to tilt", "点击翻转，拖动倾斜"), ctx: ctx)
                    .padding(.bottom, 16)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .autoplay(ctx.isPreview, every: 2.4, delay: 0.8) { flip() }
    }

    private var card: some View {
        VStack(alignment: .leading, spacing: 10) {
            BoardHeader(language: ctx.language)
            BoardFlipper(
                angle: angle,
                tiltX: Double(tilt.width) * 0.25 * ctx["tilt"],
                tiltY: Double(-tilt.height) * 0.25 * ctx["tilt"]
            )
            .frame(maxWidth: .infinity)
            .frame(height: 118)
            .contentShape(Rectangle())
            .onTapGesture { flip() }
            .gesture(tiltGesture)
            BoardStats(language: ctx.language)
        }
        .padding(20)
        .frame(width: 292)
        .signatureCard()
    }

    private var tiltGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                tilt = CGSize(
                    width: value.translation.width.clamped(to: -100...100),
                    height: value.translation.height.clamped(to: -100...100)
                )
            }
            .onEnded { _ in
                withAnimation(.spring(response: 0.5, dampingFraction: 0.45)) { tilt = .zero }
            }
    }

    private func flip() {
        let delta: Double = ctx.int("mode") == 1 ? 360 : 180
        withAnimation(.spring(response: ctx["response"], dampingFraction: 0.72)) { angle += delta }
        if !ctx.isPreview { Haptics.tap(.medium) }
    }
}

/// Receives the interpolated angles every frame so it can choose which face is visible.
private struct BoardFlipper: View, Animatable {
    var angle: Double
    var tiltX: Double
    var tiltY: Double

    var animatableData: AnimatablePair<Double, AnimatablePair<Double, Double>> {
        get { AnimatablePair(angle, AnimatablePair(tiltX, tiltY)) }
        set {
            angle = newValue.first
            tiltX = newValue.second.first
            tiltY = newValue.second.second
        }
    }

    private var showsBase: Bool {
        let wrapped = angle.truncatingRemainder(dividingBy: 360)
        let a = wrapped < 0 ? wrapped + 360 : wrapped
        return a > 90 && a < 270
    }

    var body: some View {
        ZStack {
            if showsBase {
                BoardBase()
                    .scaleEffect(x: 1, y: -1)
            } else {
                BoardTop()
            }
        }
        .frame(width: 228, height: 60)
        .overlay { BoardSheen(shift: CGFloat(tiltX * 3 + sin(angle * .pi / 180) * 90)) }
        .rotationEffect(.degrees(-10))
        .rotation3DEffect(.degrees(angle + tiltY), axis: (x: 1, y: 0, z: 0), perspective: 0.5)
        .rotation3DEffect(.degrees(tiltX), axis: (x: 0, y: 1, z: 0), perspective: 0.5)
        .shadow(color: .black.opacity(0.55), radius: 14, y: 12)
    }
}

private struct BoardTop: View {
    var body: some View {
        ZStack {
            Capsule()
                .fill(LinearGradient(colors: [Color(hex: 0x2C2C33), Color(hex: 0x0E0E11)], startPoint: .top, endPoint: .bottom))
            Rectangle()
                .fill(Signature.accentGradient)
                .frame(width: 44, height: 140)
                .rotationEffect(.degrees(24))
                .offset(x: 46)
            Rectangle()
                .fill(Signature.lime.opacity(0.9))
                .frame(width: 6, height: 140)
                .rotationEffect(.degrees(24))
                .offset(x: 80)
            HStack(spacing: 14) {
                BoardBinding()
                Text(verbatim: "NORDKETTE")
                    .font(.system(size: 8, weight: .heavy, design: .rounded))
                    .tracking(2.5)
                    .foregroundStyle(Color.white.opacity(0.55))
                BoardBinding()
            }
        }
        .clipShape(Capsule())
        .overlay(Capsule().strokeBorder(Color.white.opacity(0.18), lineWidth: 1))
    }
}

private struct BoardBase: View {
    var body: some View {
        ZStack {
            Capsule()
                .fill(Signature.accentGradient)
            ForEach(0..<4, id: \.self) { ring in
                Ellipse()
                    .stroke(Color.black.opacity(0.16), lineWidth: 1)
                    .frame(width: 50 + CGFloat(ring) * 34, height: 16 + CGFloat(ring) * 11)
                    .offset(x: 34)
            }
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(verbatim: "CARVE")
                    .font(.system(size: 9, weight: .heavy, design: .rounded))
                    .tracking(2)
                Text(verbatim: "156")
                    .font(.system(size: 28, weight: .black, design: .rounded))
            }
            .foregroundStyle(Color.black.opacity(0.72))
            .offset(x: -30)
        }
        .clipShape(Capsule())
        .overlay(Capsule().strokeBorder(Color.white.opacity(0.35), lineWidth: 1))
    }
}

private struct BoardBinding: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 5, style: .continuous)
            .fill(LinearGradient(colors: [Color(hex: 0x4A4A52), Color(hex: 0x26262B)], startPoint: .top, endPoint: .bottom))
            .frame(width: 18, height: 42)
            .overlay(RoundedRectangle(cornerRadius: 5, style: .continuous).strokeBorder(Color.white.opacity(0.2)))
    }
}

private struct BoardSheen: View {
    let shift: CGFloat

    var body: some View {
        ZStack {
            LinearGradient(colors: [.clear, Color.white.opacity(0.38), .clear], startPoint: .leading, endPoint: .trailing)
                .frame(width: 64)
                .rotationEffect(.degrees(20))
                .offset(x: shift)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .blendMode(.plusLighter)
        .clipShape(Capsule())
        .allowsHitTesting(false)
    }
}

private struct BoardHeader: View {
    let language: AppLanguage

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 3) {
                Text(L("My Board", "我的雪板"), language)
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.white)
                Text(verbatim: "Carve Custom · 156")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(Signature.textSecondary)
            }
            Spacer(minLength: 0)
            Image(systemName: "arrow.up.right")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(Color.white)
                .frame(width: 30, height: 30)
                .background(Circle().fill(Color.white.opacity(0.08)))
        }
    }
}

private struct BoardStats: View {
    let language: AppLanguage

    var body: some View {
        HStack(spacing: 8) {
            BoardStat(value: "156", unit: "cm", label: L("Length", "板长")(language))
            BoardStat(value: "6", unit: "/10", label: L("Flex", "软硬")(language))
            BoardStat(value: "2", unit: language == .zh ? "天" : "d", label: L("Waxed", "打蜡")(language))
        }
    }
}

private struct BoardStat: View {
    let value: String
    let unit: String
    let label: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(Signature.number(17))
                    .foregroundStyle(Color.white)
                Text(unit)
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundStyle(Signature.textSecondary)
            }
            Text(label)
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundStyle(Signature.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.white.opacity(0.05)))
    }
}
