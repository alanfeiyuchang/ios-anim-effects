import SwiftUI

extension Effect {
    static let iconsPlayPause = Effect(
        id: "icons.play-pause",
        category: .icons,
        interaction: .tap,
        name: L("Play ↔ Pause Morph", "播放 ↔ 暂停形变"),
        summary: L("The play triangle splits and reshapes into two pause bars.", "播放三角形一分为二，重塑为两根暂停竖条。"),
        prompt: L(
            "Inside a compact now-playing card, a large gradient button holds a play triangle drawn as two quads that meet — overlapping by a hair so no seam shows — at the triangle's vertical midline. On tap the left half straightens into the left pause bar and the right half widens from a sliver into the right bar — every vertex interpolates on a spring (≈0.45 s, 0.75 damping) while the whole glyph spins a half turn, so the shape visibly re-forms rather than cross-fading. Rounded joins keep corners soft; the equaliser bars beside the title start dancing while playing and settle when paused. Tactile, musical and continuous.",
            "紧凑的正在播放卡片中，一个大号渐变按钮里是由两个四边形组成的播放三角形，二者在三角形的纵向中线处相接，并略微重叠以免出现接缝。点击后，左半部分拉直成左侧暂停竖条，右半部分从一道窄尖展宽为右侧竖条——每个顶点都沿弹簧曲线（约0.45秒、阻尼0.75）插值，同时整个图形旋转半圈，让人清楚看到形状在“重塑”，而不是交叉淡化。圆角连接让转角保持柔和；标题旁的均衡器条在播放时跳动、暂停时静止。有触感、有音乐性、连贯流畅。"
        ),
        implementation: L(
            "A custom Shape with animatableData lerps eight vertices between the play and pause geometry; fill plus a round-joined stroke softens the corners.",
            "自定义 Shape 通过 animatableData 在播放与暂停几何之间插值八个顶点；填充叠加圆角连接的描边让转角更柔和。"
        ),
        apis: ["Shape", "animatableData", "Path", "spring(response:dampingFraction:)"],
        tags: ["play", "pause", "morph", "media", "播放", "暂停", "形变", "音乐"],
        params: [
            .slider("response", L("Spring response", "弹簧响应"), 0.2...1, default: 0.45, unit: "s"),
            .slider("damping", L("Damping", "阻尼"), 0.4...1, default: 0.75),
            .toggle("spin", L("Spin while morphing", "形变时旋转"), default: true),
        ]
    ) { ctx in
        PlayPauseDemo(ctx: ctx)
    }
}

private struct PlayPauseDemo: View {
    let ctx: DemoContext
    @State private var playing = false

    var body: some View {
        VStack(spacing: 18) {
            HStack(spacing: 14) {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Palette.sunset)
                    .frame(width: 60, height: 60)
                    .overlay(Image(systemName: "music.note").font(.title2.weight(.bold)).foregroundStyle(.white))
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(L("Midnight Drive", "午夜驾驶"), ctx.language)
                            .font(.headline)
                        EqualizerBars(active: playing, preview: ctx.isPreview)
                    }
                    Text(L("Neon Coast", "霓虹海岸"), ctx.language)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
            }
            playButton
        }
        .padding(20)
        .frame(width: 290)
        .demoCard(cornerRadius: 28)
        .overlay(alignment: .bottom) {
            DemoHint(text: L("Tap play", "点击播放"), ctx: ctx)
                .fixedSize()
                .offset(y: 30)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 1.6) { toggle() }
    }

    private var playButton: some View {
        Button { toggle() } label: {
            ZStack {
                PlayPauseShape(progress: playing ? 1 : 0)
                    .fill(.white)
                PlayPauseShape(progress: playing ? 1 : 0)
                    .stroke(.white, style: StrokeStyle(lineWidth: 5, lineJoin: .round))
            }
            .frame(width: 30, height: 30)
            .rotationEffect(.degrees(ctx.bool("spin") && playing ? 180 : 0))
            .animation(.spring(response: ctx["response"], dampingFraction: ctx["damping"]), value: playing)
            .frame(width: 76, height: 76)
            .background(Palette.primary, in: Circle())
            .shadow(color: Palette.violet.opacity(0.4), radius: 14, y: 8)
        }
        .buttonStyle(.plain)
    }

    private func toggle() {
        playing.toggle()
        if !ctx.isPreview { Haptics.tap(.medium) }
    }
}

private struct PlayPauseShape: Shape {
    var progress: CGFloat

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    // The two play halves overlap by 0.04 across the midline (each inner edge still sits exactly on
    // the triangle's outline: y = 0.5 · (x − 0.1) / 0.85), so no anti-aliased seam shows between them.
    private static let playLeft: [CGPoint] = [
        CGPoint(x: 0.1, y: 0), CGPoint(x: 0.545, y: 0.2618), CGPoint(x: 0.545, y: 0.7382), CGPoint(x: 0.1, y: 1),
    ]
    private static let playRight: [CGPoint] = [
        CGPoint(x: 0.505, y: 0.2382), CGPoint(x: 0.95, y: 0.5), CGPoint(x: 0.95, y: 0.5), CGPoint(x: 0.505, y: 0.7618),
    ]
    private static let pauseLeft: [CGPoint] = [
        CGPoint(x: 0.1, y: 0), CGPoint(x: 0.38, y: 0), CGPoint(x: 0.38, y: 1), CGPoint(x: 0.1, y: 1),
    ]
    private static let pauseRight: [CGPoint] = [
        CGPoint(x: 0.62, y: 0), CGPoint(x: 0.9, y: 0), CGPoint(x: 0.9, y: 1), CGPoint(x: 0.62, y: 1),
    ]

    func path(in rect: CGRect) -> Path {
        var path = Path()
        addQuad(&path, from: Self.playLeft, to: Self.pauseLeft, in: rect)
        addQuad(&path, from: Self.playRight, to: Self.pauseRight, in: rect)
        return path
    }

    private func addQuad(_ path: inout Path, from a: [CGPoint], to b: [CGPoint], in rect: CGRect) {
        let t = min(max(progress, -0.2), 1.2)
        var points: [CGPoint] = []
        for index in 0..<min(a.count, b.count) {
            let x = a[index].x + (b[index].x - a[index].x) * t
            let y = a[index].y + (b[index].y - a[index].y) * t
            points.append(CGPoint(x: rect.minX + x * rect.width, y: rect.minY + y * rect.height))
        }
        path.addLines(points)
        path.closeSubpath()
    }
}

private struct EqualizerBars: View {
    let active: Bool
    /// Grid previews tick at the capped frame rate.
    let preview: Bool

    var body: some View {
        TimelineView(.animation(minimumInterval: MotionFrameRate.interval(preview: preview), paused: !active)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            HStack(alignment: .bottom, spacing: 2) {
                ForEach(0..<3, id: \.self) { i in
                    Capsule()
                        .fill(Palette.pink)
                        .frame(width: 3, height: height(i, t))
                }
            }
            .frame(height: 14, alignment: .bottom)
        }
    }

    private func height(_ i: Int, _ t: Double) -> CGFloat {
        guard active else { return 4 }
        let wave = sin(t * (7 + Double(i) * 2.3) + Double(i) * 1.7)
        return CGFloat(8 + wave * 6)
    }
}
