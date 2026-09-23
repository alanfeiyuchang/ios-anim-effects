import SwiftUI

extension Effect {
    static let buttonsAddToCart = Effect(
        id: "buttons.add-to-cart",
        category: .buttons,
        interaction: .tap,
        name: L("Add to Bag", "加入购物袋"),
        summary: L("The button morphs into a check while an item arcs into the bag.", "按钮收缩成对勾，商品沿弧线飞入购物袋。"),
        prompt: L(
            "A product card (gradient thumbnail, name, price) with a wide “Add to Bag” capsule; a bag icon with a count badge floats top-right. On tap the capsule collapses from 220 pt to a 60 pt circle on a spring (response 0.45 s, damping 0.75), turning green as its label cross-fades into a bold checkmark. A copy of the 64 pt product image lifts off the thumbnail, swells to 108% in the first 100 ms, then flies a parabolic arc (peak ~44 pt above the bag, ~600 ms, ease-in-out), shrinking to 30% and tilting 18° as it drops in. On landing the bag bounces, the badge pops to 145% and springs back (response 0.3 s, damping 0.45) while its number rolls up, and a success haptic fires. After ~1.2 s the button springs back to its pill. Legible, delightful commerce feedback.",
            "商品卡片底部是“加入购物袋”宽胶囊，右上角悬浮带角标的购物袋。点击后胶囊以弹簧（响应 0.45 秒、阻尼 0.75）从 220pt 收成 60pt 绿色圆，文字淡变为对勾。同时 64pt 商品图副本从缩略图拎起，前 100 毫秒放大到 108%，再沿抛物线（顶点高出袋口约 44pt，约 600 毫秒）落入袋中，途中缩到 30%、倾斜 18°。落袋时购物袋弹跳，角标弹到 145% 再回落（响应 0.3 秒、阻尼 0.45），数字上滚并触发成功触觉；约 1.2 秒后复原。"
        ),
        implementation: L(
            "Width, color and label swap animate together with a spring; a KeyframeAnimator view with separate x/y/scale/rotation/opacity tracks flies the thumbnail on an arc; the bag uses symbolEffect(.bounce) and the badge a keyframeAnimator pop plus numericText.",
            "宽度、颜色与文字切换由同一弹簧驱动；KeyframeAnimator 视图用独立的 x/y/缩放/旋转/透明度轨道让缩略图沿弧线飞行；购物袋使用 symbolEffect(.bounce)，角标使用 keyframeAnimator 弹跳与 numericText。"
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
    var spin: Double = 0
    var opacity: Double = 0
}

/// Product image stand-in: a warm gradient tile with a glyph and a glossy top edge.
private struct ButtonProductThumb: View {
    let side: CGFloat

    var body: some View {
        RoundedRectangle(cornerRadius: side * 0.26, style: .continuous)
            .fill(LinearGradient(colors: [Palette.amber, Palette.coral, Palette.pink], startPoint: .topLeading, endPoint: .bottomTrailing))
            .overlay {
                Image(systemName: "headphones")
                    .font(.system(size: side * 0.44, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .overlay {
                RoundedRectangle(cornerRadius: side * 0.26, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.3), lineWidth: 1)
            }
            .frame(width: side, height: side)
            .shadow(color: Palette.coral.opacity(0.3), radius: side * 0.15, y: side * 0.08)
    }
}

private struct ButtonAddToCartDemo: View {
    let ctx: DemoContext
    @State private var added = false
    @State private var count = 2
    @State private var flights = 0

    /// Layout anchors relative to the stage center.
    private let bagCenter = CGPoint(x: 104, y: -122)
    private let buttonCenter = CGPoint(x: 0, y: 62)
    private let thumbCenter = CGPoint(x: -97, y: -30)

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(Color.clear)
                .frame(width: 292, height: 210)
                .demoCard(cornerRadius: 26)
                .offset(y: 16)
            productRow
                .offset(y: thumbCenter.y)
            bag
                .offset(x: bagCenter.x, y: bagCenter.y)
            button
                .offset(x: buttonCenter.x, y: buttonCenter.y)
            if ctx.bool("fly") {
                flyingItem
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: ctx["hold"] + 1.6, delay: 0.4) { add() }
    }

    private var productRow: some View {
        HStack(spacing: 14) {
            ButtonProductThumb(side: 64)
            VStack(alignment: .leading, spacing: 4) {
                Text(ctx.language == .zh ? "降噪头戴耳机" : "Studio Headphones")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                HStack(spacing: 3) {
                    Image(systemName: "star.fill")
                        .foregroundStyle(Palette.amber)
                    Text("4.9 · 2.1k")
                        .foregroundStyle(.secondary)
                }
                .font(.caption2.weight(.semibold))
                Text(ctx.language == .zh ? "¥1,299" : "$199")
                    .font(.system(.headline, design: .rounded).monospacedDigit())
                    .foregroundStyle(.primary)
            }
            Spacer(minLength: 0)
        }
        .frame(width: 258)
    }

    private var bag: some View {
        Image(systemName: "bag.fill")
            .font(.system(size: 26, weight: .semibold))
            .foregroundStyle(.primary)
            .symbolEffect(.bounce, value: count)
            .frame(width: 56, height: 56)
            .background(Palette.elevated, in: Circle())
            .overlay(Circle().strokeBorder(Palette.stroke))
            .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
            .overlay(alignment: .topTrailing) {
                Text("\(count)")
                    .font(.caption.weight(.bold).monospacedDigit())
                    .foregroundStyle(.white)
                    .contentTransition(.numericText(value: Double(count)))
                    .frame(minWidth: 22, minHeight: 22)
                    .background(Palette.pink, in: Capsule())
                    .keyframeAnimator(initialValue: 1.0, trigger: count) { content, scale in
                        content.scaleEffect(scale)
                    } keyframes: { _ in
                        KeyframeTrack(\.self) {
                            CubicKeyframe(1.45, duration: 0.12)
                            SpringKeyframe(1, duration: 0.45, spring: Spring(response: 0.3, dampingRatio: 0.45))
                        }
                    }
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

    /// A mini copy of the product image hops from the card into the bag.
    private var flyingItem: some View {
        let start = thumbCenter
        let end = bagCenter
        return KeyframeAnimator(initialValue: ButtonFlyFrame(), trigger: flights) { frame in
            ButtonProductThumb(side: 64)
                .scaleEffect(frame.scale)
                .rotationEffect(.degrees(frame.spin))
                .opacity(frame.opacity)
                .offset(x: frame.x, y: frame.y)
                .allowsHitTesting(false)
        } keyframes: { _ in
            KeyframeTrack(\.x) {
                MoveKeyframe(Double(start.x))
                CubicKeyframe(Double(end.x), duration: 0.6)
            }
            KeyframeTrack(\.y) {
                MoveKeyframe(Double(start.y))
                CubicKeyframe(Double(end.y) - 44, duration: 0.34)
                CubicKeyframe(Double(end.y), duration: 0.26)
            }
            KeyframeTrack(\.scale) {
                // Starts exactly over the 64 pt thumbnail, lifts a touch, then shrinks into the bag.
                MoveKeyframe(1)
                CubicKeyframe(1.08, duration: 0.1)
                CubicKeyframe(0.3, duration: 0.5)
            }
            KeyframeTrack(\.spin) {
                MoveKeyframe(0)
                CubicKeyframe(18, duration: 0.6)
            }
            KeyframeTrack(\.opacity) {
                MoveKeyframe(1)
                LinearKeyframe(1, duration: 0.52)
                LinearKeyframe(0, duration: 0.08)
            }
        }
    }

    private func add() {
        guard !added else { return }
        let response = ctx["response"]
        let hold = ctx["hold"]
        let fly = ctx.bool("fly")
        // Captured now: autoplay (and the detail intro) mute haptics only for the synchronous part.
        let preview = ctx.isPreview || Haptics.isMuted
        if !preview { Haptics.tap() }
        withAnimation(.spring(response: response, dampingFraction: 0.75)) { added = true }
        if fly { flights += 1 }
        Task {
            try? await Task.sleep(for: .seconds(fly ? 0.6 : 0.2))
            withAnimation(.bouncy) { count += 1 }
            if !preview { Haptics.success() }
            try? await Task.sleep(for: .seconds(hold))
            withAnimation(.spring(response: response, dampingFraction: 0.75)) { added = false }
        }
    }
}
