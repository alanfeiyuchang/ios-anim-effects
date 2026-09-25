import SwiftUI

private typealias M = TrailerMath

// MARK: - 70–80 s · Prompt: unfold, 中/EN flip, copy, fly into an AI chat

struct TrailerPromptScene: View {
    let t: Double

    var body: some View {
        ZStack {
            TrailerHeadline(
                title: TrailerCopy.current.prompt.title,
                subtitle: TrailerCopy.optional(TrailerCopy.current.prompt.subtitle),
                reveal: M.progress(t, 70.4, 0.9),
                exit: M.easeIn(M.progress(t, 79.0, 0.5))
            )
            .position(x: 195, y: TrailerLayout.headlineY)
            if t > 76.0 {
                TrailerChatPanel(t: t)
            }
            if t < 77.5 {
                TrailerPromptCard(t: t)
            }
        }
        .frame(width: TrailerCanvas.width, height: TrailerCanvas.height)
    }
}

private enum PromptSource {
    /// `TrailerCopy.prompt.effectID` if it names a real effect, else the first demo played on the phone.
    static let effect: Effect? = {
        let override = TrailerCopy.current.prompt.effectID
        if !override.isEmpty, let chosen = EffectLibrary.effect(id: override) {
            return chosen
        }
        return EffectLibrary.effect(id: TrailerData.heroID)
    }()
    static var zh: String {
        let override = TrailerCopy.current.prompt.textZh
        return override.isEmpty ? (effect?.prompt.zh ?? "") : override
    }
    static var en: String {
        let override = TrailerCopy.current.prompt.textEn
        return override.isEmpty ? (effect?.prompt.en ?? "") : override
    }
    /// The chat bubble's title (`{name}` = the effect's Chinese name).
    static var bubbleTitle: String {
        TrailerCopy.current.chat.bubbleTitle.replacingOccurrences(of: "{name}", with: effect?.name.zh ?? "")
    }
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

/// The prompt card: rises out of depth, cross-fades its text to English and back, gets copied, then
/// shrinks (uniformly) along an arc into the chat's message bubble.
private struct TrailerPromptCard: View {
    let t: Double

    /// The user bubble of `TrailerChatPanel`, which shares the card's centre.
    static let bubbleCenter = CGPoint(x: 252, y: TrailerLayout.promptCenter.y - 43)

    var body: some View {
        let unfold = M.spring(t, at: 70.05, response: 0.8, damping: 0.82)
        let settled = M.clamp(unfold)
        let fly = M.easeInOut(M.progress(t, 76.35, 0.8))
        let arc = CGFloat(sin(fly * Double.pi)) * 56
        let path = M.mix(TrailerLayout.promptCenter, Self.bubbleCenter, fly)
        let center = CGPoint(x: path.x, y: path.y - arc)
        let size = TrailerLayout.promptSize
        let scale: Double = (0.9 + 0.1 * unfold) * (1 - 0.55 * fly)
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
        .trailerGlint(M.progress(t, 71.1, 0.8), strength: 0.18)
        .scaleEffect(CGFloat(scale))
        .blur(radius: CGFloat(1 - settled) * 8)
        .offset(y: CGFloat(1 - settled) * 28)
        .rotationEffect(.degrees(-6 * sin(fly * Double.pi)))
        .opacity(M.clamp(unfold * 2) * (1 - M.progress(t, 76.85, 0.35)))
        .position(center)
    }

    private var header: some View {
        HStack(spacing: 8) {
            Image(systemName: "text.quote")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Palette.accentFill)
            Text(verbatim: TrailerCopy.current.prompt.cardTitle)
                .font(.system(size: 15, weight: .heavy))
                .foregroundStyle(Color.white)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Spacer(minLength: 0)
            languageToggle
        }
        .frame(height: 28)
    }

    private var languageToggle: some View {
        let toEnglish: Double = M.spring(t, at: 73.4, response: 0.45, damping: 0.72)
        let toChinese: Double = M.spring(t, at: 74.9, response: 0.45, damping: 0.72)
        let pill: Double = toEnglish - toChinese
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
                toggleLabel(TrailerCopy.current.prompt.languageZh, selected: 1 - onEnglish)
                toggleLabel(TrailerCopy.current.prompt.languageEn, selected: onEnglish)
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
        .lineLimit(1)
        .minimumScaleFactor(0.5)
        .frame(width: 38)
        .frame(width: 42)
    }

    /// 中 → EN → 中 as a cross-fade with a soft blur and a small slide (never a squashing flip).
    private var promptText: some View {
        let english: Double = M.easeInOut(M.progress(t, 73.45, 0.5)) - M.easeInOut(M.progress(t, 74.95, 0.5))
        let slide = CGFloat(english) * 6
        return ZStack(alignment: .topLeading) {
            promptBody(PromptSource.zh, english: false)
                .blur(radius: CGFloat(english) * 6)
                .offset(y: -slide)
                .opacity(1 - english)
            promptBody(PromptSource.en, english: true)
                .blur(radius: CGFloat(1 - english) * 6)
                .offset(y: 6 - slide)
                .opacity(english)
        }
        .frame(width: TrailerLayout.promptSize.width - 36, height: TrailerLayout.promptSize.height - 142, alignment: .topLeading)
    }

    private func promptBody(_ text: String, english: Bool) -> some View {
        Text(verbatim: text)
            .font(.system(size: english ? 12 : 13, weight: .regular))
            .lineSpacing(english ? 3 : 4)
            .foregroundStyle(Color.white.opacity(0.86))
            .lineLimit(TrailerCanvas.isTall ? 7 : 6)
            .textRenderer(TrailerLineReveal(progress: M.progress(t, 70.7, 1.4)))
            .frame(width: TrailerLayout.promptSize.width - 36, height: TrailerLayout.promptSize.height - 142, alignment: .topLeading)
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
        let copied: Double = M.progress(t, 75.85, 0.12)
        let dip: Double = M.progress(t, 75.76, 0.06) * (1 - M.progress(t, 75.9, 0.25))
        let pop: Double = t > 75.85 ? M.spring(t, at: 75.85, response: 0.4, damping: 0.55) : 1
        return ZStack {
            Capsule().fill(Palette.accentFill)
                .opacity(1 - copied)
            Capsule().fill(Palette.successStrong)
                .opacity(copied)
            ZStack {
                label(TrailerCopy.current.prompt.copyButton, symbol: "doc.on.doc", color: Palette.onAccent)
                    .opacity(1 - copied)
                label(TrailerCopy.current.prompt.copiedButton, symbol: "checkmark", color: Color.white)
                    .opacity(copied)
                    .scaleEffect(CGFloat(0.7 + 0.3 * pop))
            }
        }
        .frame(width: TrailerLayout.copyButtonWidth, height: 32)
        .shadow(color: Palette.accentGlow, radius: 10, x: 0, y: 4)
        .scaleEffect(CGFloat(1 - 0.08 * dip))
    }

    private func label(_ text: String, symbol: String, color: Color) -> some View {
        HStack(spacing: 5) {
            Image(systemName: symbol)
                .font(.system(size: 12, weight: .bold))
            Text(verbatim: text)
                .font(.system(size: 13, weight: .heavy))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .foregroundStyle(color)
        .padding(.horizontal, 10)
    }
}

/// The AI chat the prompt is pasted into.
private struct TrailerChatPanel: View {
    let t: Double

    var body: some View {
        let appear = M.spring(t, at: 76.15, response: 0.6, damping: 0.82)
        let exit = M.easeInOut(M.progress(t, 79.1, 0.8))
        let size = CGSize(width: 334, height: 276)
        let scaleValue: Double = (0.94 + 0.06 * appear) * (1 - 0.72 * exit)
        let scale = CGFloat(scaleValue)
        let blur = CGFloat(exit) * 6
        let fadeOut: Double = 1 - M.progress(t, 79.45, 0.45)
        let opacity: Double = M.clamp(appear * 2) * fadeOut
        let exitCenter = CGPoint(x: 195, y: TrailerLayout.promptCenter.y + 23)
        let center: CGPoint = M.mix(TrailerLayout.promptCenter, exitCenter, exit)
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
                Text(verbatim: TrailerCopy.current.chat.assistantName)
                    .font(.system(size: 14, weight: .heavy))
                    .foregroundStyle(Color.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                HStack(spacing: 4) {
                    Circle().fill(Palette.green).frame(width: 5, height: 5)
                    Text(verbatim: TrailerCopy.current.chat.status)
                        .font(.system(size: 10, weight: .medium))
                        .lineLimit(1)
                        .foregroundStyle(Color.white.opacity(0.5))
                }
            }
            Spacer(minLength: 0)
        }
    }

    private var userBubble: some View {
        let pop = M.spring(t, at: 76.95, response: 0.5, damping: 0.66)
        return HStack {
            Spacer(minLength: 60)
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 5) {
                    Image(systemName: "doc.on.clipboard")
                        .font(.system(size: 11, weight: .bold))
                    Text(verbatim: PromptSource.bubbleTitle)
                        .font(.system(size: 12, weight: .heavy))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
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
        let appear = M.spring(t, at: 77.4, response: 0.5, damping: 0.72)
        let typing = t < 78.0
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
            Text(verbatim: TrailerCopy.current.chat.reply)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color.white.opacity(0.9))
                .lineLimit(2)
                .minimumScaleFactor(0.8)
                .fixedSize(horizontal: false, vertical: true)
            ForEach(lines.indices, id: \.self) { index in
                let reveal = M.easeOut(M.progress(t, 78.05 + Double(index) * 0.09, 0.3))
                Capsule()
                    .fill(lines[index].color.opacity(0.75))
                    .frame(width: lines[index].width * CGFloat(reveal), height: 6)
                    .padding(.leading, index == 1 || index == 2 ? 14 : 0)
            }
        }
    }
}


// MARK: - 79–88 s (source) · Outro: the web page and the phone, then the repository on GitHub

/// "网页随时看 · App 感受手感": the documentation site in a browser (its address typed in) beside the
/// phone playing a demo under the finger. Both then condense into the app icon of the end card: the window's
/// frame morphs into the icon's rounded square, the phone shrinks into it.
struct TrailerOutroScene: View {
    let t: Double
    let origin: Date

    static let enter: Double = 79.3
    /// The phone leaves and the browser takes the stage for GitHub ("整个项目已经开源").
    static let githubStart: Double = 85.3
    static let condenseStart: Double = 88.3

    /// Browser window (left) and phone (right), per aspect.
    static let windowSize: CGSize = TrailerCanvas.isTall ? CGSize(width: 212, height: 300) : CGSize(width: 214, height: 250)
    static let windowCenter: CGPoint = {
        let x: CGFloat = 18 + TrailerOutroScene.windowSize.width / 2
        return CGPoint(x: x, y: TrailerCanvas.pick(250, 362))
    }()
    static let phoneScale: CGFloat = TrailerCanvas.pick(0.56, 0.64)
    static let phoneCenter: CGPoint = {
        let halfWidth: CGFloat = TrailerPhone.bodySize.width * TrailerOutroScene.phoneScale / 2
        let x: CGFloat = TrailerCanvas.width - 18 - halfWidth
        return CGPoint(x: x, y: TrailerOutroScene.windowCenter.y)
    }()
    static let labelY: CGFloat = windowCenter.y + TrailerCanvas.pick(143, 172)
    /// The browser on GitHub: centred, as large as the content area allows.
    static let githubSize: CGSize = TrailerCanvas.isTall ? CGSize(width: 312, height: 388) : CGSize(width: 312, height: 300)
    static let githubCenter = CGPoint(x: 195, y: TrailerCanvas.pick(262, 372))
    /// Halfway across the gap between the window and the phone: each label stays on its own side of it.
    private static let labelDivider: CGFloat = {
        let windowRight: CGFloat = windowCenter.x + windowSize.width / 2
        let phoneLeft: CGFloat = phoneCenter.x - TrailerPhone.bodySize.width * phoneScale / 2
        return (windowRight + phoneLeft) / 2
    }()

    /// Widest a label centred at `x` may be: 190 pt, narrower when that would cross the divider or leave
    /// less than 12 pt to the canvas edge (the text shrinks to fit).
    static func labelMaxWidth(centeredAt x: CGFloat) -> CGFloat {
        let reach: CGFloat = min(x - 12, TrailerCanvas.width - 12 - x, abs(labelDivider - x) - 4)
        return min(190, max(reach, 40) * 2)
    }

    /// The demo on the phone (board-card: delay 0.8, every 2.4 → flips at 83.2).
    static let phoneEffectID = "showcase.board-card"
    static let phoneEpochOffset: Double = 82.4
    static let phoneTapTimes: [Double] = [83.2]
    /// The finger's spot on the phone's stage (the board, 170 × 160 on the demo's 340 pt canvas).
    static let phoneTapPoint: CGPoint = {
        let stage = TrailerPhone.stageRect
        let screen = TrailerPhone.screenSize
        let x: CGFloat = stage.minX + 170 * stage.width / StageMetrics.previewCanvas
        let y: CGFloat = stage.minY + 160 * stage.height / StageMetrics.previewCanvas
        let scale: CGFloat = TrailerOutroScene.phoneScale
        let center: CGPoint = TrailerOutroScene.phoneCenter
        let dx: CGFloat = (x - screen.width / 2) * scale
        let dy: CGFloat = (y - screen.height / 2) * scale
        return CGPoint(x: center.x + dx, y: center.y + dy)
    }()

    static func condense(_ t: Double) -> Double {
        M.spring(t, at: condenseStart, response: 0.8, damping: 0.86)
    }

    var body: some View {
        let copy = TrailerCopy.current.web
        let windowIn: Double = M.spring(t, at: Self.enter, response: 0.85, damping: 0.86)
        let phoneIn: Double = M.spring(t, at: Self.enter + 0.3, response: 0.8, damping: 0.84)
        let condense: Double = Self.condense(t)
        let morph: Double = M.clamp(condense)
        let github: Double = M.spring(t, at: Self.githubStart, response: 0.75, damping: 0.86)
        let phoneOut: Double = M.easeIn(M.progress(t, Self.githubStart - 0.05, 0.45))
        let labelsExit: Double = M.easeIn(M.progress(t, Self.githubStart - 0.2, 0.4))
        let windowSlide = CGFloat(1 - windowIn) * -60
        let phoneSlide = CGFloat(1 - phoneIn) * 70 + CGFloat(phoneOut) * 90
        let windowHome: CGPoint = M.mix(Self.windowCenter, Self.githubCenter, github)
        let windowSize = CGSize(
            width: M.mix(Self.windowSize.width, Self.githubSize.width, CGFloat(github)),
            height: M.mix(Self.windowSize.height, Self.githubSize.height, CGFloat(github))
        )
        let windowPath: CGPoint = M.mix(windowHome, TrailerEndScene.iconCenter, condense)
        let phonePath: CGPoint = M.mix(Self.phoneCenter, TrailerEndScene.iconCenter, condense)
        let phoneShrink = CGFloat(1 - 0.75 * morph)
        let phoneFade: Double = 1 - M.progress(condense, 0.15, 0.4)
        let buzz = CGFloat(TrailerScript.buzz(t, window: 82.0...87.0) * 1.6)
        let settleBlur: CGFloat = CGFloat(1 - M.clamp(phoneIn)) * 8
        let phoneBlur: CGFloat = settleBlur + CGFloat(morph) * 6 + CGFloat(phoneOut) * 8
        ZStack {
            TrailerHeadline(
                title: copy.title,
                subtitle: TrailerCopy.optional(copy.subtitle),
                titleSize: TrailerCanvas.pick(28, 32),
                reveal: M.progress(t, 80.1, 0.9),
                exit: M.easeIn(M.progress(t, Self.githubStart - 0.1, 0.5))
            )
            .position(x: 195, y: TrailerLayout.headlineY)
            if t > Self.githubStart {
                TrailerHeadline(
                    title: TrailerCopy.current.openSource.title,
                    subtitle: TrailerCopy.optional(TrailerCopy.current.openSource.subtitle),
                    titleSize: TrailerCanvas.pick(28, 32),
                    reveal: M.progress(t, Self.githubStart + 0.35, 0.9),
                    exit: M.easeIn(M.progress(t, Self.condenseStart - 0.1, 0.5))
                )
                .position(x: 195, y: TrailerLayout.headlineY)
            }
            TrailerBrowserWindow(t: t, size: windowSize, morph: morph, contentOpacity: 1 - M.clamp(condense * 2.2))
                .scaleEffect(CGFloat(1.12 - 0.12 * windowIn))
                .blur(radius: CGFloat(1 - M.clamp(windowIn)) * 8)
                .opacity(M.clamp(windowIn * 2) * (1 - M.progress(condense, 0.45, 0.35)))
                .position(x: windowPath.x + windowSlide, y: windowPath.y)
            ZStack {
                TrailerPhoneBody {
                    TrailerOutroPhoneScreen(t: t, origin: origin)
                }
                TrailerPhoneGlass()
            }
            .scaleEffect(Self.phoneScale * phoneShrink)
            .offset(x: buzz)
            .blur(radius: phoneBlur)
            .opacity(M.clamp(phoneIn * 2) * phoneFade * (1 - phoneOut))
            .position(x: phonePath.x + phoneSlide, y: phonePath.y)
            label(copy.webLabel, x: Self.windowCenter.x, appear: M.progress(t, 81.0, 0.6), exit: labelsExit)
            label(copy.appLabel, x: Self.phoneCenter.x, appear: M.progress(t, 81.3, 0.6), exit: labelsExit)
        }
        .frame(width: TrailerCanvas.width, height: TrailerCanvas.height)
    }

    private func label(_ text: String, x: CGFloat, appear: Double, exit: Double) -> some View {
        let eased: Double = M.easeOut(appear)
        return Text(verbatim: text)
            .font(.system(size: 13, weight: .bold))
            .foregroundStyle(Color.white.opacity(0.85))
            .lineLimit(1)
            .minimumScaleFactor(0.6)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .frame(maxWidth: Self.labelMaxWidth(centeredAt: x))
            .background(TrailerGlass(shape: Capsule(), frosted: true, shadowOpacity: 0.25))
            .offset(y: CGFloat(1 - eased) * 10)
            .opacity(eased)
            .trailerDepth(exit, scale: 0.1, lift: 10, blur: 8)
            .position(x: x, y: Self.labelY)
    }
}

/// The outro phone's display: the detail page of one demo, played live.
private struct TrailerOutroPhoneScreen: View {
    let t: Double
    let origin: Date

    var body: some View {
        let size = TrailerPhone.screenSize
        let stage = TrailerPhone.stageRect
        let card = TrailerPhone.cardRect
        let effect: Effect? = EffectLibrary.effect(id: TrailerOutroScene.phoneEffectID)
        ZStack {
            LinearGradient(
                colors: [Color(hex: 0x17120F), TrailerCanvas.ink, TrailerCanvas.ink],
                startPoint: .top,
                endPoint: .bottom
            )
            Image(systemName: "chevron.left")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(Palette.accent)
                .position(x: 15, y: TrailerPhone.navY)
            HStack(spacing: 4) {
                Text(verbatim: effect?.name.zh ?? "")
                    .font(.system(size: 10.5, weight: .heavy))
                    .foregroundStyle(Color.white)
                Text(verbatim: effect?.category.title.zh ?? "")
                    .font(.system(size: 7, weight: .bold))
                    .foregroundStyle(Palette.accent)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1.5)
                    .background(Palette.ember.opacity(0.16), in: Capsule())
            }
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .frame(width: 136)
            .position(x: size.width / 2, y: TrailerPhone.navY)
            TrailerStageTile(
                effectID: TrailerOutroScene.phoneEffectID,
                epoch: origin.addingTimeInterval(TrailerOutroScene.phoneEpochOffset),
                side: stage.width,
                cornerRadius: TrailerPhone.stageCorner
            )
            .position(x: stage.midX, y: stage.midY)
            HStack(spacing: 4) {
                Image(systemName: "hand.tap.fill")
                    .font(.system(size: 7, weight: .bold))
                    .foregroundStyle(Palette.accentFill)
                Text(verbatim: TrailerCopy.current.phone.hintTap)
                    .font(.system(size: 8, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.72))
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
            .padding(.horizontal, 10)
            .frame(height: 17)
            .background(Color.white.opacity(0.06), in: Capsule())
            .position(x: size.width / 2, y: TrailerPhone.hintY)
            VStack(alignment: .leading, spacing: 6) {
                Text(verbatim: effect?.summary.zh ?? "")
                    .font(.system(size: 8.5, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.7))
                    .lineSpacing(2)
                    .lineLimit(4)
            }
            .padding(10)
            .frame(width: card.width, height: card.height, alignment: .topLeading)
            .background(TrailerGlass(shape: RoundedRectangle(cornerRadius: 14, style: .continuous), shadowOpacity: 0.2))
            .position(x: card.midX, y: card.midY)
            TrailerPhoneStatusBar()
        }
        .frame(width: size.width, height: size.height)
        .environment(\.colorScheme, .dark)
    }
}

/// A browser window on the documentation site. `morph` 0 = the window, 1 = the app icon's rounded square.
/// Narrow windows (< 300 pt) drop the traffic lights and the reload glyph so the address stays readable.
private struct TrailerBrowserWindow: View {
    let t: Double
    let size: CGSize
    let morph: Double
    let contentOpacity: Double

    static let typingStart: Double = 80.3
    /// Typing time grows with the address: 22 ms per character (0.9 s for the default 41), 0.4 … 1.4 s.
    static let typingDuration: Double = {
        let perCharacter: Double = 0.022
        let natural: Double = Double(TrailerCopy.current.web.url.count) * perCharacter
        return min(max(natural, 0.4), 1.4)
    }()

    /// The address is retyped to the GitHub repository, the page loads (a thin progress bar), then scrolls.
    static let githubTypeStart: Double = TrailerOutroScene.githubStart + 0.3
    static let githubTypeDuration: Double = {
        let natural: Double = Double(TrailerCopy.current.openSource.url.count) * 0.022
        return min(max(natural, 0.4), 1.4)
    }()
    static let githubLoadStart: Double = githubTypeStart + githubTypeDuration + 0.05
    static let githubShown: Double = githubLoadStart + 0.3

    private var isCompact: Bool { size.width < 300 }
    /// 0 in the small window, 1 once it has grown for GitHub: the traffic lights and the reload glyph
    /// slide in with the width instead of popping.
    private var chrome: Double { M.clamp(Double((size.width - 240) / 60)) }

    var body: some View {
        let side = TrailerEndScene.iconSide
        let width = M.mix(size.width, side, morph)
        let height = M.mix(size.height, side, morph)
        let corner = M.mix(CGFloat(18), side * 0.225, morph)
        let shape = RoundedRectangle(cornerRadius: corner, style: .continuous)
        VStack(spacing: 0) {
            toolbar
            Rectangle()
                .fill(Color.white.opacity(0.08))
                .frame(height: 0.5)
            // The page is taller than the window: pin it under the toolbar and clip the bottom, so its
            // height never pushes the toolbar (and the URL) out of the top of the window.
            ZStack(alignment: .top) {
                TrailerWebPage(t: t, columns: 3)
                    .opacity(1 - M.progress(t, Self.githubLoadStart + 0.15, 0.25))
                if t > Self.githubLoadStart {
                    TrailerGitHubPage(t: t, width: size.width, shownAt: Self.githubShown)
                        .opacity(M.progress(t, Self.githubLoadStart + 0.15, 0.25))
                }
                loadingBar
            }
            .frame(width: size.width, height: size.height - 38.5, alignment: .top)
            .clipped()
        }
        .opacity(contentOpacity)
        .frame(width: size.width, height: size.height, alignment: .top)
        // Cropped from the top, so the URL bar stays pinned until the content has faded.
        .frame(width: width, height: height, alignment: .top)
        .background(TrailerGlass(shape: shape, glow: 0.2, shadowOpacity: 0.6))
        .clipShape(shape)
        .overlay(shape.strokeBorder(TrailerStyle.rim, lineWidth: 0.75))
    }

    /// A thin ember bar under the address while GitHub loads.
    private var loadingBar: some View {
        let p: Double = M.easeOut(M.progress(t, Self.githubLoadStart, 0.3))
        let fade: Double = 1 - M.progress(t, Self.githubShown, 0.2)
        return Rectangle()
            .fill(Palette.accentFill)
            .frame(width: size.width * CGFloat(p), height: 2)
            .frame(width: size.width, alignment: .leading)
            .opacity(t > Self.githubLoadStart ? fade : 0)
    }

    private var toolbar: some View {
        let onGitHub: Bool = t >= Self.githubTypeStart
        let url: String = onGitHub ? TrailerCopy.current.openSource.url : TrailerCopy.current.web.url
        let start: Double = onGitHub ? Self.githubTypeStart : Self.typingStart
        let duration: Double = onGitHub ? Self.githubTypeDuration : Self.typingDuration
        let typingEnd: Double = start + duration
        let typed = Int((Double(url.count) * M.progress(t, start, duration)).rounded(.down))
        let text = String(url.prefix(typed))
        let caretOn: Bool = t < typingEnd || sin(t * 2 * Double.pi * 1.4) > -0.2
        let focus: Double = onGitHub
            ? M.progress(t, start - 0.2, 0.2) * (1 - M.progress(t, typingEnd + 0.4, 0.4))
            : M.progress(t, Self.typingStart - 0.2, 0.3) * (1 - M.progress(t, typingEnd + 0.5, 0.5))
        let chrome = self.chrome
        return HStack(spacing: 10 * CGFloat(chrome)) {
            HStack(spacing: 6) {
                Circle().fill(Color(hex: 0xFF5F57)).frame(width: 9, height: 9)
                Circle().fill(Color(hex: 0xFEBC2E)).frame(width: 9, height: 9)
                Circle().fill(Color(hex: 0x28C840)).frame(width: 9, height: 9)
            }
            .frame(width: 39 * CGFloat(chrome), alignment: .leading)
            .clipped()
            .opacity(chrome)
            HStack(spacing: 4) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(Color.white.opacity(0.55))
                Text(verbatim: text)
                    .font(.system(size: isCompact ? 9.5 : 10, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.92))
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .truncationMode(.head)
                Rectangle()
                    .fill(Palette.ember)
                    .frame(width: 1.5, height: 12)
                    .opacity(caretOn && t > start - 0.2 ? 1 : 0)
                Spacer(minLength: 0)
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(Color.white.opacity(0.4))
                    .opacity(chrome)
            }
            .padding(.horizontal, isCompact ? 8 : 10)
            .frame(height: 24)
            .background(Color.white.opacity(0.07), in: Capsule())
            .overlay(Capsule().strokeBorder(Palette.ember.opacity(0.55 * focus), lineWidth: 1))
            .trailerGlint(M.progress(t, typingEnd + 0.15, 0.7), strength: 0.5)
        }
        .padding(.horizontal, 8 + 6 * CGFloat(chrome))
        .frame(height: 38)
    }
}

/// The repository on GitHub: a screenshot of the page (mobile layout, dark), scrolled from the repository
/// header down to the README's title and its live-preview link. The screenshot is `trailer/github.jpg`,
/// copied into the app's Documents by the record script; without it a plain stand-in is drawn.
private struct TrailerGitHubPage: View {
    let t: Double
    let width: CGFloat
    let shownAt: Double

    /// Where the scroll stops, as a fraction of the screenshot's height: the README's icon, title and the
    /// preview badge fill the window (the screenshot is 393 pt wide and 1610 pt tall; the icon starts
    /// ~860 pt down, the badge sits at ~1175 pt).
    static let stopFraction: CGFloat = 0.53

    var body: some View {
        if let image = TrailerGitHubShot.image {
            let height: CGFloat = width * image.size.height / max(image.size.width, 1)
            let p: Double = M.easeInOut(M.progress(t, shownAt + 0.25, TrailerOutroScene.condenseStart - shownAt - 0.65))
            Image(uiImage: image)
                .resizable()
                .interpolation(.high)
                .frame(width: width, height: height)
                .offset(y: -height * Self.stopFraction * CGFloat(p))
                .frame(width: width, alignment: .top)
        } else {
            VStack(spacing: 10) {
                Text(verbatim: "alanfeiyuchang / ios-anim-effects")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color(hex: 0x4493F8))
                Text(verbatim: "Motionary · 动效词典")
                    .font(.system(size: 20, weight: .heavy))
                    .foregroundStyle(Color.white)
            }
            .padding(.top, 40)
            .frame(width: width)
        }
    }
}

/// The GitHub screenshot from `Documents/trailer-github.jpg` (see `scripts/record-trailer.sh`), loaded once.
enum TrailerGitHubShot {
    static let image: UIImage? = {
        guard let folder = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return nil }
        return UIImage(contentsOfFile: folder.appendingPathComponent("trailer-github.jpg").path)
    }()
}

/// The documentation site: a header and a grid of recorded effects that keeps scrolling.
private struct TrailerWebPage: View {
    let t: Double
    let columns: Int

    private static let effects: [Effect] = {
        let all = EffectLibrary.all
        guard !all.isEmpty else { return [] }
        let step = max(all.count / 24, 1)
        return stride(from: 0, to: all.count, by: step).prefix(24).map { all[$0] }
    }()

    var body: some View {
        let local: Double = max(t - 81.2, 0)
        let scroll = CGFloat(22 * (local - (1 - exp(-2 * local)) / 2))
        let compact = columns < 4
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 5) {
                Text(verbatim: TrailerCopy.current.web.siteName)
                    .font(.system(size: compact ? 12 : 13, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color.white)
                    .lineLimit(1)
                    .layoutPriority(1)
                Text(verbatim: TrailerCopy.current.web.siteTagline)
                    .font(.system(size: compact ? 9.5 : 11, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.55))
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                Spacer(minLength: 0)
                Text(verbatim: TrailerCopy.current.web.countBadge)
                    .font(.system(size: compact ? 9.5 : 10.5, weight: .heavy).monospacedDigit())
                    .lineLimit(1)
                    .fixedSize()
                    .foregroundStyle(Palette.onAccent)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Palette.accentFill, in: Capsule())
            }
            // The grid scrolls inside its own clipped area, so it never slides over the header.
            grid
                .offset(y: -scroll)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .clipped()
        }
        .padding(.horizontal, compact ? 10 : 12)
        .padding(.top, 9)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private var grid: some View {
        let spacing: CGFloat = columns < 4 ? 7 : 8
        let items = Array(repeating: GridItem(.flexible(), spacing: spacing), count: max(columns, 1))
        return LazyVGrid(columns: items, spacing: spacing) {
            ForEach(Self.effects.indices, id: \.self) { index in
                tile(index)
            }
        }
        .drawingGroup()
    }

    private func tile(_ index: Int) -> some View {
        let effect = Self.effects[index]
        let pop: Double = M.spring(t, at: 80.4 + Double(index) * 0.035, response: 0.5, damping: 0.72)
        let colors = effect.category.gradient
        let bob = CGFloat(2 * sin(t * 2.2 + Double(index)))
        return VStack(spacing: 3) {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing))
                .aspectRatio(1, contentMode: .fit)
                .overlay {
                    Image(systemName: effect.category.symbol)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Color.white.opacity(0.92))
                        .offset(y: bob)
                }
                .overlay(alignment: .bottomTrailing) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 6, weight: .black))
                        .foregroundStyle(Color.white)
                        .frame(width: 14, height: 14)
                        .background(Color.black.opacity(0.35), in: Circle())
                        .padding(4)
                }
            Text(verbatim: effect.name.zh)
                .font(.system(size: 8, weight: .semibold))
                .foregroundStyle(Color.white.opacity(0.7))
                .lineLimit(1)
        }
        .scaleEffect(CGFloat(0.7 + 0.3 * pop))
        .opacity(M.clamp(pop * 2.5))
    }
}

// MARK: - 88–93 s (source) · End card: app icon + Motionary – 动效词典

struct TrailerEndScene: View {
    let t: Double

    static let iconSide: CGFloat = TrailerCanvas.pick(132, 150)
    static let iconCenter = TrailerCanvas.point(195, 188, 262)

    var body: some View {
        let condense: Double = TrailerOutroScene.condense(t)
        let side = Self.iconSide
        let start: Double = TrailerOutroScene.condenseStart
        let float = CGFloat(2 * sin((t - start - 2.15) * 1.3) * M.progress(t, start + 2.15, 0.8))
        let iconIn: Double = M.progress(condense, 0.3, 0.35)
        let path: CGPoint = M.mix(TrailerOutroScene.githubCenter, Self.iconCenter, condense)
        ZStack {
            // Always a true square: it only grows uniformly while cross-fading over the morphing window.
            TrailerAppIcon(t: t, side: side, popAt: start + 0.6, glintAt: start + 1.5)
                .scaleEffect(CGFloat(0.86 + 0.14 * M.easeOut(iconIn)))
                .shadow(color: Palette.ember.opacity(0.45 * M.clamp(condense)), radius: 34, x: 0, y: 10)
                .opacity(iconIn)
                .position(x: path.x, y: path.y + float)
            Text(verbatim: TrailerCopy.current.end.title)
                .font(.system(size: TrailerCanvas.pick(44, 50), weight: .heavy, design: .rounded))
                .foregroundStyle(Color.white)
                .lineLimit(1)
                .minimumScaleFactor(0.45)
                .textRenderer(GlyphBlurRenderer(progress: M.progress(t, start + 0.9, 0.8)))
                .frame(width: 360)
                .shadow(color: Color.black.opacity(0.4), radius: 12, x: 0, y: 4)
                .position(x: 195, y: TrailerCanvas.pick(300, 394))
            Text(verbatim: TrailerCopy.current.end.subtitle)
                .font(.system(size: TrailerCanvas.pick(17, 18), weight: .semibold))
                .tracking(1)
                .foregroundStyle(TrailerStyle.emberText)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .textRenderer(GlyphBlurRenderer(progress: M.progress(t, start + 1.2, 0.8)))
                .frame(width: 360)
                .position(x: 195, y: TrailerCanvas.pick(344, 444))
            Text(verbatim: TrailerCopy.current.end.tagline)
                .font(.system(size: TrailerCanvas.pick(13, 14), weight: .medium))
                .foregroundStyle(Color.white.opacity(0.55))
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .frame(width: 360)
                .opacity(M.easeOut(M.progress(t, start + 1.55, 0.7)))
                .offset(y: CGFloat(1 - M.easeOut(M.progress(t, start + 1.55, 0.7))) * 8)
                .position(x: 195, y: TrailerCanvas.pick(382, 486))
            if let upcoming = TrailerCopy.optional(TrailerCopy.current.end.upcoming) {
                let pop: Double = M.spring(t, at: start + 2.0, response: 0.5, damping: 0.72)
                HStack(spacing: 5) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 11, weight: .bold))
                    Text(verbatim: upcoming)
                        .font(.system(size: TrailerCanvas.pick(12, 13), weight: .bold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                }
                .foregroundStyle(Palette.accent)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Palette.ember.opacity(0.14), in: Capsule())
                .overlay(Capsule().strokeBorder(Palette.ember.opacity(0.45), lineWidth: 0.75))
                .frame(maxWidth: 300)
                .scaleEffect(CGFloat(0.85 + 0.15 * pop))
                .opacity(M.clamp(pop * 1.6))
                .position(x: 195, y: TrailerCanvas.pick(414, 524))
            }
        }
        .frame(width: TrailerCanvas.width, height: TrailerCanvas.height)
    }
}
