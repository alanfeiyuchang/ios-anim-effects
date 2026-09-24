import SwiftUI

extension Effect {
    static let cardsTilt3D = Effect(
        id: "cards.tilt-3d",
        category: .cards,
        interaction: .gesture,
        name: L("3D Tilt Card", "3D 倾斜卡片"),
        summary: L("Drag to tilt a glossy card in 3D with a moving glare and shifting shadow.", "拖动让卡片在三维空间中倾斜，高光随指移动，阴影随之偏移。"),
        prompt: L(
            "A glossy 250×158 pt payment card with 18 pt continuous corners and an indigo-to-pink gradient rests flat on a soft shadow. Dragging tilts it toward the finger in perspective, up to ±16° on both axes, through a tight interactive spring (response 0.25 s, damping 0.8) while it lifts to 104% with a soft haptic on touch-down. A radial white glare in overlay blend tracks the finger, the inner light blobs parallax the opposite way, and the shadow slides against the tilt as it grows larger and softer. Release springs it flat with a slight overshoot (response 0.5 s, damping 0.6); before the first touch it drifts in a slow Lissajous sway, like a weighty card catching studio light.",
            "一张250×158 pt的光泽支付卡，18 pt连续圆角，靛蓝到粉色渐变，静静平放在柔和投影上。手指拖动时，卡片以透视朝触点倾斜，X、Y轴最多各±16°，由紧致的交互弹簧（响应0.25秒、阻尼0.8）跟手，同时抬升到104%，按下瞬间有一下轻柔触感。径向白色高光以叠加模式追着手指走，卡内光斑反向视差；投影往倾斜的反方向滑开，并随抬升变大、变虚。松手后以弹簧（响应0.5秒、阻尼0.6）略带过冲地回正。未触摸前卡片会缓缓做利萨如摇摆，像影棚灯下的实体卡。"
        ),
        implementation: L(
            "The drag location is normalised to −1…1 and drives two rotation3DEffect modifiers, a RadialGradient glare whose center follows the finger, and the shadow offset; release animates back to zero with a spring.",
            "将拖动位置归一化到 −1…1，驱动两个 rotation3DEffect、中心随手指移动的 RadialGradient 高光以及投影偏移；松手时用弹簧动画归零。"
        ),
        apis: ["rotation3DEffect", "DragGesture", "RadialGradient", "blendMode(.overlay)", "interactiveSpring"],
        tags: ["tilt", "3D", "parallax", "glare", "倾斜", "视差", "高光", "透视"],
        params: [
            .slider("angle", L("Max tilt", "最大倾角"), 4...30, default: 16, step: 1, decimals: 0, unit: "°"),
            .slider("glare", L("Glare intensity", "高光强度"), 0...1, default: 0.6),
            .slider("follow", L("Follow spring", "跟手弹簧"), 0.1...0.6, default: 0.25, unit: "s"),
            .slider("response", L("Release spring", "松手回弹"), 0.2...1.0, default: 0.5, unit: "s"),
        ]
    ) { ctx in
        CardsTiltDemo(ctx: ctx)
    }
}

private struct CardsTiltDemo: View {
    let ctx: DemoContext
    /// Normalised touch position, −1…1 on each axis.
    @State private var tilt: CGSize = .zero
    @State private var touching = false
    /// Until the first touch the card drifts through a slow idle tilt, so the stage is alive on arrival.
    @State private var touched = false
    /// Resets on system cancellation too, so a stolen touch never leaves the card lifted.
    @GestureState private var pressing = false

    var body: some View {
        VStack(spacing: 28) {
            TimelineView(.animation(minimumInterval: MotionFrameRate.interval(preview: ctx.isPreview), paused: touched)) { timeline in
                let idle = sway(at: timeline.date.timeIntervalSinceReferenceDate)
                CardsTiltedCard(
                    tilt: touched ? tilt : idle,
                    lifted: touched ? touching : ctx.isPreview,
                    maxAngle: ctx["angle"],
                    glare: ctx["glare"]
                )
            }
            .gesture(drag)
            DemoHint(text: L("Drag across the card", "在卡片上拖动"), ctx: ctx)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onChange(of: pressing) { _, isPressing in
            if !isPressing { endHold() }
        }
    }

    /// Idle Lissajous drift: full swing in previews, a gentle ~45% sway on the detail stage.
    private func sway(at t: Double) -> CGSize {
        let amount = ctx.isPreview ? 1.0 : 0.45
        return CGSize(width: sin(t * 1.3) * 0.85 * amount, height: cos(t * 0.9) * 0.7 * amount)
    }

    private var drag: some Gesture {
        DragGesture(minimumDistance: 0)
            .updating($pressing) { _, state, _ in state = true }
            .onChanged { value in
                if !touched {
                    // Pick up from the idle pose instead of jumping.
                    tilt = sway(at: Date().timeIntervalSinceReferenceDate)
                    touched = true
                }
                let size = CardsTiltedCard.size
                let x = (value.location.x / size.width - 0.5) * 2
                let y = (value.location.y / size.height - 0.5) * 2
                if !touching { Haptics.tap(.soft) }
                withAnimation(.interactiveSpring(response: ctx["follow"], dampingFraction: 0.8)) {
                    tilt = CGSize(width: x.clamped(to: -1...1), height: y.clamped(to: -1...1))
                    touching = true
                }
            }
            .onEnded { _ in endHold() }
    }

    /// Release or system cancellation: the card drops back flat.
    private func endHold() {
        guard touching else { return }
        withAnimation(.spring(response: ctx["response"], dampingFraction: 0.6)) {
            tilt = .zero
            touching = false
        }
    }
}

private struct CardsTiltedCard: View {
    static let size = CGSize(width: 250, height: 158)

    let tilt: CGSize
    let lifted: Bool
    let maxAngle: Double
    let glare: Double

    var body: some View {
        CardsCreditCard(theme: 0, shift: CGSize(width: -tilt.width * 14, height: -tilt.height * 10))
            .overlay { glareLayer }
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .rotation3DEffect(.degrees(-Double(tilt.height) * maxAngle), axis: (x: 1, y: 0, z: 0), perspective: 0.55)
            .rotation3DEffect(.degrees(Double(tilt.width) * maxAngle), axis: (x: 0, y: 1, z: 0), perspective: 0.55)
            .scaleEffect(lifted ? 1.04 : 1)
            .shadow(
                color: .black.opacity(lifted ? 0.32 : 0.2),
                radius: lifted ? 26 : 16,
                x: -tilt.width * 16,
                y: 16 - tilt.height * 8
            )
    }

    private var glareLayer: some View {
        RadialGradient(
            colors: [.white.opacity(0.8 * glare), .white.opacity(0)],
            center: UnitPoint(x: 0.5 + tilt.width * 0.5, y: 0.5 + tilt.height * 0.5),
            startRadius: 0,
            endRadius: 190
        )
        .blendMode(.overlay)
        .allowsHitTesting(false)
    }
}
