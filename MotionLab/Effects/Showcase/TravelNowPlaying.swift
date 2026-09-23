import SwiftUI

extension Effect {
    static let showcaseNowPlaying = Effect(
        id: "showcase.now-playing",
        category: .showcase,
        interaction: .gesture,
        name: L("Road-Trip Now Playing", "旅途正在播放"),
        summary: L("Album art breathes, the waveform dances and doubles as a scrubber; play morphs into pause.", "封面随播放舒展，波形跳动并兼作进度条；播放键形变为暂停键。"),
        prompt: L(
            "A dark road-trip music widget: golden-hour album art, title and artist, a bar waveform that doubles as the scrubber, elapsed / remaining time and transport controls around an orange play button. Pressing play springs the art from 88% to full size over a warm blooming shadow, symbol-replaces play with pause while the button morphs from circle to rounded square (corner 29 → 18 pt), and the bars start dancing to layered sines; played bars fill with the orange gradient behind a glowing white playhead. Dragging the waveform scrubs instantly while a lens swells the nearest bars up to 35% with a cosine falloff. Back and forward really skip: the title pushes in from that side, the art cross-fades and playback restarts at 0:00. Pausing sinks the bars to a quiet silhouette, and a soft glow behind the card pulses only while music plays. Warm and tactile.",
            "深色旅途音乐小组件：金色时刻封面、曲名与艺人、兼作进度条的柱状波形与播放控制。点击播放，封面以弹簧从 88% 舒展到原大，下方晕开暖色投影；播放图标换成暂停，按钮由圆形变圆角方形（圆角 29 → 18pt）；波形柱随叠加正弦律动，已播放部分填橙色渐变。拖动波形即时定位，指尖附近的柱子按余弦衰减最多拉高 35%。上一首/下一首真的切歌：曲名从对应方向推入，封面交叉淡化，从 0:00 播放。暂停时柱子回落、封面缩回；背后的氛围光只在播放时呼吸。"
        ),
        implementation: L(
            "A pausable TimelineView(.animation) derives playback position from accumulated time and feeds sine-driven bar heights; a DragGesture on the waveform maps x to position and a cosine lens enlarges the bars around it. Skips swap an id-keyed title with a push transition. The play button uses contentTransition(.symbolEffect(.replace)) inside an animated RoundedRectangle cornerRadius.",
            "可暂停的 TimelineView(.animation) 根据累计时间计算播放位置，并驱动正弦律动的柱高；波形上的 DragGesture 把横向位置映射为进度，并以余弦“放大镜”拉高附近的柱子；切歌时以 id 区分的标题使用 push 过渡。播放键在圆角半径可动画的 RoundedRectangle 中使用 contentTransition(.symbolEffect(.replace))。"
        ),
        apis: ["TimelineView(.animation(paused:))", "DragGesture", "contentTransition(.symbolEffect(.replace))", "RoundedRectangle(cornerRadius:)", "scaleEffect"],
        tags: ["music", "now playing", "waveform", "scrubber", "音乐", "正在播放", "波形", "进度条"],
        params: [
            .slider("bars", L("Waveform bars", "波形柱数"), 16...44, default: 30, step: 1, decimals: 0),
            .slider("artScale", L("Paused art scale", "暂停时封面缩放"), 0.75...1.0, default: 0.88),
            .toggle("glow", L("Ambient glow", "氛围光晕"), default: true),
        ]
    ) { ctx in
        TravelNowPlayingDemo(ctx: ctx)
    }
}

private struct TravelNowPlayingDemo: View {
    let ctx: DemoContext
    @State private var playing = false
    @State private var elapsed: Double = 38
    @State private var playStart = Date()
    @State private var scrubbing = false
    @State private var trackIndex = 0
    @State private var skipDirection: Double = 1

    private var track: TravelTrack { TravelTrack.all[trackIndex] }
    private var length: Double { track.length }

    var body: some View {
        SignatureStage {
            VStack(spacing: 0) {
                Spacer()
                // Only the waveform, time row and glow tick per frame; the card's static parts stay outside the clock.
                TravelNowPlayingCard(
                    position: position(at:),
                    length: length,
                    track: track,
                    skipDirection: skipDirection,
                    playing: playing,
                    scrubbing: scrubbing,
                    bars: max(ctx.int("bars"), 8),
                    pausedArt: ctx.cg("artScale"),
                    glow: ctx.bool("glow"),
                    preview: ctx.isPreview,
                    language: ctx.language,
                    onToggle: toggle,
                    onScrub: scrub,
                    onScrubEnd: endScrub,
                    onSkip: skip
                )
                Spacer()
                DemoHint(text: L("Play, skip, or drag the waveform", "播放、切歌，或拖动波形"), ctx: ctx)
                    .padding(.bottom, 14)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .autoplay(ctx.isPreview, every: 3.4, delay: 0.6) { toggle() }
    }

    private func position(at date: Date) -> Double {
        let raw = playing && !scrubbing ? elapsed + max(0, date.timeIntervalSince(playStart)) : elapsed
        return raw.truncatingRemainder(dividingBy: length)
    }

    private func toggle() {
        if playing {
            elapsed = position(at: Date())
        } else {
            playStart = Date()
        }
        withAnimation(.spring(response: 0.45, dampingFraction: 0.72)) { playing.toggle() }
        if !ctx.isPreview { Haptics.tap(.medium) }
    }

    private func scrub(_ fraction: Double) {
        if !scrubbing {
            if !ctx.isPreview { Haptics.tap(.light) }
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { scrubbing = true }
        }
        elapsed = fraction.clamped(to: 0...0.999) * length
    }

    /// Back rewinds first if the song is more than 3 s in; otherwise both buttons change track.
    private func skip(_ delta: Int) {
        if !ctx.isPreview { Haptics.tap(.light) }
        if delta < 0 && position(at: Date()) > 3 {
            elapsed = 0
            playStart = Date()
            return
        }
        let count = TravelTrack.all.count
        skipDirection = delta < 0 ? -1 : 1
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            trackIndex = (trackIndex + delta + count) % count
        }
        elapsed = 0
        playStart = Date()
    }

    /// Single cleanup for a lifted or cancelled finger (the card calls it from both paths).
    private func endScrub() {
        guard scrubbing else { return }
        playStart = Date()
        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) { scrubbing = false }
    }
}

private struct TravelTrack {
    let title: LocalizedText
    let artist: String
    let seed: Int
    let length: Double

    static let all: [TravelTrack] = [
        TravelTrack(title: L("Coastal Drive", "海岸公路"), artist: "Lumen & The Tides", seed: 1, length: 214),
        TravelTrack(title: L("Alpine Morning", "高山清晨"), artist: "North Pass", seed: 0, length: 188),
        TravelTrack(title: L("Desert Radio", "沙漠电台"), artist: "Wadi Sound", seed: 3, length: 241),
    ]
}

private struct TravelNowPlayingCard: View {
    let position: (Date) -> Double
    let length: Double
    let track: TravelTrack
    let skipDirection: Double
    let playing: Bool
    let scrubbing: Bool
    let bars: Int
    let pausedArt: CGFloat
    let glow: Bool
    let preview: Bool
    let language: AppLanguage
    let onToggle: () -> Void
    let onScrub: (Double) -> Void
    let onScrubEnd: () -> Void
    let onSkip: (Int) -> Void

    private let waveWidth: CGFloat = 252
    private let waveHeight: CGFloat = 46
    /// Resets on system cancellation too (Control Center pull, incoming call), so a cancelled scrub still ends.
    @GestureState private var touching = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            clock { date in
                let seconds = position(date)
                let time = date.timeIntervalSinceReferenceDate
                VStack(alignment: .leading, spacing: 14) {
                    waveform(seconds: seconds, time: time)
                    timeRow(seconds: seconds)
                }
            }
            controls
        }
        .padding(18)
        .frame(width: 288)
        .signatureCard()
        .background {
            clock { date in
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(LinearGradient(colors: [Color(hex: 0xE0785A), Signature.accent], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .blur(radius: 34)
                    .scaleEffect(0.9)
                    .opacity(glow && playing ? 0.32 + 0.1 * sin(date.timeIntervalSinceReferenceDate * 2.2) : 0)
            }
        }
        .onChange(of: touching) { _, isTouching in
            if !isTouching { onScrubEnd() }
        }
    }

    /// A frame clock that runs only while playing (30 fps in grid previews).
    private func clock<Content: View>(@ViewBuilder _ content: @escaping (Date) -> Content) -> some View {
        TimelineView(.animation(minimumInterval: MotionFrameRate.interval(preview: preview), paused: !playing)) { timeline in
            content(timeline.date)
        }
    }

    private var header: some View {
        HStack(spacing: 14) {
            // ZStack so the outgoing and incoming art overlap while they cross-fade.
            ZStack {
                LandscapeArt(seed: track.seed)
                    .id(track.seed)
                    .transition(.opacity)
            }
            .frame(width: 78, height: 78)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(Color.white.opacity(0.12)))
            .shadow(color: Color(hex: 0xE0785A).opacity(playing ? 0.5 : 0.1), radius: playing ? 14 : 5, y: playing ? 8 : 3)
            .scaleEffect(playing ? 1 : pausedArt)
            VStack(alignment: .leading, spacing: 3) {
                Text(verbatim: language == .zh ? "自驾 · 蔚蓝海岸" : "Road trip · Riviera")
                    .signatureEyebrow()
                ZStack(alignment: .leading) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(track.title, language)
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.white)
                        Text(verbatim: track.artist)
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundStyle(Signature.textSecondary)
                    }
                    .id(track.seed)
                    .transition(.push(from: skipDirection < 0 ? .leading : .trailing))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .clipped()
            }
            Spacer(minLength: 0)
        }
    }

    private func waveform(seconds: Double, time: Double) -> some View {
        let progress = seconds / length
        let gap: CGFloat = 3
        let barWidth = (waveWidth - gap * CGFloat(bars - 1)) / CGFloat(bars)
        return HStack(alignment: .center, spacing: gap) {
            ForEach(0..<bars, id: \.self) { index in
                let played = Double(index) / Double(bars) < progress
                Capsule()
                    .fill(played ? AnyShapeStyle(Signature.accentGradient) : AnyShapeStyle(Color.white.opacity(0.18)))
                    .frame(width: barWidth, height: barHeight(index, time: time) * lens(index, progress: progress))
            }
        }
        .frame(width: waveWidth, height: waveHeight)
        .overlay(alignment: .leading) {
            Capsule()
                .fill(Color.white)
                .frame(width: 2, height: waveHeight + 8)
                .shadow(color: .white.opacity(0.6), radius: 3)
                .offset(x: waveWidth * CGFloat(progress) - 1)
        }
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .updating($touching) { _, state, _ in state = true }
                .onChanged { value in onScrub(Double(value.location.x / waveWidth)) }
                .onEnded { _ in onScrubEnd() }
        )
    }

    /// Static per-bar envelope times a live, layered sine while playing; a low silhouette when paused.
    private func barHeight(_ index: Int, time: Double) -> CGFloat {
        let x = Double(index)
        let envelope = 0.35 + 0.65 * sportHash(x * 3.3 + 1)
        let live = playing ? 0.5 + 0.3 * abs(sin(time * 5.2 + x * 0.9)) + 0.2 * abs(sin(time * 2.3 + x * 0.37)) : 0.38
        return CGFloat(max(4, Double(waveHeight) * envelope * live))
    }

    /// While scrubbing, bars near the playhead swell up to 35% with a cosine falloff over ~4 bars.
    private func lens(_ index: Int, progress: Double) -> CGFloat {
        guard scrubbing else { return 1 }
        let distance = abs((Double(index) + 0.5) / Double(bars) - progress) * Double(bars)
        guard distance < 4 else { return 1 }
        return CGFloat(1 + 0.35 * (0.5 + 0.5 * cos(distance / 4 * .pi)))
    }

    private func timeRow(seconds: Double) -> some View {
        HStack {
            Text(verbatim: Self.format(seconds))
            Spacer(minLength: 0)
            Text(verbatim: "-" + Self.format(length - seconds))
        }
        .font(.system(size: 11, weight: .semibold, design: .rounded).monospacedDigit())
        .foregroundStyle(Signature.textSecondary)
        .padding(.top, -6)
    }

    private var controls: some View {
        HStack(spacing: 24) {
            Spacer(minLength: 0)
            Button { onSkip(-1) } label: {
                Image(systemName: "backward.fill")
                    .frame(width: 40, height: 40)
                    .contentShape(Rectangle())
            }
            .buttonStyle(SportPressStyle(scale: 0.85, dim: 0.1))
            .accessibilityLabel(Text(L("Previous", "上一首"), language))
            Button(action: onToggle) {
                Image(systemName: playing ? "pause.fill" : "play.fill")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(Signature.ink)
                    .contentTransition(.symbolEffect(.replace))
                    .offset(x: playing ? 0 : 2)
                    .frame(width: 58, height: 58)
                    .background(Signature.accentGradient, in: RoundedRectangle(cornerRadius: playing ? 18 : 29, style: .continuous))
                    .shadow(color: Signature.accent.opacity(0.55), radius: playing ? 14 : 8, y: 4)
            }
            .buttonStyle(SportPressStyle(scale: 0.9, dim: 0.05))
            Button { onSkip(1) } label: {
                Image(systemName: "forward.fill")
                    .frame(width: 40, height: 40)
                    .contentShape(Rectangle())
            }
            .buttonStyle(SportPressStyle(scale: 0.85, dim: 0.1))
            .accessibilityLabel(Text(L("Next", "下一首"), language))
            Spacer(minLength: 0)
        }
        .font(.system(size: 20, weight: .semibold))
        .foregroundStyle(Color.white.opacity(0.85))
    }

    private static func format(_ seconds: Double) -> String {
        let total = max(0, Int(seconds))
        return String(format: "%d:%02d", total / 60, total % 60)
    }
}
