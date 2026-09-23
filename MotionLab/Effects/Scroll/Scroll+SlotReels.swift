import SwiftUI

extension Effect {
    static let scrollSlotReels = Effect(
        id: "scroll.slot-reels",
        category: .scroll,
        interaction: .scroll,
        name: L("Slot Machine Reels", "老虎机滚轮"),
        summary: L("Three curved scroll reels spin and stop one after another with a bounce, lining up on a payline.", "三条弧形滚动卷轴旋转后依次回弹停下，在中线上对齐。"),
        prompt: L(
            "Three vertical reels of 64 pt symbol cells sit side by side inside a rounded cabinet, each curved like a drum: cells tilt back up to 50° and fade toward the top and bottom edges, which dissolve through a gradient mask. Tapping Spin sends every reel 16–30 cells down with a bouncy spring whose duration grows per reel (1.1 s, 1.55 s, 2.0 s, bounce 0.18), so they stop left to right with a small overshoot each, with a haptic on every stop. When all three symbols match on the gold payline, the payline glows and a success haptic fires. Each reel can also be flicked by hand and snaps to whole cells. Suspenseful, rhythmic and fun.",
            "三条竖向卷轴并排放在圆角机箱中，每格符号64 pt，每条卷轴都弯成滚筒：越靠上下边缘的格子向后倾斜越多（最多50°）并逐渐变淡，边缘通过渐变遮罩融化。点击「旋转」后，每条卷轴向下滚动16–30格，弹簧时长逐条递增（1.1秒、1.55秒、2.0秒，回弹0.18），因此从左到右依次停下，每次都带轻微过冲，并伴随触感。三个符号在金色中线上一致时，中线发光并触发成功触感。每条卷轴也可以用手拨动，并吸附到整格。悬念十足、富有节奏、好玩。"
        ),
        implementation: L(
            "Each reel is a ScrollView with its own ScrollPosition in an array; a spin calls scrollTo(y:) inside withAnimation(.spring(duration:bounce:)) with a per-reel duration. visualEffect curves the cells like a drum, and reels jump back by whole symbol cycles without animation before each spin so they never run out.",
            "每条卷轴都是一个 ScrollView，各自的 ScrollPosition 存放在数组中；旋转时在 withAnimation(.spring(duration:bounce:)) 中以逐条递增的时长调用 scrollTo(y:)。visualEffect 把格子弯成滚筒；每次旋转前，卷轴会无动画地回退整数个符号周期，因此永远转不到尽头。"
        ),
        apis: ["ScrollPosition", "spring(duration:bounce:)", "visualEffect", "rotation3DEffect", "ScrollTargetBehavior"],
        tags: ["slot machine", "reels", "spin", "jackpot", "老虎机", "滚轮", "旋转", "中奖"],
        params: [
            .slider("duration", L("First reel duration", "首轴时长"), 0.6...2.0, default: 1.1, unit: "s"),
            .slider("bounce", L("Stop bounce", "停止回弹"), 0...0.4, default: 0.18),
        ]
    ) { ctx in
        ScrollSlotDemo(ctx: ctx)
    }
}

private let scrollSlotSymbols: [String] = ["star.fill", "heart.fill", "bolt.fill", "leaf.fill", "moon.fill", "flame.fill", "crown.fill", "diamond.fill"]
private let scrollSlotColors: [Color] = [Palette.amber, Palette.pink, Palette.sky, Palette.mint, Palette.violet, Palette.coral, Palette.amber, Palette.blue]
private let scrollSlotCells = 96
private let scrollSlotCell: CGFloat = 64

private struct ScrollSlotDemo: View {
    let ctx: DemoContext
    @State private var positions: [ScrollPosition] = Array(repeating: ScrollPosition(edge: .top), count: 3)
    @State private var targets: [Int]
    /// The cell each reel actually rests on, including hand flicks (spins start from here).
    @State private var resting: [Int]
    @State private var spins = 0
    @State private var spinning = false
    @State private var win: Bool

    /// Still thumbnails never run `onAppear`, so every reel stays on cell 0 (three stars on the payline):
    /// seed that row and its win glow, so the frame shows the jackpot it actually draws.
    init(ctx: DemoContext) {
        self.ctx = ctx
        let start: [Int] = ctx.isStill ? [0, 0, 0] : [10, 13, 18]
        _targets = State(initialValue: start)
        _resting = State(initialValue: start)
        _win = State(initialValue: ctx.isStill)
    }

    var body: some View {
        VStack(spacing: 18) {
            cabinet
            spinButton
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            for k in 0..<3 { positions[k].scrollTo(y: CGFloat(targets[k]) * scrollSlotCell) }
        }
        .autoplay(ctx.isPreview, every: 2.8) { spin() }
    }

    private var cabinet: some View {
        HStack(spacing: 8) {
            ForEach(0..<3, id: \.self) { k in
                ScrollSlotReel(
                    position: $positions[k],
                    onCell: { resting[k] = $0 },
                    onSettle: { handSettled() }
                )
            }
        }
        .padding(10)
        .background(Palette.elevated, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).strokeBorder(Palette.stroke))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Palette.amber.opacity(win ? 1 : 0.55), lineWidth: win ? 3 : 1.5)
                .frame(height: scrollSlotCell + 4)
                .padding(.horizontal, 4)
                .shadow(color: Palette.amber.opacity(win ? 0.8 : 0), radius: 12)
                .allowsHitTesting(false)
        }
        .shadow(color: .black.opacity(0.12), radius: 16, y: 8)
        .animation(.spring(response: 0.35, dampingFraction: 0.5), value: win)
    }

    private var spinButton: some View {
        Button(action: spin) {
            Text(L("Spin", "旋转"), ctx.language)
                .font(.headline)
                .foregroundStyle(.white)
                .frame(width: 150, height: 46)
                .background(Palette.sunset, in: Capsule())
                .shadow(color: Palette.coral.opacity(0.4), radius: 10, y: 5)
        }
        .buttonStyle(.plain)
        .opacity(spinning ? 0.6 : 1)
        .disabled(spinning)
    }

    private func spin() {
        guard !spinning else { return }
        spinning = true
        win = false
        spins += 1
        Haptics.tap(.medium)
        // Captured now: the delayed stop haptics below run after autoplay has unmuted Haptics.
        let muted = Haptics.isMuted || ctx.isPreview
        let count = scrollSlotSymbols.count
        // Recenter each reel by whole symbol cycles so it never reaches the end.
        var starts: [Int] = resting.map { min(max($0, 0), scrollSlotCells - 1) }
        for k in 0..<3 where starts[k] > count * 5 {
            starts[k] -= count * ((starts[k] - count * 2) / count)
        }
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            for k in 0..<3 { positions[k].scrollTo(y: CGFloat(starts[k]) * scrollSlotCell) }
        }
        // Every third spin lines up for the demo's payoff.
        let jackpot = spins % 3 == 0
        let jackpotSymbol = Int.random(in: 0..<count)
        var next: [Int] = []
        for k in 0..<3 {
            var target = starts[k] + 16 + Int.random(in: 0...8) + k * 3
            if jackpot {
                let symbol = ((target % count) + count) % count
                target += (jackpotSymbol - symbol + count) % count
            }
            next.append(min(target, scrollSlotCells - 1))
        }
        targets = next
        DispatchQueue.main.async {
            for k in 0..<3 {
                let duration = ctx["duration"] + Double(k) * 0.45
                withAnimation(.spring(duration: duration, bounce: ctx["bounce"])) {
                    positions[k].scrollTo(y: CGFloat(next[k]) * scrollSlotCell)
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + duration * 0.8) {
                    if !muted { Haptics.tap(.rigid) }
                    if k == 2 { finish(haptic: !muted) }
                }
            }
        }
    }

    private func finish(haptic: Bool) {
        spinning = false
        if isLine(targets) {
            win = true
            if haptic { Haptics.success() }
        }
    }

    /// A reel flicked by hand came to rest: judge the row it actually shows.
    private func handSettled() {
        guard !spinning else { return }
        let lined = isLine(resting)
        if lined && !win && !ctx.isPreview { Haptics.success() }
        win = lined
    }

    private func isLine(_ cells: [Int]) -> Bool {
        let count = scrollSlotSymbols.count
        let symbols = cells.map { (($0 % count) + count) % count }
        return symbols.allSatisfy { $0 == symbols[0] }
    }
}

private struct ScrollSlotReel: View {
    @Binding var position: ScrollPosition
    let onCell: (Int) -> Void
    let onSettle: () -> Void

    private let viewport: CGFloat = scrollSlotCell * 3

    var body: some View {
        let height = viewport
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(0..<scrollSlotCells, id: \.self) { i in
                    let symbol = i % scrollSlotSymbols.count
                    Image(systemName: scrollSlotSymbols[symbol])
                        .font(.system(size: 30, weight: .bold))
                        .foregroundStyle(scrollSlotColors[symbol])
                        .frame(maxWidth: .infinity)
                        .frame(height: scrollSlotCell)
                        .visualEffect { content, proxy in
                            let mid: CGFloat = proxy.frame(in: .scrollView).midY
                            let t: CGFloat = ((mid - height / 2) / (height / 2)).clamped(to: -1...1)
                            return content
                                .rotation3DEffect(.degrees(-Double(t) * 50), axis: (x: 1, y: 0, z: 0), perspective: 0.5)
                                .opacity(1 - Double(abs(t)) * 0.55)
                        }
                }
            }
            .padding(.vertical, scrollSlotCell)
        }
        .scrollIndicators(.hidden)
        .scrollTargetBehavior(ScrollStrideSnap(pitch: scrollSlotCell, axis: .vertical))
        .scrollPosition($position)
        .onScrollGeometryChange(for: Int.self) { geometry in
            Int((geometry.contentOffset.y / scrollSlotCell).rounded())
        } action: { _, cell in
            onCell(cell)
        }
        .onScrollPhaseChange { oldPhase, newPhase in
            // Only a finger ends in .interacting or .decelerating; programmatic spins end from .animating.
            let byHand = oldPhase == .interacting || oldPhase == .decelerating
            if newPhase == .idle && byHand { onSettle() }
        }
        .frame(width: 84, height: viewport)
        .background(Color.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .mask {
            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0),
                    .init(color: .black, location: 0.28),
                    .init(color: .black, location: 0.72),
                    .init(color: .clear, location: 1),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }
}
