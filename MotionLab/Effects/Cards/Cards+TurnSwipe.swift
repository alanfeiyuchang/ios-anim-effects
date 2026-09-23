import SwiftUI

extension Effect {
    static let cardsTurnSwipe = Effect(
        id: "cards.turn-swipe",
        category: .cards,
        interaction: .gesture,
        name: L("Revolving Swipe", "旋转门滑卡"),
        summary: L("Swiped cards turn away in 3D like a revolving door while the next one swings in.", "滑动时卡片像旋转门一样在三维中转开，下一张随之转入。"),
        prompt: L(
            "A deck of 190×240 pt cards. Dragging sideways does not slide the top card flat: it turns around its vertical axis in perspective — up to 60° at the 110 pt threshold — while travelling only 55% of the finger's distance and darkening toward edge-on, like a revolving door being pushed. Releasing past the threshold (or flicking) keeps it turning to 90°, edge-on and gone, with a firm spring (response 0.42 s, damping 0.88) and a medium haptic; the next card starts 25° turned the other way at 92% scale and swings in to face the viewer with a softer spring (response 0.55 s, damping 0.7). Short releases rotate back to flat. Architectural, smooth and a little theatrical.",
            "一叠190×240 pt的卡片。左右拖动时，顶部卡片不是平移，而是绕竖直轴以透视转动——在110 pt阈值处最多转60°——同时只移动手指距离的55%，并在接近侧立时逐渐变暗，就像推动一扇旋转门。越过阈值松手（或快速甩动）时，卡片以硬朗的弹簧（响应0.42秒、阻尼0.88）继续转到90°侧立后消失，并伴随中等触感；下一张卡片从反方向转过25°、缩放92%的状态，以更柔和的弹簧（响应0.55秒、阻尼0.7）转正面向观者。距离不足则转回平面。顺滑又带点戏剧性。"
        ),
        implementation: L(
            "The drag translation maps to a y-axis rotation3DEffect plus a reduced offset on the top card; a throw animates the angle to ±90°, then the deck is reordered and a separate 'incoming' angle state springs the new top card from −25° to 0°.",
            "拖动位移映射为顶部卡片绕 y 轴的 rotation3DEffect 与缩减后的偏移；甩出时把角度动画到 ±90°，随后重排卡组，并由独立的“转入”角度状态让新的顶部卡片从 −25° 弹簧过渡到 0°。"
        ),
        apis: ["rotation3DEffect", "DragGesture", "predictedEndTranslation", "withTransaction", "spring(response:dampingFraction:)"],
        tags: ["swipe", "3D", "revolving", "turn", "滑卡", "三维", "旋转门", "翻转"],
        params: [
            .slider("maxAngle", L("Drag angle", "拖动角度"), 30...85, default: 60, step: 1, decimals: 0, unit: "°"),
            .slider("threshold", L("Swipe threshold", "甩出阈值"), 60...180, default: 110, step: 5, decimals: 0, unit: "pt"),
            .slider("perspective", L("Perspective", "透视强度"), 0.2...1.0, default: 0.6),
        ]
    ) { ctx in
        CardsTurnSwipeDemo(ctx: ctx)
    }
}

private struct CardsTurnSwipeDemo: View {
    let ctx: DemoContext
    @State private var order: [Int] = [2, 3, 4, 5, 0]
    @State private var drag: CGFloat = 0
    /// Angle of the outgoing card once it is thrown (degrees).
    @State private var thrown: Double?
    /// Starting turn of the card that has just become the top one.
    @State private var incoming: Double = 0
    @State private var autoDirection: CGFloat = 1

    var body: some View {
        VStack(spacing: 18) {
            ZStack {
                ForEach(order, id: \.self) { id in
                    card(id)
                }
            }
            .frame(height: 270)
            DemoHint(text: L("Swipe the card left or right", "左右滑动卡片"), ctx: ctx)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 1.7) { autoSwipe() }
    }

    private func card(_ id: Int) -> some View {
        let depth = order.firstIndex(of: id) ?? 0
        let isTop = depth == 0
        let threshold = max(ctx.cg("threshold"), 1)
        let progress = min(abs(drag) / threshold, 1)
        let dragAngle = Double(drag / threshold) * ctx["maxAngle"]
        let angle: Double = isTop ? (thrown ?? dragAngle.clamped(to: -89...89)) + incoming : 0
        let edge = abs(sin(angle * .pi / 180))
        let slot = max(CGFloat(depth) - (thrown == nil ? 0 : 1), 0)
        return CardsDeckFace(index: id, language: ctx.language)
            .overlay {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color.black.opacity(0.45 * edge))
            }
            .rotation3DEffect(.degrees(angle), axis: (x: 0, y: 1, z: 0), perspective: ctx.cg("perspective"))
            .scaleEffect(isTop ? 1 - CGFloat(abs(incoming)) / 25 * 0.08 : 1 - slot * 0.06)
            .offset(x: isTop ? drag * 0.55 : 0, y: isTop ? 0 : slot * 16)
            .opacity(depth < 3 ? 1 : (depth == 3 ? Double(progress) : 0))
            .shadow(color: .black.opacity(0.16), radius: 14, y: 8)
            .zIndex(Double(order.count - depth))
            .allowsHitTesting(isTop)
            .gesture(dragGesture)
    }

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                guard thrown == nil else { return }
                drag = value.translation.width
            }
            .onEnded { value in
                guard thrown == nil else { return }
                let threshold = ctx.cg("threshold")
                let predicted = value.predictedEndTranslation.width
                if abs(value.translation.width) > threshold || abs(predicted) > threshold * 2 {
                    throwCard(direction: predicted >= 0 ? 1 : -1)
                } else {
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.7)) { drag = 0 }
                }
            }
    }

    private func throwCard(direction: CGFloat, haptic: Bool = true) {
        if haptic && !ctx.isPreview { Haptics.tap(.medium) }
        withAnimation(.spring(response: 0.42, dampingFraction: 0.88)) {
            thrown = Double(direction) * 90
            drag = direction * ctx.cg("threshold")
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.34) {
            var transaction = Transaction()
            transaction.disablesAnimations = true
            withTransaction(transaction) {
                let first = order.removeFirst()
                order.append(first)
                thrown = nil
                drag = 0
                incoming = -Double(direction) * 25
            }
            DispatchQueue.main.async {
                withAnimation(.spring(response: 0.55, dampingFraction: 0.7)) { incoming = 0 }
            }
        }
    }

    private func autoSwipe() {
        autoDirection = -autoDirection
        let direction = autoDirection
        let muted = Haptics.isMuted || ctx.isPreview
        withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
            drag = direction * 70
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
            throwCard(direction: direction, haptic: !muted)
        }
    }
}
