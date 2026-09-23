import SwiftUI

extension Effect {
    static let cardsJellySwipe = Effect(
        id: "cards.jelly-swipe",
        category: .cards,
        interaction: .gesture,
        name: L("Jelly Swipe", "果冻滑卡"),
        summary: L("Cards stretch along the drag velocity like jelly, wobble when the finger stops and pop in with a squash.", "卡片沿拖动速度像果冻一样拉伸，手指停下时晃动，新卡片挤压弹出。"),
        prompt: L(
            "A deck of 190×240 pt destination cards with 24 pt corners. While dragging, the top card follows the finger and stretches along the direction of travel in proportion to speed — up to 18% longer and 9% thinner at 3,000 pt/s — through a wobbly spring (response 0.28 s, damping 0.32), so when the finger pauses for 80 ms or lets go the card jiggles back to shape. Releasing past 100 pt or with a fast flick throws it off-stage still stretched; the next card then pops forward with a squash-and-stretch keyframe sequence (x/y 108/92% → 95/105% → 102/98% → 100% over ~0.55 s) while the pile behind steps up. Playful, gummy and elastic.",
            "一叠 190×240 pt、24 pt 圆角的目的地卡片。拖动时顶部卡片跟手，并按速度沿运动方向拉伸——3000 pt/s 时最多拉长 18%、变细 9%——拉伸由易晃动的弹簧（响应 0.28 秒、阻尼 0.32）驱动，手指停顿 80 毫秒或松开时，卡片便抖动着恢复原形。拖过 100 pt 或快速甩动后松手，卡片带着拉伸飞出舞台；下一张随即以挤压拉伸关键帧弹到前面（x/y 依次 108/92% → 95/105% → 102/98% → 100%，约 0.55 秒），后方卡堆同步上移。俏皮而 Q 弹。"
        ),
        implementation: L(
            "DragGesture.velocity sets a stretch vector that an .animation(value:) spring smooths; the card is rotated to the velocity angle, scaled on x and rotated back. A debounce Task relaxes the stretch when events stop, and keyframeAnimator plays the pop.",
            "DragGesture.velocity 设置拉伸向量，并由 .animation(value:) 弹簧平滑；卡片先旋转到速度方向、在 x 轴缩放、再旋转回来。事件停止时由防抖 Task 放松拉伸，keyframeAnimator 播放弹出效果。"
        ),
        apis: ["DragGesture.Value.velocity", "scaleEffect(x:y:)", "keyframeAnimator", "animation(_:value:)", "Task.sleep"],
        tags: ["jelly", "swipe", "squash", "stretch", "果冻", "滑卡", "挤压拉伸", "弹性"],
        params: [
            .slider("jelly", L("Jelly amount", "果冻程度"), 0...2, default: 1),
            .slider("wobble", L("Wobble damping", "晃动阻尼"), 0.15...0.9, default: 0.32),
            .slider("threshold", L("Throw threshold", "甩出阈值"), 60...160, default: 100, step: 5, decimals: 0, unit: "pt"),
        ]
    ) { ctx in
        CardsJellySwipeDemo(ctx: ctx)
    }
}

private struct CardsJellySwipeDemo: View {
    let ctx: DemoContext
    @State private var order: [Int] = Array(0..<5)
    @State private var offset: CGSize = .zero
    /// Stretch vector: direction = travel direction, length = amount (0…0.18).
    @State private var stretch: CGSize = .zero
    @State private var pops = 0
    @State private var relaxTask: Task<Void, Never>?
    @State private var autoDirection: CGFloat = 1

    var body: some View {
        VStack(spacing: 18) {
            ZStack {
                ForEach(order, id: \.self) { id in
                    card(id)
                }
            }
            .frame(height: 280)
            DemoHint(text: L("Drag fast and flick the card", "快速拖动并甩出卡片"), ctx: ctx)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 1.8) { autoFling() }
    }

    private func card(_ id: Int) -> some View {
        let depth = order.firstIndex(of: id) ?? 0
        let isTop = depth == 0
        // While the top card travels, the pile behind already slides into the next slot,
        // so the instant reorder after a throw is invisible.
        let progress = min(abs(offset.width) / max(ctx.cg("threshold"), 1), 1)
        let slot = max(CGFloat(depth) - progress, 0)
        let appear: Double = depth < 3 ? 1 : (depth == 3 ? Double(progress) : 0)
        return CardsJellyBody(stretch: isTop ? stretch : .zero, content: CardsDeckFace(index: id, language: ctx.language))
            .animation(.spring(response: 0.28, dampingFraction: ctx["wobble"]), value: stretch)
            .keyframeAnimator(initialValue: CardsJellyPop(), trigger: pops) { content, pop in
                content.scaleEffect(x: isTop ? pop.x : 1, y: isTop ? pop.y : 1)
            } keyframes: { _ in
                KeyframeTrack(\.x) {
                    CubicKeyframe(1.08, duration: 0.12)
                    CubicKeyframe(0.95, duration: 0.14)
                    CubicKeyframe(1.02, duration: 0.14)
                    CubicKeyframe(1.0, duration: 0.15)
                }
                KeyframeTrack(\.y) {
                    CubicKeyframe(0.92, duration: 0.12)
                    CubicKeyframe(1.05, duration: 0.14)
                    CubicKeyframe(0.98, duration: 0.14)
                    CubicKeyframe(1.0, duration: 0.15)
                }
            }
            .scaleEffect(isTop ? 1 : 1 - slot * 0.05)
            .offset(y: isTop ? 0 : slot * 14)
            .offset(isTop ? offset : .zero)
            .opacity(appear)
            .shadow(color: .black.opacity(isTop ? 0.18 : 0.1), radius: isTop ? 16 : 10, y: isTop ? 10 : 6)
            .zIndex(Double(order.count - depth))
            .allowsHitTesting(isTop)
            .gesture(drag)
    }

    private var drag: some Gesture {
        DragGesture()
            .onChanged { value in
                offset = value.translation
                stretch = stretchVector(for: value.velocity)
                scheduleRelax()
            }
            .onEnded { value in
                relaxTask?.cancel()
                let threshold = ctx.cg("threshold")
                let predicted = value.predictedEndTranslation
                if abs(value.translation.width) > threshold || abs(predicted.width) > threshold * 2 {
                    fling(direction: predicted.width >= 0 ? 1 : -1)
                } else {
                    stretch = .zero
                    withAnimation(.spring(response: 0.42, dampingFraction: 0.6)) { offset = .zero }
                }
            }
    }

    private func stretchVector(for velocity: CGSize) -> CGSize {
        let speed = hypot(velocity.width, velocity.height)
        guard speed > 1 else { return .zero }
        let amount = min(speed / 3000, 1) * 0.18 * ctx.cg("jelly")
        return CGSize(width: velocity.width / speed * amount, height: velocity.height / speed * amount)
    }

    /// DragGesture only reports movement: treat 80 ms without events as "stopped".
    private func scheduleRelax() {
        relaxTask?.cancel()
        relaxTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(80))
            guard !Task.isCancelled else { return }
            stretch = .zero
        }
    }

    private func fling(direction: CGFloat, haptic: Bool = true) {
        if haptic && !ctx.isPreview { Haptics.tap(.medium) }
        stretch = CGSize(width: direction * 0.18 * ctx.cg("jelly"), height: 0)
        withAnimation(.spring(response: 0.38, dampingFraction: 0.9)) {
            offset = CGSize(width: direction * 460, height: offset.height + 30)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            var transaction = Transaction()
            transaction.disablesAnimations = true
            withTransaction(transaction) {
                let first = order.removeFirst()
                order.append(first)
                offset = .zero
                stretch = .zero
            }
            // Next tick, so the new top card sees the trigger change and plays the pop.
            DispatchQueue.main.async {
                pops += 1
            }
        }
    }

    private func autoFling() {
        autoDirection = -autoDirection
        let direction = autoDirection
        let muted = Haptics.isMuted || ctx.isPreview
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            offset = CGSize(width: direction * 60, height: -4)
        }
        stretch = CGSize(width: direction * 0.14 * ctx.cg("jelly"), height: 0)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            stretch = .zero
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            fling(direction: direction, haptic: !muted)
        }
    }
}

private struct CardsJellyPop {
    var x: CGFloat = 1
    var y: CGFloat = 1
}

/// Stretches its content along the stretch vector: rotate to the travel angle, scale on x, rotate back.
private struct CardsJellyBody<Content: View>: View, Animatable {
    var stretch: CGSize
    let content: Content

    var animatableData: CGSize.AnimatableData {
        get { stretch.animatableData }
        set { stretch.animatableData = newValue }
    }

    var body: some View {
        let amount = hypot(stretch.width, stretch.height)
        let angle = amount > 0.0001 ? atan2(Double(stretch.height), Double(stretch.width)) : 0
        content
            .rotationEffect(.radians(-angle))
            .scaleEffect(x: 1 + amount, y: 1 - amount * 0.5)
            .rotationEffect(.radians(angle))
    }
}
