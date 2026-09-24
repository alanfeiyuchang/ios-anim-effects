import SwiftUI

extension Effect {
    static let cardsJellySwipe = Effect(
        id: "cards.jelly-swipe",
        category: .cards,
        interaction: .gesture,
        name: L("Jelly Swipe", "果冻滑卡"),
        summary: L("Cards stretch along the drag velocity like jelly, wobble when the finger stops and pop in with a squash.", "卡片沿拖动速度像果冻一样拉伸，手指停下时晃动，新卡片挤压弹出。"),
        prompt: L(
            "A deck of 190×240 pt destination cards with 24 pt corners. While dragging, the top card follows the finger and stretches along the direction of travel in proportion to speed — up to 18% longer and 15% thinner at 3,000 pt/s, keeping its area — through a wobbly spring (response 0.28 s, damping 0.32). When the finger pauses for 80 ms or lets go, the overshoot flips into a squash, so the card jiggles stretch → squash → stretch back to shape. Releasing past 100 pt or with a fast flick throws it off-stage still stretched; the next card then pops forward with a squash-and-stretch keyframe sequence (x/y 108/92% → 95/105% → 102/98% → 100% over ~0.55 s) while the pile behind steps up. Playful, gummy and elastic.",
            "一叠190×240 pt、24 pt圆角的目的地卡片。拖动时顶部卡片跟手，并按速度沿运动方向拉伸——3000 pt/s时最多拉长18%、变细15%，面积不变——由易晃动的弹簧（响应0.28秒、阻尼0.32）驱动；手指停顿80毫秒或松开时，过冲翻转为挤压，卡片拉长、压扁、再拉长地抖回原形。拖过100 pt或快速甩动后松手，卡片带着拉伸飞出舞台；下一张随即以挤压拉伸关键帧弹到前面（x/y依次108/92%→95/105%→102/98%→100%，约0.55秒），后方卡堆上移。俏皮Q弹。"
        ),
        implementation: L(
            "DragGesture.velocity sets a signed, traceless strain tensor (s·cos2θ, s·sin2θ) that an .animation(value:) spring smooths; a GeometryEffect applies an area-preserving stretch (1+s along, 1/(1+s) across), so the spring's overshoot through zero becomes a squash. A debounce Task relaxes the strain when events stop, and keyframeAnimator plays the pop.",
            "DragGesture.velocity 设置带符号的无迹应变张量 (s·cos2θ, s·sin2θ)，由 .animation(value:) 弹簧平滑；GeometryEffect 施加面积不变的拉伸（沿向 1+s、横向 1/(1+s)），弹簧越过零点的过冲因此变成挤压。事件停止时由防抖 Task 放松应变，keyframeAnimator 播放弹出效果。"
        ),
        apis: ["DragGesture.Value.velocity", "GeometryEffect", "keyframeAnimator", "animation(_:value:)", "Task.sleep"],
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
    /// Signed strain tensor (e1, e2) = s·(cos 2θ, sin 2θ): s = amount (0…0.18), θ = travel angle.
    /// Relaxing through zero flips the principal axis by 90°, so the overshoot squashes.
    @State private var stretch: CGSize = .zero
    @State private var pops = 0
    @State private var relaxTask: Task<Void, Never>?
    @State private var autoDirection: CGFloat = 1
    /// True from a throw until the reorder, so the flying card can't be grabbed or thrown twice.
    @State private var flinging = false
    /// True while a real finger holds the top card.
    @State private var held = false
    /// The scripted (preview / intro) fling, cancelled on the first real touch and on disappear.
    @State private var script: Task<Void, Never>?
    /// Resets on system cancellation too, so a stolen touch never leaves the card stretched off-centre.
    @GestureState private var pressing = false

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
        .onChange(of: pressing) { _, isPressing in
            if !isPressing { cancelHold() }
        }
        .onDisappear {
            script?.cancel()
            script = nil
            relaxTask?.cancel()
            held = false
            guard !flinging else { return }
            var transaction = Transaction()
            transaction.disablesAnimations = true
            withTransaction(transaction) {
                offset = .zero
                stretch = .zero
            }
        }
    }

    private func card(_ id: Int) -> some View {
        let depth = order.firstIndex(of: id) ?? 0
        let isTop = depth == 0
        // While the top card travels, the pile behind already slides into the next slot,
        // so the instant reorder after a throw is invisible.
        let progress = min(abs(offset.width) / max(ctx.cg("threshold"), 1), 1)
        let slot = max(CGFloat(depth) - progress, 0)
        let appear: Double = depth < 3 ? 1 : (depth == 3 ? Double(progress) : 0)
        return CardsDeckFace(index: id, language: ctx.language)
            .modifier(CardsJellyStrain(e1: isTop ? stretch.width : 0, e2: isTop ? stretch.height : 0))
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
            .allowsHitTesting(isTop && !flinging)
            .gesture(drag)
    }

    private var drag: some Gesture {
        DragGesture()
            .updating($pressing) { _, state, _ in state = true }
            .onChanged { value in
                guard !flinging else { return }
                if !held {
                    held = true
                    script?.cancel()
                    script = nil
                }
                offset = value.translation
                stretch = stretchVector(for: value.velocity)
                scheduleRelax()
            }
            .onEnded { value in
                guard held, !flinging else { return }
                held = false
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
        let theta = atan2(velocity.height, velocity.width)
        return CGSize(width: amount * cos(2 * theta), height: amount * sin(2 * theta))
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

    /// System cancellation (no `onEnded`): relax the jelly and spring the card home.
    private func cancelHold() {
        guard held else { return }
        held = false
        relaxTask?.cancel()
        stretch = .zero
        withAnimation(.spring(response: 0.42, dampingFraction: 0.6)) { offset = .zero }
    }

    private func fling(direction: CGFloat, haptic: Bool = true) {
        guard !flinging else { return }
        flinging = true
        if haptic && !ctx.isPreview { Haptics.tap(.medium) }
        // Horizontal travel (θ = 0 or π): the tensor is (s, 0) either way.
        stretch = CGSize(width: 0.18 * ctx.cg("jelly"), height: 0)
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
            flinging = false
            // Next tick, so the new top card sees the trigger change and plays the pop.
            DispatchQueue.main.async {
                pops += 1
            }
        }
    }

    private func autoFling() {
        guard !held && !flinging else { return }
        autoDirection = -autoDirection
        let direction = autoDirection
        let muted = Haptics.isMuted || ctx.isPreview
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            offset = CGSize(width: direction * 60, height: -4)
        }
        stretch = CGSize(width: 0.14 * ctx.cg("jelly"), height: 0)
        script?.cancel()
        script = Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.35))
            guard !Task.isCancelled else { return }
            stretch = .zero
            try? await Task.sleep(for: .seconds(0.45))
            guard !Task.isCancelled else { return }
            fling(direction: direction, haptic: !muted)
        }
    }
}

private struct CardsJellyPop {
    var x: CGFloat = 1
    var y: CGFloat = 1
}

/// Area-preserving stretch from a signed strain tensor (e1, e2) = s·(cos 2θ, sin 2θ):
/// scale 1 + s along θ and 1 / (1 + s) across, around the view centre. Because the tensor is
/// animated component-wise, a spring that overshoots zero lands on the perpendicular axis,
/// which is a squash along the original travel direction.
private struct CardsJellyStrain: GeometryEffect {
    var e1: CGFloat
    var e2: CGFloat

    var animatableData: AnimatablePair<CGFloat, CGFloat> {
        get { AnimatablePair(e1, e2) }
        set {
            e1 = newValue.first
            e2 = newValue.second
        }
    }

    func effectValue(size: CGSize) -> ProjectionTransform {
        let s = (e1 * e1 + e2 * e2).squareRoot()
        guard s > 0.0001 else { return ProjectionTransform(CGAffineTransform.identity) }
        let along = 1 + s
        let across = 1 / along
        let mean = (along + across) / 2
        let half = (along - across) / 2
        // R(θ)·diag(along, across)·R(−θ), written with cos 2θ = e1 / s and sin 2θ = e2 / s.
        let a = mean + half * e1 / s
        let d = mean - half * e1 / s
        let b = half * e2 / s
        let cx = size.width / 2
        let cy = size.height / 2
        let transform = CGAffineTransform(
            a: a, b: b, c: b, d: d,
            tx: cx - (a * cx + b * cy),
            ty: cy - (b * cx + d * cy)
        )
        return ProjectionTransform(transform)
    }
}
