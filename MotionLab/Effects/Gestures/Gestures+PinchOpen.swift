import SwiftUI

extension Effect {
    static let gesturesPinchOpen = Effect(
        id: "gestures.pinch-open",
        category: .gestures,
        interaction: .gesture,
        name: L("Pinch to Open", "捏合展开"),
        summary: L("Spread two fingers on a card to grow it live; past the threshold it blooms into a full page.", "双指张开，卡片随之实时放大；越过阈值便绽开为完整页面。"),
        prompt: L(
            "A 170×128 pt album card with an aurora-gradient cover and a title rests at the centre. Spreading two fingers scales it live with the pinch, lifting its shadow and tilting it 2° toward the anchor, with rubber-band resistance above 1.6×; crossing 1.3× arms it with a light haptic and a thin glowing ring. Releasing while armed hands the live scale straight over to a layout change: the card blooms into a 300×320 pt page on a spring (response 0.5 s, damping 0.78) as the cover grows into a 150 pt header and body lines fade up 8 pt, 60 ms apart. Pinching the page below 0.8× or double-tapping folds it back on the same spring, and an unarmed release simply springs back. Direct, continuous and intentional.",
            "一张170×128 pt的相册卡片（极光渐变封面加标题）居中。双指张开时卡片实时放大，投影抬升，并朝锚点一侧倾斜2°，超过1.6倍后带橡皮筋阻力；越过1.3倍即“就绪”，一下轻触感，外缘亮起细光环。就绪时松手，实时缩放无缝交接为布局变化：卡片以弹簧（响应0.5秒、阻尼0.78）绽开成300×320 pt的页面，封面长成150 pt的头图，正文行错开60毫秒上移8 pt淡入。在页面上捏到0.8倍以下或双击即以同一弹簧折回；未就绪松手则弹回。直接而连贯。"
        ),
        implementation: L(
            "MagnifyGesture sets a live scale (rubber-banded) and an armed flag; onEnded toggles the expanded state and resets the scale in one spring so the layout frame and the gesture scale blend into a single motion. UIImpactFeedbackGenerator marks the threshold.",
            "MagnifyGesture 设置带橡皮筋的实时缩放与“就绪”标记；onEnded 在同一个弹簧中切换展开状态并重置缩放，让布局尺寸变化与手势缩放融合成一段连续运动。越过阈值时由 UIImpactFeedbackGenerator 提示。"
        ),
        apis: ["MagnifyGesture", "scaleEffect", "frame(width:height:)", "UIImpactFeedbackGenerator", "onTapGesture(count:)"],
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
    /// True while autoplay (or the detail intro) drives the pinch, so the scripted arm tick stays silent.
    @State private var scripted = false
    /// True while a real pinch is in progress.
    @State private var held = false
    /// The scripted pinch, cancelled on the first real one.
    @State private var script: Task<Void, Never>?
    /// Resets on system cancellation too, so a stolen pinch never leaves the card scaled and tilted.
    @GestureState private var pinching = false

    var body: some View {
        let armed = expanded ? live < 0.8 : live > ctx.cg("threshold")
        ZStack {
            card(armed: armed)
                .scaleEffect(live)
                .rotationEffect(.degrees(tilt))
                .gesture(magnify)
                .onTapGesture(count: 2) { toggle(haptic: true) }
                .onChange(of: armed) { _, newValue in
                    if newValue && !ctx.isPreview && !scripted { Haptics.tap(.light) }
                }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(alignment: .bottom) {
            // The open 300×320 page leaves only ~10 pt on a 340 pt stage, so the hint shows only while closed
            // (it already names the double-tap that closes the page again).
            if !expanded {
                DemoHint(text: L("Spread two fingers on the card, or double-tap", "在卡片上双指张开，或双击"), ctx: ctx)
                    .padding(.bottom, 12)
                    .transition(.opacity)
            }
        }
        .autoplay(ctx.isPreview, every: 2.4, delay: 0.6) { simulate() }
        .onChange(of: pinching) { _, isPinching in
            if !isPinching { endHold() }
        }
        .onDisappear { script?.cancel() }
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
            Text(L("Summer Trip", "夏日旅行"), ctx.language)
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
            .updating($pinching) { _, state, _ in state = true }
            .onChanged { value in
                if !held {
                    held = true
                    script?.cancel()
                    script = nil
                }
                scripted = false
                let m = value.magnification
                if expanded {
                    live = min(max(m, 0.55), 1) + rubberBand(max(m - 1, 0), limit: 0.05, coefficient: 1)
                } else {
                    live = m > 1.6 ? 1.6 + rubberBand(m - 1.6, limit: 0.3, coefficient: 1) : max(m, 0.55)
                }
                tilt = expanded ? 0 : Double(value.startAnchor.x - 0.5) * 4 * Double(min(max(m - 1, 0), 1))
            }
            .onEnded { _ in
                guard held else { return }
                held = false
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

    /// System cancellation (no `onEnded`): the card springs back without opening or closing.
    private func endHold() {
        guard held else { return }
        held = false
        withAnimation(.spring(response: 0.35, dampingFraction: 0.72)) {
            live = 1
            tilt = 0
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
        guard !held else { return }
        scripted = true
        let target: CGFloat = expanded ? 0.74 : ctx.cg("threshold") + 0.12
        withAnimation(.easeInOut(duration: 0.45)) {
            live = target
            tilt = expanded ? 0 : 2
        }
        script?.cancel()
        script = Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.5))
            guard !Task.isCancelled else { return }
            toggle(haptic: false)
        }
    }
}
