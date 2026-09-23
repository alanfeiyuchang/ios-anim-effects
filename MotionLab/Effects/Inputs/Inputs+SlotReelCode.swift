import SwiftUI

extension Effect {
    static let inputsSlotReelCode = Effect(
        id: "inputs.slot-reel-code",
        category: .inputs,
        interaction: .tap,
        name: L("Slot-Reel AutoFill", "老虎机式验证码填充"),
        summary: L("Tapping the AutoFill suggestion spins every box like a slot reel until the code lands.", "点击自动填充建议后，每个格子像老虎机一样转动，直到停在验证码上。"),
        prompt: L(
            "Six 42 × 54 pt code boxes above an iOS-style AutoFill suggestion pill (\"From Messages · 482 913\"). Tapping the pill morphs it into a small Reset chip and sets each box spinning like a slot-machine reel: a column of digits scrolls upward through two full cycles and lands on its target digit on a spring (response 0.6 s, damping 0.78) that slightly overshoots and settles. Reels stop left to right with a 110 ms stagger, each landing with a selection haptic, a bouncy pop from 97% to full size and a thicker indigo border. When the last reel settles, the borders sweep from grey to green one after another and a success haptic confirms the code. Top and bottom edges of each box fade the passing digits so the reels read as curved drums. Delightful, and it makes an invisible autofill feel earned.",
            "六个 42 × 54pt 验证码格子，下方是 iOS 风格的自动填充建议胶囊（“来自信息 · 482 913”）。点击胶囊后它收成一个小“重置”按钮，每个格子像老虎机转轮一样旋转：一列数字向上滚过两整圈，再以弹簧（响应 0.6 秒、阻尼 0.78）停在目标数字上，略微过冲后回稳。转轮从左到右以 110 毫秒错峰停下，每停稳一格触发选择触觉，格子从 97% 弹回原大，边框加粗变靛蓝。全部停稳后边框依次由灰扫成绿，并以成功触觉确认。格子上下缘淡化经过的数字，像弯曲的滚筒。"
        ),
        implementation: L(
            "Each box clips a VStack of repeated digits and animates its y-offset to (cycles × 10 + digit) rows with a per-index delayed spring; resetting jumps back to row 0 inside a transaction with animations disabled. A gradient mask fades the edges.",
            "每个格子裁剪一列重复数字的 VStack，并以按索引延迟的弹簧把 y 偏移动画到（圈数 × 10 + 目标数字）行；重置时在禁用动画的事务中跳回第 0 行。渐变遮罩淡化上下边缘。"
        ),
        apis: ["offset(y:)", "spring(response:dampingFraction:).delay", "mask", "Transaction", "clipped"],
        tags: ["otp", "autofill", "slot machine", "reel", "验证码", "自动填充", "老虎机", "滚动"],
        params: [
            .slider("stagger", L("Reel stagger", "转轮错峰"), 0...0.25, default: 0.11, unit: "s"),
            .slider("cycles", L("Spin cycles", "旋转圈数"), 1...4, default: 2, step: 1, decimals: 0),
            .slider("damping", L("Landing damping", "停止阻尼"), 0.4...1.0, default: 0.78),
        ]
    ) { ctx in
        SlotReelCodeDemo(ctx: ctx)
    }
}

private struct SlotReelCodeDemo: View {
    let ctx: DemoContext
    @State private var rows: [Int] = Array(repeating: 0, count: 6)
    @State private var landed: [Bool] = Array(repeating: false, count: 6)
    @State private var verified = false
    @State private var spinning = false
    @State private var runID = 0

    private let digits: [Int] = [4, 8, 2, 9, 1, 3]
    private let boxSize = CGSize(width: 42, height: 54)
    private var cycles: Int { max(ctx.int("cycles"), 1) }

    var body: some View {
        VStack(spacing: 28) {
            Spacer(minLength: 0)
            VStack(spacing: 6) {
                Text(L("Enter the code", "输入验证码"), ctx.language)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text(L("Sent to +1 ••• ••• 0142", "已发送至 +86 ••• •••• 0142"), ctx.language)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            HStack(spacing: 7) {
                ForEach(0..<6, id: \.self) { index in
                    reel(index)
                }
            }
            suggestion
            Spacer(minLength: 0)
            DemoHint(text: L("Tap the AutoFill suggestion", "点击自动填充建议"), ctx: ctx)
                .padding(.bottom, 14)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onChange(of: cycles) { _, _ in reset() }
        .autoplay(ctx.isPreview, every: 3.2, delay: 0.4) { spinOrReset() }
    }

    private var suggestion: some View {
        Button {
            spinOrReset()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: spinning || verified ? "arrow.counterclockwise" : "message.fill")
                    .foregroundStyle(Palette.green)
                    .contentTransition(.symbolEffect(.replace))
                if spinning || verified {
                    Text(L("Reset", "重置"), ctx.language)
                } else {
                    Text(L("From Messages · 482 913", "来自信息 · 482 913"), ctx.language)
                }
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.primary)
            .padding(.horizontal, 16)
            .frame(height: 40)
            .background(Palette.elevated, in: Capsule())
            .overlay(Capsule().strokeBorder(Palette.stroke))
            .shadow(color: .black.opacity(0.08), radius: 8, y: 4)
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: spinning || verified)
    }

    private func reel(_ index: Int) -> some View {
        let rowCount = (cycles + 1) * 10
        let shape = RoundedRectangle(cornerRadius: 12, style: .continuous)
        let isLanded = landed[index]
        let border: Color = verified ? Palette.green : (isLanded ? Palette.indigo : Color.primary.opacity(0.15))
        let sweepDelay = Double(index) * 0.05
        return VStack(spacing: 0) {
            ForEach(0..<rowCount, id: \.self) { row in
                Text("\(row % 10)")
                    .font(.system(size: 26, weight: .semibold, design: .rounded).monospacedDigit())
                    .foregroundStyle(.primary)
                    .frame(width: boxSize.width, height: boxSize.height)
            }
        }
        .offset(y: -CGFloat(rows[index]) * boxSize.height)
        .animation(reelSpring(index), value: rows[index])
        .frame(width: boxSize.width, height: boxSize.height, alignment: .top)
        .clipped()
        .mask {
            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0),
                    .init(color: .black, location: 0.25),
                    .init(color: .black, location: 0.75),
                    .init(color: .clear, location: 1),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .opacity(isLanded ? 0 : 1)
            .background(isLanded ? Color.black : Color.clear)
        }
        .background(Palette.elevated, in: shape)
        .overlay(shape.strokeBorder(border, lineWidth: isLanded ? 2 : 1))
        .scaleEffect(isLanded ? 1 : 0.97)
        .animation(.spring(response: 0.25, dampingFraction: 0.5), value: isLanded)
        .animation(.easeOut(duration: 0.25).delay(verified ? sweepDelay : 0), value: verified)
    }

    /// Each reel carries its own delayed spring so they stop left to right.
    private func reelSpring(_ index: Int) -> Animation {
        let delay: Double = Double(index) * ctx["stagger"]
        return .spring(response: 0.6 + delay * 0.4, dampingFraction: ctx["damping"]).delay(delay)
    }

    private func spinOrReset() {
        if spinning || verified {
            reset()
        } else {
            spin()
        }
    }

    private func spin() {
        runID += 1
        let id = runID
        spinning = true
        let stagger = ctx["stagger"]
        // Simulated spins (previews, the detail intro) stay silent; captured before the first await.
        let muted = ctx.isPreview || Haptics.isMuted
        rows = digits.map { cycles * 10 + $0 }
        Task {
            var elapsed: Double = 0
            for index in 0..<6 {
                // Same numbers as reelSpring: the reel reads as settled at ~80% of its spring response.
                let delay = Double(index) * stagger
                let settle = delay + (0.6 + delay * 0.4) * 0.8
                try? await Task.sleep(for: .seconds(max(settle - elapsed, 0)))
                elapsed = max(settle, elapsed)
                guard id == runID else { return }
                landed[index] = true
                if !muted { Haptics.selection() }
            }
            try? await Task.sleep(for: .seconds(0.3))
            guard id == runID else { return }
            spinning = false
            verified = true
            if !muted { Haptics.success() }
        }
    }

    private func reset() {
        runID += 1
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            rows = Array(repeating: 0, count: 6)
        }
        landed = Array(repeating: false, count: 6)
        verified = false
        spinning = false
    }
}
