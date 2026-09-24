import SwiftUI

private typealias M = TrailerMath

// MARK: - 44–52 s · Prompt: unfold, 中/EN flip, copy, fly into an AI chat

struct TrailerPromptScene: View {
    let t: Double

    var body: some View {
        ZStack {
            TrailerHeadline(
                title: "专业中英提示词",
                subtitle: "一键复制给 AI",
                reveal: M.progress(t, 44.4, 0.9),
                exit: M.easeIn(M.progress(t, 51.55, 0.5))
            )
            .position(x: 195, y: 58)
            if t > 49.1 {
                TrailerChatPanel(t: t)
            }
            if t < 50.6 {
                TrailerPromptCard(t: t)
            }
        }
        .frame(width: TrailerCanvas.width, height: TrailerCanvas.height)
    }
}

private enum PromptSource {
    static var effect: Effect? { EffectLibrary.effect(id: TrailerData.heroID) }
    static var zh: String { effect?.prompt.zh ?? "" }
    static var en: String { effect?.prompt.en ?? "" }
    static var title: String {
        guard let effect else { return "" }
        return "\(effect.name.zh) · \(effect.name.en)"
    }

    /// The first two slider parameters with their default values, e.g. "抬升 0.08".
    static var params: [String] {
        guard let effect else { return [] }
        let values = effect.defaultParams
        return effect.params
            .filter { spec in
                if case .slider = spec.kind { return true }
                return false
            }
            .prefix(2)
            .map { "\($0.name.zh) \($0.formatted(values[$0.id], .zh))" }
    }
}

/// The prompt card: unfolds from its top edge, flips its text to English and back, gets copied,
/// then shrinks along an arc into the chat's message bubble.
private struct TrailerPromptCard: View {
    let t: Double

    static let bubbleCenter = CGPoint(x: 252, y: 214)

    var body: some View {
        let unfold = M.spring(t, at: 44.05, response: 0.8, damping: 0.82)
        let fly = M.easeInOut(M.progress(t, 49.45, 0.8))
        let arc = CGFloat(sin(fly * Double.pi)) * 56
        let path = M.mix(TrailerLayout.promptCenter, Self.bubbleCenter, fly)
        let center = CGPoint(x: path.x, y: path.y - arc)
        let size = TrailerLayout.promptSize
        return VStack(alignment: .leading, spacing: 10) {
            header
            Text(verbatim: PromptSource.title)
                .font(.system(size: 11.5, weight: .semibold))
                .foregroundStyle(Color.white.opacity(0.5))
                .lineLimit(1)
                .frame(height: 16)
            promptText
            Spacer(minLength: 0)
            footer
        }
        .padding(18)
        .frame(width: size.width, height: size.height, alignment: .topLeading)
        .background {
            ZStack {
                TrailerGlass(shape: RoundedRectangle(cornerRadius: 26, style: .continuous), glow: 0.3, shadowOpacity: 0.55)
                RadialGradient(colors: [Palette.ember.opacity(0.16), Color.clear], center: .topTrailing, startRadius: 0, endRadius: 220)
                    .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
            }
        }
        .trailerGlint(M.progress(t, 45.1, 0.8), strength: 0.18)
        .rotation3DEffect(.degrees(72 * (1 - M.clamp(unfold))), axis: (x: 1, y: 0, z: 0), anchor: .top, perspective: 0.6)
        .scaleEffect(CGFloat((0.92 + 0.08 * unfold) * (1 - 0.55 * fly)))
        .rotationEffect(.degrees(-6 * sin(fly * Double.pi)))
        .opacity(M.clamp(unfold * 2) * (1 - M.progress(t, 49.95, 0.35)))
        .position(center)
    }

    private var header: some View {
        HStack(spacing: 8) {
            Image(systemName: "text.quote")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Palette.accentFill)
            Text(verbatim: "专业提示词")
                .font(.system(size: 15, weight: .heavy))
                .foregroundStyle(Color.white)
            Spacer(minLength: 0)
            languageToggle
        }
        .frame(height: 28)
    }

    private var languageToggle: some View {
        let pill = M.spring(t, at: 46.65, response: 0.45, damping: 0.72) - M.spring(t, at: 48.05, response: 0.45, damping: 0.72)
        let onEnglish = M.clamp(pill)
        return ZStack {
            Capsule()
                .fill(Palette.chipOnCard)
                .overlay(Capsule().strokeBorder(Color.white.opacity(0.1), lineWidth: 0.75))
            Capsule()
                .fill(Palette.accentFill)
                .frame(width: 40, height: 24)
                .shadow(color: Palette.accentGlow, radius: 6, x: 0, y: 2)
                .offset(x: M.mix(CGFloat(-20), CGFloat(20), pill))
            HStack(spacing: 0) {
                toggleLabel("中", selected: 1 - onEnglish)
                toggleLabel("EN", selected: onEnglish)
            }
        }
        .frame(width: 84, height: 28)
    }

    private func toggleLabel(_ text: String, selected: Double) -> some View {
        ZStack {
            Text(verbatim: text)
                .foregroundStyle(Color.white.opacity(0.8))
                .opacity(1 - selected)
            Text(verbatim: text)
                .foregroundStyle(Palette.onAccent)
                .opacity(selected)
        }
        .font(.system(size: 12, weight: .heavy))
        .frame(width: 42)
    }

    private var promptText: some View {
        let angle = 180 * M.easeInOut(M.progress(t, 46.7, 0.5)) + 180 * M.easeInOut(M.progress(t, 48.1, 0.5))
        let wrapped = angle.truncatingRemainder(dividingBy: 360)
        let showEnglish = wrapped > 90 && wrapped < 270
        return Text(verbatim: showEnglish ? PromptSource.en : PromptSource.zh)
            .font(.system(size: showEnglish ? 12 : 13, weight: .regular))
            .lineSpacing(showEnglish ? 3 : 4)
            .foregroundStyle(Color.white.opacity(0.86))
            .lineLimit(6)
            .textRenderer(TrailerLineReveal(progress: M.progress(t, 44.7, 1.4)))
            .frame(width: TrailerLayout.promptSize.width - 36, height: 128, alignment: .topLeading)
            .rotation3DEffect(.degrees(showEnglish ? angle + 180 : angle), axis: (x: 1, y: 0, z: 0), perspective: 0.5)
    }

    private var footer: some View {
        HStack(spacing: 6) {
            ForEach(PromptSource.params, id: \.self) { text in
                Text(verbatim: text)
                    .font(.system(size: 10.5, weight: .semibold).monospacedDigit())
                    .foregroundStyle(Color.white.opacity(0.7))
                    .lineLimit(1)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(Palette.chipOnCard, in: Capsule())
            }
            Spacer(minLength: 0)
            copyButton
        }
        .frame(height: 32)
    }

    private var copyButton: some View {
        let copied = M.progress(t, 48.95, 0.12)
        let dip = M.progress(t, 48.86, 0.06) * (1 - M.progress(t, 49.0, 0.25))
        let pop = t > 48.95 ? M.spring(t, at: 48.95, response: 0.4, damping: 0.55) : 1
        return ZStack {
            Capsule().fill(Palette.accentFill)
                .opacity(1 - copied)
            Capsule().fill(Palette.successStrong)
                .opacity(copied)
            ZStack {
                label("一键复制", symbol: "doc.on.doc", color: Palette.onAccent)
                    .opacity(1 - copied)
                label("已复制", symbol: "checkmark", color: Color.white)
                    .opacity(copied)
                    .scaleEffect(CGFloat(0.7 + 0.3 * pop))
            }
        }
        .frame(width: 104, height: 32)
        .shadow(color: Palette.accentGlow, radius: 10, x: 0, y: 4)
        .scaleEffect(CGFloat(1 - 0.08 * dip))
    }

    private func label(_ text: String, symbol: String, color: Color) -> some View {
        HStack(spacing: 5) {
            Image(systemName: symbol)
                .font(.system(size: 12, weight: .bold))
            Text(verbatim: text)
                .font(.system(size: 13, weight: .heavy))
        }
        .foregroundStyle(color)
    }
}

/// The AI chat the prompt is pasted into.
private struct TrailerChatPanel: View {
    let t: Double

    var body: some View {
        let appear = M.spring(t, at: 49.25, response: 0.6, damping: 0.82)
        let exit = M.easeInOut(M.progress(t, 51.55, 0.8))
        let size = CGSize(width: 334, height: 276)
        let scaleValue: Double = (0.94 + 0.06 * appear) * (1 - 0.72 * exit)
        let scale = CGFloat(scaleValue)
        let blur = CGFloat(exit) * 6
        let fadeOut: Double = 1 - M.progress(t, 51.9, 0.45)
        let opacity: Double = M.clamp(appear * 2) * fadeOut
        let center: CGPoint = M.mix(TrailerLayout.promptCenter, CGPoint(x: 195, y: 280), exit)
        return VStack(alignment: .leading, spacing: 14) {
            header
            userBubble
            aiBubble
            Spacer(minLength: 0)
        }
        .padding(16)
        .frame(width: size.width, height: size.height, alignment: .topLeading)
        .background(TrailerGlass(shape: RoundedRectangle(cornerRadius: 26, style: .continuous), shadowOpacity: 0.55))
        .scaleEffect(scale)
        .blur(radius: blur)
        .opacity(opacity)
        .position(center)
    }

    private var header: some View {
        HStack(spacing: 8) {
            Image(systemName: "sparkles")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(Palette.onAccent)
                .frame(width: 28, height: 28)
                .background(Palette.accentFill, in: Circle())
            VStack(alignment: .leading, spacing: 1) {
                Text(verbatim: "AI 助手")
                    .font(.system(size: 14, weight: .heavy))
                    .foregroundStyle(Color.white)
                HStack(spacing: 4) {
                    Circle().fill(Palette.green).frame(width: 5, height: 5)
                    Text(verbatim: "在线")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.5))
                }
            }
            Spacer(minLength: 0)
        }
    }

    private var userBubble: some View {
        let pop = M.spring(t, at: 50.05, response: 0.5, damping: 0.66)
        return HStack {
            Spacer(minLength: 60)
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 5) {
                    Image(systemName: "doc.on.clipboard")
                        .font(.system(size: 11, weight: .bold))
                    Text(verbatim: "\(PromptSource.effect?.name.zh ?? "") · 提示词")
                        .font(.system(size: 12, weight: .heavy))
                }
                Text(verbatim: PromptSource.zh)
                    .font(.system(size: 10.5, weight: .medium))
                    .lineLimit(2)
                    .opacity(0.8)
            }
            .foregroundStyle(Palette.onAccent)
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(Palette.accentFill, in: UnevenRoundedRectangle(topLeadingRadius: 16, bottomLeadingRadius: 16, bottomTrailingRadius: 4, topTrailingRadius: 16, style: .continuous))
            .shadow(color: Palette.accentGlow, radius: 10, x: 0, y: 4)
            .scaleEffect(CGFloat(0.6 + 0.4 * pop), anchor: .bottomTrailing)
            .opacity(M.clamp(pop * 3))
        }
    }

    private var aiBubble: some View {
        let appear = M.spring(t, at: 50.5, response: 0.5, damping: 0.72)
        let typing = t < 51.05
        return HStack {
            ZStack(alignment: .topLeading) {
                if typing {
                    HStack(spacing: 4) {
                        ForEach(0..<3, id: \.self) { dot in
                            Circle()
                                .fill(Color.white.opacity(0.7))
                                .frame(width: 6, height: 6)
                                .offset(y: CGFloat(-3 * max(0, sin(t * 9 - Double(dot) * 0.9))))
                        }
                    }
                    .padding(.vertical, 6)
                } else {
                    reply
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(Palette.chipOnCard, in: UnevenRoundedRectangle(topLeadingRadius: 16, bottomLeadingRadius: 4, bottomTrailingRadius: 16, topTrailingRadius: 16, style: .continuous))
            .scaleEffect(CGFloat(0.6 + 0.4 * appear), anchor: .bottomLeading)
            .opacity(M.clamp(appear * 3))
            Spacer(minLength: 40)
        }
    }

    private var reply: some View {
        let lines: [(width: CGFloat, color: Color)] = [
            (150, Palette.ember), (112, Palette.sky), (176, Palette.violet), (92, Palette.mint),
        ]
        return VStack(alignment: .leading, spacing: 6) {
            Text(verbatim: "收到！这就用 SwiftUI 实现：")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color.white.opacity(0.9))
            ForEach(lines.indices, id: \.self) { index in
                let reveal = M.easeOut(M.progress(t, 51.1 + Double(index) * 0.09, 0.3))
                Capsule()
                    .fill(lines[index].color.opacity(0.75))
                    .frame(width: lines[index].width * CGFloat(reveal), height: 6)
                    .padding(.leading, index == 1 || index == 2 ? 14 : 0)
            }
        }
    }
}

// MARK: - 52–58 s · Web: browser window with every recorded effect

struct TrailerWebScene: View {
    let t: Double

    static let url = "alanfeiyuchang.github.io/ios-anim-effects"
    static let windowCenter = CGPoint(x: 195, y: 257)
    static let windowSize = CGSize(width: 350, height: 294)

    var body: some View {
        let enter = M.spring(t, at: 51.65, response: 0.85, damping: 0.88)
        let condense = TrailerEndScene.condense(t)
        let size = Self.windowSize
        let side = TrailerEndScene.iconSide
        let scaleX = M.mix(CGFloat(1), side / size.width, condense)
        let scaleY = M.mix(CGFloat(1), side / size.height, condense)
        ZStack {
            TrailerHeadline(
                title: "网页版全部动效",
                subtitle: "录像一览，随时查看",
                reveal: M.progress(t, 52.3, 0.9),
                exit: M.easeIn(M.progress(t, 56.75, 0.5))
            )
            .position(x: 195, y: 58)
            TrailerBrowserWindow(t: t, contentOpacity: 1 - M.clamp(condense * 2.2))
                .scaleEffect(CGFloat(1.45 - 0.45 * enter))
                .scaleEffect(x: scaleX, y: scaleY)
                .blur(radius: CGFloat(1 - M.clamp(enter)) * 8)
                .opacity(M.clamp(enter * 2) * (1 - M.progress(condense, 0.45, 0.35)))
                .position(M.mix(Self.windowCenter, TrailerEndScene.iconCenter, condense))
        }
        .frame(width: TrailerCanvas.width, height: TrailerCanvas.height)
    }
}

private struct TrailerBrowserWindow: View {
    let t: Double
    let contentOpacity: Double

    var body: some View {
        let size = TrailerWebScene.windowSize
        let shape = RoundedRectangle(cornerRadius: 20, style: .continuous)
        VStack(spacing: 0) {
            toolbar
            Rectangle()
                .fill(Color.white.opacity(0.08))
                .frame(height: 0.5)
            // The page is taller than the window: pin it under the toolbar and clip the bottom, so its
            // height never pushes the toolbar (and the URL) out of the top of the window.
            TrailerWebPage(t: t)
                .frame(width: size.width, height: size.height - 38.5, alignment: .top)
                .clipped()
        }
        .opacity(contentOpacity)
        .frame(width: size.width, height: size.height, alignment: .top)
        .background(TrailerGlass(shape: shape, glow: 0.2, shadowOpacity: 0.6))
        .clipShape(shape)
        .overlay(shape.strokeBorder(TrailerStyle.rim, lineWidth: 0.75))
    }

    private var toolbar: some View {
        let typed = Int((Double(TrailerWebScene.url.count) * M.progress(t, 52.2, 0.9)).rounded(.down))
        let text = String(TrailerWebScene.url.prefix(typed))
        let caretOn = t < 53.1 || sin(t * 2 * Double.pi * 1.4) > -0.2
        return HStack(spacing: 10) {
            HStack(spacing: 6) {
                Circle().fill(Color(hex: 0xFF5F57)).frame(width: 9, height: 9)
                Circle().fill(Color(hex: 0xFEBC2E)).frame(width: 9, height: 9)
                Circle().fill(Color(hex: 0x28C840)).frame(width: 9, height: 9)
            }
            HStack(spacing: 5) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 8.5, weight: .bold))
                    .foregroundStyle(Color.white.opacity(0.55))
                Text(verbatim: text)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.92))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Rectangle()
                    .fill(Palette.ember)
                    .frame(width: 1.5, height: 12)
                    .opacity(caretOn && t > 52.0 ? 1 : 0)
                Spacer(minLength: 0)
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(Color.white.opacity(0.4))
            }
            .padding(.horizontal, 10)
            .frame(height: 24)
            .background(Color.white.opacity(0.07), in: Capsule())
            .overlay(Capsule().strokeBorder(Palette.ember.opacity(0.55 * M.progress(t, 52.1, 0.3) * (1 - M.progress(t, 53.6, 0.5))), lineWidth: 1))
            .trailerGlint(M.progress(t, 53.25, 0.7), strength: 0.5)
        }
        .padding(.horizontal, 14)
        .frame(height: 38)
    }
}

/// The documentation site: a header and a grid of recorded effects that keeps scrolling.
private struct TrailerWebPage: View {
    let t: Double

    private static let effects: [Effect] = {
        let all = EffectLibrary.all
        guard !all.isEmpty else { return [] }
        let step = max(all.count / 24, 1)
        return stride(from: 0, to: all.count, by: step).prefix(24).map { all[$0] }
    }()

    var body: some View {
        let local = max(t - 53.2, 0)
        let scroll = CGFloat(26 * (local - (1 - exp(-2 * local)) / 2))
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Text(verbatim: "动效词典")
                    .font(.system(size: 13, weight: .heavy))
                    .foregroundStyle(Color.white)
                Text(verbatim: "全部动效录像一览")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.55))
                Spacer(minLength: 0)
                Text(verbatim: "\(TrailerData.effectCount) 个")
                    .font(.system(size: 10.5, weight: .heavy).monospacedDigit())
                    .foregroundStyle(Palette.onAccent)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(Palette.accentFill, in: Capsule())
            }
            grid
                .offset(y: -scroll)
        }
        .padding(.horizontal, 12)
        .padding(.top, 10)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private var grid: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 4)
        return LazyVGrid(columns: columns, spacing: 8) {
            ForEach(Self.effects.indices, id: \.self) { index in
                tile(index)
            }
        }
        .drawingGroup()
    }

    private func tile(_ index: Int) -> some View {
        let effect = Self.effects[index]
        let pop = M.spring(t, at: 52.35 + Double(index) * 0.035, response: 0.5, damping: 0.72)
        let colors = effect.category.gradient
        return VStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .fill(LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing))
                .aspectRatio(1, contentMode: .fit)
                .overlay {
                    Image(systemName: effect.category.symbol)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(Color.white.opacity(0.92))
                        .offset(y: CGFloat(2 * sin(t * 2.2 + Double(index))))
                }
                .overlay(alignment: .bottomTrailing) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 6, weight: .black))
                        .foregroundStyle(Color.white)
                        .frame(width: 14, height: 14)
                        .background(Color.black.opacity(0.35), in: Circle())
                        .padding(5)
                }
            Text(verbatim: effect.name.zh)
                .font(.system(size: 8.5, weight: .semibold))
                .foregroundStyle(Color.white.opacity(0.7))
                .lineLimit(1)
        }
        .scaleEffect(CGFloat(0.7 + 0.3 * pop))
        .opacity(M.clamp(pop * 2.5))
    }
}

// MARK: - 57–60 s · End card: app icon + 动效词典 · Motion Lexicon

struct TrailerEndScene: View {
    let t: Double

    static let iconSide: CGFloat = 132
    static let iconCenter = CGPoint(x: 195, y: 188)

    /// The browser window condensing into the icon.
    static func condense(_ t: Double) -> Double {
        M.spring(t, at: 56.9, response: 0.8, damping: 0.86)
    }

    var body: some View {
        let condense = Self.condense(t)
        let size = TrailerWebScene.windowSize
        let side = Self.iconSide
        let scaleX = M.mix(size.width / side, CGFloat(1), condense)
        let scaleY = M.mix(size.height / side, CGFloat(1), condense)
        let float = CGFloat(2 * sin((t - 58.5) * 1.3) * M.progress(t, 58.5, 0.8))
        ZStack {
            TrailerAppIcon(t: t, side: side)
                .scaleEffect(x: scaleX, y: scaleY)
                .shadow(color: Palette.ember.opacity(0.45 * M.clamp(condense)), radius: 34, x: 0, y: 10)
                .opacity(M.progress(condense, 0.25, 0.4))
                .position(x: M.mix(TrailerWebScene.windowCenter.x, Self.iconCenter.x, condense), y: M.mix(TrailerWebScene.windowCenter.y, Self.iconCenter.y, condense) + float)
            Text(verbatim: "动效词典")
                .font(.system(size: 44, weight: .heavy))
                .foregroundStyle(Color.white)
                .textRenderer(GlyphBlurRenderer(progress: M.progress(t, 57.75, 0.8)))
                .shadow(color: Color.black.opacity(0.4), radius: 12, x: 0, y: 4)
                .position(x: 195, y: 300)
            Text(verbatim: "Motion Lexicon")
                .font(.system(size: 20, weight: .semibold))
                .tracking(3)
                .foregroundStyle(TrailerStyle.emberText)
                .textRenderer(GlyphBlurRenderer(progress: M.progress(t, 58.05, 0.8)))
                .position(x: 195, y: 344)
            Text(verbatim: "\(TrailerData.effectCount) 个 iOS 高级动效 · 即看即用")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.55))
                .opacity(M.easeOut(M.progress(t, 58.4, 0.7)))
                .offset(y: CGFloat(1 - M.easeOut(M.progress(t, 58.4, 0.7))) * 8)
                .position(x: 195, y: 382)
        }
        .frame(width: TrailerCanvas.width, height: TrailerCanvas.height)
    }
}

/// The app icon, drawn live: an ember gradient that cools to near-black, and three cream motion
/// dots growing along a diagonal (they pop in one after another), with a glint sweep.
private struct TrailerAppIcon: View {
    let t: Double
    let side: CGFloat

    private static let dots: [(x: CGFloat, y: CGFloat, radius: CGFloat, opacity: Double)] = [
        (0.293, 0.605, 0.107, 0.5),
        (0.479, 0.498, 0.137, 0.78),
        (0.664, 0.391, 0.176, 1),
    ]

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: side * 0.225, style: .continuous)
        ZStack(alignment: .topLeading) {
            LinearGradient(
                colors: [Color(hex: 0xE2692A), Color(hex: 0x9C4216), Color(hex: 0x42190B), Color(hex: 0x130E0E)],
                startPoint: .top,
                endPoint: .bottom
            )
            RadialGradient(
                colors: [Color(hex: 0xF5832E, opacity: 0.9), Color(hex: 0xF5832E, opacity: 0)],
                center: UnitPoint(x: 0.47, y: 0),
                startRadius: 0,
                endRadius: side * 0.75
            )
            RadialGradient(
                colors: [Color.black.opacity(0), Color.black.opacity(0.35)],
                center: UnitPoint(x: 0.35, y: 0.35),
                startRadius: side * 0.3,
                endRadius: side * 0.95
            )
            ForEach(Self.dots.indices, id: \.self) { index in
                dot(index)
            }
        }
        .frame(width: side, height: side)
        .clipShape(shape)
        .overlay(shape.strokeBorder(Color.white.opacity(0.18), lineWidth: 0.75))
        .trailerGlint(M.progress(t, 58.35, 0.75), strength: 0.55)
    }

    private func dot(_ index: Int) -> some View {
        let spec = Self.dots[index]
        let pop = M.spring(t, at: 57.5 + Double(index) * 0.13, response: 0.45, damping: 0.6)
        let diameter = spec.radius * 2 * side
        let travel = CGFloat(1 - M.clamp(pop)) * side * 0.12
        return Circle()
            .fill(Color(hex: 0xFFF6EC).opacity(spec.opacity))
            .frame(width: diameter, height: diameter)
            .shadow(color: index == 2 ? Color(hex: 0xFFB36B).opacity(0.8) : Color.clear, radius: 10, x: 0, y: 0)
            .scaleEffect(CGFloat(max(pop, 0)))
            .offset(x: spec.x * side - diameter / 2 - travel, y: spec.y * side - diameter / 2 + travel)
    }
}
