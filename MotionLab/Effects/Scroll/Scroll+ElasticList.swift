import SwiftUI

extension Effect {
    static let scrollElasticList = Effect(
        id: "scroll.elastic-list",
        category: .scroll,
        interaction: .scroll,
        name: L("Elastic Message List", "弹性消息列表"),
        summary: L("Chat bubbles trail the scroll on springs, stretching apart and bouncing back together like iMessage.", "聊天气泡通过弹簧跟随滚动，像 iMessage 一样被拉开再弹回聚拢。"),
        prompt: L(
            "A chat thread of alternating capsule message bubbles on 44 pt rows (incoming on the left, outgoing blue gradient on the right) with 10 pt gaps. The bubbles are not glued to the scroll: each one follows through its own spring, and the further a bubble sits from the leading edge of the motion, the looser its spring (response 0.2 → 0.45 s, damping 0.62) and the more it lags — up to 1.2× the per-frame scroll delta, capped at 40 pt. Fast scrolling therefore stretches the gaps open like an accordion, and when the scroll comes to rest the bubbles bounce back together with a small overshoot. Nothing changes layout; only offsets move. Lively, physical and unmistakably iOS.",
            "一段聊天记录，胶囊形消息气泡排在 44 pt 高的行中左右交替（收到的在左、发出的蓝色渐变在右），间距 10 pt。气泡并没有和滚动牢牢粘在一起：每个气泡都通过自己的弹簧跟随，离运动前沿越远，弹簧越松（响应 0.2 → 0.45 秒、阻尼 0.62），滞后也越多——最多为每帧滚动增量的 1.2 倍，上限 40 pt。因此快速滚动时气泡间距像手风琴一样被拉开，滚动停下后，气泡带着轻微过冲弹回聚拢。布局本身不变，只有偏移在动。灵动、真实，一眼就是 iOS 的味道。"
        ),
        implementation: L(
            "onScrollGeometryChange tracks the offset and its per-frame delta; each row offsets by delta × its normalised screen position and carries its own .animation(.spring(response:…), value: delta), so rows chase each other. onScrollPhaseChange resets the delta to zero when the scroll settles.",
            "onScrollGeometryChange 跟踪偏移及每帧增量；每一行按「增量 × 自身归一化屏幕位置」偏移，并各自带有 .animation(.spring(response:…), value: delta)，于是各行相互追赶。滚动停止时由 onScrollPhaseChange 把增量归零。"
        ),
        apis: ["onScrollGeometryChange", "onScrollPhaseChange", "animation(_:value:)", "spring(response:dampingFraction:)", "ScrollPosition"],
        tags: ["elastic", "chat", "bubbles", "spring", "弹性", "聊天", "气泡", "弹簧"],
        params: [
            .slider("elasticity", L("Elasticity", "弹性"), 0...2.5, default: 1.2),
            .slider("damping", L("Damping", "阻尼"), 0.3...1.0, default: 0.62),
        ]
    ) { ctx in
        ScrollElasticListDemo(ctx: ctx)
    }
}

private let scrollElasticMessages: [LocalizedText] = [
    L("Are we still on for tonight?", "今晚还照常吗？"),
    L("Yes! 7:30 at the ramen place", "对！7:30 拉面店见"),
    L("Perfect, I'll book a table", "好，我去订位"),
    L("Bring the camera 📷", "记得带相机 📷"),
    L("Already packed it", "早就装好了"),
    L("Leaving the office now", "我刚下班出发"),
    L("Traffic is wild", "路上好堵"),
    L("No rush, I'm early", "不急，我到早了"),
    L("Order me the spicy one", "帮我点辣的那款"),
    L("Done 🍜", "点好了 🍜"),
    L("Parking now", "在停车"),
    L("See you in 2", "两分钟后见"),
    L("Window seat!", "靠窗的位子！"),
    L("Best spot 🙌", "最佳位置 🙌"),
    L("Walking in", "我进来了"),
    L("I see you 👋", "看到你啦 👋"),
    L("Let's eat", "开吃"),
    L("Photo time first", "先拍照"),
]

private struct ScrollElasticListDemo: View {
    let ctx: DemoContext
    @State private var position = ScrollPosition(edge: .top)
    @State private var offset: CGFloat = 0
    @State private var delta: CGFloat = 0
    @State private var viewport: CGFloat = 340
    @State private var down = false

    private let rowHeight: CGFloat = 44
    private let gap: CGFloat = 10
    private let topPad: CGFloat = 16

    var body: some View {
        ScrollView {
            VStack(spacing: gap) {
                ForEach(scrollElasticMessages.indices, id: \.self) { i in
                    row(i)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, topPad)
        }
        .scrollIndicators(.hidden)
        .scrollPosition($position)
        .onScrollGeometryChange(for: CGFloat.self, of: { geometry in
            geometry.contentOffset.y + geometry.contentInsets.top
        }, action: { oldValue, newValue in
            offset = newValue
            delta = (newValue - oldValue).clamped(to: -40...40)
        })
        .onScrollPhaseChange { _, newPhase in
            if newPhase == .idle { delta = 0 }
        }
        .onGeometryChange(for: CGFloat.self, of: { proxy in proxy.size.height }, action: { newHeight in
            viewport = max(newHeight, 1)
        })
        .autoplay(ctx.isPreview, every: 1.6) {
            down.toggle()
            withAnimation(.easeInOut(duration: 0.9)) {
                position.scrollTo(edge: down ? .bottom : .top)
            }
        }
    }

    private func row(_ i: Int) -> some View {
        // Screen position of the row, 0 at the top of the viewport and 1 at the bottom.
        let rowY: CGFloat = topPad + CGFloat(i) * (rowHeight + gap) - offset
        let screen: CGFloat = (rowY / viewport).clamped(to: 0...1)
        // Rows far from the leading edge of the motion lag the most.
        let far: CGFloat = delta >= 0 ? screen : 1 - screen
        let lag: CGFloat = delta * far * ctx.cg("elasticity")
        let response: Double = 0.2 + 0.25 * Double(far)
        return ScrollElasticBubble(text: scrollElasticMessages[i], outgoing: i % 2 == 1, language: ctx.language)
            .frame(height: rowHeight)
            .offset(y: lag)
            .animation(.spring(response: response, dampingFraction: ctx["damping"]), value: delta)
    }
}

private struct ScrollElasticBubble: View {
    let text: LocalizedText
    let outgoing: Bool
    let language: AppLanguage

    var body: some View {
        HStack {
            if outgoing { Spacer(minLength: 60) }
            Text(text, language)
                .font(.subheadline)
                .lineLimit(1)
                .foregroundStyle(outgoing ? Color.white : Color.primary)
                .padding(.horizontal, 14)
                .frame(height: 36)
                .background(bubble)
            if !outgoing { Spacer(minLength: 60) }
        }
    }

    @ViewBuilder
    private var bubble: some View {
        if outgoing {
            Capsule().fill(Palette.ocean)
        } else {
            Capsule().fill(Palette.elevated)
        }
    }
}
