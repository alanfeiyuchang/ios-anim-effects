import SwiftUI

extension Effect {
    static let textNumericCounter = Effect(
        id: "text.numeric-counter",
        category: .text,
        interaction: .tap,
        name: L("Numeric Counter", "数字滚动"),
        summary: L("A hero figure whose digits roll up or down into place.", "核心数字逐位上下滚动，平滑过渡到新数值。"),
        prompt: L(
            "A large, rounded-semibold balance figure with tabular digits sits in a floating card, above a small delta pill. When the value changes, only the digits that differ roll vertically: they slide up and fade when the number increases, down when it decreases, while unchanged digits stay perfectly still. Each column moves on a gentle spring (≈0.6 s, bounce 0.15) and the width re-flows smoothly as the digit count changes. The delta pill flips its arrow and tints green or red in the same beat, with a light selection haptic — precise, calm, finance-grade.",
            "悬浮卡片中央是一组大号圆体半粗数字，使用等宽数字，下方配一枚涨跌幅小胶囊。数值变化时，只有发生变化的数位会纵向滚动：数值增大时新数字自下而上滑入并淡入，减小时方向相反，未变化的数位纹丝不动。每一列都以轻柔弹簧（约 0.6 秒、弹性 0.15）过渡，位数变化时整体宽度平滑重排。涨跌胶囊同步切换箭头方向并变为绿或红，伴随一次轻微选择触感——精准、克制，有金融级的质感。"
        ),
        implementation: L(
            "Text with .contentTransition(.numericText(value:)) and .monospacedDigit(); the value changes inside withAnimation(.spring(duration:bounce:)).",
            "为 Text 设置 .contentTransition(.numericText(value:)) 与 .monospacedDigit()，在 withAnimation(.spring(duration:bounce:)) 中修改数值。"
        ),
        apis: ["contentTransition(.numericText(value:))", "monospacedDigit()", "spring(duration:bounce:)", "symbolEffect(.replace)"],
        tags: ["counter", "number", "price", "odometer", "数字", "计数器", "价格", "滚动数字"],
        params: [
            .slider("duration", L("Spring duration", "弹簧时长"), 0.2...1.2, default: 0.6, unit: "s"),
            .slider("bounce", L("Bounce", "弹性"), 0...0.4, default: 0.15),
            .choice("style", L("Content", "内容"), [L("Balance", "余额"), L("Followers", "粉丝数")], default: 0),
        ]
    ) { ctx in
        NumericCounterDemo(ctx: ctx)
    }
}

private struct NumericCounterDemo: View {
    let ctx: DemoContext
    @State private var balance: Double = 12_480.50
    @State private var followers: Double = 48_210
    @State private var lastDelta: Double = 1_204.10

    private var isFollowers: Bool { ctx.int("style") == 1 }
    private var value: Double { isFollowers ? followers : balance }

    var body: some View {
        VStack(spacing: 22) {
            card
            HStack(spacing: 14) {
                StepButton(symbol: "minus") { bump(up: false) }
                StepButton(symbol: "plus") { bump(up: true) }
            }
            DemoHint(text: L("Tap + or −", "点击 + 或 −"), ctx: ctx)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 1.5) { bump(up: Int.random(in: 0..<4) != 0) }
    }

    private var card: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(isFollowers ? L("Followers", "粉丝") : L("Total balance", "账户余额"), ctx.language)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
            Text(formatted)
                .font(.system(size: 44, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .contentTransition(.numericText(value: value))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            DeltaPill(text: deltaText, isUp: lastDelta >= 0)
        }
        .padding(22)
        .frame(width: 284, alignment: .leading)
        .demoCard(cornerRadius: 26)
    }

    private var formatted: String {
        if isFollowers {
            return Int(followers).formatted(.number)
        }
        let symbol = ctx.language == .zh ? "¥" : "$"
        return symbol + balance.formatted(.number.precision(.fractionLength(2)))
    }

    private var deltaText: String {
        let magnitude = abs(lastDelta)
        let sign = lastDelta >= 0 ? "+" : "−"
        if isFollowers {
            return sign + Int(magnitude).formatted(.number)
        }
        return sign + magnitude.formatted(.number.precision(.fractionLength(2)))
    }

    private func bump(up: Bool) {
        let direction: Double = up ? 1 : -1
        let delta: Double
        if isFollowers {
            delta = direction * Double(Int.random(in: 12...480))
        } else {
            delta = direction * (Double(Int.random(in: 1_200...240_000)) / 100)
        }
        withAnimation(.spring(duration: ctx["duration"], bounce: ctx["bounce"])) {
            lastDelta = delta
            if isFollowers {
                followers = max(0, followers + delta)
            } else {
                balance = max(0, balance + delta)
            }
        }
        if !ctx.isPreview { Haptics.selection() }
    }
}

private struct DeltaPill: View {
    let text: String
    let isUp: Bool

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: isUp ? "arrow.up.right" : "arrow.down.right")
                .font(.caption.weight(.bold))
                .contentTransition(.symbolEffect(.replace))
            Text(text)
                .font(.subheadline.weight(.semibold))
                .monospacedDigit()
                .contentTransition(.numericText())
        }
        .foregroundStyle(isUp ? Palette.green : Palette.red)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background((isUp ? Palette.green : Palette.red).opacity(0.14), in: Capsule())
    }
}

private struct StepButton: View {
    let symbol: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.title3.weight(.semibold))
                .foregroundStyle(.primary)
                .frame(width: 56, height: 56)
                .background(.regularMaterial, in: Circle())
                .overlay(Circle().strokeBorder(Palette.stroke))
        }
        .buttonStyle(.plain)
    }
}
