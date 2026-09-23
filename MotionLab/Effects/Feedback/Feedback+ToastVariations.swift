import SwiftUI

// MARK: - Hinge drop toast

extension Effect {
    static let feedbackHingeToast = Effect(
        id: "feedback.hinge-toast",
        category: .feedback,
        interaction: .tap,
        name: L("Hinge Swing Toast", "铰链摆动横幅"),
        summary: L("A banner hinged at its top edge swings down like a hanging sign and sways to rest.", "以顶边为铰链的横幅像挂牌一样甩下，摇摆着停稳。"),
        prompt: L(
            "A 290 × 64 pt frosted banner with a coral bell badge, 'Reminder' title and 'Stand-up in 5 minutes' caption is hinged along its top edge just below the stage's top. At rest it is folded flat, rotated -90° about the X axis. On trigger it swings down in 0.6-perspective 3D on a loose spring (response 0.7 s, damping 0.38), overshooting past vertical, swaying back and forth two or three times like a hanging sign, while its shadow grows as it faces the viewer; the bell rings with a wiggle as it lands. After a 2.4 s hold it folds back up on a quick 0.3 s ease-in. Tapping it dismisses early. Physical, whimsical, eye-catching without sliding.",
            "一枚 290 × 64 pt 的磨砂横幅——珊瑚色铃铛徽标、“提醒”标题与“5 分钟后开站会”说明——沿顶边铰接在画面顶部下方。静止时它平折起来，绕 X 轴转到 -90°。触发后它以 0.6 透视在 3D 中甩下，采用松弛的弹簧（响应 0.7 秒、阻尼 0.38），先冲过竖直位置，再像挂牌一样来回摇摆两三次；随着它正对观者，投影逐渐加深；落定时铃铛摇晃一下。停留 2.4 秒后以 0.3 秒缓入快速向上折回。点击横幅可提前关闭。有物理感、俏皮、醒目却不靠滑动。"
        ),
        implementation: L(
            "rotation3DEffect with anchor: .top animates between -90° and 0° on an under-damped spring; the bell glyph uses symbolEffect(.wiggle) keyed on the show count.",
            "rotation3DEffect 以 anchor: .top 在 -90° 与 0° 之间用欠阻尼弹簧动画；铃铛图标以显示次数为触发值运行 symbolEffect(.wiggle)。"
        ),
        apis: ["rotation3DEffect(_:axis:anchor:perspective:)", "spring(response:dampingFraction:)", "symbolEffect(.wiggle)", "regularMaterial"],
        tags: ["banner", "hinge", "swing", "reminder", "横幅", "铰链", "摆动", "提醒"],
        params: [
            .slider("damping", L("Damping", "阻尼"), 0.2...1.0, default: 0.38),
            .slider("response", L("Spring response", "弹簧响应"), 0.3...1.2, default: 0.7, unit: "s"),
            .slider("hold", L("Hold time", "停留时长"), 1...5, default: 2.4, decimals: 1, unit: "s"),
        ]
    ) { ctx in
        HingeToastDemo(ctx: ctx)
    }
}

private struct HingeToastDemo: View {
    let ctx: DemoContext
    @State private var shown = false
    @State private var token = 0
    @State private var rings = 0

    var body: some View {
        let zh = ctx.language == .zh
        ZStack(alignment: .top) {
            Color.clear
            banner(zh: zh)
                .rotation3DEffect(.degrees(shown ? 0 : -90), axis: (x: 1, y: 0, z: 0), anchor: .top, perspective: 0.6)
                .opacity(shown ? 1 : 0.001)
                .padding(.top, 26)
                .onTapGesture { hide() }
                .allowsHitTesting(shown)
            VStack(spacing: 14) {
                Button(action: show) {
                    Label(zh ? "设置提醒" : "Set Reminder", systemImage: "bell")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 22)
                        .frame(height: 50)
                        .background(Palette.sunset, in: Capsule())
                        .shadow(color: Palette.coral.opacity(0.35), radius: 12, y: 6)
                }
                .buttonStyle(.plain)
                DemoHint(text: L("Tap Set Reminder", "点击“设置提醒”"), ctx: ctx)
            }
            .frame(maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: ctx["hold"] + 1.8, delay: 0.4) { show() }
    }

    private func banner(zh: Bool) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "bell.fill")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(.white)
                .symbolEffect(.wiggle, value: rings)
                .frame(width: 34, height: 34)
                .background(Palette.coral.gradient, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                Text(zh ? "提醒" : "Reminder")
                    .font(.subheadline.weight(.semibold))
                Text(zh ? "5 分钟后开站会" : "Stand-up in 5 minutes")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
            Text(zh ? "现在" : "now")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 14)
        .frame(width: 290, height: 64)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).strokeBorder(Palette.stroke))
        .shadow(color: .black.opacity(shown ? 0.18 : 0), radius: 18, y: 10)
    }

    private func show() {
        token += 1
        let current = token
        let hold = ctx["hold"]
        if !ctx.isPreview { Haptics.tap(.medium) }
        withAnimation(.spring(response: ctx["response"], dampingFraction: ctx["damping"])) { shown = true }
        Task {
            try? await Task.sleep(for: .seconds(0.35))
            guard token == current else { return }
            rings += 1
            try? await Task.sleep(for: .seconds(hold))
            guard token == current else { return }
            withAnimation(.easeIn(duration: 0.3)) { shown = false }
        }
    }

    private func hide() {
        token += 1
        withAnimation(.easeIn(duration: 0.3)) { shown = false }
    }
}

// MARK: - Morphing status toast

extension Effect {
    static let feedbackMorphToast = Effect(
        id: "feedback.morph-toast",
        category: .feedback,
        interaction: .tap,
        name: L("Morphing Status Toast", "形变状态吐司"),
        summary: L("One toast that stays put and reshapes itself from 'Uploading' to 'Done' to a dot.", "同一枚吐司原地变形：从“上传中”到“完成”，再缩成一个圆点。"),
        prompt: L(
            "A toast that is one shape from start to finish. A 12 pt green dot rises 60 pt from the bottom of a photo grid and, on a spring (response 0.45 s, damping 0.8), swells into a dark pill with a spinning arc and 'Uploading 3 photos'. When the upload finishes, the pill springs to fit 'Uploaded to Shared Album' as the arc scales out, a green check scales in and the text blur-replaces, with a success haptic. After 1.6 s it contracts back to the green dot on a snappy 0.35 s spring, holds 0.5 s, then sinks and fades as a dot. Its size always follows its content, so every change is a reshape, never a swap.",
            "一枚从头到尾都是同一个形状的吐司。12 pt 的绿色圆点从照片网格底部升起 60 pt，随即以弹簧（响应 0.45 秒、阻尼 0.8）鼓胀成深色胶囊，露出旋转小弧线与“正在上传 3 张照片”。上传完成，胶囊弹性伸展以容纳“已上传到共享相簿”：弧线缩没、绿色对勾放大浮现，文字模糊替换，伴随成功触感。1.6 秒后以 0.35 秒的利落弹簧缩回绿点，停 0.5 秒，再以圆点的形态下沉淡出。尺寸始终跟随内容——只变形，不替换。"
        ),
        implementation: L(
            "The toast's background is a Capsule sized by its content; a stage enum swaps content with blur/opacity transitions inside a spring so the capsule reshapes to each new size.",
            "吐司背景是由内容决定尺寸的 Capsule；阶段枚举在弹簧动画中以模糊/透明度转场切换内容，胶囊随之形变到新的尺寸。"
        ),
        apis: ["Capsule", "fixedSize()", "transition(.blurReplace)", "spring(response:dampingFraction:)"],
        tags: ["toast", "morph", "status", "upload", "吐司", "形变", "状态", "上传"],
        params: [
            .slider("upload", L("Upload time", "上传时长"), 0.6...4.0, default: 1.8, decimals: 1, unit: "s"),
            .slider("response", L("Morph response", "形变响应"), 0.2...0.8, default: 0.45, unit: "s"),
        ]
    ) { ctx in
        MorphToastDemo(ctx: ctx)
    }
}

private enum MorphToastStage: Int {
    case hidden
    case uploading
    case done
    case dot
}

private struct MorphToastDemo: View {
    let ctx: DemoContext
    @State private var stage: MorphToastStage = .hidden
    @State private var token = 0

    private let tiles: [Color] = [Palette.coral, Palette.sky, Palette.mint, Palette.violet, Palette.amber, Palette.pink]

    var body: some View {
        VStack(spacing: 14) {
            ZStack(alignment: .bottom) {
                grid
                toast
                    .padding(.bottom, 24)
            }
            .frame(width: 300, height: 300)
            .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
            DemoHint(text: L("Tap a photo to upload", "点击照片开始上传"), ctx: ctx)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: ctx["upload"] + 4.4, delay: 0.4) { start() }
    }

    private var grid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 3), spacing: 4) {
            ForEach(0..<9, id: \.self) { index in
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(tiles[index % tiles.count].gradient)
                    .aspectRatio(1, contentMode: .fit)
                    .overlay(alignment: .topTrailing) {
                        if index < 3 && stage.rawValue >= MorphToastStage.uploading.rawValue {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 18))
                                .foregroundStyle(.white, Palette.indigo)
                                .padding(6)
                                .transition(.scale.combined(with: .opacity))
                        }
                    }
                    .onTapGesture { start() }
            }
        }
    }

    private var toast: some View {
        let zh = ctx.language == .zh
        let visible = stage != .hidden
        let isDot = stage == .dot || stage == .hidden
        return HStack(spacing: 10) {
            switch stage {
            case .uploading:
                MorphToastSpinner(preview: ctx.isPreview)
                    .frame(width: 18, height: 18)
                Text(zh ? "正在上传 3 张照片" : "Uploading 3 photos")
                    .transition(.blurReplace)
            case .done:
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(Palette.green)
                    .transition(.scale.combined(with: .opacity))
                Text(zh ? "已上传到共享相簿" : "Uploaded to Shared Album")
                    .transition(.blurReplace)
            case .hidden, .dot:
                EmptyView()
            }
        }
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(.white)
        .fixedSize()
        .padding(.horizontal, isDot ? 0 : 16)
        .frame(minWidth: 12, minHeight: 12)
        .frame(height: isDot ? 12 : 44)
        .background(isDot ? AnyShapeStyle(Palette.green) : AnyShapeStyle(Color.black.opacity(0.82)), in: Capsule())
        .shadow(color: .black.opacity(0.25), radius: 14, y: 8)
        .offset(y: visible ? 0 : 60)
        .opacity(visible ? 1 : 0)
    }

    private func start() {
        guard stage == .hidden else { return }
        token += 1
        let current = token
        let spring = Animation.spring(response: ctx["response"], dampingFraction: 0.8)
        let upload = ctx["upload"]
        let live = !ctx.isPreview
        if live { Haptics.tap() }
        withAnimation(spring) { stage = .uploading }
        Task {
            try? await Task.sleep(for: .seconds(upload))
            guard token == current else { return }
            withAnimation(spring) { stage = .done }
            if live { Haptics.success() }
            try? await Task.sleep(for: .seconds(1.6))
            guard token == current else { return }
            withAnimation(.snappy(duration: 0.35)) { stage = .dot }
            try? await Task.sleep(for: .seconds(0.85))
            guard token == current else { return }
            withAnimation(.easeIn(duration: 0.3)) { stage = .hidden }
        }
    }
}

private struct MorphToastSpinner: View {
    let preview: Bool

    var body: some View {
        TimelineView(.animation(minimumInterval: MotionFrameRate.interval(preview: preview))) { timeline in
            let t: Double = timeline.date.timeIntervalSinceReferenceDate
            Circle()
                .trim(from: 0.1, to: 0.8)
                .stroke(Color.white, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                .rotationEffect(.degrees(t.truncatingRemainder(dividingBy: 0.8) / 0.8 * 360))
        }
    }
}
