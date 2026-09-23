import SwiftUI

extension Effect {
    static let buttonsApproveStamp = Effect(
        id: "buttons.approve-stamp",
        category: .buttons,
        interaction: .tap,
        name: L("Rubber Stamp", "印章确认"),
        summary: L("Approve slams an inked stamp onto the document, which jolts on impact.", "点击批准，一枚印章重重盖在单据上，纸面随冲击一震。"),
        prompt: L(
            "An expense report card (merchant, amount, date) with a wide green \"Approve\" button in its footer. On tap a rubber stamp reading \"APPROVED\" — 3 pt rounded border, heavy rounded caps, rotated −12° — falls onto the card from 220% scale, 6 pt blur and zero opacity to 100% in 180 ms on an accelerating ease-in, with no overshoot, like real weight. On impact the card jolts (3 pt down, 1 pt back up, settle in ~200 ms), six tiny ink specks splash outward and fade, and a rigid haptic thuds. The button then morphs into a quiet grey \"Approved ✓\" pill with an Undo affordance; tapping it lifts the stamp away — it grows, blurs and fades in 0.25 s. Decisive, official and satisfying.",
            "一张报销单卡片（商户、金额、日期），底部是一枚宽大的绿色“批准”按钮。点击后，一枚写着“APPROVED / 已批准”的橡皮印章——3pt 圆角边框、粗壮的圆体大字、旋转 −12°——从 220% 缩放、6pt 模糊、零透明度，以加速的 ease-in 在 180 毫秒内落到 100%，没有任何过冲，像真实的重量砸下。落下瞬间卡片一震（下沉 3pt、回弹 1pt，约 200 毫秒内稳住），六颗细小的墨点向外溅开并淡出，同时一次硬朗的触感“咚”地落下。随后按钮形变为低调的灰色“已批准 ✓”胶囊，并提供撤销；点击它，印章被抬起移走——0.25 秒内放大、模糊并淡出。果断、正式、令人满足。"
        ),
        implementation: L(
            "The stamp's scale, blur and opacity animate with a 0.18 s easeIn keyed on the approved flag; a keyframeAnimator on an impact counter holds for the fall time, then jolts the card and throws the ink specks. The footer swaps pills with a blurReplace transition.",
            "印章的缩放、模糊与透明度以 0.18 秒 easeIn 动画，由批准状态驱动；以冲击计数触发的 keyframeAnimator 先等待下落时长，再让卡片一震并甩出墨点。底部按钮通过 blurReplace 过渡切换。"
        ),
        apis: ["easeIn(duration:)", "keyframeAnimator", "blur(radius:)", "transition(.blurReplace)", "rotationEffect"],
        tags: ["stamp", "approve", "confirm", "impact", "印章", "批准", "确认", "冲击"],
        params: [
            .slider("fall", L("Fall time", "下落时长"), 0.1...0.4, default: 0.18, unit: "s"),
            .slider("start", L("Start scale", "起始缩放"), 1.4...3.0, default: 2.2),
            .slider("jolt", L("Impact jolt", "冲击震动"), 0...8, default: 3, decimals: 0, unit: "pt"),
        ]
    ) { ctx in
        ButtonApproveStampDemo(ctx: ctx)
    }
}

private struct ButtonStampImpact {
    var jolt: CGFloat = 0
    var splash: CGFloat = 0
}

private struct ButtonApproveStampDemo: View {
    let ctx: DemoContext
    @State private var approved = false
    @State private var impacts = 0

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            card
            Spacer()
            DemoHint(text: L("Tap Approve", "点击批准"), ctx: ctx)
                .padding(.bottom, 18)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 1.8, delay: 0.4) { toggle() }
    }

    private var card: some View {
        let fall = ctx["fall"]
        let jolt = ctx.cg("jolt")
        return VStack(alignment: .leading, spacing: 16) {
            receipt
            footer
        }
        .padding(18)
        .frame(width: 290)
        .demoCard(cornerRadius: 22)
        .keyframeAnimator(initialValue: ButtonStampImpact(), trigger: impacts) { content, impact in
            content
                .overlay { stamp(splash: impact.splash) }
                .offset(y: impact.jolt)
        } keyframes: { _ in
            KeyframeTrack(\.jolt) {
                LinearKeyframe(0, duration: fall)
                CubicKeyframe(jolt, duration: 0.05)
                CubicKeyframe(-jolt / 3, duration: 0.08)
                SpringKeyframe(0, duration: 0.12, spring: .snappy)
            }
            KeyframeTrack(\.splash) {
                LinearKeyframe(0, duration: fall)
                CubicKeyframe(1, duration: 0.45)
            }
        }
    }

    private var receipt: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "airplane")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Palette.sky)
                    .frame(width: 34, height: 34)
                    .background(Palette.sky.opacity(0.14), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                VStack(alignment: .leading, spacing: 2) {
                    Text(L("Flight to Lisbon", "飞往里斯本的机票"), ctx.language)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                    Text(L("Mar 14 · Design offsite", "3 月 14 日 · 设计团建"), ctx.language)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
            }
            Divider()
            HStack(alignment: .firstTextBaseline) {
                Text(L("Total", "合计"), ctx.language)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer(minLength: 0)
                Text(verbatim: "€ 428.60")
                    .font(.system(.title2, design: .rounded).weight(.bold).monospacedDigit())
                    .foregroundStyle(.primary)
            }
        }
    }

    private var footer: some View {
        Button(action: toggle) {
            ZStack {
                if approved {
                    Label(ctx.language == .zh ? "已批准 · 撤销" : "Approved · Undo", systemImage: "checkmark")
                        .foregroundStyle(.secondary)
                        .transition(.blurReplace)
                } else {
                    Label(ctx.language == .zh ? "批准" : "Approve", systemImage: "signature")
                        .foregroundStyle(.white)
                        .transition(.blurReplace)
                }
            }
            .font(.headline)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(approved ? AnyShapeStyle(Color.primary.opacity(0.07)) : AnyShapeStyle(Palette.successStrong))
            }
        }
        .buttonStyle(SportPressStyle(scale: 0.97, dim: 0.05))
    }

    private func stamp(splash: CGFloat) -> some View {
        let start = ctx.cg("start")
        return ZStack {
            ButtonStampSpecks(progress: splash)
            Text(L("APPROVED", "已批准"), ctx.language)
                .font(.system(size: 26, weight: .black, design: .rounded))
                .tracking(ctx.language == .zh ? 6 : 2)
                .foregroundStyle(Palette.green)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .strokeBorder(Palette.green, lineWidth: 3)
                )
                .opacity(0.88)
        }
        .rotationEffect(.degrees(-12))
        .scaleEffect(approved ? 1 : start)
        .blur(radius: approved ? 0 : 6)
        .opacity(approved ? 1 : 0)
        .offset(x: 40, y: -24)
        .allowsHitTesting(false)
    }

    private func toggle() {
        if approved {
            withAnimation(.easeOut(duration: 0.25)) { approved = false }
            Haptics.tap()
            return
        }
        withAnimation(.easeIn(duration: ctx["fall"])) { approved = true }
        impacts += 1
        let muted = Haptics.isMuted
        let fall = ctx["fall"]
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(fall))
            if !muted { Haptics.tap(.rigid) }
        }
    }
}

private struct ButtonStampSpecks: View {
    let progress: CGFloat

    var body: some View {
        ZStack {
            ForEach(0..<6, id: \.self) { index in
                speck(index)
            }
        }
        .opacity(progress > 0.001 && progress < 0.999 ? Double(1 - progress) : 0)
    }

    private func speck(_ index: Int) -> some View {
        let angle = Double(index) * 60 + 18
        let radians = angle * Double.pi / 180
        let distance = 60 + 30 * progress
        let size = CGFloat(3 + index % 3)
        return Circle()
            .fill(Palette.green)
            .frame(width: size, height: size)
            .offset(x: CGFloat(cos(radians)) * distance, y: CGFloat(sin(radians)) * distance * 0.6)
    }
}
