import SwiftUI

extension Effect {
    static let inputsRangeSlider = Effect(
        id: "inputs.range-slider",
        category: .inputs,
        interaction: .gesture,
        name: L("Price Range Slider", "价格区间滑块"),
        summary: L(
            "Two springy handles with value bubbles carve a range out of a live price histogram.",
            "两个带数值气泡的弹性手柄，在实时价格分布图上圈出区间。"
        ),
        prompt: L(
            "A “Price per night” filter card: a 24-bar price histogram above a 6 pt track with two white 26 pt handles, a gradient fill between them, and a small blue value bubble riding above each handle. Touching the track grabs the nearest handle — if the touch lands away from it, the handle leaps there on a spring (response 0.35 s, damping 0.7) — and the grabbed handle swells to 115% with a blue ring while its bubble lifts 4 pt and grows. Dragging updates the price in $10 steps with a selection tick each step; histogram bars inside the range light up blue as the edges pass them, the header range and the “Show N stays” count roll with numeric transitions. The handles can't cross: they stop a minimum gap apart with a rigid haptic, and bubbles that would overlap slide apart. Precise, lively and legible.",
            "“每晚价格”筛选卡片：上方 24 根价格分布柱，下方是 6pt 轨道、两个 26pt 白色手柄、其间的渐变填充，以及悬在手柄上方的蓝色数值气泡。触摸轨道会抓取最近的手柄，触点较远时手柄以弹簧（响应 0.35 秒、阻尼 0.7）跳过去；被抓手柄放大到 115% 并现蓝色描边，气泡上移 4pt 并放大。拖动以 10 美元步进，每步一次选择触感；区间内分布柱随边界经过点亮，标题区间与“查看 N 处住宿”滚动更新。手柄不能交叉：到最小间距时停住并硬朗触感，重叠的气泡自动错开。"
        ),
        implementation: L(
            "One zero-distance DragGesture over the track picks the nearest handle on touch-down and then drives that handle's value, clamped against the other plus a minimum gap; jumps and the active state animate with a spring, while prices are quantized to $10 for haptics and numericText.",
            "轨道上的一个零距离 DragGesture 在按下时选中最近的手柄，之后驱动该手柄的数值，并以另一手柄加最小间隔为界；跳转与激活状态用弹簧动画，价格按 10 美元量化，用于触感与 numericText。"
        ),
        apis: ["DragGesture", "spring(response:dampingFraction:)", "contentTransition(.numericText(value:))", "scaleEffect(anchor:)", "Haptics"],
        tags: ["range slider", "dual slider", "filter", "price", "区间滑块", "双滑块", "筛选", "价格"],
        params: [
            .slider("response", L("Spring response", "弹簧响应"), 0.15...0.8, default: 0.35, unit: "s"),
            .slider("damping", L("Damping", "阻尼"), 0.4...1.0, default: 0.7),
            .slider("gap", L("Minimum gap", "最小间隔"), 0.04...0.3, default: 0.1),
        ]
    ) { ctx in
        InputRangeSliderDemo(ctx: ctx)
    }
}

private enum InputRangeThumb {
    case lower
    case upper
}

private struct InputRangeSliderDemo: View {
    let ctx: DemoContext
    @State private var lower: Double = 0.24
    @State private var upper: Double = 0.66
    @State private var active: InputRangeThumb?
    @State private var pinned = false
    @State private var step = 0
    /// Resets on system cancellation too (Control Center pull, incoming call), so a cancelled touch still releases.
    @GestureState private var touching = false

    private let width: CGFloat = 264
    private static let maxPrice = 500.0
    private static let bars: [Double] = (0..<24).map { i in
        let x = Double(i)
        let bell = exp(-pow((x - 9) / 6, 2))
        let n = sin(x * 12.9898 + 4.1) * 43758.5453
        return 0.18 + 0.62 * bell + 0.2 * (n - n.rounded(.down))
    }
    private static let previewRanges: [(Double, Double)] = [(0.1, 0.46), (0.36, 0.9), (0.2, 0.5), (0.5, 0.78)]

    private var spring: Animation { .spring(response: ctx["response"], dampingFraction: ctx["damping"]) }

    private static func price(_ value: Double) -> Int {
        Int((value * maxPrice / 10).rounded()) * 10
    }

    private func inRange(_ index: Int) -> Bool {
        let center = (Double(index) + 0.5) / Double(Self.bars.count)
        return center >= lower && center <= upper
    }

    private var stays: Int {
        let covered = Self.bars.indices.filter { inRange($0) }.map { Self.bars[$0] }.reduce(0, +)
        return Int((covered * 11).rounded())
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)
            card
            Spacer(minLength: 0)
            DemoHint(text: L("Drag either handle, or tap the track", "拖动任一手柄，或点按轨道"), ctx: ctx)
                .padding(.bottom, 16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 1.4, delay: 0.4) { previewTick() }
    }

    private var card: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text(L("Price per night", "每晚价格"), ctx.language)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Spacer(minLength: 0)
                Text(verbatim: "$\(Self.price(lower)) – $\(Self.price(upper))")
                    .font(.subheadline.weight(.semibold).monospacedDigit())
                    .foregroundStyle(Palette.blue)
                    .contentTransition(.numericText(value: lower + upper))
                    .animation(.snappy, value: Self.price(lower) + Self.price(upper) * 1000)
            }
            histogram
            slider
                .padding(.top, 34)
            HStack {
                Text(verbatim: "$0")
                Spacer(minLength: 0)
                Text(verbatim: "$500+")
            }
            .font(.caption2.weight(.medium).monospacedDigit())
            .foregroundStyle(.tertiary)
            Text(ctx.language == .zh ? "查看 \(stays) 处住宿" : "Show \(stays) stays")
                .font(.subheadline.weight(.semibold).monospacedDigit())
                .foregroundStyle(.white)
                .contentTransition(.numericText(value: Double(stays)))
                .animation(.snappy, value: stays)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(Palette.primary, in: Capsule())
                .padding(.top, 2)
        }
        .padding(18)
        .frame(width: width + 36)
        .demoCard(cornerRadius: 24)
    }

    private var histogram: some View {
        let gap: CGFloat = 3
        let count = Self.bars.count
        let barWidth = (width - gap * CGFloat(count - 1)) / CGFloat(count)
        return HStack(alignment: .bottom, spacing: gap) {
            ForEach(0..<count, id: \.self) { index in
                let lit = inRange(index)
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(lit ? Palette.blue.opacity(0.75) : Color.primary.opacity(0.12))
                    .frame(width: barWidth, height: 40 * CGFloat(Self.bars[index]))
                    .animation(.easeOut(duration: 0.15), value: lit)
            }
        }
        .frame(width: width, height: 40, alignment: .bottom)
    }

    private var slider: some View {
        let xl = width * CGFloat(lower)
        let xu = width * CGFloat(upper)
        let bubbles = bubbleCenters(xl, xu)
        return ZStack(alignment: .leading) {
            Capsule()
                .fill(Color.primary.opacity(0.1))
                .frame(height: 6)
            Capsule()
                .fill(LinearGradient(colors: [Palette.sky, Palette.blue], startPoint: .leading, endPoint: .trailing))
                .frame(width: max(xu - xl, 6), height: 6)
                .offset(x: xl)
            handle(.lower, x: xl)
            handle(.upper, x: xu)
            bubble(.lower, centerX: bubbles.0)
            bubble(.upper, centerX: bubbles.1)
        }
        .frame(width: width, height: 28)
        .contentShape(Rectangle())
        .gesture(drag)
        .onChange(of: touching) { _, isTouching in
            if !isTouching { endDrag() }
        }
    }

    /// Keeps the two 52 pt bubbles apart and inside the track.
    private func bubbleCenters(_ xl: CGFloat, _ xu: CGFloat) -> (CGFloat, CGFloat) {
        let half: CGFloat = 26
        var left = xl
        var right = xu
        if right - left < half * 2 + 4 {
            let mid = (left + right) / 2
            left = mid - half - 2
            right = mid + half + 2
        }
        let shiftIn = max(0, half - left)
        let shiftOut = max(0, right - (width - half))
        return (left + shiftIn - shiftOut, right + shiftIn - shiftOut)
    }

    private func handle(_ thumb: InputRangeThumb, x: CGFloat) -> some View {
        let isActive = active == thumb
        return Circle()
            .fill(Color.white)
            .overlay(Circle().strokeBorder(Palette.blue, lineWidth: isActive ? 2.5 : 0))
            .shadow(color: .black.opacity(0.22), radius: 5, y: 2)
            .frame(width: 26, height: 26)
            .scaleEffect(isActive ? 1.15 : 1)
            .animation(spring, value: isActive)
            .offset(x: x - 13)
    }

    private func bubble(_ thumb: InputRangeThumb, centerX: CGFloat) -> some View {
        let isActive = active == thumb
        let value = thumb == .lower ? lower : upper
        return Text(verbatim: "$\(Self.price(value))")
            .font(.system(size: 12, weight: .bold, design: .rounded).monospacedDigit())
            .foregroundStyle(.white)
            .frame(width: 52, height: 24)
            .background(Palette.blue.opacity(isActive ? 1 : 0.8), in: Capsule())
            .scaleEffect(isActive ? 1.1 : 0.92, anchor: .bottom)
            .offset(y: isActive ? -4 : 0)
            .animation(spring, value: isActive)
            .offset(x: centerX - 26, y: -32)
            .allowsHitTesting(false)
    }

    private var drag: some Gesture {
        DragGesture(minimumDistance: 0)
            .updating($touching) { _, state, _ in state = true }
            .onChanged { gesture in
                let v = Double(gesture.location.x / width).clamped(to: 0...1)
                if let thumb = active {
                    move(thumb, to: v, animated: false)
                } else {
                    let dl = abs(v - lower)
                    let du = abs(v - upper)
                    let pick: InputRangeThumb = dl == du ? (v < lower ? .lower : .upper) : (dl < du ? .lower : .upper)
                    active = pick
                    let current = pick == .lower ? lower : upper
                    move(pick, to: v, animated: abs(v - current) * Double(width) > 14)
                }
            }
            .onEnded { _ in endDrag() }
    }

    /// Single cleanup for a lifted or cancelled finger.
    private func endDrag() {
        guard active != nil || pinned else { return }
        active = nil
        pinned = false
    }

    private func move(_ thumb: InputRangeThumb, to value: Double, animated: Bool) {
        let gap = ctx["gap"]
        var target = value
        var hit = false
        switch thumb {
        case .lower:
            let limit = upper - gap
            if target > limit {
                target = limit
                hit = true
            }
            target = max(0, target)
        case .upper:
            let limit = lower + gap
            if target < limit {
                target = limit
                hit = true
            }
            target = min(1, target)
        }
        let oldPrice = Self.price(thumb == .lower ? lower : upper)
        let apply = {
            if thumb == .lower { lower = target } else { upper = target }
        }
        if animated {
            withAnimation(spring, apply)
        } else {
            apply()
        }
        if Self.price(target) != oldPrice && !hit { Haptics.selection() }
        if hit && !pinned { Haptics.tap(.rigid) }
        pinned = hit
    }

    private func previewTick() {
        let range = Self.previewRanges[step % Self.previewRanges.count]
        let thumb: InputRangeThumb = step % 2 == 0 ? .lower : .upper
        step += 1
        active = thumb
        withAnimation(spring) {
            lower = range.0
            upper = range.1
        }
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.7))
            active = nil
        }
    }
}
