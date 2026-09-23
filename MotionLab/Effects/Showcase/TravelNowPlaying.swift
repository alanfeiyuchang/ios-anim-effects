import SwiftUI

extension Effect {
    static let showcaseNowPlaying = Effect(
        id: "showcase.now-playing",
        category: .showcase,
        interaction: .gesture,
        name: L("Road-Trip Now Playing", "旅途正在播放"),
        summary: L("Album art breathes, the waveform dances and doubles as a scrubber; play morphs into pause.", "封面随播放舒展，波形跳动并兼作进度条；播放键形变为暂停键。"),
        prompt: L(
            "A dark road-trip music widget: golden-hour album art, track title and artist, a bar waveform that doubles as the scrubber, elapsed / remaining time and transport controls around an orange play button. Pressing play springs the art from 88% to full size with a warm tinted shadow blooming beneath it, symbol-replaces play with pause while the button's circle morphs into a rounded square (corner 29 → 18 pt), and the bars start dancing to layered sine motion; played bars glow orange, the rest stay faint, with a white playhead. Dragging on the waveform scrubs instantly, stretching the bars 15% taller under the finger. Pausing lets the bars sink to a quiet resting silhouette and the art shrink back. A soft ambient glow behind the card pulses while music plays. Warm, cinematic and tactile.",
            "深色旅途音乐小组件：金色时刻的专辑封面、曲名与艺人、兼作进度条的柱状波形、已播放/剩余时间，以及围绕橙色播放键的播放控制。点击播放，封面以弹簧从 88% 舒展到原始大小，下方晕开一团暖色投影；播放图标以符号替换变为暂停，按钮圆形同时形变为圆角方形（圆角 29 → 18pt）；波形柱开始随叠加的正弦律动跳动，已播放部分发出橙色光，其余保持浅淡，并有一条白色播放头。在波形上拖动即可即时拖拽进度，手指下的波形整体拉高 15%。暂停时柱子回落为安静的静态轮廓，封面缩回。播放期间卡片背后还有一团柔和的氛围光随之呼吸。温暖、有电影感、富有触感。"
        ),
        implementation: L(
            "A pausable TimelineView(.animation) derives playback position from accumulated time and feeds sine-driven bar heights; a DragGesture on the waveform maps x to position. The play button uses contentTransition(.symbolEffect(.replace)) inside an animated RoundedRectangle cornerRadius.",
            "可暂停的 TimelineView(.animation) 根据累计时间计算播放位置，并驱动正弦律动的柱高；波形上的 DragGesture 把横向位置映射为进度。播放键在圆角半径可动画的 RoundedRectangle 中使用 contentTransition(.symbolEffect(.replace))。"
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

    private let length: Double = 214

    var body: some View {
        SignatureStage {
            VStack(spacing: 0) {
                Spacer()
                TimelineView(.animation(minimumInterval: nil, paused: !playing)) { timeline in
                    TravelNowPlayingCard(
                        seconds: position(at: timeline.date),
                        length: length,
                        time: timeline.date.timeIntervalSinceReferenceDate,
                        playing: playing,
                        scrubbing: scrubbing,
                        bars: max(ctx.int("bars"), 8),
                        pausedArt: ctx.cg("artScale"),
                        glow: ctx.bool("glow"),
                        language: ctx.language,
                        onToggle: toggle,
                        onScrub: scrub,
                        onScrubEnd: endScrub
                    )
                }
                Spacer()
                DemoHint(text: L("Play, or drag the waveform", "播放，或拖动波形"), ctx: ctx)
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

    private func endScrub() {
        playStart = Date()
        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) { scrubbing = false }
    }
}

private struct TravelNowPlayingCard: View {
    let seconds: Double
    let length: Double
    let time: Double
    let playing: Bool
    let scrubbing: Bool
    let bars: Int
    let pausedArt: CGFloat
    let glow: Bool
    let language: AppLanguage
    let onToggle: () -> Void
    let onScrub: (Double) -> Void
    let onScrubEnd: () -> Void

    private let waveWidth: CGFloat = 252
    private let waveHeight: CGFloat = 46

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            waveform
            timeRow
            controls
        }
        .padding(18)
        .frame(width: 288)
        .signatureCard()
        .background {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(LinearGradient(colors: [Color(hex: 0xE0785A), Signature.accent], startPoint: .topLeading, endPoint: .bottomTrailing))
                .blur(radius: 34)
                .scaleEffect(0.9)
                .opacity(glow && playing ? 0.32 + 0.1 * sin(time * 2.2) : 0)
        }
    }

    private var header: some View {
        HStack(spacing: 14) {
            LandscapeArt(seed: 1)
                .frame(width: 78, height: 78)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(Color.white.opacity(0.12)))
                .shadow(color: Color(hex: 0xE0785A).opacity(playing ? 0.5 : 0.1), radius: playing ? 14 : 5, y: playing ? 8 : 3)
                .scaleEffect(playing ? 1 : pausedArt)
            VStack(alignment: .leading, spacing: 3) {
                Text(verbatim: language == .zh ? "自驾 · 蔚蓝海岸" : "Road trip · Riviera")
                    .signatureEyebrow()
                Text(verbatim: language == .zh ? "海岸公路" : "Coastal Drive")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.white)
                Text(verbatim: "Lumen & The Tides")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(Signature.textSecondary)
            }
            Spacer(minLength: 0)
        }
    }

    private var waveform: some View {
        let progress = seconds / length
        let gap: CGFloat = 3
        let barWidth = (waveWidth - gap * CGFloat(bars - 1)) / CGFloat(bars)
        return HStack(alignment: .center, spacing: gap) {
            ForEach(0..<bars, id: \.self) { index in
                let played = Double(index) / Double(bars) < progress
                Capsule()
                    .fill(played ? AnyShapeStyle(Signature.accentGradient) : AnyShapeStyle(Color.white.opacity(0.18)))
                    .frame(width: barWidth, height: barHeight(index))
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
        .scaleEffect(x: 1, y: scrubbing ? 1.15 : 1)
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in onScrub(Double(value.location.x / waveWidth)) }
                .onEnded { _ in onScrubEnd() }
        )
    }

    /// Static per-bar envelope times a live, layered sine while playing; a low silhouette when paused.
    private func barHeight(_ index: Int) -> CGFloat {
        let x = Double(index)
        let envelope = 0.35 + 0.65 * sportHash(x * 3.3 + 1)
        let live = playing ? 0.5 + 0.3 * abs(sin(time * 5.2 + x * 0.9)) + 0.2 * abs(sin(time * 2.3 + x * 0.37)) : 0.38
        return CGFloat(max(4, Double(waveHeight) * envelope * live))
    }

    private var timeRow: some View {
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
        HStack(spacing: 36) {
            Spacer(minLength: 0)
            Image(systemName: "backward.fill")
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
            Image(systemName: "forward.fill")
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
