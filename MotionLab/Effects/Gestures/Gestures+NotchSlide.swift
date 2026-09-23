import SwiftUI

extension Effect {
    static let gesturesNotchSlide = Effect(
        id: "gestures.notch-slide",
        category: .gestures,
        interaction: .gesture,
        name: L("Checkpoint Slide to Pay", "分段滑动支付"),
        summary: L("A four-segment track whose knob sticks at each notch, lighting segments and steps as it goes.", "四段式滑轨：滑块在每个刻口处略作停顿，沿途点亮分段与步骤。"),
        prompt: L(
            "A 290×64 pt capsule track is split into four segments by 3 pt gaps, with step labels above (Review · Verify · Authorize · Pay) and a 56 pt white card-glyph knob. Dragging is magnetic around each notch: within 18 pt of one the knob's offset eases quadratically, so it sticks and then catches up, and a rigid haptic clicks as each notch is passed. Every passed segment fills indigo with a squash pop (spring response 0.3 s, damping 0.5) and its label turns bold. Releasing at the end commits, turning the segments green left to right 60 ms apart, swapping the glyph for a checkmark and playing a success haptic; releasing early springs the knob home as segments switch off right to left. Staged, trustworthy and crisp.",
            "一条 290×64 pt 的胶囊滑轨被 3 pt 间隙分成四段，上方是步骤标签（核对 · 验证 · 授权 · 支付），左侧是带银行卡图标的 56 pt 白色滑块。拖动在每个刻口附近带磁性：距刻口 18 pt 以内，滑块偏移按二次曲线缓动，像被吸住，再拉才追上手指，每越过一个刻口都有一下硬朗的“咔哒”触感。越过的分段以挤压弹跳（弹簧响应 0.3 秒、阻尼 0.5）填成靛蓝，对应标签变粗。拖到终点松手即提交：各段从左到右间隔 60 毫秒依次变绿，图标换成对勾，伴随成功触感；中途松手则滑块弹回，分段从右到左依次熄灭。层次分明、值得信赖、干脆利落。"
        ),
        implementation: L(
            "The drag translation passes through a notch-attraction function (quadratic inside the sticky radius, identity outside); each segment derives lit/done flags and carries its own .animation(value:) with an index-based delay, so cascades run forward on commit and backward on return.",
            "拖动位移先经过刻口吸附函数（黏滞半径内为二次曲线，半径外为恒等）；每个分段由此得出点亮 / 完成标记，并带有按序号延迟的 .animation(value:)，于是提交时正向级联、退回时反向级联。"
        ),
        apis: ["DragGesture", "animation(_:value:)", "Animation.delay", "scaleEffect(x:y:)", "contentTransition(.symbolEffect(.replace))"],
        tags: ["slide to pay", "checkpoint", "detent", "confirm", "滑动支付", "分段", "刻口", "确认"],
        params: [
            .slider("sticky", L("Sticky radius", "黏滞半径"), 0...30, default: 18, step: 1, decimals: 0, unit: "pt"),
            .slider("cascade", L("Cascade delay", "级联间隔"), 0.02...0.12, default: 0.06, unit: "s"),
        ]
    ) { ctx in
        NotchSlideDemo(ctx: ctx)
    }
}

private let notchSteps: [LocalizedText] = [L("Review", "核对"), L("Verify", "验证"), L("Authorize", "授权"), L("Pay", "支付")]

private struct NotchSlideDemo: View {
    let ctx: DemoContext
    @State private var raw: CGFloat = 0
    @State private var done = false
    @State private var passed = 0

    private let trackWidth: CGFloat = 290
    private let knob: CGFloat = 56
    private let inset: CGFloat = 4
    private var maxX: CGFloat { trackWidth - knob - inset * 2 }

    var body: some View {
        let x = attracted(raw)
        let lit = litCount(x)
        VStack(spacing: 14) {
            labels(active: done ? 3 : min(lit, 3))
            ZStack(alignment: .leading) {
                segments(lit: lit)
                knobView
                    .offset(x: inset + x)
                    .gesture(dragGesture)
            }
            .frame(width: trackWidth, height: knob + inset * 2)
            DemoHint(text: L("Drag through every checkpoint", "拖过每一个刻口"), ctx: ctx)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 3.6, delay: 0.6) { simulate() }
    }

    private func labels(active: Int) -> some View {
        HStack(spacing: 0) {
            ForEach(0..<4, id: \.self) { index in
                Text(notchSteps[index], ctx.language)
                    .font(.caption.weight(index <= active && (raw > 2 || done) ? .bold : .medium))
                    .foregroundStyle(index <= active && (raw > 2 || done) ? AnyShapeStyle(Color.primary) : AnyShapeStyle(Color.secondary))
                    .frame(maxWidth: .infinity)
            }
        }
        .frame(width: trackWidth)
        .animation(.easeOut(duration: 0.2), value: active)
    }

    private func segments(lit: Int) -> some View {
        let cascade = ctx["cascade"]
        return HStack(spacing: 3) {
            ForEach(0..<4, id: \.self) { index in
                let isLit = index < lit || done
                Rectangle()
                    .fill(Color.primary.opacity(0.07))
                    .overlay {
                        ZStack {
                            Rectangle()
                                .fill(Palette.primary)
                            Rectangle()
                                .fill(Palette.green.gradient)
                                .opacity(done ? 1 : 0)
                                .animation(.easeOut(duration: 0.25).delay(Double(index) * cascade), value: done)
                        }
                        .opacity(isLit ? 1 : 0)
                        .scaleEffect(x: 1, y: isLit ? 1 : 0.6)
                        .animation(.spring(response: 0.3, dampingFraction: 0.5).delay(isLit ? 0 : Double(3 - index) * cascade * 0.85), value: isLit)
                    }
            }
        }
        .clipShape(Capsule())
    }

    private var knobView: some View {
        Circle()
            .fill(.white)
            .frame(width: knob, height: knob)
            .overlay {
                Image(systemName: done ? "checkmark" : "creditcard.fill")
                    .font(.system(size: 19, weight: .bold))
                    .foregroundStyle(done ? Palette.green : Palette.indigo)
                    .contentTransition(.symbolEffect(.replace))
            }
            .shadow(color: .black.opacity(0.18), radius: 8, y: 4)
    }

    private func notch(_ k: Int) -> CGFloat { maxX * CGFloat(k) / 4 }

    /// Quadratic stickiness near each interior notch; identity elsewhere (continuous at the radius).
    private func attracted(_ value: CGFloat) -> CGFloat {
        let radius = ctx.cg("sticky")
        guard radius > 0 else { return value }
        for k in 1...3 {
            let n = notch(k)
            let d = value - n
            if abs(d) < radius {
                return n + d * abs(d) / radius
            }
        }
        return value
    }

    private func litCount(_ x: CGFloat) -> Int {
        var count = 0
        for k in 1...4 where x >= notch(k) - 2 { count = k }
        return count
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                guard !done else { return }
                let t = value.translation.width
                if t < 0 {
                    raw = rubberBand(t, limit: 16)
                } else if t > maxX {
                    raw = maxX + rubberBand(t - maxX, limit: 16)
                } else {
                    raw = t
                }
                let now = litCount(attracted(raw))
                if now > passed && !ctx.isPreview { Haptics.tap(.rigid) }
                passed = now
            }
            .onEnded { _ in
                guard !done else { return }
                if raw >= maxX * 0.97 {
                    commit(haptic: true)
                } else {
                    reset()
                }
            }
    }

    private func commit(haptic: Bool) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            raw = maxX
            done = true
        }
        passed = 4
        if haptic && !ctx.isPreview { Haptics.success() }
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(1.8))
            withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) { done = false }
            reset()
        }
    }

    private func reset() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.78)) { raw = 0 }
        passed = 0
    }

    private func simulate() {
        guard !done else { return }
        Task { @MainActor in
            for k in 1...4 {
                withAnimation(.easeInOut(duration: 0.32)) { raw = notch(k) + (k < 4 ? 4 : 0) }
                try? await Task.sleep(for: .seconds(0.4))
            }
            commit(haptic: false)
        }
    }
}
