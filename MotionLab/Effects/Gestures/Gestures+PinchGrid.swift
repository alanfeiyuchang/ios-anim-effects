import SwiftUI

extension Effect {
    static let gesturesPinchGrid = Effect(
        id: "gestures.pinch-grid",
        category: .gestures,
        interaction: .gesture,
        name: L("Pinch Grid Density", "捏合切换网格密度"),
        summary: L("Pinch a photo grid to step between 2, 3 and 4 columns while every tile reflows in a cascade.", "捏合照片网格在 2、3、4 列之间切换，每张图块以瀑布式错峰重排。"),
        prompt: L(
            "A 300 × 300 pt photo grid (6 pt gutters, gradient tiles with white glyphs) clipped in a 28 pt rounded frame, with a column pill above. While pinching, the whole grid scales live around the pinch anchor, rubber-banded to about ±25%. Releasing past 115% steps to one column fewer (bigger tiles); below 87% one column more. Every tile then animates to its new frame on a spring (response 0.45 s, damping 0.8) delayed 15 ms × its index, so the reflow ripples from the top-left corner like Photos, while the live scale springs back to 1 in the same beat. The pill counts to the new column number with a numeric transition and a medium haptic confirms the step. Double-tap cycles density. Tactile and spatially continuous.",
            "一个 300 × 300pt 的照片网格（6pt 间距、渐变图块配白色图标）裁切在 28pt 圆角框内，上方有显示列数的胶囊。捏合过程中整个网格围绕捏合锚点实时缩放，超出约 ±25% 时有橡皮筋阻尼。松手时若放大超过 115% 就减少一列（图块变大），缩小到 87% 以下则增加一列。随后每个图块以弹簧（响应 0.45 秒、阻尼 0.8）移动到新位置，并按序号延迟 15ms，重排像“照片”那样从左上角荡漾开来，同时整体缩放在同一拍内弹回 1。胶囊以数字转场滚动到新列数，并伴随一次中等触感。双击可循环切换密度。井然有序、手感扎实、空间连续。"
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

    private let side: CGFloat = 300
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
            Text("\(columns)")
                .monospacedDigit()
                .contentTransition(.numericText(value: Double(columns)))
            Text(ctx.language == .zh ? "列" : "columns")
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

    private func commit(_ target: Int) {
        let clampedTarget = target.clamped(to: 2...4)
        let changed = clampedTarget != columns
        withAnimation(.spring(response: ctx["response"], dampingFraction: 0.8)) {
            live = 1
            columns = clampedTarget
        }
        if changed && !ctx.isPreview { Haptics.tap(.medium) }
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
            commit(zoomingIn ? columns - 1 : columns + 1)
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
