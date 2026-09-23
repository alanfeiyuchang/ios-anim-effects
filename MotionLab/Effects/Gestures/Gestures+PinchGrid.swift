import SwiftUI

extension Effect {
    static let gesturesPinchGrid = Effect(
        id: "gestures.pinch-grid",
        category: .gestures,
        interaction: .gesture,
        name: L("Pinch Grid Density", "捏合切换网格密度"),
        summary: L("Pinch a photo grid to step between 2, 3 and 4 columns while every tile reflows in a cascade.", "捏合照片网格在 2、3、4 列之间切换，每张图块以瀑布式错峰重排。"),
        prompt: L(
            "A 288×288 pt photo grid (6 pt gutters, gradient tiles with white glyphs) is clipped in a 28 pt rounded frame under a column-count pill. While pinching, the whole grid scales live around the pinch anchor, rubber-banded to about ±25%; releasing past 115% steps to one column fewer with bigger tiles, below 87% to one column more. Every tile then springs to its new frame (response 0.45 s, damping 0.8) delayed 15 ms × its index, so the reflow ripples from the top-left corner like Photos while the live scale springs back to 1 in the same beat. The pill rolls to the new count with a numeric transition and a medium haptic confirms the step; double-tap cycles the density. Tactile and spatially continuous.",
            "一个288×288 pt的照片网格（6 pt间距，渐变图块配白色图标）裁在28 pt圆角框里，上方胶囊示列数。捏合时整个网格围绕捏合锚点实时缩放，超出约±25%带橡皮筋阻尼；松手时放大超过115%就少一列、图块变大，缩到87%以下就多一列。随后每个图块以弹簧（响应0.45秒、阻尼0.8）移到新位置，按序号各延迟15毫秒，重排如“照片”App般从左上角荡开，整体缩放也在同一拍弹回1。胶囊以数字转场滚到新列数，一下中等触感确认；双击可循环切换密度。扎实连贯。"
        ),
        implementation: L(
            "MagnifyGesture drives a rubber-banded scaleEffect anchored at value.startAnchor; tiles are placed with explicit frames and positions computed from the column count, each with its own .animation(spring.delay(i × stagger), value: columns) so the reflow cascades.",
            "MagnifyGesture 驱动以 value.startAnchor 为锚点、带橡皮筋的 scaleEffect；图块根据列数计算出明确的尺寸与位置，每个图块单独使用 .animation(spring.delay(序号 × 间隔), value: columns)，让重排呈瀑布式。"
        ),
        apis: ["MagnifyGesture", "scaleEffect(_:anchor:)", "animation(_:value:)", "Animation.delay", "onTapGesture(count:)"],
        tags: ["pinch", "grid", "zoom", "photos", "捏合", "网格", "缩放", "照片"],
        params: [
            .slider("stagger", L("Reflow stagger", "重排错峰"), 0...0.05, default: 0.015, decimals: 3, unit: "s"),
            .slider("response", L("Spring response", "弹簧响应"), 0.25...0.9, default: 0.45, unit: "s"),
        ]
    ) { ctx in
        PinchGridDemo(ctx: ctx)
    }
}

private let pinchTileCount = 16
private let pinchSymbols = ["leaf.fill", "sun.max.fill", "moon.stars.fill", "cloud.fill", "flame.fill", "drop.fill", "camera.fill", "star.fill"]

private struct PinchGridDemo: View {
    let ctx: DemoContext
    @State private var columns = 3
    @State private var live: CGFloat = 1
    @State private var anchor: UnitPoint = .center
    @State private var zoomingIn = true

    /// Pill + 12 pt + grid stays inside the 340 pt preview canvas.
    private let side: CGFloat = 288
    private let gutter: CGFloat = 6

    var body: some View {
        VStack(spacing: 12) {
            pill
            grid
                .frame(width: side, height: side, alignment: .topLeading)
                .scaleEffect(live, anchor: anchor)
                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 28, style: .continuous).strokeBorder(Palette.stroke, lineWidth: 1))
                .contentShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                .gesture(magnify)
                .onTapGesture(count: 2) { cycle() }
            DemoHint(text: L("Pinch the grid, or double-tap", "捏合网格，或双击"), ctx: ctx)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 2.0, delay: 0.6) { simulate() }
    }

    private var pill: some View {
        HStack(spacing: 6) {
            Image(systemName: "square.grid.3x3.fill")
            Text(verbatim: "\(columns)")
                .monospacedDigit()
                .contentTransition(.numericText(value: Double(columns)))
            Text(L("columns", "列"), ctx.language)
        }
        .font(.subheadline.weight(.semibold))
        .padding(.horizontal, 14)
        .padding(.vertical, 7)
        .background(Palette.elevated, in: Capsule())
        .overlay(Capsule().strokeBorder(Palette.stroke, lineWidth: 1))
    }

    private var grid: some View {
        let count = CGFloat(columns)
        let tile: CGFloat = (side - gutter * (count - 1)) / count
        let stagger = ctx["stagger"]
        let spring = Animation.spring(response: ctx["response"], dampingFraction: 0.8)
        return ZStack(alignment: .topLeading) {
            ForEach(0..<pinchTileCount, id: \.self) { index in
                let column = CGFloat(index % columns)
                let row = CGFloat(index / columns)
                PinchTile(index: index, size: tile)
                    .frame(width: tile, height: tile)
                    .offset(x: column * (tile + gutter), y: row * (tile + gutter))
                    .animation(spring.delay(Double(index) * stagger), value: columns)
            }
        }
    }

    private var magnify: some Gesture {
        MagnifyGesture()
            .onChanged { value in
                anchor = value.startAnchor
                let delta = value.magnification - 1
                live = 1 + rubberBand(delta, limit: 0.25, coefficient: 1)
            }
            .onEnded { value in
                if value.magnification > 1.15 {
                    commit(columns - 1)
                } else if value.magnification < 0.87 {
                    commit(columns + 1)
                } else {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) { live = 1 }
                }
            }
    }

    private func commit(_ target: Int, haptic: Bool = true) {
        let clampedTarget = target.clamped(to: 2...4)
        let changed = clampedTarget != columns
        withAnimation(.spring(response: ctx["response"], dampingFraction: 0.8)) {
            live = 1
            columns = clampedTarget
        }
        if changed && haptic && !ctx.isPreview { Haptics.tap(.medium) }
    }

    private func cycle() {
        commit(columns == 2 ? 4 : columns - 1)
    }

    private func simulate() {
        if columns == 2 { zoomingIn = false }
        if columns == 4 { zoomingIn = true }
        anchor = UnitPoint(x: CGFloat.random(in: 0.3...0.7), y: CGFloat.random(in: 0.3...0.7))
        withAnimation(.easeInOut(duration: 0.35)) { live = zoomingIn ? 1.16 : 0.86 }
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.4))
            // Scripted (preview or detail intro): the column step stays silent.
            commit(zoomingIn ? columns - 1 : columns + 1, haptic: false)
        }
    }
}

private struct PinchTile: View {
    let index: Int
    let size: CGFloat

    var body: some View {
        let colors = Palette.spectrum
        let a = colors[index % colors.count]
        let b = colors[(index + 2) % colors.count]
        RoundedRectangle(cornerRadius: 10, style: .continuous)
            .fill(LinearGradient(colors: [a, b], startPoint: .topLeading, endPoint: .bottomTrailing))
            .overlay {
                Image(systemName: pinchSymbols[index % pinchSymbols.count])
                    .font(.system(size: max(size * 0.28, 12), weight: .semibold))
                    .foregroundStyle(.white.opacity(0.9))
            }
    }
}
