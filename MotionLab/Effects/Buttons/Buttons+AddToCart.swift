import SwiftUI

extension Effect {
    static let buttonsAddToCart = Effect(
        id: "buttons.add-to-cart",
        category: .buttons,
        interaction: .tap,
        name: L("Add to Bag", "加入购物袋"),
        summary: L("The button morphs into a check while an item arcs into the bag.", "按钮收缩成对勾，商品沿弧线飞入购物袋。"),
        prompt: L(
            "A wide capsule \"Add to Bag\" button with a bag-plus glyph sits below a bag icon carrying a small count badge. On tap the capsule collapses from 220 pt to a 60 pt circle on a spring (response 0.45 s, damping 0.75) while turning green and cross-fading its label into a bold checkmark that scales in. At the same moment a small accent dot launches from the button and travels along a parabolic arc (rises ~40 pt above the target, ~550 ms, ease-in-out) into the bag, shrinking to half size. As it lands the bag does a symbol bounce, the badge pops and its number rolls up, and a success haptic fires. After ~1.2 s the button springs back to its original pill. Delightful, legible commerce feedback.",
            "购物袋图标右上角带一个数量角标，下方是一枚写着“加入购物袋”的宽胶囊按钮。点击后，胶囊以弹簧（响应 0.45 秒、阻尼 0.75）从 220pt 宽收缩为 60pt 的圆，同时变为绿色，文字交叉淡出、换成缩放出现的粗对勾。与此同时，一颗强调色小圆点从按钮弹出，沿抛物线（比目标点高约 40pt，约 550 毫秒，缓入缓出）飞进购物袋并缩小一半。落点瞬间购物袋做一次符号弹跳，角标弹起、数字向上滚动，并触发成功触觉。约 1.2 秒后按钮弹回原本的胶囊形态。清晰易懂又令人愉悦的电商反馈。"
        ),
        implementation: L(
            "Width, color and label swap animate together with a spring; a KeyframeAnimator view with separate x/y/scale/opacity tracks flies the dot on an arc; the bag uses symbolEffect(.bounce) and the badge numericText.",
            "宽度、颜色与文字切换由同一弹簧驱动；KeyframeAnimator 视图用独立的 x/y/缩放/透明度轨道让小圆点沿弧线飞行；购物袋使用 symbolEffect(.bounce)，角标使用 numericText。"
        ),
        apis: ["KeyframeAnimator", "symbolEffect(.bounce)", "numericText", "transition"],
        tags: ["cart", "shop", "morph", "success", "购物车", "加购", "电商", "形变"],
        params: [
            .slider("response", L("Morph response", "形变响应"), 0.2...0.9, default: 0.45, unit: "s"),
            .slider("hold", L("Hold before reset", "复位前停留"), 0.6...3.0, default: 1.2, unit: "s"),
            .toggle("fly", L("Flying item", "飞入动画"), default: true),
        ]
    ) { ctx in
        ButtonAddToCartDemo(ctx: ctx)
    }
}

private struct ButtonFlyFrame {
    var x: Double = 0
    var y: Double = 0
    var scale: Double = 1
    var opacity: Double = 0
}

private struct ButtonAddToCartDemo: View {
    let ctx: DemoContext
    @State private var added = false
    @State private var count = 2
    @State private var flights = 0

    /// Layout anchors relative to the stage center.
    private let bagCenter = CGPoint(x: 96, y: -96)
    private let buttonCenter = CGPoint(x: 0, y: 50)

    var body: some View {
        ZStack {
            bag
                .offset(x: bagCenter.x, y: bagCenter.y)
            button
                .offset(x: buttonCenter.x, y: buttonCenter.y)
            if ctx.bool("fly") {
                flyingDot
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: ctx["hold"] + 1.6, delay: 0.4) { add() }
    }

    private var bag: some View {
        Image(systemName: "bag.fill")
            .font(.system(size: 34, weight: .semibold))
            .foregroundStyle(.primary)
            .symbolEffect(.bounce, value: count)
            .frame(width: 64, height: 64)
            .background(Palette.elevated, in: Circle())
            .overlay(Circle().strokeBorder(Palette.stroke))
            .overlay(alignment: .topTrailing) {
                Text("\(count)")
                    .font(.caption.weight(.bold).monospacedDigit())
                    .foregroundStyle(.white)
                    .contentTransition(.numericText(value: Double(count)))
                    .frame(minWidth: 22, minHeight: 22)
                    .background(Palette.pink, in: Capsule())
                    .offset(x: 4, y: -4)
            }
    }

    private var button: some View {
        Button(action: add) {
            ZStack {
                if added {
                    Image(systemName: "checkmark")
                        .font(.system(size: 22, weight: .bold))
                        .transition(.scale(scale: 0.3).combined(with: .opacity))
                } else {
                    HStack(spacing: 8) {
                        Image(systemName: "bag.badge.plus")
                        Text(ctx.language == .zh ? "加入购物袋" : "Add to Bag")
                            .lineLimit(1)
                    }
                    .font(.headline)
                    .transition(.opacity.combined(with: .scale(scale: 0.8)))
                }
            }
            .foregroundStyle(.white)
            .frame(width: added ? 60 : 220, height: 60)
            .background(added ? Palette.green : Palette.indigo, in: Capsule())
            .shadow(color: (added ? Palette.green : Palette.indigo).opacity(0.35), radius: 14, y: 8)
        }
        .buttonStyle(.plain)
    }

    private var flyingDot: some View {
        KeyframeAnimator(initialValue: ButtonFlyFrame(), trigger: flights) { frame in
            Circle()
                .fill(Palette.primary)
                .frame(width: 22, height: 22)
                .scaleEffect(frame.scale)
                .opacity(frame.opacity)
                .offset(x: frame.x, y: frame.y)
                .allowsHitTesting(false)
        } keyframes: { _ in
            KeyframeTrack(\.x) {
                MoveKeyframe(Double(buttonCenter.x))
                CubicKeyframe(Double(bagCenter.x), duration: 0.55)
            }
            KeyframeTrack(\.y) {
                MoveKeyframe(Double(buttonCenter.y))
                CubicKeyframe(Double(bagCenter.y) - 40, duration: 0.3)
                CubicKeyframe(Double(bagCenter.y), duration: 0.25)
            }
            KeyframeTrack(\.scale) {
                MoveKeyframe(1)
                CubicKeyframe(0.5, duration: 0.55)
            }
            KeyframeTrack(\.opacity) {
                MoveKeyframe(1)
                LinearKeyframe(1, duration: 0.5)
                LinearKeyframe(0, duration: 0.08)
            }
        }
    }

    private func add() {
        guard !added else { return }
        let response = ctx["response"]
        let hold = ctx["hold"]
        let fly = ctx.bool("fly")
        let preview = ctx.isPreview
        if !preview { Haptics.tap() }
        withAnimation(.spring(response: response, dampingFraction: 0.75)) { added = true }
        if fly { flights += 1 }
        Task {
            try? await Task.sleep(for: .seconds(fly ? 0.55 : 0.2))
            withAnimation(.bouncy) { count += 1 }
            if !preview { Haptics.success() }
            try? await Task.sleep(for: .seconds(hold))
            withAnimation(.spring(response: response, dampingFraction: 0.75)) { added = false }
        }
    }
}
