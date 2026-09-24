import SwiftUI

extension Effect {
    static let cardsRewindSwipe = Effect(
        id: "cards.rewind-swipe",
        category: .cards,
        interaction: .gesture,
        name: L("Swipe with Rewind", "可撤回滑卡"),
        summary: L("Fling cards away, then rewind: the last one flies back along its exit path with a reverse spin.", "把卡片甩走后可以撤回：上一张沿离场路径带着反向旋转飞回。"),
        prompt: L(
            "A deck of five 190×240 pt cards with a round rewind button beneath. Dragged cards tilt up to 12° and, past 100 pt or on a flick, fly 440 pt off-stage with a 30° spin on a quick spring (response 0.4 s, damping 0.85). Tapping rewind replays the exit backwards: the most recent card swoops in from the side it left, un-spinning from 30° to 0° on a bouncy spring (response 0.55 s, damping 0.62) that overshoots slightly, lands on top of the deck, and the button's arrow spins −360°. When the deck is empty, all five cards fly back in one after another, 70 ms apart. Forgiving, reversible and delightful.",
            "五张190×240 pt的卡片叠成一摞，下方有一个圆形撤回按钮。拖动卡片时最多倾斜12°，超过100 pt或快速甩动时，卡片带着30°旋转以快速弹簧（响应0.4秒、阻尼0.85）飞出舞台440 pt。点击撤回会倒放离场过程：最近一张卡片从它离开的那一侧飞回，以带轻微过冲的弹性弹簧（响应0.55秒、阻尼0.62）把旋转从30°收回到0°，落回卡堆顶部，按钮上的箭头同时旋转−360°。卡堆被清空时，五张卡片以70毫秒的间隔依次飞回。宽容、可逆、令人愉悦。"
        ),
        implementation: L(
            "Cards are never removed: each keeps an 'exit direction' in a dictionary (0 = in the deck), so flinging and rewinding are just springs on the same offset and rotation, and depth is computed over the cards still in the deck.",
            "卡片从不被移除：每张卡在字典中记录“离场方向”（0 表示仍在卡堆中），因此甩出与撤回只是同一组 offset 与旋转上的弹簧动画，层级只按仍在卡堆中的卡片计算。"
        ),
        apis: ["DragGesture", "spring(response:dampingFraction:)", "Animation.delay", "rotationEffect", "zIndex"],
        tags: ["swipe", "undo", "rewind", "deck", "滑卡", "撤回", "倒放", "卡堆"],
        params: [
            .slider("rewindResponse", L("Rewind response", "撤回响应"), 0.3...1.0, default: 0.55, unit: "s"),
            .slider("rewindDamping", L("Rewind damping", "撤回阻尼"), 0.4...1.0, default: 0.62),
            .slider("spin", L("Exit spin", "离场旋转"), 0...60, default: 30, step: 1, decimals: 0, unit: "°"),
        ]
    ) { ctx in
        CardsRewindDemo(ctx: ctx)
    }
}

private let cardsRewindIDs: [Int] = [1, 2, 3, 4, 5]

private struct CardsRewindDemo: View {
    let ctx: DemoContext
    /// Exit direction per card: 0 = in the deck, ±1 = flung left/right.
    @State private var exits: [Int: CGFloat] = [:]
    /// Flung cards, most recent last.
    @State private var history: [Int] = []
    @State private var drag: CGSize = .zero
    @State private var rewinds = 0
    @State private var step = 0
    /// True while a real finger holds the top card.
    @State private var held = false
    /// Resets on system cancellation too, so a stolen touch never leaves the card half-swiped.
    @GestureState private var pressing = false

    private var deck: [Int] { cardsRewindIDs.filter { (exits[$0] ?? 0) == 0 } }

    var body: some View {
        VStack(spacing: 18) {
            ZStack {
                ForEach(cardsRewindIDs, id: \.self) { id in
                    card(id)
                }
            }
            .frame(height: 262)
            rewindButton
            DemoHint(text: L("Swipe a card, then tap rewind", "滑走卡片，再点撤回"), ctx: ctx)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 1.1) { autoStep() }
        .onChange(of: pressing) { _, isPressing in
            if !isPressing { endHold() }
        }
    }

    private func card(_ id: Int) -> some View {
        let exit = exits[id] ?? 0
        let depth = deck.firstIndex(of: id) ?? 0
        let isTop = exit == 0 && depth == 0
        let tilt = isTop ? (Double(drag.width / 110) * 12).clamped(to: -12...12) : 0
        let spin = Double(exit) * ctx["spin"]
        let x: CGFloat = exit != 0 ? exit * 440 : (isTop ? drag.width : 0)
        let y: CGFloat = exit != 0 ? 40 : (isTop ? drag.height * 0.4 : CGFloat(depth) * 14)
        let order = cardsRewindIDs.firstIndex(of: id) ?? 0
        return CardsDeckFace(index: id, language: ctx.language)
            .scaleEffect(exit != 0 || isTop ? 1 : 1 - CGFloat(depth) * 0.05)
            .rotationEffect(.degrees(tilt + spin), anchor: .bottom)
            .offset(x: x, y: y)
            .opacity(exit == 0 && depth > 2 ? 0 : 1)
            .shadow(color: .black.opacity(0.15), radius: 14, y: 8)
            // Earlier cards stay above later ones, so a rewound card lands on top of the deck.
            .zIndex(Double(cardsRewindIDs.count - order))
            .allowsHitTesting(isTop)
            .gesture(dragGesture)
    }

    private var rewindButton: some View {
        Button(action: rewind) {
            Image(systemName: "arrow.uturn.backward")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(history.isEmpty ? Color.secondary : Palette.amber)
                .rotationEffect(.degrees(Double(rewinds) * -360))
                .frame(width: 48, height: 48)
                .background(Circle().fill(Palette.elevated))
                .overlay(Circle().strokeBorder(Palette.stroke))
                .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
        }
        .buttonStyle(.plain)
        .disabled(history.isEmpty)
        .animation(.spring(response: 0.6, dampingFraction: 0.75), value: rewinds)
    }

    private var dragGesture: some Gesture {
        DragGesture()
            .updating($pressing) { _, state, _ in state = true }
            .onChanged { value in
                held = true
                drag = value.translation
            }
            .onEnded { value in
                guard held else { return }
                held = false
                let predicted = value.predictedEndTranslation.width
                if abs(value.translation.width) > 100 || abs(predicted) > 200 {
                    fling(direction: predicted >= 0 ? 1 : -1)
                } else {
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.65)) { drag = .zero }
                }
            }
    }

    /// System cancellation (no `onEnded`): spring the top card back to the deck.
    private func endHold() {
        guard held else { return }
        held = false
        withAnimation(.spring(response: 0.45, dampingFraction: 0.65)) { drag = .zero }
    }

    private func fling(direction: CGFloat) {
        guard let top = deck.first else { return }
        Haptics.tap(.medium)
        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
            exits[top] = direction
            history.append(top)
            drag = .zero
        }
        if deck.isEmpty {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                if deck.isEmpty { restoreAll() }
            }
        }
    }

    private func rewind() {
        guard let last = history.last else { return }
        Haptics.tap(.soft)
        rewinds += 1
        withAnimation(.spring(response: ctx["rewindResponse"], dampingFraction: ctx["rewindDamping"])) {
            exits[last] = 0
            history.removeLast()
        }
    }

    /// Flies every flung card back, newest first, 70 ms apart.
    private func restoreAll() {
        for (i, id) in history.reversed().enumerated() {
            withAnimation(.spring(response: ctx["rewindResponse"], dampingFraction: ctx["rewindDamping"]).delay(Double(i) * 0.07)) {
                exits[id] = 0
            }
        }
        rewinds += 1
        history.removeAll()
    }

    private func autoStep() {
        // Fling, fling, rewind, then fling until the deck is empty so `fling` restores all five.
        // Seven flings against one rewind per cycle, so every cycle reaches the "all fly back" beat.
        let pattern: [Int] = [1, -1, 0, 1, -1, 1, -1, 1]
        let move = pattern[step % pattern.count]
        step += 1
        if held || deck.isEmpty {
            return
        } else if move == 0 {
            rewind()
        } else {
            fling(direction: CGFloat(move))
        }
    }
}
