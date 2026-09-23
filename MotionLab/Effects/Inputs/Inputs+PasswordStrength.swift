import SwiftUI

extension Effect {
    static let inputsPasswordStrength = Effect(
        id: "inputs.password-strength",
        category: .inputs,
        interaction: .state,
        name: L("Password Strength Meter", "密码强度指示"),
        summary: L("Segments fill and shift from red to green as rules tick off.", "随着规则逐项达成，分段条填充并由红转绿。"),
        prompt: L(
            "A password field on a card, followed by a four-segment strength meter and a checklist of rules (8+ characters, uppercase, number, symbol). As the user types, each satisfied rule's empty circle morphs into a filled green checkmark with a symbol replace transition. Newly earned segments grow from their leading edge left to right with a 40 ms stagger on a spring (response 0.4 s, damping 0.75); when the score drops they retract in reverse, rightmost first. All filled segments share one color that shifts red → orange → amber → green immediately, with no stagger. The strength word (Weak / Fair / Good / Strong) moves like a ticker: the old word fades out upward while the new one rises in from 6 pt below. Encouraging, informative and never scolding.",
            "卡片上方是密码输入框，下方是四段式强度条与规则清单（8 位以上、大写字母、数字、符号）。输入时，每满足一条规则，空心圆就经符号替换变为实心绿对勾。新得的分段从左缘横向生长，从左到右以 40 毫秒错峰、弹簧（响应 0.4 秒、阻尼 0.75）驱动；分数下降时倒序收回，最右先退。已填充段共享同一颜色，红 → 橙 → 琥珀 → 绿即时切换、不错峰。强度文字（弱 / 一般 / 良好 / 很强）像滚动字幕：旧词向上淡出，新词从下方 6pt 升入。积极而不责备。"
        ),
        implementation: L(
            "The score and the previous score are stored together on each edit, so every segment's scaleEffect(x:anchor: .leading) delay can be ordered by direction; the colour sits under its own undelayed animation, the label uses an asymmetric transition, and rule icons use contentTransition(.symbolEffect(.replace)).",
            "每次输入同时记录新旧分数，据此按方向计算每段 scaleEffect(x:anchor: .leading) 的错峰延迟；颜色使用单独的无延迟动画，强度文字使用非对称转场，规则图标使用 contentTransition(.symbolEffect(.replace))。"
        ),
        apis: ["SecureField", "scaleEffect(x:anchor:)", "contentTransition(.symbolEffect(.replace))", "animation(_:value:)"],
        tags: ["password", "strength", "meter", "validation", "密码", "强度", "校验", "表单"],
        params: [
            .slider("stagger", L("Segment stagger", "分段错峰"), 0...0.15, default: 0.04, unit: "s"),
            .slider("response", L("Segment spring response", "分段弹簧响应"), 0.2...0.8, default: 0.4, unit: "s"),
            .toggle("mask", L("Mask input", "隐藏输入"), default: false),
        ]
    ) { ctx in
        InputPasswordStrengthDemo(ctx: ctx)
    }
}

private struct InputPasswordStrengthDemo: View {
    let ctx: DemoContext
    @State private var password = ""
    @State private var step = 0
    /// Stored (with the previous value) so the meter knows which way to stagger.
    @State private var score = 0
    @State private var previousScore = 0

    private static let samples = ["", "moon", "moonlight", "Moonlight7", "Moonlight7!"]

    private var rules: [(LocalizedText, Bool)] { Self.rules(for: password) }

    private static func rules(for password: String) -> [(LocalizedText, Bool)] {
        [
            (L("8+ characters", "至少 8 位"), password.count >= 8),
            (L("Uppercase letter", "包含大写字母"), password.contains(where: \.isUppercase)),
            (L("Number", "包含数字"), password.contains(where: \.isNumber)),
            (L("Symbol", "包含符号"), password.contains { !$0.isLetter && !$0.isNumber && !$0.isWhitespace }),
        ]
    }

    private static func score(for password: String) -> Int {
        guard !password.isEmpty else { return 0 }
        return max(1, rules(for: password).filter { $0.1 }.count)
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            VStack(alignment: .leading, spacing: 16) {
                field
                InputStrengthMeter(
                    score: score,
                    previousScore: previousScore,
                    stagger: ctx["stagger"],
                    response: ctx["response"],
                    language: ctx.language
                )
                checklist
            }
            .padding(20)
            .frame(width: 300)
            .demoCard()
            Spacer()
            DemoHint(text: L("Type a password — try adding A, 7 and !", "输入密码——试着加上大写、数字和符号"), ctx: ctx)
                .padding(.bottom, 18)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onChange(of: password) { _, newValue in
            let next = Self.score(for: newValue)
            guard next != score else { return }
            previousScore = score
            score = next
        }
        .autoplay(ctx.isPreview, every: 1.1, delay: 0.4) { previewTick() }
    }

    private var field: some View {
        HStack(spacing: 10) {
            Image(systemName: "lock.fill")
                .foregroundStyle(.secondary)
            Group {
                if ctx.bool("mask") {
                    SecureField(ctx.language == .zh ? "设置密码" : "Create password", text: $password)
                } else {
                    TextField(ctx.language == .zh ? "设置密码" : "Create password", text: $password)
                }
            }
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .font(.body.weight(.medium))
        }
        .padding(.horizontal, 14)
        .frame(height: 48)
        .background(Color.primary.opacity(0.05), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var checklist: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(rules.indices, id: \.self) { index in
                let rule = rules[index]
                HStack(spacing: 8) {
                    Image(systemName: rule.1 ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(rule.1 ? Palette.green : Color.secondary)
                        .contentTransition(.symbolEffect(.replace))
                    Text(rule.0, ctx.language)
                        .foregroundStyle(rule.1 ? Color.primary : Color.secondary)
                }
                .font(.footnote.weight(.medium))
                .animation(.spring(response: 0.35, dampingFraction: 0.7), value: rule.1)
            }
        }
    }

    private func previewTick() {
        step += 1
        password = Self.samples[step % Self.samples.count]
    }
}

private struct InputStrengthMeter: View {
    let score: Int
    let previousScore: Int
    let stagger: Double
    let response: Double
    let language: AppLanguage

    private var color: Color {
        switch score {
        case 0, 1: return Palette.red
        case 2: return Palette.coral
        case 3: return Palette.amber
        default: return Palette.green
        }
    }

    private var label: LocalizedText {
        switch score {
        case 0: return L("Enter a password", "请输入密码")
        case 1: return L("Weak", "弱")
        case 2: return L("Fair", "一般")
        case 3: return L("Good", "良好")
        default: return L("Strong", "很强")
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                ForEach(0..<4, id: \.self) { index in
                    segment(index)
                }
            }
            .frame(height: 6)
            ZStack(alignment: .leading) {
                Text(label, language)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(score == 0 ? Color.secondary : color)
                    .id(score)
                    .transition(
                        .asymmetric(
                            insertion: .opacity.combined(with: .offset(y: 6)),
                            removal: .opacity.combined(with: .offset(y: -6))
                        )
                    )
            }
            .animation(.easeOut(duration: 0.25), value: score)
        }
    }

    /// Rising: only newly earned segments stagger, left to right. Falling: retract right to left.
    private func delay(for index: Int) -> Double {
        if score >= previousScore {
            return index >= previousScore ? Double(index - previousScore) * stagger : 0
        }
        return index < previousScore ? Double(previousScore - 1 - index) * stagger : 0
    }

    private func segment(_ index: Int) -> some View {
        let filled = index < score
        return ZStack(alignment: .leading) {
            Capsule().fill(Color.primary.opacity(0.08))
            Capsule()
                .fill(color)
                // Colour shifts together, immediately (inner animation wins for the fill).
                .animation(.easeOut(duration: 0.2), value: score)
                .scaleEffect(x: filled ? 1 : 0.001, anchor: .leading)
                .opacity(filled ? 1 : 0)
        }
        .animation(.spring(response: response, dampingFraction: 0.75).delay(delay(for: index)), value: score)
    }
}
