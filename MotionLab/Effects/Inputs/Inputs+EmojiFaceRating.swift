import SwiftUI

extension Effect {
    static let inputsEmojiFaceRating = Effect(
        id: "inputs.emoji-face-rating",
        category: .inputs,
        interaction: .gesture,
        name: L("Morphing Face Rating", "表情形变评分"),
        summary: L("One face morphs continuously from frown to grin, shifting colour as you slide.", "一张脸随滑动从皱眉连续形变为大笑，颜色也随之变化。"),
        prompt: L(
            "A feedback card with a single 120 pt face above a five-label slider (Awful → Great). Dragging morphs the face continuously: the mouth is one Bézier curve whose control points move from a deep frown to a wide grin, the eyes squint shorter as it brightens, the brows lift at their inner ends into a worried slant below the midpoint and relax flat above it, and the face colour blends coral → amber → mint. The slider thumb follows the finger, and on release it snaps to the nearest of five levels on a bouncy spring (response 0.45 s, damping 0.6), so the mouth overshoots its final shape; each time the level changes the face bobs up 6 pt with a keyframed hop and the label beneath swaps with a push transition. A selection haptic ticks per level. Expressive, empathetic and impossible to misread.",
            "反馈卡片上方是一张 120pt 的脸，下方是带五个标签（很差 → 很棒）的滑块。拖动时脸部连续形变：嘴巴是一条贝塞尔曲线，控制点从深深的皱眉移动到咧嘴大笑；眼睛随心情变好眯得更短；低于中间档时眉毛内端上扬呈担忧状，高于中间档则放平舒展；脸色由珊瑚红经琥珀过渡到薄荷绿。滑块跟随手指，松手后以弹性弹簧（响应 0.45 秒、阻尼 0.6）吸附到最近的五档之一，嘴形会先过冲再定型；每换一档，脸会以关键帧向上轻跳 6pt，下方标签以推入过渡切换，并触发一次选择触觉。表达丰富、有同理心，绝不会被误读。"
        ),
        implementation: L(
            "A custom Shape with an animatable mood value draws the mouth's quadratic curve; eye and brow shapes derive from the same value, colour comes from stacked fills with computed opacities, and a keyframeAnimator keyed on the level adds the hop.",
            "带可动画 mood 值的自定义 Shape 绘制嘴部二次曲线；眼睛与眉毛由同一数值推导，颜色通过叠加填充的透明度计算得出，以档位为触发的 keyframeAnimator 添加轻跳。"
        ),
        apis: ["Shape", "animatableData", "keyframeAnimator", "DragGesture", "transition(.push(from:))"],
        tags: ["rating", "emoji", "face", "feedback", "评分", "表情", "反馈", "形变"],
        params: [
            .toggle("snap", L("Snap to levels", "吸附档位"), default: true),
            .slider("response", L("Snap response", "吸附响应"), 0.2...0.8, default: 0.45, unit: "s"),
            .slider("damping", L("Snap damping", "吸附阻尼"), 0.3...1.0, default: 0.6),
        ]
    ) { ctx in
        EmojiFaceRatingDemo(ctx: ctx)
    }
}

private struct EmojiFaceRatingDemo: View {
    let ctx: DemoContext
    @State private var mood: Double = 0.5
    @State private var step = 0

    private let width: CGFloat = 250
    private static let previewMoods: [Double] = [1, 0.25, 0.75, 0, 0.5]

    private var labels: [LocalizedText] {
        [L("Awful", "很差"), L("Meh", "一般"), L("Okay", "还行"), L("Good", "不错"), L("Great!", "很棒！")]
    }

    private var level: Int { Int((mood * 4).rounded()).clamped(to: 0...4) }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            card
            Spacer()
            DemoHint(text: L("Drag the slider", "拖动滑块"), ctx: ctx)
                .padding(.bottom, 18)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 1.3, delay: 0.3) { previewTick() }
    }

    private var card: some View {
        VStack(spacing: 16) {
            FeelingFace(mood: mood)
                .frame(width: 120, height: 120)
                .keyframeAnimator(initialValue: 0.0, trigger: level) { content, hop in
                    content.offset(y: hop)
                } keyframes: { _ in
                    KeyframeTrack(\.self) {
                        CubicKeyframe(-6, duration: 0.1)
                        SpringKeyframe(0, duration: 0.35, spring: .bouncy)
                    }
                }
            ZStack {
                Text(labels[level], ctx.language)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .id(level)
                    .transition(.push(from: .bottom))
            }
            .frame(height: 24)
            .clipped()
            .animation(.snappy, value: level)
            slider
        }
        .padding(20)
        .frame(width: width + 40)
        .demoCard(cornerRadius: 26)
    }

    private var slider: some View {
        let x: CGFloat = width * CGFloat(mood)
        return ZStack(alignment: .leading) {
            Capsule()
                .fill(
                    LinearGradient(colors: [Palette.coral, Palette.amber, Palette.mint], startPoint: .leading, endPoint: .trailing)
                )
                .frame(height: 8)
                .opacity(0.8)
            ForEach(0..<5, id: \.self) { index in
                Circle()
                    .fill(Color.white.opacity(0.9))
                    .frame(width: 4, height: 4)
                    .offset(x: width * CGFloat(index) / 4 - 2)
            }
            Circle()
                .fill(Color.white)
                .shadow(color: .black.opacity(0.2), radius: 5, y: 2)
                .frame(width: 28, height: 28)
                .offset(x: x - 14)
        }
        .frame(width: width, height: 36)
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    let before = level
                    mood = Double(value.location.x / width).clamped(to: 0...1)
                    if level != before { Haptics.selection() }
                }
                .onEnded { _ in snap() }
        )
    }

    private func snap() {
        guard ctx.bool("snap") else { return }
        withAnimation(.spring(response: ctx["response"], dampingFraction: ctx["damping"])) {
            mood = Double(level) / 4
        }
    }

    private func previewTick() {
        let target = Self.previewMoods[step % Self.previewMoods.count]
        step += 1
        withAnimation(.spring(response: ctx["response"], dampingFraction: ctx["damping"])) { mood = target }
    }
}

/// The whole face is driven by one animatable mood value (0 = awful, 1 = great).
private struct FeelingFace: View, Animatable {
    var mood: Double

    var animatableData: Double {
        get { mood }
        set { mood = newValue }
    }

    var body: some View {
        let low: Double = max(0, 1 - mood * 2)
        let high: Double = max(0, mood * 2 - 1)
        ZStack {
            Circle().fill(Palette.amber)
            Circle().fill(Palette.coral).opacity(low)
            Circle().fill(Palette.mint).opacity(high)
            Circle()
                .fill(LinearGradient(colors: [.white.opacity(0.3), .clear], startPoint: .top, endPoint: .center))
            features
        }
        .shadow(color: Palette.amber.opacity(0.35), radius: 14, y: 8)
    }

    private var features: some View {
        let tilt: Double = -max(0, 0.5 - mood) * 40
        let eyeHeight: CGFloat = 16 - CGFloat(max(0, mood - 0.6)) * 22
        let ink = Color.black.opacity(0.72)
        return VStack(spacing: 14) {
            HStack(spacing: 30) {
                eye(tilt: tilt, height: eyeHeight, ink: ink)
                eye(tilt: -tilt, height: eyeHeight, ink: ink)
            }
            MoodMouth(mood: mood)
                .stroke(ink, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                .frame(width: 56, height: 22)
        }
        .offset(y: 6)
    }

    private func eye(tilt: Double, height: CGFloat, ink: Color) -> some View {
        VStack(spacing: 6) {
            Capsule()
                .fill(ink)
                .frame(width: 18, height: 4)
                .rotationEffect(.degrees(tilt))
            Capsule()
                .fill(ink)
                .frame(width: 11, height: max(height, 5))
        }
    }
}

private struct MoodMouth: Shape {
    var mood: Double

    var animatableData: Double {
        get { mood }
        set { mood = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let curve: CGFloat = CGFloat(mood * 2 - 1)
        let edgeY: CGFloat = rect.midY - curve * rect.height * 0.25
        let controlY: CGFloat = rect.midY + curve * rect.height * 1.1
        path.move(to: CGPoint(x: rect.minX, y: edgeY))
        path.addQuadCurve(to: CGPoint(x: rect.maxX, y: edgeY), control: CGPoint(x: rect.midX, y: controlY))
        return path
    }
}
