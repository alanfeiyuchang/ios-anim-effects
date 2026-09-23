import SwiftUI

extension Effect {
    static let buttonsHoldTrace = Effect(
        id: "buttons.hold-trace",
        category: .buttons,
        interaction: .gesture,
        name: L("Perimeter Trace", "描边长按"),
        summary: L("Two bright strokes race around the button's outline and meet at the bottom.", "两道亮线沿按钮轮廓两侧赛跑，最终在底部汇合。"),
        prompt: L(
            "A 250 × 60 pt quiet outline capsule reading \"Hold to send\" with a paper-plane glyph, under a message preview. While the finger holds, two 3 pt indigo-to-violet strokes start together at the top centre and race around the perimeter in opposite directions at constant speed, meeting at the bottom centre after 1.3 s; a soft glow follows the lines and the label tints to indigo as the button eases to 98%. Releasing early rewinds both strokes on a soft spring (response 0.35 s). When they meet, the capsule flashes full with the gradient in 150 ms, the label blur-replaces with \"Sent\", the message preview flies up and fades, and a success haptic fires; it resets after 1.4 s. Precise, calm and elegant.",
            "一枚 250 × 60pt 的安静描边胶囊“长按发送”，带纸飞机图标，上方是一条消息预览。手指按住时，两道 3pt 的靛蓝到紫罗兰描边从顶部中点同时出发，沿轮廓向相反方向匀速赛跑，1.3 秒后在底部中点汇合；线条带着柔和辉光，文字渐变为靛蓝，按钮缓缓缩到 98%。中途松手，两道描边以柔和的弹簧（响应 0.35 秒）倒退收回。两线汇合时，胶囊在 150 毫秒内被渐变整体填满，文字模糊替换为“已发送”，消息预览向上飞出并淡出，同时触发成功触感；1.4 秒后复位。精准、沉静、优雅。"
        ),
        implementation: L(
            "A custom capsule Shape whose path starts at the top centre and runs clockwise is trimmed from 0 to half the progress; a horizontally mirrored copy (scaleEffect(x: -1)) runs the other way. onLongPressGesture drives a linear progress animation or springs it back.",
            "自定义胶囊 Shape 的路径从顶部中点出发顺时针绘制，trim 从 0 到进度的一半；水平镜像的副本（scaleEffect(x: -1)）沿另一方向绘制。onLongPressGesture 驱动线性进度动画或将其弹回。"
        ),
        apis: ["Shape", "Path.addRelativeArc", "trim(from:to:)", "onLongPressGesture(minimumDuration:perform:onPressingChanged:)", "transition(.blurReplace)"],
        tags: ["hold", "trace", "outline", "send", "长按", "描边", "轮廓", "发送"],
        params: [
            .slider("duration", L("Hold duration", "按住时长"), 0.5...2.5, default: 1.3, unit: "s"),
            .slider("line", L("Stroke width", "描边粗细"), 1.5...6, default: 3, decimals: 1, unit: "pt"),
            .toggle("glow", L("Glow", "辉光"), default: true),
        ]
    ) { ctx in
        ButtonHoldTraceDemo(ctx: ctx)
    }
}

/// A capsule outline that starts at the top centre and runs clockwise back to it.
private struct ButtonTopCenterCapsule: Shape {
    func path(in rect: CGRect) -> Path {
        let r = rect.height / 2
        let midX = rect.midX
        var path = Path()
        path.move(to: CGPoint(x: midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - r, y: rect.minY))
        path.addRelativeArc(center: CGPoint(x: rect.maxX - r, y: rect.minY + r), radius: r, startAngle: .degrees(-90), delta: .degrees(180))
        path.addLine(to: CGPoint(x: rect.minX + r, y: rect.maxY))
        path.addRelativeArc(center: CGPoint(x: rect.minX + r, y: rect.minY + r), radius: r, startAngle: .degrees(90), delta: .degrees(180))
        path.addLine(to: CGPoint(x: midX, y: rect.minY))
        return path
    }
}

private struct ButtonHoldTraceDemo: View {
    let ctx: DemoContext
    @State private var progress: CGFloat = 0
    @State private var pressing = false
    @State private var sent = false

    private let size = CGSize(width: 250, height: 60)

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            VStack(spacing: 26) {
                message
                button
            }
            Spacer()
            DemoHint(text: L("Press and hold to send", "按住发送"), ctx: ctx)
                .padding(.bottom, 18)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: ctx["duration"] + 2.4, delay: 0.4) { simulate() }
    }

    private var message: some View {
        Text(L("Running 5 min late — save me a seat!", "要晚到 5 分钟——帮我占个座！"), ctx.language)
            .font(.subheadline)
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Palette.primary, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .frame(width: size.width, alignment: .trailing)
            .offset(y: sent ? -40 : 0)
            .opacity(sent ? 0 : 1)
            .scaleEffect(sent ? 0.9 : 1, anchor: .trailing)
    }

    private var button: some View {
        let line = ctx.cg("line")
        let gradient = LinearGradient(colors: [Palette.indigo, Palette.violet], startPoint: .leading, endPoint: .trailing)
        return ZStack {
            Capsule().fill(Palette.elevated)
            Capsule().strokeBorder(Color.primary.opacity(0.12), lineWidth: 1)
            Capsule()
                .fill(gradient)
                .opacity(sent ? 1 : 0)
            trace(gradient: gradient, line: line)
            trace(gradient: gradient, line: line)
                .scaleEffect(x: -1, y: 1)
            label
        }
        .frame(width: size.width, height: size.height)
        .scaleEffect(pressing ? 0.98 : 1)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: pressing)
        .contentShape(Capsule())
        .onLongPressGesture(minimumDuration: ctx["duration"], maximumDistance: 40) {
            complete()
        } onPressingChanged: { isPressing in
            if isPressing { begin() } else { end() }
        }
        .accessibilityAddTraits(.isButton)
    }

    private func trace(gradient: LinearGradient, line: CGFloat) -> some View {
        ButtonTopCenterCapsule()
            .trim(from: 0, to: progress / 2)
            .stroke(gradient, style: StrokeStyle(lineWidth: line, lineCap: .round, lineJoin: .round))
            .padding(line / 2)
            .shadow(color: Palette.violet.opacity(ctx.bool("glow") ? 0.6 : 0), radius: 6)
            .allowsHitTesting(false)
    }

    private var label: some View {
        ZStack {
            if sent {
                Label(ctx.language == .zh ? "已发送" : "Sent", systemImage: "checkmark")
                    .foregroundStyle(.white)
                    .transition(.blurReplace)
            } else {
                Label(ctx.language == .zh ? "长按发送" : "Hold to send", systemImage: "paperplane.fill")
                    .foregroundStyle(pressing ? Palette.indigo : Color.primary)
                    .transition(.blurReplace)
            }
        }
        .font(.headline)
    }

    private func begin() {
        guard !sent else { return }
        pressing = true
        Haptics.tap(.soft)
        withAnimation(.linear(duration: ctx["duration"])) { progress = 1 }
    }

    private func end() {
        pressing = false
        guard !sent else { return }
        withAnimation(.spring(response: 0.35, dampingFraction: 1)) { progress = 0 }
    }

    private func complete() {
        guard !sent else { return }
        pressing = false
        withAnimation(.easeOut(duration: 0.15)) {
            progress = 1
            sent = true
        }
        Haptics.success()
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(1.4))
            withAnimation(.spring(response: 0.5, dampingFraction: 0.9)) {
                sent = false
                progress = 0
            }
        }
    }

    private func simulate() {
        guard !sent else { return }
        begin()
        let hold = ctx["duration"]
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(hold))
            Haptics.isMuted = true
            complete()
            Haptics.isMuted = false
        }
    }
}
