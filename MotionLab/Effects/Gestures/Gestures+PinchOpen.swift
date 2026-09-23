import SwiftUI

extension Effect {
    static let gesturesPinchOpen = Effect(
        id: "gestures.pinch-open",
        category: .gestures,
        interaction: .gesture,
        name: L("Pinch to Open", "捏合展开"),
        summary: L("Spread two fingers on a card to grow it live; past the threshold it blooms into a full page.", "双指张开，卡片随之实时放大；越过阈值便绽开为完整页面。"),
        prompt: L(
            "A 170 × 128 pt album card (aurora gradient cover, title) rests at the centre. Spreading two fingers scales it live with the pinch, lifting its shadow and tilting 2° toward the anchor, with rubber-band resistance above 1.6×. Crossing 1.3× arms it: a light haptic fires and a thin ring glows around the card. Releasing while armed hands the live scale over to a layout change: the card blooms into a 300 × 320 pt page on a spring (response 0.5 s, damping 0.78), the cover grows to a 150 pt header and body lines fade up 8 pt with a 60 ms stagger. Pinching the page below 0.8× (or double-tapping) folds it back into the card on the same spring. Releasing unarmed springs back. Direct, continuous, intentional.",
            "一张 170 × 128pt 的相册卡片（极光渐变封面与标题）置于中央。双指张开时，卡片随捏合实时放大，投影随之抬升，并朝锚点一侧倾斜 2°，超过 1.6 倍后带橡皮筋阻力。越过 1.3 倍即进入“就绪”：触发一次轻触感，卡片外缘亮起一圈细光环。就绪时松手，实时缩放会无缝交接为布局变化：卡片以弹簧（响应 0.5 秒、阻尼 0.78）绽开为 300 × 320pt 的页面，封面扩展为 150pt 的头图，正文行以 60ms 的错峰上移 8pt 淡入。在页面上捏合到 0.8 倍以下（或双击）即以同一弹簧折回卡片；未就绪松手则弹回原状。直接、连贯、意图明确。"
        ),
        implementation: L(
            "MagnifyGesture sets a live scale (rubber-banded) and an armed flag; onEnded toggles the expanded state and resets the scale in one spring so the layout frame and the gesture scale blend into a single motion. sensoryFeedback marks the threshold.",
            "MagnifyGesture 设置带橡皮筋的实时缩放与“就绪”标记；onEnded 在同一个弹簧中切换展开状态并重置缩放，让布局尺寸变化与手势缩放融合成一段连续运动。越过阈值时由 sensoryFeedback 提示。"
        ),
        apis: ["MagnifyGesture", "scaleEffect", "frame(width:height:)", "sensoryFeedback", "onTapGesture(count:)"],
        tags: ["pinch", "open", "expand", "zoom", "捏合", "展开", "放大", "卡片"],
        params: [
            .slider("threshold", L("Open threshold", "展开阈值"), 1.1...1.6, default: 1.3, decimals: 2, unit: "×"),
            .slider("response", L("Spring response", "弹簧响应"), 0.3...0.9, default: 0.5, unit: "s"),
            .slider("damping", L("Damping", "阻尼"), 0.5...1.0, default: 0.78),
        ]
    ) { ctx in
        PinchOpenDemo(ctx: ctx)
    }
}

private struct PinchOpenDemo: View {
    let ctx: DemoContext
    @State private var expanded = false
    @State private var live: CGFloat = 1
    @State private var tilt: Double = 0

    var body: some View {
        let armed = expanded ? live < 0.8 : live > ctx.cg("threshold")
        ZStack {
            card(armed: armed)
                .scaleEffect(live)
                .rotationEffect(.degrees(tilt))
                .gesture(magnify)
                .onTapGesture(count: 2) { toggle(haptic: true) }
                .sensoryFeedback(.impact(weight: .light), trigger: armed) { _, newValue in
                    newValue && !ctx.isPreview
                }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(alignment: .bottom) {
            if !expanded {
                DemoHint(text: L("Spread two fingers on the card, or double-tap", "在卡片上双指张开，或双击"), ctx: ctx)
                    .padding(.bottom, 12)
            }
        }
        .autoplay(ctx.isPreview, every: 2.4, delay: 0.6) { simulate() }
    }

    private func card(armed: Bool) -> some View {
        let lift: CGFloat = expanded ? 20 : 10 + 16 * min(max((live - 1) / 0.5, 0), 1)
        return VStack(alignment: .leading, spacing: 10) {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Palette.aurora)
                .overlay {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: expanded ? 40 : 26, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.9))
                }
                .frame(height: expanded ? 150 : 72)
            Text(ctx.language == .zh ? "夏日旅行" : "Summer Trip")
                .font(expanded ? Font.title3.weight(.bold) : Font.subheadline.weight(.semibold))
            if expanded {
                ForEach(0..<3, id: \.self) { index in
                    PlaceholderLines(count: 1)
                        .frame(width: CGFloat(250 - index * 50), alignment: .leading)
                        .transition(Self.lineIn(index))
                }
            }
            Spacer(minLength: 0)
        }
        .padding(expanded ? 16 : 10)
        .frame(width: expanded ? 300 : 170, height: expanded ? 320 : 128, alignment: .top)
        .background(Palette.elevated, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(armed ? AnyShapeStyle(Palette.aurora) : AnyShapeStyle(Palette.stroke), lineWidth: armed ? 2.5 : 1)
        )
        .shadow(color: .black.opacity(0.16), radius: lift, y: lift * 0.5)
    }

    private static func lineIn(_ index: Int) -> AnyTransition {
        AnyTransition.opacity
            .combined(with: .offset(y: 8))
            .animation(.spring(response: 0.45, dampingFraction: 0.85).delay(0.12 + Double(index) * 0.06))
    }

    private var magnify: some Gesture {
        MagnifyGesture()
            .onChanged { value in
                let m = value.magnification
                if expanded {
                    live = min(max(m, 0.55), 1) + rubberBand(max(m - 1, 0), limit: 0.05, coefficient: 1)
                } else {
                    live = m > 1.6 ? 1.6 + rubberBand(m - 1.6, limit: 0.3, coefficient: 1) : max(m, 0.55)
                }
                tilt = expanded ? 0 : Double(value.startAnchor.x - 0.5) * 4 * Double(min(max(m - 1, 0), 1))
            }
            .onEnded { _ in
                let armed = expanded ? live < 0.8 : live > ctx.cg("threshold")
                if armed {
                    toggle(haptic: true)
                } else {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.72)) {
                        live = 1
                        tilt = 0
                    }
                }
            }
    }

    private func toggle(haptic: Bool) {
        withAnimation(.spring(response: ctx["response"], dampingFraction: ctx["damping"])) {
            expanded.toggle()
            live = 1
            tilt = 0
        }
        if haptic && !ctx.isPreview { Haptics.tap(.medium) }
    }

    private func simulate() {
        let target: CGFloat = expanded ? 0.74 : ctx.cg("threshold") + 0.12
        withAnimation(.easeInOut(duration: 0.45)) {
            live = target
            tilt = expanded ? 0 : 2
        }
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.5))
            toggle(haptic: false)
        }
    }
}
