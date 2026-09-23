import SwiftUI

extension Effect {
    static let inputsPasswordStrength = Effect(
        id: "inputs.password-strength",
        category: .inputs,
        interaction: .state,
        name: L("Password Strength Meter", "密码强度指示"),
        summary: L("Segments fill and shift from red to green as rules tick off.", "随着规则逐项达成，分段条填充并由红转绿。"),
        prompt: L(
            "A password field on a card, followed by a four-segment strength meter and a checklist of rules (8+ characters, uppercase, number, symbol). As the user types, each satisfied rule's empty circle morphs into a filled green checkmark with a symbol replace transition. The meter fills segment by segment from the left — each segment grows horizontally from its leading edge with a 40 ms stagger on a spring (response 0.4 s, damping 0.75) — and all filled segments share one color that shifts red → orange → amber → green as the score rises. The strength word (Weak / Fair / Good / Strong) crossfades with a subtle upward slide. Encouraging, informative and never scolding.",
            "卡片上方是密码输入框，下方是四段式强度条和一份规则清单（8 位以上、大写字母、数字、符号）。用户输入时，每满足一条规则，其空心圆就以符号替换过渡变为实心绿色对勾。强度条从左往右逐段填充——每段从左边缘横向生长，以 40 毫秒错峰、弹簧（响应 0.4 秒、阻尼 0.75）驱动——所有已填充段共享同一颜色，随分数升高由红 → 橙 → 琥珀 → 绿过渡。强度文字（弱 / 一般 / 良好 / 很强）伴随轻微上移交叉淡入。积极、信息清晰，从不责备用户。"
        ),
        implementation: L(
            "A score derived from simple character-class checks drives per-segment scaleEffect(x:anchor: .leading) with staggered animation(_:value:), a shared color, and contentTransition(.symbolEffect(.replace)) on the rule icons.",
            "由字符类别检查得出分数，驱动每段的 scaleEffect(x:anchor: .leading) 与错峰 animation(_:value:)、统一颜色，以及规则图标的 contentTransition(.symbolEffect(.replace))。"
        ),
        apis: ["SecureField", "scaleEffect(x:anchor:)", "contentTransition(.symbolEffect(.replace))", "animation(_:value:)"],
        tags: ["password", "strength", "meter", "validation", "密码", "强度", "校验", "表单"],
        params: [
            .slider("stagger", L("Segment stagger", "分段错峰"), 0...0.15, default: 0.04, unit: "s"),
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

    private static let samples = ["", "moon", "moonlight", "Moonlight7", "Moonlight7!"]

    private var rules: [(LocalizedText, Bool)] {
        [
            (L("8+ characters", "至少 8 位"), password.count >= 8),
            (L("Uppercase letter", "包含大写字母"), password.contains(where: \.isUppercase)),
            (L("Number", "包含数字"), password.contains(where: \.isNumber)),
            (L("Symbol", "包含符号"), password.contains { !$0.isLetter && !$0.isNumber && !$0.isWhitespace }),
        ]
    }

    private var score: Int {
        guard !password.isEmpty else { return 0 }
        return max(1, rules.filter { $0.1 }.count)
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            VStack(alignment: .leading, spacing: 16) {
                field
                InputStrengthMeter(score: score, stagger: ctx["stagger"], language: ctx.language)
                checklist
            }
            .padding(20)
            .frame(width: 300)
            .demoCard()
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
    let stagger: Double
    let language: AppLanguage

    private var color: Color {
        switch score {
        case 1: return Palette.red
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
                    .transition(.opacity.combined(with: .offset(y: 6)))
            }
            .animation(.easeOut(duration: 0.25), value: score)
        }
    }

    private func segment(_ index: Int) -> some View {
        let filled = index < score
        return ZStack(alignment: .leading) {
            Capsule().fill(Color.primary.opacity(0.08))
            Capsule()
                .fill(color)
                .scaleEffect(x: filled ? 1 : 0.001, anchor: .leading)
                .opacity(filled ? 1 : 0)
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.75).delay(Double(index) * stagger), value: score)
    }
}
