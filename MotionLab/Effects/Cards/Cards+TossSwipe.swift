import SwiftUI

extension Effect {
    static let cardsTossSwipe = Effect(
        id: "cards.toss-swipe",
        category: .cards,
        interaction: .gesture,
        name: L("Arc Toss Deck", "抛物线甩卡"),
        summary: L("Pick a card up by any corner and toss it: it arcs up, spins and falls off-stage under gravity.", "从任意位置拎起卡片抛出：它先向上划出弧线、旋转，再在重力下坠出舞台。"),
        prompt: L(
            "A loose pile of 180×230 pt cards, each resting at a slightly different angle (±4°). The top card is picked up where the finger lands: it pivots around that grab point, swinging up to ±18° as it is dragged, so holding it by a corner feels different from holding it by the middle. Releasing past 90 pt tosses it along a real arc — horizontally with an ease-out over 0.75 s, vertically first rising 70 pt in 0.2 s then accelerating downward with an ease-in over 0.55 s — while it keeps spinning up to 140°, then it drops off the bottom of the stage. The next card lifts out of the pile with a gentle spring. Casual, physical and fun.",
            "一叠180×230 pt的卡片随意堆放，每张的角度略有不同（±4°）。顶部卡片从手指落下的位置被拎起：拖动时它绕这个抓取点摆动，最多±18°，因此捏着角拖和捏着中间拖的手感完全不同。拖动超过90 pt后松手，卡片沿真实的抛物线被抛出——水平方向在0.75秒内缓出，竖直方向先在0.2秒内上升70 pt，再在0.55秒内加速下落——同时持续旋转最多140°，最终从舞台底部掉出。下一张卡片以柔和的弹簧从牌堆中浮起。随性、真实、好玩。"
        ),
        implementation: L(
            "The drag's startLocation becomes the rotationEffect anchor; on release separate x, y and spin states are animated with different curves (easeOut for x, easeOut then easeIn for y) so their sum draws a parabola.",
            "拖动的 startLocation 作为 rotationEffect 的锚点；松手后 x、y 与旋转分别用不同的曲线动画（x 为缓出，y 先缓出后缓入），叠加起来便形成抛物线。"
        ),
        apis: ["DragGesture.startLocation", "rotationEffect(_:anchor:)", "easeOut / easeIn", "Task.sleep(for:)"],
        tags: ["toss", "throw", "gravity", "parabola", "抛掷", "重力", "抛物线", "卡片"],
        params: [
            .slider("lift", L("Toss height", "抛起高度"), 20...140, default: 70, step: 5, decimals: 0, unit: "pt"),
            .slider("spin", L("Spin", "旋转"), 0...360, default: 140, step: 10, decimals: 0, unit: "°"),
            .slider("threshold", L("Toss threshold", "抛出阈值"), 50...160, default: 90, step: 5, decimals: 0, unit: "pt"),
        ]
    ) { ctx in
        CardsTossDemo(ctx: ctx)
    }
}

private let cardsTossSize = CGSize(width: 180, height: 230)

private struct CardsTossDemo: View {
    let ctx: DemoContext
    @State private var order: [Int] = [4, 0, 1, 2, 3, 5]
    @State private var drag: CGSize = .zero
    @State private var grab = UnitPoint.center
    @State private var tossX: CGFloat = 0
    @State private var tossY: CGFloat = 0
    @State private var tossSpin: Double = 0
    @State private var tossing = false
    /// Briefly true when a new card becomes the top one, so it lifts out of the pile.
    @State private var rise = false
    @State private var autoDirection: CGFloat = 1
    /// The running toss sequence (scripted or real), cancelled on the first real touch and if the demo leaves the screen.
    @State private var sequence: Task<Void, Never>?
    /// True while a real finger holds the top card.
    @State private var held = false
    /// Resets on system cancellation too, so a stolen touch never leaves the card lifted off the pile.
    @GestureState private var pressing = false

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                ForEach(order, id: \.self) { id in
                    card(id)
                }
            }
            .frame(height: 270)
            DemoHint(text: L("Grab the card anywhere and toss it", "从任意位置拎起卡片并抛出"), ctx: ctx)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 1.9) { autoToss() }
        .onChange(of: pressing) { _, isPressing in
            if !isPressing { cancelHold() }
        }
        .onDisappear { settleNow() }
    }

    /// Leaving the screen cancels whatever sequence runs and puts the deck back at rest, so a card
    /// cancelled mid-toss is recycled instead of staying off-stage (and un-hittable) when the view returns.
    private func settleNow() {
        sequence?.cancel()
        sequence = nil
        held = false
        if tossing {
            land()
        } else {
            var transaction = Transaction()
            transaction.disablesAnimations = true
            withTransaction(transaction) {
                drag = .zero
                grab = .center
            }
        }
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) { rise = false }
    }

    private func card(_ id: Int) -> some View {
        let depth = order.firstIndex(of: id) ?? 0
        let isTop = depth == 0
        let rest = Double((id * 5) % 9) - 4
        let lever: Double = grab.y < 0.5 ? 1 : -1
        let swing = (Double(drag.width) / 8 * lever).clamped(to: -18...18)
        let angle: Double = isTop ? rest + swing + tossSpin : rest
        let x: CGFloat = isTop ? drag.width + tossX : 0
        let y: CGFloat = isTop ? drag.height + tossY : CGFloat(depth) * 3
        return CardsDeckFace(index: id, language: ctx.language, width: cardsTossSize.width, height: cardsTossSize.height)
            .rotationEffect(.degrees(angle), anchor: isTop ? grab : .center)
            .scaleEffect(isTop && (drag != .zero || rise) ? 1.03 : 1)
            .shadow(color: .black.opacity(isTop ? 0.2 : 0.08), radius: isTop ? 16 : 6, y: isTop ? 10 : 3)
            .offset(x: x, y: y)
            .opacity(depth < 4 ? 1 : 0)
            .zIndex(Double(order.count - depth))
            .allowsHitTesting(isTop && !tossing)
            .gesture(dragGesture)
    }

    private var dragGesture: some Gesture {
        DragGesture()
            .updating($pressing) { _, state, _ in state = true }
            .onChanged { value in
                if !held {
                    // The first real touch takes over from any scripted toss that hasn't released yet.
                    held = true
                    sequence?.cancel()
                    sequence = nil
                    grab = UnitPoint(
                        x: (value.startLocation.x / cardsTossSize.width).clamped(to: 0...1),
                        y: (value.startLocation.y / cardsTossSize.height).clamped(to: 0...1)
                    )
                }
                withAnimation(.interactiveSpring(response: 0.2, dampingFraction: 0.8)) {
                    drag = value.translation
                }
            }
            .onEnded { value in
                guard held else { return }
                held = false
                if hypot(value.translation.width, value.translation.height) > ctx.cg("threshold") {
                    toss(direction: value.predictedEndTranslation.width >= 0 ? 1 : -1)
                } else {
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.65)) { drag = .zero }
                }
            }
    }

    /// System cancellation (no `onEnded`): let the card fall back onto the pile.
    private func cancelHold() {
        guard held else { return }
        held = false
        withAnimation(.spring(response: 0.45, dampingFraction: 0.65)) { drag = .zero }
    }

    private func toss(direction: CGFloat, haptic: Bool = true) {
        tossing = true
        if haptic && !ctx.isPreview { Haptics.tap(.medium) }
        let lift = ctx.cg("lift")
        withAnimation(.easeOut(duration: 0.75)) {
            tossX = direction * 240
            tossSpin = Double(direction) * ctx["spin"]
        }
        withAnimation(.easeOut(duration: 0.2)) {
            tossY = -lift
        }
        sequence = Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.2))
            guard !Task.isCancelled else { return }
            withAnimation(.easeIn(duration: 0.55)) {
                tossY = 460
            }
            try? await Task.sleep(for: .seconds(0.58))
            guard !Task.isCancelled else { return }
            land()
            try? await Task.sleep(for: .seconds(0.22))
            guard !Task.isCancelled else { return }
            withAnimation(.spring(response: 0.45, dampingFraction: 0.7)) { rise = false }
        }
    }

    /// Recycles the tossed card to the bottom and lifts the next one out of the pile.
    private func land() {
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            let first = order.removeFirst()
            order.append(first)
            drag = .zero
            tossX = 0
            tossY = 0
            tossSpin = 0
            grab = .center
        }
        tossing = false
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { rise = true }
    }

    private func autoToss() {
        guard !tossing && !held else { return }
        autoDirection = -autoDirection
        let direction = autoDirection
        let muted = Haptics.isMuted || ctx.isPreview
        grab = UnitPoint(x: direction > 0 ? 0.8 : 0.2, y: 0.15)
        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
            drag = CGSize(width: direction * 50, height: -20)
        }
        sequence = Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.5))
            guard !Task.isCancelled else { return }
            toss(direction: direction, haptic: !muted)
        }
    }
}
