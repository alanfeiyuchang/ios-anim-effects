import SwiftUI

extension Effect {
    static let loadingAIGenerating = Effect(
        id: "loading.ai-generating",
        category: .loading,
        interaction: .tap,
        name: L("AI Writing Card", "AI 撰写卡片"),
        summary: L(
            "A spectral border orbits the card and shimmering lines signal 'writing', then resolve into text.",
            "光谱描边绕卡片旋转、流光占位行表示“正在撰写”，随后化为正文。"
        ),
        prompt: L(
            "A 290 pt reply card with 24 pt continuous corners. While the model is thinking, a 2 pt angular-gradient border (sky → violet → pink → amber → mint) rotates around the card once every 3 s, and a blurred 5 pt copy of it glows softly outside the edge. Inside, a pulsing sparkle badge sits beside 'Writing a reply…', and four skeleton lines carry a violet-to-pink sheen that sweeps left to right every 1.6 s. When the text is ready, the border, glow and skeleton lines fade out on a 0.4 s ease-out while the content settles on a spring (response 0.55 s, damping 0.85): the paragraph rises 6 pt out of an 8 pt blur, the title cross-fades to 'Draft ready', a green check pops in and a success haptic fires. Magical but restrained.",
            "一张 290 pt 宽、24 pt 连续圆角的回复卡片。模型思考时，一条 2 pt 的角向渐变描边（天蓝 → 紫罗兰 → 粉 → 琥珀 → 薄荷绿）每 3 秒绕卡片旋转一圈，其 5 pt 的模糊副本在边缘外晕出柔光。卡片内，脉动的星光徽标旁写着“正在撰写回复…”，四条骨架行上有一道紫到粉的流光每 1.6 秒自左向右扫过。文字就绪时，描边、辉光与骨架行以 0.4 秒缓出淡去，内容则以弹簧（响应 0.55 秒、阻尼 0.85）落定：正文从 8 pt 模糊中上浮 6 pt 显现，标题交叉淡变为“草稿已生成”，绿色对勾弹出，并伴随成功触感。神奇，却克制。"
        ),
        implementation: L(
            "A TimelineView rotates an AngularGradient used as strokeBorder (plus a blurred copy in the background for the glow); skeleton lines are masked by a moving LinearGradient; a task(id:) toggles between thinking and done.",
            "TimelineView 旋转作为 strokeBorder 的 AngularGradient（背景中再放一层模糊副本作辉光）；骨架行被移动的线性渐变遮罩出流光；task(id:) 在“思考中”与“完成”之间切换。"
        ),
        apis: ["AngularGradient", "strokeBorder", "TimelineView", "symbolEffect(.pulse)", "contentTransition(.interpolate)"],
        tags: ["ai", "generating", "thinking", "gradient border", "AI", "生成中", "思考", "渐变描边"],
        params: [
            .slider("period", L("Border rotation", "描边周期"), 1.5...6, default: 3, decimals: 1, unit: "s"),
            .slider("glow", L("Glow", "辉光"), 0...20, default: 10, decimals: 0, unit: "pt"),
            .slider("hold", L("Thinking time", "思考时长"), 1...5, default: 2.4, decimals: 1, unit: "s"),
        ]
    ) { ctx in
        AIGeneratingDemo(ctx: ctx)
    }
}

private struct AIGeneratingDemo: View {
    let ctx: DemoContext
    @State private var done = false
    @State private var run = 0

    var body: some View {
        VStack(spacing: 18) {
            AIWritingCard(done: done, period: ctx["period"], glow: ctx.cg("glow"), language: ctx.language, preview: ctx.isPreview)
            DemoHint(text: L("Tap to regenerate", "点击重新生成"), ctx: ctx)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .onTapGesture { run += 1 }
        .task(id: run) { await cycle() }
    }

    private func cycle() async {
        withAnimation(.smooth(duration: 0.4)) { done = false }
        try? await Task.sleep(for: .seconds(ctx["hold"]))
        guard !Task.isCancelled else { return }
        withAnimation(.spring(response: 0.55, dampingFraction: 0.85)) { done = true }
        if !ctx.isPreview { Haptics.success() }
        guard ctx.isPreview else { return }
        try? await Task.sleep(for: .seconds(2.2))
        guard !Task.isCancelled else { return }
        run += 1
    }
}

private struct AIWritingCard: View {
    let done: Bool
    let period: Double
    let glow: CGFloat
    let language: AppLanguage
    let preview: Bool

    private let shape = RoundedRectangle(cornerRadius: 24, style: .continuous)

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header
            ZStack(alignment: .topLeading) {
                AIShimmerLines(preview: preview, paused: done)
                    .opacity(done ? 0 : 1)
                    .animation(.easeOut(duration: 0.4), value: done)
                Text(language == .zh
                     ? "谢谢更新！周四上午十点可以。我会带上新的动效规范，我们一起过一遍转场细节。"
                     : "Thanks for the update — Thursday at 10 works. I'll bring the new motion specs so we can walk through the transitions together.")
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(width: 250, alignment: .leading)
                    .opacity(done ? 1 : 0)
                    .blur(radius: done ? 0 : 8)
                    .offset(y: done ? 0 : 6)
            }
        }
        .padding(20)
        .frame(width: 290, alignment: .leading)
        .background(Palette.elevated, in: shape)
        .overlay { shape.strokeBorder(Palette.stroke) }
        .overlay {
            AISpectralBorder(period: period, lineWidth: 2, preview: preview, paused: done)
                .opacity(done ? 0 : 1)
                // The border and glow fade on their own 0.4 s ease-out, independent of the card's spring.
                .animation(.easeOut(duration: 0.4), value: done)
        }
        .background {
            AISpectralBorder(period: period, lineWidth: 5, preview: preview, paused: done)
                .blur(radius: glow)
                .drawingGroup()
                .opacity(done ? 0 : 0.85)
                .animation(.easeOut(duration: 0.4), value: done)
        }
        .shadow(color: .black.opacity(0.08), radius: 16, y: 8)
    }

    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: "sparkles")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.white)
                .symbolEffect(.pulse, isActive: !done)
                .frame(width: 32, height: 32)
                .background(
                    LinearGradient(colors: [Palette.violet, Palette.pink], startPoint: .topLeading, endPoint: .bottomTrailing),
                    in: Circle()
                )
            Text(done ? L("Draft ready", "草稿已生成") : L("Writing a reply…", "正在撰写回复…"), language)
                .font(.subheadline.weight(.semibold))
                .contentTransition(.interpolate)
            Spacer(minLength: 0)
            if done {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(Palette.green)
                    .transition(.scale(scale: 0.4).combined(with: .opacity))
            }
        }
    }
}

private struct AISpectralBorder: View {
    let period: Double
    let lineWidth: CGFloat
    let preview: Bool
    let paused: Bool
    @State private var anchor = Date()
    @State private var anchorTurn: Double = 0

    private let colors: [Color] = [Palette.sky, Palette.violet, Palette.pink, Palette.amber, Palette.mint, Palette.sky]

    var body: some View {
        TimelineView(.animation(minimumInterval: MotionFrameRate.interval(preview: preview), paused: paused)) { timeline in
            let turn = (anchorTurn + timeline.date.timeIntervalSince(anchor) / max(period, 0.1)).truncatingRemainder(dividingBy: 1)
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(
                    AngularGradient(colors: colors, center: .center, angle: .degrees(turn * 360)),
                    lineWidth: lineWidth
                )
        }
        .allowsHitTesting(false)
        .onChange(of: period) { old, _ in
            // Rebase so a new period changes the speed without jumping the gradient.
            let now = Date()
            anchorTurn += now.timeIntervalSince(anchor) / max(old, 0.1)
            anchor = now
        }
    }
}

private struct AIShimmerLines: View {
    let preview: Bool
    let paused: Bool

    private let widths: [CGFloat] = [250, 232, 244, 150]

    var body: some View {
        lines(Color.primary.opacity(0.07))
            .overlay {
                TimelineView(.animation(minimumInterval: MotionFrameRate.interval(preview: preview), paused: paused)) { timeline in
                    let x = (timeline.date.timeIntervalSinceReferenceDate / 1.6).truncatingRemainder(dividingBy: 1) * 2.4 - 0.7
                    LinearGradient(
                        stops: [
                            .init(color: Palette.violet.opacity(0), location: 0),
                            .init(color: Palette.violet.opacity(0.55), location: 0.42),
                            .init(color: Palette.pink.opacity(0.5), location: 0.58),
                            .init(color: Palette.pink.opacity(0), location: 1),
                        ],
                        startPoint: UnitPoint(x: x - 0.4, y: 0.5),
                        endPoint: UnitPoint(x: x + 0.4, y: 0.5)
                    )
                }
                .mask { lines(.black) }
            }
    }

    private func lines(_ color: Color) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(0..<widths.count, id: \.self) { index in
                Capsule()
                    .fill(color)
                    .frame(width: widths[index], height: 10)
            }
        }
    }
}
