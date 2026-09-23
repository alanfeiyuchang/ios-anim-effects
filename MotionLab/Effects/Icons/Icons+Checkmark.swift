import SwiftUI

extension Effect {
    static let iconsCheckmark = Effect(
        id: "icons.checkmark-draw",
        category: .icons,
        interaction: .tap,
        name: L("Checkmark Draw", "对勾描绘"),
        summary: L("A ring traces itself, the tick strokes in, then the badge pops.", "圆环先自行描出，对勾随后画入，徽章轻弹定格。"),
        prompt: L(
            "A success badge assembles in three overlapping beats. First a rounded-cap ring strokes itself clockwise from 12 o'clock over ~0.6 s with an ease-in-out curve while a pale tinted disc fades up behind it. At ~70% of the ring, the checkmark draws from its short left arm through the corner to the long right arm with a fast ease-out (≈0.35 s). As the tick lands the badge springs from 90% to full size with a lively under-damped overshoot (damping 0.5), and a thin halo ring — invisible until this moment — flashes in at 50% opacity and expands to 150% while fading out; a success haptic fires on the pop. Clean, affirmative and satisfying.",
            "成功徽章分三个相互重叠的节拍组装。首先，一条圆头描边的圆环从 12 点方向顺时针自行描出，约 0.6 秒、缓入缓出，同时背后一枚浅色圆底渐显。圆环画到约 70% 时，对勾从左侧短边经过拐点画向右侧长边，使用快速缓出（约 0.35 秒）。对勾落定的瞬间，徽章以欠阻尼弹簧（阻尼 0.5）从 90% 弹回原尺寸并带轻快过冲，一道此前完全不可见的细光环以 50% 不透明度闪现，随即扩散到 150% 并淡出；弹出时触发成功触感。干净、肯定、令人满足。"
        ),
        implementation: L(
            "Circle and a custom check Path both use .trim(from:to:) driven by state; the sequence is chained with Animation.delay after an instant, non-animated reset.",
            "Circle 与自定义对勾 Path 都通过状态驱动的 .trim(from:to:) 绘制；先无动画瞬间重置，再用 Animation.delay 串联各段动画。"
        ),
        apis: ["trim(from:to:)", "StrokeStyle", "Animation.delay", "withTransaction"],
        tags: ["checkmark", "success", "done", "stroke", "对勾", "成功", "完成", "描边动画"],
        params: [
            .slider("duration", L("Ring duration", "圆环时长"), 0.3...1.5, default: 0.6, unit: "s"),
            .slider("lineWidth", L("Line width", "线宽"), 3...12, default: 7, decimals: 0, unit: "pt"),
            .choice("color", L("Color", "颜色"), [L("Green", "绿"), L("Blue", "蓝"), L("Violet", "紫")], default: 0),
        ]
    ) { ctx in
        CheckmarkDemo(ctx: ctx)
    }
}

private struct CheckmarkDemo: View {
    let ctx: DemoContext
    @State private var ring: CGFloat = 0
    @State private var tick: CGFloat = 0
    @State private var pop = false
    @State private var halo = false
    /// The halo ring is invisible until the burst, so nothing shows before the stroke draws.
    @State private var haloVisible = false

    private var color: Color {
        switch ctx.int("color") {
        case 1: return Palette.blue
        case 2: return Palette.violet
        default: return Palette.green
        }
    }

    var body: some View {
        VStack(spacing: 26) {
            badge
            Text(L("Payment complete", "支付成功"), ctx.language)
                .font(.headline)
                .opacity(tick > 0.5 ? 1 : 0.25)
                .animation(.easeOut(duration: 0.3), value: tick)
            DemoHint(text: L("Tap to replay", "点击重播"), ctx: ctx)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .onTapGesture { play() }
        // On the detail stage the shell's intro play fires this once on arrival.
        .autoplay(ctx.isPreview, every: 2.6, delay: 0.2) { play() }
    }

    private var badge: some View {
        let line = ctx.cg("lineWidth")
        return ZStack {
            Circle()
                .stroke(color.opacity(haloVisible && !halo ? 0.5 : 0), lineWidth: 2)
                .scaleEffect(halo ? 1.5 : 1)
            Circle()
                .fill(color.opacity(0.14))
                .opacity(Double(ring))
            Circle()
                .trim(from: 0, to: ring)
                .stroke(color, style: StrokeStyle(lineWidth: line, lineCap: .round))
                .rotationEffect(.degrees(-90))
            CheckShape()
                .trim(from: 0, to: tick)
                .stroke(color, style: StrokeStyle(lineWidth: line * 1.15, lineCap: .round, lineJoin: .round))
                .padding(26)
        }
        .frame(width: 120, height: 120)
        .scaleEffect(pop ? 1 : 0.9)
        .shadow(color: color.opacity(0.3), radius: pop ? 18 : 0, y: 8)
    }

    private func play() {
        let duration = ctx["duration"]
        var reset = Transaction()
        reset.disablesAnimations = true
        withTransaction(reset) {
            ring = 0
            tick = 0
            pop = false
            halo = false
            haloVisible = false
        }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(60))
            withAnimation(.easeInOut(duration: duration)) { ring = 1 }
            withAnimation(.easeOut(duration: 0.35).delay(duration * 0.7)) { tick = 1 }
            try? await Task.sleep(for: .seconds(duration * 0.7 + 0.25))
            // Burst: the halo appears at 50% at the badge's edge, then expands and fades out.
            var instant = Transaction()
            instant.disablesAnimations = true
            withTransaction(instant) { haloVisible = true }
            withAnimation(.spring(response: 0.4, dampingFraction: 0.5)) { pop = true }
            withAnimation(.easeOut(duration: 0.7)) { halo = true }
            if !ctx.isPreview { Haptics.success() }
        }
    }
}

private struct CheckShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + rect.width * 0.05, y: rect.minY + rect.height * 0.55))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.38, y: rect.minY + rect.height * 0.85))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.95, y: rect.minY + rect.height * 0.18))
        return path
    }
}
