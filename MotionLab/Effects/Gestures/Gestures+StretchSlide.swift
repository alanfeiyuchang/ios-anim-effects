import SwiftUI

extension Effect {
    static let gesturesStretchSlide = Effect(
        id: "gestures.stretch-slide",
        category: .gestures,
        interaction: .gesture,
        name: L("Stretchy Slide to Send", "拉伸滑动发送"),
        summary: L("A liquid knob whose front follows the finger while its tail lags behind, then a paper plane takes off.", "液态滑块：前端跟手、尾部滞后拉长，成功后纸飞机起飞。"),
        prompt: L(
            "A 290 × 64 pt capsule track holds a 56 pt indigo-to-violet knob carrying a paper-plane glyph, beside the label “Slide to send”. Dragging moves the knob's leading edge 1:1 while its trailing edge chases it on an interactive spring (response 0.3 s, damping 0.7), so the knob stretches into a liquid pill that grows with speed and snaps round again when you pause. The label fades twice as fast as the knob travels. Releasing beyond 85% of the travel commits: the pill floods the whole track and turns green on a spring (response 0.4 s, damping 0.75), the plane flies off 60 pt up and to the right while fading, and a checkmark pops in with a success haptic; it resets after 1.8 s. Releasing short snaps the tail home first while the head follows more slowly, a gooey recoil. Fluid, playful, alive.",
            "一条 290 × 64pt 的胶囊滑轨，左侧是 56pt 的靛蓝到紫色滑块，上面是纸飞机图标，旁边写着“滑动发送”。拖动时滑块前缘 1:1 跟手，尾缘则以交互式弹簧（响应 0.3 秒、阻尼 0.7）追赶，于是滑块被拉成一条液态长条：速度越快拉得越长，停顿时又缩回圆形。文字以滑块行程两倍的速度淡出。行程超过 85% 时松手即提交：长条以弹簧（响应 0.4 秒、阻尼 0.75）铺满整条滑轨并变为绿色，纸飞机向右上方飞出 60pt 并淡出，对勾随之弹出，同时触发成功触感；1.8 秒后复位。未达阈值松手时，尾部先弹回起点，前端随后慢慢收回，呈现黏稠的回弹。流畅、俏皮、有生命力。"
        ),
        implementation: L(
            "Two offsets describe the knob: head is set directly from the drag, tail is re-targeted to head inside withAnimation(.interactiveSpring) on every change. The pill is a long capsule offset by tail and masked by a long capsule ending at head, so each edge animates with its own transaction.",
            "滑块由两个偏移量描述：head 直接取自拖动，tail 在每次变化时于 withAnimation(.interactiveSpring) 中重新追向 head。长条是一条按 tail 偏移的长胶囊，再用一条止于 head 的长胶囊做遮罩，于是两端各自沿用自己的动画事务。"
        ),
        apis: ["DragGesture", "interactiveSpring(response:dampingFraction:)", "Capsule", "contentTransition(.symbolEffect)", "rubberBand"],
        tags: ["slide to send", "liquid", "stretch", "gooey", "confirm", "滑动发送", "液态", "拉伸", "确认"],
        params: [
            .slider("lag", L("Tail lag", "尾部滞后"), 0.1...0.6, default: 0.3, unit: "s"),
            .slider("threshold", L("Commit threshold", "确认阈值"), 0.6...0.95, default: 0.85),
        ]
    ) { ctx in
        StretchSlideDemo(ctx: ctx)
    }
}

private struct StretchSlideDemo: View {
    let ctx: DemoContext
    @State private var head: CGFloat = 0
    @State private var tail: CGFloat = 0
    @State private var sent = false
    @State private var planeGone = false

    private let trackWidth: CGFloat = 290
    private let knob: CGFloat = 56
    private let inset: CGFloat = 4
    private var maxX: CGFloat { trackWidth - knob - inset * 2 }

    var body: some View {
        let progress = min(max(head / maxX, 0), 1)
        VStack(spacing: 18) {
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.primary.opacity(0.07))
                Text(ctx.language == .zh ? "滑动发送" : "Slide to send")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                    .padding(.leading, knob)
                    .frame(maxWidth: .infinity)
                    .opacity(sent ? 0 : Double(max(1 - progress * 2, 0)))
                pill
                glyph
                    .offset(x: inset + head)
                    .gesture(dragGesture)
                if sent {
                    Text(ctx.language == .zh ? "已发送" : "Sent")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .allowsHitTesting(false)
                        .transition(.opacity.combined(with: .scale(scale: 0.9)))
                }
            }
            .frame(width: trackWidth, height: knob + inset * 2)
            .overlay(Capsule().strokeBorder(Palette.stroke, lineWidth: 1))
            DemoHint(text: L("Drag the knob to the end", "把滑块拖到最右端"), ctx: ctx)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 3.4, delay: 0.8) { simulate() }
    }

    /// The pill is the intersection of a long capsule starting at `tail` (animated) and a long capsule
    /// mask ending at `head + knob` (not animated), so each edge follows exactly one piece of state.
    private var pill: some View {
        let long: CGFloat = 640
        return Capsule()
            .fill(sent ? AnyShapeStyle(Palette.green.gradient) : AnyShapeStyle(Palette.primary))
            .frame(width: long, height: knob)
            .offset(x: inset + tail)
            .frame(width: trackWidth, height: knob + inset * 2, alignment: .leading)
            .mask(alignment: .leading) {
                Capsule()
                    .frame(width: long, height: knob)
                    .offset(x: inset + head + knob - long)
            }
            .shadow(color: Palette.violet.opacity(0.35), radius: 10, y: 5)
            .allowsHitTesting(false)
    }

    private var glyph: some View {
        ZStack {
            Image(systemName: "paperplane.fill")
                .offset(x: planeGone ? 60 : 0, y: planeGone ? -60 : 0)
                .opacity(planeGone ? 0 : 1)
            if sent {
                Image(systemName: "checkmark")
                    .transition(.scale(scale: 0.3).combined(with: .opacity))
            }
        }
        .font(.system(size: 20, weight: .bold))
        .foregroundStyle(.white)
        .frame(width: knob, height: knob)
        .contentShape(Circle())
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                guard !sent else { return }
                let raw = value.translation.width
                if raw < 0 {
                    head = rubberBand(raw, limit: 16)
                } else if raw > maxX {
                    head = maxX + rubberBand(raw - maxX, limit: 16)
                } else {
                    head = raw
                }
                if head < tail {
                    // Moving back: the tail is now the leading edge, so it tracks the finger directly.
                    tail = head
                } else {
                    withAnimation(.interactiveSpring(response: ctx["lag"], dampingFraction: 0.7)) { tail = head }
                }
            }
            .onEnded { _ in
                guard !sent else { return }
                if head > maxX * ctx.cg("threshold") {
                    commit(haptic: true)
                } else {
                    // The tail snaps home first and the head follows, a gooey recoil.
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) { tail = 0 }
                    withAnimation(.spring(response: 0.45 + ctx["lag"], dampingFraction: 0.72)) { head = 0 }
                }
            }
    }

    private func commit(haptic: Bool) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
            head = maxX
            tail = 0
            sent = true
        }
        withAnimation(.easeIn(duration: 0.35).delay(0.1)) { planeGone = true }
        if haptic && !ctx.isPreview { Haptics.success() }
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(1.8))
            withAnimation(.spring(response: 0.5, dampingFraction: 0.86)) {
                sent = false
                head = 0
                tail = 0
            }
            planeGone = false
        }
    }

    private func simulate() {
        guard !sent else { return }
        withAnimation(.easeInOut(duration: 0.8)) { head = maxX * 0.95 }
        withAnimation(.spring(response: 0.8 + ctx["lag"], dampingFraction: 0.8)) { tail = maxX * 0.95 }
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.85))
            commit(haptic: false)
        }
    }
}
