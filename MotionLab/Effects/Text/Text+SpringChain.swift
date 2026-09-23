import SwiftUI

extension Effect {
    static let textSpringChain = Effect(
        id: "text.spring-chain",
        category: .text,
        interaction: .gesture,
        name: L("Spring-Chain Letters", "弹簧链字母"),
        summary: L("Drag the word and each letter follows the one before it on a looser spring.", "拖动单词，每个字母以更松的弹簧追随前一个字母。"),
        prompt: L(
            "A short word in 56 pt heavy rounded letters, each tinted along a sunset gradient, rests centred on the stage. Dragging anywhere pulls the first letter directly under the finger's translation (spring response 0.15 s), and every following letter chases with a looser spring whose response grows by 0.07 s per letter, so the word stretches into a trailing, rope-like arc. Each letter also leans up to 18° in the direction of horizontal travel. On release all letters spring home with a lively 0.6 damping, overshooting and swinging past each other before settling; a light haptic fires on grab and on release. It feels playful and tactile, like pulling a string of beads.",
            "一个56 pt粗圆体的短单词居中静置，每个字母沿日落渐变着色。在任意位置拖动时，第一个字母直接跟随手指位移（弹簧响应0.15秒），后面每个字母都用更松的弹簧追赶——响应时间每个字母递增0.07秒，于是整个单词被拉成一条拖尾的弧线，像一根绳子。每个字母还会按水平移动方向倾斜最多18°。松手后所有字母以0.6的阻尼弹回原位，冲过头、彼此摆动交错后才稳定；按住与松手时各有一次轻触感。俏皮又有手感，像拉动一串珠子。"
        ),
        implementation: L(
            "One drag translation drives every letter's offset and rotation; each Text carries its own .animation(.spring(response:dampingFraction:), value:) with a response that grows by index, so the springs retarget every frame and naturally form a trailing chain.",
            "同一个拖动位移驱动每个字母的偏移与旋转；每个 Text 都挂着自己的 .animation(.spring(response:dampingFraction:), value:)，响应时间随序号递增，弹簧每帧重新定向，自然形成拖尾链条。"
        ),
        apis: ["DragGesture", "spring(response:dampingFraction:)", "animation(_:value:)", "offset", "rotationEffect"],
        tags: ["drag", "spring", "chain", "follow", "拖动", "弹簧", "跟随", "动态字形"],
        params: [
            .slider("lag", L("Lag per letter", "逐字延迟"), 0.02...0.15, default: 0.07, unit: "s"),
            .slider("damping", L("Release damping", "回弹阻尼"), 0.3...1.0, default: 0.6),
            .slider("lean", L("Lean", "倾斜"), 0...40, default: 18, decimals: 0, unit: "°"),
        ]
    ) { ctx in
        TextSpringChainDemo(ctx: ctx)
    }
}

private struct TextSpringChainDemo: View {
    let ctx: DemoContext
    @State private var drag: CGSize = .zero
    @State private var dragging = false

    private var letters: [String] { (ctx.language == .zh ? "拉我试试" : "PULL ME").map { String($0) } }

    var body: some View {
        VStack(spacing: 30) {
            word
            DemoHint(text: L("Drag anywhere", "任意拖动"), ctx: ctx)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .gesture(dragGesture)
        .autoplay(ctx.isPreview, every: 2.4) { simulate() }
    }

    private var word: some View {
        let chars = letters
        return HStack(spacing: 0) {
            ForEach(chars.indices, id: \.self) { index in
                Text(verbatim: chars[index])
                    .font(.system(size: 56, weight: .heavy, design: .rounded))
                    .foregroundStyle(tint(index, count: chars.count))
                    .rotationEffect(.degrees(lean), anchor: .bottom)
                    .offset(drag)
                    .animation(animation(index), value: drag)
                    .animation(animation(index), value: dragging)
            }
        }
        .fixedSize()
    }

    private var lean: Double {
        guard dragging else { return 0 }
        let raw: Double = Double(drag.width) * 0.12
        return raw.clamped(to: -ctx["lean"]...ctx["lean"])
    }

    private func tint(_ index: Int, count: Int) -> Color {
        let colors: [Color] = [Palette.amber, Palette.coral, Palette.pink, Palette.violet]
        let position = count > 1 ? Double(index) / Double(count - 1) : 0
        let slot = Int((position * Double(colors.count - 1)).rounded())
        return colors[min(max(slot, 0), colors.count - 1)]
    }

    private func animation(_ index: Int) -> Animation {
        let response: Double = 0.15 + Double(index) * ctx["lag"]
        let damping: Double = dragging ? 0.82 : ctx["damping"]
        return .spring(response: response, dampingFraction: damping)
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                if !dragging {
                    dragging = true
                    Haptics.tap(.light)
                }
                drag = value.translation
            }
            .onEnded { _ in
                dragging = false
                drag = .zero
                Haptics.tap(.light)
            }
    }

    private func simulate() {
        dragging = true
        drag = CGSize(width: CGFloat.random(in: -90...90), height: CGFloat.random(in: -80...60))
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            dragging = false
            drag = .zero
        }
    }
}
