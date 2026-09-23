import SwiftUI

extension Effect {
    static let gesturesSpringChain = Effect(
        id: "gestures.spring-chain",
        category: .gestures,
        interaction: .gesture,
        name: L("Spring Chain Trail", "弹簧链尾迹"),
        summary: L("A comet of dots chasing your finger, each on a slightly lazier spring.", "一串圆点追随手指，每颗的弹簧都比前一颗更慵懒。"),
        prompt: L(
            "A chain of 10 glowing dots, shrinking from 44 pt at the head to 14 pt at the tail and shifting hue from mint to violet while fading from 100% to 35% opacity, rests stacked at the center. Touching or dragging anywhere sets a single target point; every dot springs toward it independently, and each successive dot’s spring response grows by ~35 ms (head 0.25 s, tail ≈ 0.57 s, damping 0.7). The result is a fluid comet that stretches along fast movements, curls around turns and collapses back into a single bead when the finger stops. The head sits on top; soft coloured shadows give depth. It feels organic, like a school of fish following a lure.",
            "十颗发光圆点叠放在中心：从头部 44pt 递减到尾部 14pt，色相由薄荷绿渐变为紫色，透明度从 100% 递减到 35%。在任意位置按下或拖动都会设置同一个目标点，每颗圆点各自以弹簧追向目标，且后一颗的弹簧响应比前一颗长约 35ms（头部 0.25 秒、尾部约 0.57 秒，阻尼 0.7）。于是快速移动时整串被拉成流畅的彗星，转弯时优雅地卷曲，手指停下后又收拢成一颗珠子。头部始终置顶，柔和的同色投影增加层次。整体有机灵动，像鱼群追逐诱饵。"
        ),
        implementation: L(
            "One target point in @State; each dot applies .animation(.spring(response: base + lag × i), value: target), so identical state produces a cascade of increasingly delayed springs.",
            "只用一个 @State 目标点；每颗圆点使用 .animation(.spring(response: 基础值 + 延迟 × 序号), value: target)，同一状态变化即产生逐级滞后的弹簧级联。"
        ),
        apis: ["DragGesture", "animation(_:value:)", "spring(response:dampingFraction:)", "zIndex"],
        tags: ["trail", "follow", "chain", "cursor", "spring", "尾迹", "跟随", "弹簧链", "拖尾"],
        params: [
            .slider("count", L("Dots", "圆点数量"), 4...16, default: 10, step: 1, decimals: 0),
            .slider("lag", L("Lag per dot", "逐级延迟"), 0.01...0.08, default: 0.035, unit: "s"),
            .slider("damping", L("Damping", "阻尼"), 0.4...1.0, default: 0.7),
        ]
    ) { ctx in
        SpringChainDemo(ctx: ctx)
    }
}

private struct SpringChainDemo: View {
    let ctx: DemoContext
    @State private var target: CGPoint = .zero
    @State private var phase: Double = 0

    private let area: CGFloat = 300

    var body: some View {
        let count = max(ctx.int("count"), 2)
        ZStack {
            ForEach(0..<count, id: \.self) { index in
                ChainDot(
                    index: index,
                    count: count,
                    target: target,
                    response: 0.25 + ctx["lag"] * Double(index),
                    damping: ctx["damping"]
                )
                .zIndex(Double(count - index))
            }
        }
        .frame(width: area, height: area)
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    target = CGPoint(x: value.location.x - area / 2, y: value.location.y - area / 2)
                }
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(alignment: .bottom) {
            DemoHint(text: L("Drag anywhere", "在任意位置拖动"), ctx: ctx)
                .padding(.bottom, 14)
        }
        .autoplay(ctx.isPreview, every: 0.42, delay: 0.2) { wander() }
    }

    private func wander() {
        phase += 0.85
        target = CGPoint(x: cos(phase) * 95, y: sin(phase * 2) * 60)
    }
}

private struct ChainDot: View {
    let index: Int
    let count: Int
    let target: CGPoint
    let response: Double
    let damping: Double

    var body: some View {
        let t = Double(index) / Double(max(count - 1, 1))
        let size = 44 - 30 * t
        let color = Color(hue: 0.46 + 0.28 * t, saturation: 0.7, brightness: 0.95)
        Circle()
            .fill(color.gradient)
            .frame(width: size, height: size)
            .shadow(color: color.opacity(0.45), radius: 10 - 6 * t, y: 4)
            .opacity(1 - 0.65 * t)
            .offset(x: target.x, y: target.y)
            .animation(.spring(response: response, dampingFraction: damping), value: target)
    }
}
