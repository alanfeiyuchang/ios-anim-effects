import SwiftUI

extension Effect {
    static let inputsThumbsRating = Effect(
        id: "inputs.thumbs-rating",
        category: .inputs,
        interaction: .tap,
        name: L("Thumbs Flick Rating", "拇指甩动评分"),
        summary: L("Thumbs up or down with a wind-up flick, a particle burst and a rolling count.", "点赞或点踩时拇指先蓄力再甩动，伴随粒子迸发与计数滚动。"),
        prompt: L(
            "A \"Was this helpful?\" card with two 64 pt pill buttons — thumbs up with a count, thumbs down with a count. Choosing one plays a wind-up and flick: the glyph first cocks back 10° (90 ms), then whips 22° the other way and springs home (bouncy, 400 ms) while scaling to 125% and filling with colour (indigo for up, coral for down); eight small particles burst radially 26 pt from the glyph and fade within 450 ms. The count rolls up by one with numeric digits. The opposite button, if it was selected, deflates to 96% and gives its count back. Tapping the selected button again clears the rating and its count rolls back down. A medium haptic accompanies the flick. Expressive, cartoon-snappy and clear about the choice.",
            "“这篇内容有帮助吗？”卡片上有两个 64pt 胶囊按钮——带计数的点赞与点踩。选中其中一个时会播放“蓄力再甩出”：图标先向后扳 10°（90 毫秒），再向反方向甩出 22° 并弹回（弹性，400 毫秒），同时放大到 125% 并填充颜色（点赞为靛蓝、点踩为珊瑚红）；八颗小粒子从图标处径向迸发 26pt，并在 450 毫秒内消失。计数以数字滚动加一。另一个按钮若原本被选中，会缩到 96% 并退回计数。再次点击已选按钮则取消评分，计数滚动减回。甩动时伴随一次中等触觉。富有表现力、卡通般干脆，选择一目了然。"
        ),
        implementation: L(
            "A keyframeAnimator with rotation and scale tracks, keyed on a per-button trigger, produces the wind-up and flick; the particles are a ForEach of circles driven by a second keyframed progress value; counts use contentTransition(.numericText).",
            "带旋转与缩放两条轨道的 keyframeAnimator 以按钮各自的触发值驱动蓄力与甩动；粒子是由第二个关键帧进度值驱动的 ForEach 圆点；计数使用 contentTransition(.numericText)。"
        ),
        apis: ["keyframeAnimator", "KeyframeTrack", "contentTransition(.numericText)", "symbolVariant(.fill)", "ButtonStyle"],
        tags: ["rating", "thumbs up", "like", "feedback", "评分", "点赞", "点踩", "反馈"],
        params: [
            .slider("flick", L("Flick angle", "甩动角度"), 8...40, default: 22, decimals: 0, unit: "°"),
            .toggle("particles", L("Particles", "粒子"), default: true),
            .slider("pop", L("Pop scale", "弹出缩放"), 1.0...1.5, default: 1.25),
        ]
    ) { ctx in
        ThumbsRatingDemo(ctx: ctx)
    }
}

private struct ThumbsFlick {
    var angle: Double = 0
    var scale: CGFloat = 1
    var burst: CGFloat = 0
}

private struct ThumbsRatingDemo: View {
    let ctx: DemoContext
    /// 1 = up, -1 = down, 0 = none.
    @State private var choice = 0
    @State private var upTrigger = 0
    @State private var downTrigger = 0
    @State private var step = 0

    private static let script: [Int] = [1, -1, -1, 1, 1]

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            card
            Spacer()
            DemoHint(text: L("Tap thumbs up or down", "点击点赞或点踩"), ctx: ctx)
                .padding(.bottom, 18)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 1.2, delay: 0.4) { previewTick() }
    }

    private var card: some View {
        VStack(spacing: 18) {
            VStack(spacing: 4) {
                Text(L("Was this helpful?", "这篇内容有帮助吗？"), ctx.language)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text(L("Setting up Face ID", "设置面容 ID"), ctx.language)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            HStack(spacing: 14) {
                ThumbButton(
                    direction: 1,
                    selected: choice == 1,
                    count: 128 + (choice == 1 ? 1 : 0),
                    tint: Palette.indigo,
                    trigger: upTrigger,
                    flick: ctx["flick"],
                    pop: ctx.cg("pop"),
                    particles: ctx.bool("particles")
                ) { choose(1) }
                ThumbButton(
                    direction: -1,
                    selected: choice == -1,
                    count: 9 + (choice == -1 ? 1 : 0),
                    tint: Palette.coral,
                    trigger: downTrigger,
                    flick: ctx["flick"],
                    pop: ctx.cg("pop"),
                    particles: ctx.bool("particles")
                ) { choose(-1) }
            }
        }
        .padding(20)
        .frame(width: 300)
        .demoCard(cornerRadius: 26)
    }

    private func choose(_ direction: Int) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.65)) {
            choice = choice == direction ? 0 : direction
        }
        guard choice == direction else { return }
        if !ctx.isPreview { Haptics.tap(.medium) }
        if direction == 1 { upTrigger += 1 } else { downTrigger += 1 }
    }

    private func previewTick() {
        let direction = Self.script[step % Self.script.count]
        step += 1
        choose(direction)
    }
}

private struct ThumbButton: View {
    let direction: Int
    let selected: Bool
    let count: Int
    let tint: Color
    let trigger: Int
    let flick: Double
    let pop: CGFloat
    let particles: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                glyph
                Text("\(count)")
                    .font(.system(.headline, design: .rounded).monospacedDigit())
                    .foregroundStyle(selected ? tint : Color.secondary)
                    .contentTransition(.numericText(value: Double(count)))
            }
            .padding(.horizontal, 20)
            .frame(height: 64)
            .background(selected ? tint.opacity(0.14) : Color.primary.opacity(0.05), in: Capsule())
            .overlay(Capsule().strokeBorder(selected ? tint.opacity(0.5) : Palette.stroke, lineWidth: selected ? 1.5 : 1))
            .scaleEffect(selected ? 1 : 0.96)
        }
        .buttonStyle(.plain)
    }

    private var glyph: some View {
        // Thumbs up flicks counter-clockwise (up); thumbs down flicks clockwise (down).
        let sign: Double = direction > 0 ? -1 : 1
        let symbol = direction > 0 ? "hand.thumbsup" : "hand.thumbsdown"
        return ZStack {
            if particles {
                ForEach(0..<8, id: \.self) { index in
                    particle(index)
                }
            }
            Image(systemName: symbol)
                .symbolVariant(selected ? .fill : .none)
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(selected ? tint : Color.secondary)
                .keyframeAnimator(initialValue: ThumbsFlick(), trigger: trigger) { content, value in
                    content
                        .rotationEffect(.degrees(value.angle), anchor: .bottom)
                        .scaleEffect(value.scale)
                } keyframes: { _ in
                    KeyframeTrack(\.angle) {
                        CubicKeyframe(-sign * 10, duration: 0.09)
                        CubicKeyframe(sign * flick, duration: 0.1)
                        SpringKeyframe(0, duration: 0.4, spring: .bouncy)
                    }
                    KeyframeTrack(\.scale) {
                        CubicKeyframe(0.9, duration: 0.09)
                        CubicKeyframe(pop, duration: 0.12)
                        SpringKeyframe(1, duration: 0.38, spring: .bouncy)
                    }
                }
        }
        .frame(width: 30, height: 30)
    }

    private func particle(_ index: Int) -> some View {
        let angle: Double = Double(index) / 8 * 2 * .pi
        let dx: CGFloat = CGFloat(cos(angle)) * 26
        let dy: CGFloat = CGFloat(sin(angle)) * 26
        return Circle()
            .fill(tint)
            .frame(width: 5, height: 5)
            .keyframeAnimator(initialValue: ThumbsFlick(), trigger: trigger) { content, value in
                content
                    .offset(x: dx * value.burst, y: dy * value.burst)
                    .opacity(value.burst > 0 && value.burst < 1 ? Double(1 - value.burst) : 0)
            } keyframes: { _ in
                KeyframeTrack(\.burst) {
                    LinearKeyframe(0, duration: 0.12)
                    CubicKeyframe(0.02, duration: 0.01)
                    CubicKeyframe(1, duration: 0.45)
                }
            }
    }
}
