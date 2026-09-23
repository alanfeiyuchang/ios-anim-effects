import SwiftUI

extension Effect {
    static let textRotatingWords = Effect(
        id: "text.rotating-words",
        category: .text,
        interaction: .loop,
        name: L("Rotating Words", "轮播关键词"),
        summary: L("A keyword slot swaps vertically with blur while the pill resizes.", "关键词在槽位中纵向切换并带模糊，底部胶囊随之伸缩。"),
        prompt: L(
            "A landing-page headline keeps its first line fixed while the keyword below cycles every ~2 s inside a softly tinted pill. The outgoing word slides up about 34 pt, blurs to 8 pt and fades; the incoming word rises from 34 pt below, un-blurring into focus, both on a spring (≈0.55 s, bounce 0.25) so they overlap for a moment like a slot reel. The pill's width re-flows smoothly to fit each new word and its gradient tint shifts hue, giving the headline a confident, living rhythm without ever feeling busy.",
            "落地页标题第一行保持不动，下方的关键词每隔约2秒在一枚淡色胶囊中轮换。旧词向上滑出约34pt，同时模糊至8pt并淡出；新词从下方34pt处升起，由模糊逐渐对焦清晰，二者都使用弹簧曲线（约0.55秒、弹性0.25），短暂重叠，宛如老虎机的转轴。胶囊宽度随新词平滑伸缩，渐变底色同步变换色相，让标题拥有自信而鲜活的节奏，却不显得喧闹。"
        ),
        implementation: L(
            "The word is keyed with .id(index) and uses a custom Transition (offset + blur + opacity by TransitionPhase) inside an overlay; a hidden copy of the current word sizes the capsule, so its width animates with the same spring.",
            "关键词通过 .id(index) 标识身份，在 overlay 中使用自定义 Transition（依据 TransitionPhase 设置位移、模糊与透明度）；胶囊尺寸由隐藏的当前词决定，宽度随同一弹簧动画伸缩。"
        ),
        apis: ["Transition", "TransitionPhase", ".id(_:)", "spring(duration:bounce:)"],
        tags: ["rotating", "words", "headline", "slot", "hero", "轮播", "关键词", "标题", "文字切换"],
        params: [
            .slider("interval", L("Interval", "间隔"), 1...4, default: 2, unit: "s"),
            .slider("bounce", L("Bounce", "弹性"), 0...0.5, default: 0.25),
            .slider("blur", L("Blur", "模糊"), 0...16, default: 8, decimals: 0, unit: "pt"),
        ]
    ) { ctx in
        RotatingWordsDemo(ctx: ctx)
    }
}

private struct RotatingWordsDemo: View {
    let ctx: DemoContext
    @State private var index = 0

    private var words: [String] {
        ctx.language == .zh
            ? ["更流畅", "更灵动", "更高级", "更有温度"]
            : ["faster", "delightful", "beautiful", "yours"]
    }

    private let tints: [Color] = [Palette.indigo, Palette.pink, Palette.mint, Palette.coral]

    var body: some View {
        VStack(spacing: 12) {
            Text(L("Make it", "让你的界面"), ctx.language)
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
            wordSlot
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .onTapGesture { advance() }
        // A continuous loop that still honours the shell's autoplay switch (paused thumbnails stop ticking).
        .autoplay(true, every: max(ctx["interval"], 0.5), delay: max(ctx["interval"], 0.5)) { advance() }
    }

    private var wordSlot: some View {
        let tint = tints[index % tints.count]
        let word = words[index % words.count]
        // The pill is sized by a hidden copy of the *current* word only (no identity change), so its width
        // animates inside the same spring as the swap. The transitioning words live in an overlay, which
        // never affects layout, so the outgoing word's removal can't make the pill snap afterwards.
        return Text(verbatim: word)
            .font(.system(size: 40, weight: .heavy, design: .rounded))
            .fixedSize()
            .hidden()
            .overlay {
                ZStack {
                    Text(verbatim: word)
                        .font(.system(size: 40, weight: .heavy, design: .rounded))
                        .foregroundStyle(LinearGradient(colors: [tint, Palette.violet], startPoint: .leading, endPoint: .trailing))
                        .fixedSize()
                        .id(index)
                        .transition(SlotTransition(distance: 34, blur: ctx.cg("blur")))
                }
            }
        .padding(.horizontal, 22)
        .frame(height: 66)
        .background(tint.opacity(0.13), in: Capsule())
        .overlay(Capsule().strokeBorder(tint.opacity(0.25)))
        .clipShape(Capsule())
    }

    private func advance() {
        withAnimation(.spring(duration: 0.55, bounce: ctx["bounce"])) {
            index += 1
        }
    }
}

private struct SlotTransition: Transition {
    var distance: CGFloat
    var blur: CGFloat

    func body(content: Content, phase: TransitionPhase) -> some View {
        content
            .offset(y: offset(for: phase))
            .blur(radius: phase.isIdentity ? 0 : blur)
            .opacity(phase.isIdentity ? 1 : 0)
            .scaleEffect(phase.isIdentity ? 1 : 0.92)
    }

    private func offset(for phase: TransitionPhase) -> CGFloat {
        if case .willAppear = phase { return distance }
        if case .didDisappear = phase { return -distance }
        return 0
    }
}
