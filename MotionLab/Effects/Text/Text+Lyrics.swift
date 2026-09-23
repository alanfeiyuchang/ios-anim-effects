import SwiftUI

extension Effect {
    static let textLyrics = Effect(
        id: "text.synced-lyrics",
        category: .text,
        interaction: .loop,
        name: L("Synced Lyrics", "逐字歌词"),
        summary: L("Music-app lyrics: the active line fills word by word as the column glides up.", "音乐 App 式歌词：当前行逐字填色，歌词列平滑上移。"),
        prompt: L(
            "Full-bleed lyrics on a deep violet player card. The active line is set in heavy 24 pt type at full size; a soft-edged fill sweeps across it from left to right in time with the vocal, turning each word from 35% to 100% white with a faint glow. When a line finishes, the whole column glides up one line on an ease-out-back curve (~450 ms, slight overshoot) so the next line lands in the focus slot; lines above and below sit at 92% scale, dim with distance and blur by ~1.2 pt per line, like a shallow depth of field, and the column dissolves through a soft gradient mask at its top and bottom edges. The song starts with its first line in focus and nothing above it. Musical, immersive and calm.",
            "深紫色播放器卡片上铺满歌词。当前行以 24 pt 粗体完整显示；一道边缘柔和的填色随演唱节奏从左向右扫过，让每个字从 35% 白逐渐变为 100% 白并带淡淡辉光。一行唱完后，整列歌词以带轻微过冲的缓出回弹曲线（约 450 毫秒）上移一行，下一行正好落入焦点位置；上下其余行缩小至 92%，随距离变暗，并每行增加约 1.2 pt 模糊，如同浅景深；歌词列的上下边缘通过柔和的渐变遮罩淡出。歌曲从第一行开始，上方不会出现其他歌词。富有音乐性、沉浸而安静。"
        ),
        implementation: L(
            "A TimelineView(.animation) derives the current line, its fill progress and an eased scroll position from elapsed time; the active line overlays a white copy masked by a LinearGradient whose stops follow the progress.",
            "TimelineView(.animation) 根据经过时间推算当前行、填色进度与缓动后的滚动位置；当前行叠加一层白色副本，用随进度移动色标的 LinearGradient 作为遮罩。"
        ),
        apis: ["TimelineView(.animation)", "mask(alignment:_:)", "LinearGradient(stops:)", "blur"],
        tags: ["lyrics", "karaoke", "music", "fill", "sync", "歌词", "卡拉OK", "音乐", "逐字"],
        params: [
            .slider("duration", L("Seconds per line", "每行时长"), 1.5...5, default: 3, unit: "s"),
            .slider("blur", L("Depth blur", "景深模糊"), 0...3, default: 1.2, decimals: 1, unit: "pt"),
            .toggle("glow", L("Glow", "辉光"), default: true),
        ]
    ) { ctx in
        TextLyricsDemo(ctx: ctx)
    }
}

private struct TextLyricsDemo: View {
    let ctx: DemoContext
    @State private var start = Date()

    private var lines: [String] {
        ctx.language == .zh
            ? ["夜色把城市轻轻点亮", "我们沿着海岸线奔跑", "风把心事吹成浪花", "每一秒都值得收藏", "直到天边泛起微光"]
            : ["City lights begin to glow", "We ran along the coastline", "Wind turns secrets into waves", "Every second worth keeping", "Until the dawn breaks through"]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            TimelineView(.animation) { timeline in
                TextLyricsColumn(
                    lines: lines,
                    elapsed: timeline.date.timeIntervalSince(start),
                    lineDuration: max(ctx["duration"], 0.5),
                    blur: ctx["blur"],
                    glow: ctx.bool("glow")
                )
            }
            .frame(height: 196)
            .clipped()
            // Soft top and bottom edges: lines dissolve instead of being cut off.
            .mask {
                LinearGradient(
                    stops: [
                        .init(color: .clear, location: 0),
                        .init(color: .black, location: 0.2),
                        .init(color: .black, location: 0.8),
                        .init(color: .clear, location: 1),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        }
        .padding(20)
        .frame(width: 310)
        .background(
            LinearGradient(colors: [Color(hex: 0x3B2A8C), Color(hex: 0x6B2F8F), Color(hex: 0x1E1B4B)], startPoint: .topLeading, endPoint: .bottomTrailing),
            in: RoundedRectangle(cornerRadius: 28, style: .continuous)
        )
        .shadow(color: Color(hex: 0x3B2A8C).opacity(0.35), radius: 20, y: 12)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var header: some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Palette.sunset)
                .frame(width: 36, height: 36)
                .overlay {
                    Image(systemName: "music.note")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.white)
                }
            VStack(alignment: .leading, spacing: 1) {
                Text(L("Coastline", "海岸线"), ctx.language)
                    .font(.subheadline.weight(.bold))
                Text(L("Neon Harbor", "霓虹海港"), ctx.language)
                    .font(.caption)
                    .opacity(0.6)
            }
            .foregroundStyle(.white)
            Spacer(minLength: 0)
            Image(systemName: "waveform")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white.opacity(0.7))
                .symbolEffect(.variableColor.iterative, options: .repeating)
        }
    }
}

private struct TextLyricsColumn: View {
    let lines: [String]
    let elapsed: Double
    let lineDuration: Double
    let blur: Double
    let glow: Bool

    private let lineHeight: CGFloat = 64

    var body: some View {
        let beat = max(elapsed, 0) / lineDuration
        let active = Int(beat.rounded(.down))
        let local = beat - Double(active)
        // Glide into the new line during the first ~450 ms, with a small overshoot.
        let glide = min(local * lineDuration / 0.45, 1)
        let scroll = Double(active - 1) + easeOutBack(glide)
        let fill = ((local * lineDuration - 0.35) / max(lineDuration - 0.7, 0.1)).clamped(to: 0...1)
        ZStack(alignment: .topLeading) {
            // Never draw lines before the first one: the song starts at the top, it doesn't wrap backwards.
            ForEach(max(active - 2, 0)...(active + 3), id: \.self) { i in
                line(i, distance: Double(i) - scroll, fill: i == active ? fill : (i < active ? 1 : 0), isActive: i == active)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func line(_ i: Int, distance: Double, fill: Double, isActive: Bool) -> some View {
        let text = lines[((i % lines.count) + lines.count) % lines.count]
        let far = min(abs(distance), 3)
        return TextLyricsLine(text: text, fill: fill, glow: glow && isActive)
            .scaleEffect(CGFloat(1 - 0.08 * min(far, 1)), anchor: .leading)
            .opacity(isActive ? 1 : max(0.75 - far * 0.2, 0.1))
            .blur(radius: isActive ? 0 : CGFloat(far * blur))
            .offset(y: CGFloat(distance) * lineHeight + lineHeight * 0.9)
    }

    private func easeOutBack(_ x: Double) -> Double {
        let c1 = 1.2
        let c3 = c1 + 1
        let t = x - 1
        return 1 + c3 * t * t * t + c1 * t * t
    }
}

private struct TextLyricsLine: View {
    let text: String
    let fill: Double
    let glow: Bool

    var body: some View {
        let soft = 0.12
        let edge = fill * (1 + soft) - soft
        Text(verbatim: text)
            .font(.system(size: 24, weight: .heavy, design: .rounded))
            .lineLimit(1)
            .minimumScaleFactor(0.6)
            .foregroundStyle(.white.opacity(0.35))
            .overlay {
                Text(verbatim: text)
                    .font(.system(size: 24, weight: .heavy, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .foregroundStyle(.white)
                    .shadow(color: .white.opacity(glow ? 0.55 : 0), radius: 8)
                    .mask {
                        LinearGradient(
                            stops: [
                                .init(color: .black, location: CGFloat(max(edge, 0))),
                                .init(color: .clear, location: CGFloat(min(max(edge + soft, 0.0001), 1))),
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    }
            }
    }
}
