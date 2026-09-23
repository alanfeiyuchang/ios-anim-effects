import SwiftUI

extension Effect {
    static let morphSortHop = Effect(
        id: "morph.sort-hop",
        category: .morph,
        interaction: .tap,
        name: L("Sort Hop", "排序跳跃"),
        summary: L(
            "Bars re-sort by hopping over and ducking under each other, each arc sized to how far it travels.",
            "柱条重新排序时互相越过或钻过，弧线高度与移动距离成正比。"
        ),
        prompt: L(
            "Six rounded bars of different heights stand on a baseline, each labelled with its value. Tapping Sort (or Shuffle) sends every bar to its new slot on a horizontal spring (response ≈0.5 s, damping 0.78) while it follows an arc: bars moving right lift above the row and bars moving left dip below it, so they pass without colliding, and each arc's height is ≈10 pt per slot travelled. Airborne bars scale up to ≈108% and gain a deeper shadow, then land with a quick bouncy settle. Bars that stay put give a tiny nod. The button label rolls between Sort and Shuffle. Clear, playful choreography that makes a reorder legible.",
            "六根高度不同的圆角柱条立在基线上，各自标注数值。点击「排序」（或「打乱」）后，每根柱条以水平弹簧（响应约 0.5 秒、阻尼 0.78）移向新位置，同时沿一条弧线运动：向右移动的柱条从上方越过，向左移动的从下方钻过，互不碰撞；弧线高度约为每移动一格 10pt。腾空中的柱条放大到约 108% 并加深阴影，落地时带一个轻快的弹跳。位置不变的柱条只轻轻点一下头。按钮文字在「排序」与「打乱」之间滚动切换。编排清晰、俏皮，让重新排序一目了然。"
        ),
        implementation: L(
            "Slot indices drive each bar's x offset through animation(_:value:); a keyframeAnimator keyed on a move counter plays the vertical arc and scale, with the arc height and direction captured from each bar's last slot change.",
            "槽位序号通过 animation(_:value:) 驱动每根柱条的横向位移；以移动计数为触发器的 keyframeAnimator 播放竖直弧线与缩放，弧高与方向取自该柱条上一次的槽位变化。"
        ),
        apis: ["keyframeAnimator", "KeyframeTrack", "SpringKeyframe", "animation(_:value:)", "transition(.push(from:))"],
        tags: ["sort", "reorder", "shuffle", "arc", "排序", "重排", "打乱", "弧线"],
        params: [
            .slider("response", L("Spring response", "弹簧响应"), 0.25...1.0, default: 0.5, unit: "s"),
            .slider("lift", L("Arc per slot", "每格弧高"), 0...20, default: 10, decimals: 0, unit: "pt"),
            .toggle("split", L("Right over, left under", "右上左下分流"), default: true),
        ]
    ) { ctx in
        SortHopDemo(ctx: ctx)
    }
}

private struct HopFrame {
    var y: CGFloat = 0
    var scale: CGFloat = 1
}

private let hopValues: [Int] = [62, 24, 88, 45, 71, 33]

private struct SortHopDemo: View {
    let ctx: DemoContext
    /// Bar index (into hopValues) for each slot, left to right.
    @State private var order: [Int] = [0, 1, 2, 3, 4, 5]
    /// Signed slot change of each bar in its most recent move.
    @State private var travel: [Int] = Array(repeating: 0, count: 6)
    @State private var moves = 0
    @State private var sorted = false

    private let spacing: CGFloat = 42

    var body: some View {
        VStack(spacing: 26) {
            ZStack(alignment: .bottom) {
                Capsule()
                    .fill(Color.primary.opacity(0.1))
                    .frame(width: 270, height: 2)
                ForEach(0..<hopValues.count, id: \.self) { bar in
                    barView(bar)
                }
            }
            .frame(width: 280, height: 190, alignment: .bottom)

            Button { shuffleOrSort() } label: {
                Text(sorted ? L("Shuffle", "打乱") : L("Sort", "排序"), ctx.language)
                    .font(.headline)
                    .foregroundStyle(.white)
                    .id(sorted)
                    .transition(.push(from: .bottom))
                    .frame(width: 140, height: 46)
                    .background(Palette.primary, in: Capsule())
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            DemoHint(text: L("Tap the button", "点击按钮"), ctx: ctx)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 1.6) { shuffleOrSort() }
    }

    private func barView(_ bar: Int) -> some View {
        let slot: Int = order.firstIndex(of: bar) ?? bar
        let x: CGFloat = (CGFloat(slot) - 2.5) * spacing
        let value = hopValues[bar]
        let delta: Int = travel[bar]
        let perSlot: CGFloat = ctx.cg("lift")
        let direction: CGFloat = (ctx.bool("split") && delta < 0) ? 1 : -1
        let arc: CGFloat = delta == 0 ? -4 : direction * perSlot * CGFloat(abs(delta))
        let color = Palette.spectrum[bar % Palette.spectrum.count]
        return VStack(spacing: 6) {
            Text(verbatim: "\(value)")
                .font(.caption.weight(.bold).monospacedDigit())
                .foregroundStyle(.secondary)
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(color.gradient)
                .frame(width: 32, height: CGFloat(value) * 1.6)
        }
        .keyframeAnimator(initialValue: HopFrame(), trigger: moves) { content, frame in
            content
                .scaleEffect(frame.scale, anchor: .bottom)
                .offset(y: frame.y)
                .shadow(color: .black.opacity(liftShadow(frame.scale)), radius: liftRadius(frame.scale), y: 3)
        } keyframes: { _ in
            KeyframeTrack(\.y) {
                CubicKeyframe(arc, duration: 0.22)
                SpringKeyframe(0, duration: 0.42, spring: .bouncy)
            }
            KeyframeTrack(\.scale) {
                CubicKeyframe(delta == 0 ? 1 : 1.08, duration: 0.22)
                SpringKeyframe(1, duration: 0.42, spring: .bouncy)
            }
        }
        .offset(x: x)
        .animation(.spring(response: ctx["response"], dampingFraction: 0.78), value: order)
    }

    /// 0.1 at rest, 0.3 at the 108% airborne scale.
    private func liftShadow(_ scale: CGFloat) -> Double {
        let lift: Double = Double(max(scale - 1, 0))
        return 0.1 + lift * 2.5
    }

    private func liftRadius(_ scale: CGFloat) -> CGFloat {
        let lift: CGFloat = max(scale - 1, 0)
        return 4 + lift * 100
    }

    private func shuffleOrSort() {
        let next: [Int]
        if sorted {
            var candidate = order.shuffled()
            if candidate == order { candidate = Array(order.reversed()) }
            next = candidate
        } else {
            next = order.sorted { hopValues[$0] < hopValues[$1] }
        }
        var newTravel: [Int] = Array(repeating: 0, count: hopValues.count)
        for bar in 0..<hopValues.count {
            let from: Int = order.firstIndex(of: bar) ?? bar
            let to: Int = next.firstIndex(of: bar) ?? bar
            newTravel[bar] = to - from
        }
        if !ctx.isPreview { Haptics.tap(.medium) }
        travel = newTravel
        moves += 1
        withAnimation(.snappy) { sorted.toggle() }
        order = next
    }
}
