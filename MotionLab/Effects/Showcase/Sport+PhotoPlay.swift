import SwiftUI

extension Effect {
    static let showcasePhotoPlay = Effect(
        id: "showcase.photo-play",
        category: .showcase,
        interaction: .tap,
        name: L("Photo Card Play", "照片卡片播放"),
        summary: L("Press sinks and dims the photo card; play morphs into a progress ring while the shot drifts in Ken Burns.", "按下时卡片下沉变暗；播放键变形为进度环，画面缓缓推近平移。"),
        prompt: L(
            "A dark photo card shows a golden-hour alpine shot, \"Nordkette Ridge\" with its altitude beneath, and a white round play button. Touch-down sinks the whole card to ~96% and dims it by 12%, releasing with a springy 0.3 s rebound. Tapping toggles playback: the play glyph symbol-replaces into pause, the button turns glassy and grows 8%, and a 3 pt orange progress ring starts sweeping clockwise around it from 12 o'clock; meanwhile the photo slowly pushes in to ~116% and pans a few points left in a smooth Ken Burns cosine ease that ping-pongs without ever jumping. A time chip counts elapsed seconds. Pausing freezes ring and zoom exactly in place. Cinematic, calm and tactile.",
            "深色照片卡片展示一张金色时刻雪山照，下方是“Nordkette Ridge”与海拔，右侧是白色圆形播放键。按下时整张卡片下沉到约 96% 并压暗 12%，松手以 0.3 秒弹簧回弹。点击切换播放：播放图标经符号替换变为暂停，按钮转为玻璃质感并放大 8%，一圈 3pt 橙色进度环从 12 点方向顺时针扫出；画面以余弦缓动缓缓推近到约 116% 并左移几个点，形成往返不跳变的 Ken Burns 效果，时间标签同步计秒。暂停时进度环与缩放精确定格。有电影感，安静而可触。"
        ),
        implementation: L(
            "A paused-able TimelineView(.animation) derives clip progress and a cosine Ken Burns phase from accumulated play time; a custom ButtonStyle handles the press scale and dim.",
            "可暂停的 TimelineView(.animation) 根据累计播放时长计算进度与余弦 Ken Burns 相位；自定义 ButtonStyle 负责按压缩放与压暗。"
        ),
        apis: ["TimelineView(.animation(paused:))", "ButtonStyle", "contentTransition(.symbolEffect(.replace))", "Circle().trim", "scaleEffect(anchor:)"],
        tags: ["ken burns", "video card", "play button", "progress ring", "视频卡片", "播放按钮", "进度环", "推镜"],
        params: [
            .slider("zoom", L("Ken Burns zoom", "推镜缩放"), 1.0...1.4, default: 1.16),
            .slider("press", L("Pressed scale", "按下缩放"), 0.85...1.0, default: 0.96),
            .slider("clip", L("Clip length", "片段时长"), 3...12, default: 6, step: 1, decimals: 0, unit: "s"),
        ]
    ) { ctx in
        SportPhotoPlayDemo(ctx: ctx)
    }
}

private struct SportPhotoPlayDemo: View {
    let ctx: DemoContext
    @State private var playing = false
    @State private var elapsed: Double = 0
    @State private var playStart = Date()

    var body: some View {
        SignatureStage {
            VStack(spacing: 0) {
                Spacer()
                Button(action: toggle) {
                    TimelineView(.animation(minimumInterval: MotionFrameRate.interval(preview: ctx.isPreview), paused: !playing)) { timeline in
                        PhotoPlayCard(
                            seconds: current(at: timeline.date),
                            clip: max(ctx["clip"], 1),
                            playing: playing,
                            zoom: ctx.cg("zoom")
                        )
                    }
                }
                .buttonStyle(SportPressStyle(scale: ctx.cg("press"), dim: 0.12))
                Spacer()
                DemoHint(text: L("Tap the card to play / pause", "点击卡片播放或暂停"), ctx: ctx)
                    .padding(.bottom, 14)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .autoplay(ctx.isPreview, every: 3.2, delay: 0.8) { toggle() }
    }

    private func current(at date: Date) -> Double {
        playing ? elapsed + max(0, date.timeIntervalSince(playStart)) : elapsed
    }

    private func toggle() {
        if playing {
            elapsed += Date().timeIntervalSince(playStart)
        } else {
            playStart = Date()
        }
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { playing.toggle() }
        if !ctx.isPreview { Haptics.tap(.medium) }
    }
}

private struct PhotoPlayCard: View {
    let seconds: Double
    let clip: Double
    let playing: Bool
    let zoom: CGFloat

    private var progress: Double { seconds.truncatingRemainder(dividingBy: clip) / clip }
    /// Smooth 0→1→0 cosine phase with a period of two clips, so the zoom never jumps.
    private var kenBurns: CGFloat { CGFloat((1 - cos(seconds / clip * .pi)) / 2) }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            photo
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(verbatim: "Nordkette Ridge")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.white)
                    Text(verbatim: "Innsbruck · 2,256 m")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(Signature.textSecondary)
                }
                Spacer(minLength: 0)
                PhotoPlayButton(progress: progress, playing: playing)
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 6)
        }
        .padding(10)
        .frame(width: 272)
        .signatureCard(cornerRadius: 30)
    }

    private var photo: some View {
        LandscapeArt(seed: 0)
            .scaleEffect(1 + (zoom - 1) * kenBurns, anchor: UnitPoint(x: 0.35, y: 0.45))
            .offset(x: -10 * kenBurns)
            .saturation(playing ? 1.05 : 0.85)
            .frame(height: 180)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(alignment: .topLeading) {
                PhotoTimeChip(seconds: Int(seconds.truncatingRemainder(dividingBy: clip)), clip: Int(clip), playing: playing)
                    .padding(10)
            }
    }
}

private struct PhotoTimeChip: View {
    let seconds: Int
    let clip: Int
    let playing: Bool

    var body: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(playing ? Signature.accent : Color.white.opacity(0.6))
                .frame(width: 6, height: 6)
            Text(String(format: "0:%02d / 0:%02d", seconds, clip))
                .font(.system(size: 10, weight: .bold, design: .rounded).monospacedDigit())
                .foregroundStyle(Color.white)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(.ultraThinMaterial, in: Capsule())
    }
}

private struct PhotoPlayButton: View {
    let progress: Double
    let playing: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(playing ? Color.white.opacity(0.1) : Color.white)
            Circle()
                .stroke(Color.white.opacity(0.14), lineWidth: 3)
                .opacity(playing ? 1 : 0)
            Circle()
                .trim(from: 0, to: CGFloat(progress))
                .stroke(Signature.accent, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .shadow(color: Signature.accent.opacity(0.7), radius: 4)
                .opacity(playing ? 1 : 0)
            Image(systemName: playing ? "pause.fill" : "play.fill")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(playing ? Color.white : Color.black)
                .contentTransition(.symbolEffect(.replace))
                .offset(x: playing ? 0 : 1.5)
        }
        .frame(width: 46, height: 46)
        .scaleEffect(playing ? 1.08 : 1)
    }
}
