import SwiftUI

extension Effect {
    static let textScramble = Effect(
        id: "text.scramble",
        category: .text,
        interaction: .tap,
        name: L("Decode Scramble", "乱码解码"),
        summary: L("Random glyphs flicker until each letter locks into place.", "随机字符不断闪烁，直到每个字逐一锁定。"),
        prompt: L(
            "Inside a secure panel, a monospaced status line starts as a field of rapidly cycling random characters tinted mint, as if a signal is being decrypted. About a quarter of the way in, letters begin locking into their final value strictly left to right; each locked glyph snaps to the primary text colour while the unresolved tail keeps flickering at ~20 changes per second. A hairline beneath fills with the decode, and once the line resolves (~1.6 s) the padlock badge morphs open, the badge, status dot and hairline all turn green, and a success haptic lands. Technical, precise and a little cinematic — hacker-film energy with product-grade restraint.",
            "安全面板中，一行等宽状态文字起初是一片快速跳动的随机字符，染成薄荷色，如同信号正在被解密。进行到约四分之一时，字符开始严格按从左到右的顺序锁定为最终内容；每个锁定的字立即切换为主文字颜色，尚未解出的尾部仍以约每秒 20 次的频率闪烁。下方细进度线随解码推进逐渐填满；整行在约 1.6 秒内解出后，挂锁徽章切换为开锁形态，徽章、状态圆点与进度线一起转为绿色，并伴随成功触感。技术感强、精准且带一点电影氛围——黑客电影的气质，产品级的克制。"
        ),
        implementation: L(
            "TimelineView(.animation) computes, per frame and per character, whether it has locked; unlocked characters pick a glyph from a deterministic hash of frame index and position.",
            "TimelineView(.animation) 在每一帧计算每个字符是否已锁定；未锁定的字符根据帧序号与位置的确定性哈希从字符池中取字。"
        ),
        apis: ["TimelineView(.animation)", "monospaced font", "HStack", "sensoryFeedback"],
        tags: ["scramble", "decode", "decrypt", "glitch", "hacker", "乱码", "解码", "解密", "黑客"],
        params: [
            .slider("duration", L("Decode duration", "解码时长"), 0.5...3, default: 1.6, unit: "s"),
            .slider("rate", L("Flicker rate", "闪烁频率"), 6...40, default: 20, step: 1, decimals: 0, unit: "/s"),
            .choice("pool", L("Glyph pool", "字符池"), [L("Letters", "文字"), L("Binary", "二进制"), L("Blocks", "方块")], default: 0),
        ]
    ) { ctx in
        ScrambleDemo(ctx: ctx)
    }
}

private struct ScrambleDemo: View {
    let ctx: DemoContext
    /// `.distantPast` = rest on the decoded line; the first decode is the intro/autoplay replay.
    @State private var start = Date.distantPast
    @State private var index = 0
    @State private var done = true
    /// Only a decode the user asked for ends with a success haptic.
    @State private var userTriggered = false

    private var targets: [String] {
        ctx.language == .zh
            ? ["访问已授权", "信号已解密", "动效词典"]
            : ["ACCESS GRANTED", "SIGNAL DECODED", "MOTION LEXICON"]
    }

    private var pool: [Character] {
        switch ctx.int("pool") {
        case 1: return Array("01")
        case 2: return Array("▖▗▘▙▚▛▜▝▞▟█▓▒░")
        default:
            return ctx.language == .zh
                ? Array("的一是不了人我在有他这中大来上国个到说们为子和你地出道也时年得就那要下以生会自着去之过家学对可里后")
                : Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789#%&*@$<>/")
        }
    }

    var body: some View {
        VStack(spacing: 18) {
            VStack(spacing: 16) {
                lockBadge
                statusRow
                TimelineView(.animation(minimumInterval: MotionFrameRate.interval(preview: ctx.isPreview))) { timeline in
                    let elapsed = timeline.date.timeIntervalSince(start)
                    let duration = max(ctx["duration"], 0.1)
                    VStack(spacing: 14) {
                        ScrambleLine(
                            target: Array(targets[index % targets.count]),
                            elapsed: elapsed,
                            duration: duration,
                            rate: ctx["rate"],
                            pool: pool
                        )
                        .frame(height: 44)
                        ScrambleProgress(progress: min(max(elapsed / duration, 0), 1))
                    }
                }
            }
            .padding(.vertical, 22)
            .frame(width: 300)
            .demoCard(cornerRadius: 26)
            DemoHint(text: L("Tap to decode again", "点击再次解码"), ctx: ctx)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .onTapGesture {
            userTriggered = true
            replay()
        }
        .autoplay(ctx.isPreview, every: max(ctx["duration"], 0.5) + 1.6, delay: 0.1) { replay() }
        .task(id: start) {
            guard start != .distantPast else { return }
            done = false
            try? await Task.sleep(for: .seconds(max(ctx["duration"], 0.1)))
            if Task.isCancelled { return }
            withAnimation(.snappy) { done = true }
            if userTriggered && !ctx.isPreview { Haptics.success() }
        }
    }

    private var lockBadge: some View {
        Image(systemName: done ? "lock.open.fill" : "lock.fill")
            .font(.system(size: 22, weight: .semibold))
            .foregroundStyle(.white)
            .contentTransition(.symbolEffect(.replace))
            .frame(width: 52, height: 52)
            .background((done ? Palette.green : Palette.indigo).gradient, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: (done ? Palette.green : Palette.indigo).opacity(0.35), radius: 12, y: 6)
    }

    private var statusRow: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(done ? Palette.green : Palette.amber)
                .frame(width: 8, height: 8)
                .shadow(color: (done ? Palette.green : Palette.amber).opacity(0.8), radius: 6)
            Text(done ? L("DECODED", "已解码") : L("DECRYPTING", "解密中"), ctx.language)
                .font(.caption.weight(.bold).monospaced())
                .foregroundStyle(.secondary)
                .contentTransition(.opacity)
        }
    }

    private func replay() {
        index += 1
        start = Date()
    }
}

private struct ScrambleLine: View {
    let target: [Character]
    let elapsed: Double
    let duration: Double
    let rate: Double
    let pool: [Character]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<target.count, id: \.self) { i in
                glyph(at: i)
            }
        }
        .font(.system(size: 28, weight: .bold, design: .monospaced))
    }

    private func glyph(at i: Int) -> some View {
        let final = target[i]
        let lockAt = duration * (0.25 + 0.75 * Double(i + 1) / Double(max(target.count, 1)))
        let locked = elapsed >= lockAt || final == " "
        let shown: Character = locked ? final : randomGlyph(index: i)
        return Text(String(shown))
            .foregroundStyle(locked ? AnyShapeStyle(.primary) : AnyShapeStyle(Palette.mint))
            .opacity(locked ? 1 : 0.85)
    }

    private func randomGlyph(index: Int) -> Character {
        guard !pool.isEmpty else { return "?" }
        let frame = Int(elapsed * rate)
        let hash = (frame &* 73_856_093) ^ (index &* 19_349_663) ^ (frame &* index &* 83_492_791)
        let bucket = Int(UInt(bitPattern: hash) % UInt(pool.count))
        return pool[bucket]
    }
}

/// A hairline that fills while the line decodes, handing its colour from mint to green on lock.
private struct ScrambleProgress: View {
    let progress: Double

    var body: some View {
        Capsule()
            .fill(Color.primary.opacity(0.08))
            .frame(width: 180, height: 3)
            .overlay(alignment: .leading) {
                Capsule()
                    .fill(progress >= 1 ? AnyShapeStyle(Palette.green) : AnyShapeStyle(Palette.aurora))
                    .frame(width: 180 * CGFloat(progress), height: 3)
            }
    }
}
