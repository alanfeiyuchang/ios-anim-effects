import SwiftUI

extension Effect {
    static let gesturesPhotoViewer = Effect(
        id: "gestures.photo-viewer",
        category: .gestures,
        interaction: .gesture,
        name: L("Photo Viewer Zoom", "照片查看缩放"),
        summary: L("Pinch around your fingers, pan with inertia, double-tap to zoom — like Photos.", "以手指为中心捏合缩放、带惯性平移、双击放大——与“照片”一致。"),
        prompt: L(
            "A 300×340 pt landscape photo sits in a rounded viewport. Pinching zooms around the point between the fingers so it stays under them, rubber-banding beyond 1×–4× and springing back on release; once zoomed, a pan moves the photo 1:1 and keeps gliding after the flick with exponential deceleration (about 0.3 s time constant), while the edges resist with rubber-band tension and settle back inside on a spring (response 0.45 s, damping 0.85). Double-tapping zooms to 2.5× around the tap, or back to fit, on a spring (response 0.4 s, damping 0.82) with a light haptic, and a small chip rolls the zoom level. The photo is re-rendered at every scale, so tiny details like a signpost, cabin windows and stars stay razor sharp. Familiar, precise and physical.",
            "300×340 pt的风景照置于圆角视窗。双指捏合时以两指中点为中心缩放，让那一点始终留在指下，超出1×–4×时带橡皮筋阻尼，松手弹回；放大后单指平移1:1跟手，甩出后沿方向继续滑行并指数减速（时间常数约0.3秒），拖到边缘有橡皮筋阻力，再以弹簧（响应0.45秒、阻尼0.85）回到画面内。双击以点击处为中心放大到2.5×，或恢复适配，弹簧响应0.4秒、阻尼0.82，伴随轻触感，角落胶囊滚动显示倍率。照片按倍率重绘，路牌、窗户、星星始终锐利。熟悉而精准。"
        ),
        implementation: L(
            "MagnifyGesture and a DragGesture run simultaneously; the display transform is focal − (focal − offset) × scale / baseScale plus the pan, with rubber-banded bounds. An Animatable Canvas re-draws the vector scene through translateBy/scaleBy, so springs interpolate it and it stays crisp; onTapGesture(count: 2) toggles zoom.",
            "MagnifyGesture 与 DragGesture 同时识别；显示变换为 焦点 −（焦点 − 偏移）× 缩放 / 起始缩放，再叠加平移，并对边界施加橡皮筋。遵循 Animatable 的 Canvas 通过 translateBy/scaleBy 重新绘制矢量场景，弹簧可插值且始终清晰；onTapGesture(count: 2) 切换缩放。"
        ),
        apis: ["MagnifyGesture", "DragGesture", "onTapGesture(count:)", "Animatable", "Canvas", "predictedEndTranslation"],
        tags: ["photo", "zoom", "pinch", "pan", "inertia", "double tap", "照片", "缩放", "捏合", "惯性", "双击"],
        params: [
            .slider("maxZoom", L("Max zoom", "最大倍率"), 2...6, default: 4, unit: "×"),
            .slider("tapZoom", L("Double-tap zoom", "双击倍率"), 1.5...4, default: 2.5, unit: "×"),
            .slider("glide", L("Pan glide", "平移滑行"), 0.1...0.6, default: 0.3, unit: "s"),
        ]
    ) { ctx in
        PhotoViewerDemo(ctx: ctx)
    }
}

private enum PhotoMetrics {
    static let viewport = CGSize(width: 300, height: 340)
}

private struct PhotoViewerDemo: View {
    let ctx: DemoContext
    /// Committed transform (between gestures).
    @State private var scale: CGFloat = 1
    @State private var offset: CGSize = .zero
    /// Live gesture state.
    @State private var pinch: CGFloat = 1
    @State private var focal: CGSize = .zero
    @State private var pan: CGSize = .zero
    /// Translation already folded into `offset` when a pinch ends mid-pan.
    @State private var panOrigin: CGSize = .zero
    @State private var panning = false

    var body: some View {
        let display = displayTransform()
        VStack(spacing: 12) {
            PhotoCanvas(scale: display.scale, x: display.offset.width, y: display.offset.height)
                .frame(width: PhotoMetrics.viewport.width, height: PhotoMetrics.viewport.height)
                .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                .overlay(alignment: .topTrailing) { zoomChip(display.scale) }
                .shadow(color: .black.opacity(0.16), radius: 18, y: 10)
                .contentShape(Rectangle())
                .onTapGesture(count: 2, coordinateSpace: .local) { location in doubleTap(at: location) }
                .gesture(dragGesture)
                .simultaneousGesture(magnifyGesture)
            DemoHint(text: L("Pinch, pan or double-tap", "捏合、平移或双击"), ctx: ctx)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 3.4, delay: 0.4) { tour() }
    }

    private func zoomChip(_ value: CGFloat) -> some View {
        Text(String(format: "%.1f×", Double(value)))
            .font(.caption.weight(.semibold).monospacedDigit())
            .contentTransition(.numericText())
            .foregroundStyle(.white)
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(.black.opacity(0.35), in: Capsule())
            .padding(12)
            .opacity(value > 1.02 ? 1 : 0)
            .animation(.easeOut(duration: 0.2), value: value > 1.02)
            .allowsHitTesting(false)
    }

    // MARK: Transform math (all offsets relative to the viewport center)

    private var maxZoom: CGFloat { ctx.cg("maxZoom") }

    /// How far the photo may move at `scale` before an edge would show.
    private func bounds(for scale: CGFloat) -> CGSize {
        CGSize(
            width: max((PhotoMetrics.viewport.width * scale - PhotoMetrics.viewport.width) / 2, 0),
            height: max((PhotoMetrics.viewport.height * scale - PhotoMetrics.viewport.height) / 2, 0)
        )
    }

    private func clampedOffset(_ offset: CGSize, scale: CGFloat) -> CGSize {
        let limit = bounds(for: scale)
        return CGSize(
            width: offset.width.clamped(to: -limit.width...limit.width),
            height: offset.height.clamped(to: -limit.height...limit.height)
        )
    }

    /// Offset that keeps `focal` fixed on screen when going from (offset, scale) to `newScale`.
    private func refocused(keeping focal: CGSize, from offset: CGSize, scale: CGFloat, to newScale: CGFloat) -> CGSize {
        let ratio = newScale / max(scale, 0.01)
        return CGSize(
            width: focal.width - (focal.width - offset.width) * ratio,
            height: focal.height - (focal.height - offset.height) * ratio
        )
    }

    /// Committed transform + live pinch/pan, with rubber-banded scale and edges.
    private func displayTransform() -> (scale: CGFloat, offset: CGSize) {
        let raw = scale * pinch
        let shown: CGFloat
        if raw < 1 {
            shown = 1 - rubberBand(1 - raw, limit: 0.35)
        } else if raw > maxZoom {
            shown = maxZoom + rubberBand(raw - maxZoom, limit: 0.8)
        } else {
            shown = raw
        }
        var moved = refocused(keeping: focal, from: offset, scale: scale, to: shown)
        moved.width += pan.width
        moved.height += pan.height
        let limit = bounds(for: shown)
        func band(_ value: CGFloat, _ limit: CGFloat) -> CGFloat {
            if value > limit { return limit + rubberBand(value - limit, limit: 60) }
            if value < -limit { return -limit + rubberBand(value + limit, limit: 60) }
            return value
        }
        return (shown, CGSize(width: band(moved.width, limit.width), height: band(moved.height, limit.height)))
    }

    // MARK: Gestures

    private var magnifyGesture: some Gesture {
        MagnifyGesture(minimumScaleDelta: 0.01)
            .onChanged { value in
                if pinch == 1 {
                    focal = CGSize(
                        width: value.startLocation.x - PhotoMetrics.viewport.width / 2,
                        height: value.startLocation.y - PhotoMetrics.viewport.height / 2
                    )
                }
                pinch = value.magnification
            }
            .onEnded { _ in commit() }
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 10)
            .onChanged { value in
                if !panning {
                    // At fit size only horizontal-first drags are claimed, so the page can still scroll.
                    if scale <= 1.01 && pinch == 1 && abs(value.translation.height) > abs(value.translation.width) { return }
                    panning = true
                }
                pan = CGSize(width: value.translation.width - panOrigin.width, height: value.translation.height - panOrigin.height)
            }
            .onEnded { value in
                guard panning else { return }
                panning = false
                panOrigin = .zero
                if pinch != 1 {
                    // Still pinching: fold the pan into the pre-pinch offset so nothing jumps.
                    let ratio = displayTransform().scale / max(scale, 0.01)
                    offset = CGSize(width: offset.width + pan.width / ratio, height: offset.height + pan.height / ratio)
                    pan = .zero
                    return
                }
                let glide = CGFloat(ctx["glide"])
                // Exponential deceleration travels velocity × τ further.
                let fling = CGSize(width: value.velocity.width * glide, height: value.velocity.height * glide)
                let landed = CGSize(width: offset.width + pan.width + fling.width, height: offset.height + pan.height + fling.height)
                let current = displayTransform()
                offset = current.offset
                pan = .zero
                let target = clampedOffset(landed, scale: scale)
                let hitEdge = target != landed
                let animation: Animation = hitEdge
                    ? Animation.spring(response: 0.45, dampingFraction: 0.85)
                    : Animation.timingCurve(0.15, 0.75, 0.3, 1, duration: Double(glide) * 2.2)
                withAnimation(animation) { offset = target }
            }
    }

    /// Bakes the live pinch into the committed transform, then springs back inside the limits.
    private func commit() {
        let current = displayTransform()
        scale = current.scale
        offset = current.offset
        if panning {
            panOrigin = CGSize(width: panOrigin.width + pan.width, height: panOrigin.height + pan.height)
        }
        pinch = 1
        pan = .zero
        focal = .zero
        let target = scale.clamped(to: 1...maxZoom)
        withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
            if target != scale {
                offset = refocused(keeping: .zero, from: offset, scale: scale, to: target)
            }
            scale = target
            offset = clampedOffset(offset, scale: target)
        }
    }

    private func doubleTap(at location: CGPoint, haptic: Bool = true) {
        if haptic { Haptics.tap(.light) }
        let tap = CGSize(width: location.x - PhotoMetrics.viewport.width / 2, height: location.y - PhotoMetrics.viewport.height / 2)
        withAnimation(.spring(response: 0.4, dampingFraction: 0.82)) {
            if scale > 1.05 {
                scale = 1
                offset = .zero
            } else {
                let target = ctx.cg("tapZoom")
                offset = clampedOffset(refocused(keeping: tap, from: offset, scale: scale, to: target), scale: target)
                scale = target
            }
        }
    }

    /// Simulated session for previews and the arrival intro: double-tap the cabin, pan across, zoom back out.
    private func tour() {
        doubleTap(at: CGPoint(x: 210, y: 210), haptic: false)
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(1.0))
            withAnimation(.timingCurve(0.15, 0.75, 0.3, 1, duration: 0.8)) {
                offset = clampedOffset(CGSize(width: offset.width + 150, height: offset.height + 60), scale: scale)
            }
            try? await Task.sleep(for: .seconds(1.1))
            if scale > 1.05 { doubleTap(at: CGPoint(x: 150, y: 170), haptic: false) }
        }
    }
}

/// Re-draws the scene through the transform every frame, so it is crisp at any zoom and springs interpolate it.
private struct PhotoCanvas: View, Animatable {
    var scale: CGFloat
    var x: CGFloat
    var y: CGFloat

    var animatableData: AnimatablePair<CGFloat, AnimatablePair<CGFloat, CGFloat>> {
        get { AnimatablePair(scale, AnimatablePair(x, y)) }
        set {
            scale = newValue.first
            x = newValue.second.first
            y = newValue.second.second
        }
    }

    var body: some View {
        Canvas { context, size in
            context.translateBy(x: size.width / 2 + x, y: size.height / 2 + y)
            context.scaleBy(x: scale, y: scale)
            context.translateBy(x: -size.width / 2, y: -size.height / 2)
            PhotoScene.draw(context, size: size)
        }
    }
}

/// A dusk mountain lake drawn from vector shapes, with small details that reward zooming in.
private enum PhotoScene {
    static func draw(_ context: GraphicsContext, size: CGSize) {
        let w = size.width
        let h = size.height
        context.fill(Path(CGRect(origin: .zero, size: size)), with: .linearGradient(
            Gradient(colors: [Color(hex: 0x1D2B64), Color(hex: 0x6B4EA8), Color(hex: 0xF8A488)]),
            startPoint: .zero,
            endPoint: CGPoint(x: 0, y: h * 0.62)
        ))
        for index in 0..<24 {
            let sx = CGFloat((index * 73) % 97) / 97 * w
            let sy = CGFloat((index * 41) % 53) / 53 * h * 0.34
            let r: CGFloat = index % 5 == 0 ? 1.1 : 0.6
            context.fill(Path(ellipseIn: CGRect(x: sx - r, y: sy - r, width: r * 2, height: r * 2)), with: .color(.white.opacity(0.85)))
        }
        context.fill(Path(ellipseIn: CGRect(x: w * 0.62, y: h * 0.3, width: 44, height: 44)), with: .color(Color(hex: 0xFFE3A3)))
        context.fill(ridge(w, h, base: 0.5, peaks: [0.1, 0.34, 0.2, 0.4, 0.16], height: 0.22), with: .color(Color(hex: 0x7A6AB8)))
        context.fill(ridge(w, h, base: 0.6, peaks: [0.3, 0.1, 0.36, 0.14, 0.28, 0.08], height: 0.2), with: .color(Color(hex: 0x3E3A78)))
        let lake = CGRect(x: 0, y: h * 0.62, width: w, height: h * 0.38)
        context.fill(Path(lake), with: .linearGradient(
            Gradient(colors: [Color(hex: 0x5A4E9A), Color(hex: 0x1B1F4B)]),
            startPoint: CGPoint(x: 0, y: lake.minY),
            endPoint: CGPoint(x: 0, y: lake.maxY)
        ))
        for index in 0..<6 {
            let ly = lake.minY + 10 + CGFloat(index) * 14
            let lx = w * (0.55 + 0.05 * CGFloat(index % 2))
            context.fill(Path(roundedRect: CGRect(x: lx, y: ly, width: 40 - CGFloat(index) * 5, height: 1.5), cornerRadius: 0.75), with: .color(Color(hex: 0xFFE3A3).opacity(0.5)))
        }
        for index in 0..<9 {
            let tx = CGFloat(index) * 36 + 8
            let th: CGFloat = 26 + CGFloat((index * 7) % 5) * 5
            tree(context, x: tx, baseY: h * 0.63, height: th)
        }
        cabin(context, x: w * 0.68, baseY: h * 0.63)
        sign(context, x: w * 0.3, baseY: h * 0.66)
    }

    private static func ridge(_ w: CGFloat, _ h: CGFloat, base: CGFloat, peaks: [CGFloat], height: CGFloat) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: h * 0.64))
        for (index, peak) in peaks.enumerated() {
            let x = w * CGFloat(index) / CGFloat(max(peaks.count - 1, 1))
            path.addLine(to: CGPoint(x: x, y: h * (base - height * peak * 2.2)))
        }
        path.addLine(to: CGPoint(x: w, y: h * 0.64))
        path.closeSubpath()
        return path
    }

    private static func tree(_ context: GraphicsContext, x: CGFloat, baseY: CGFloat, height: CGFloat) {
        var path = Path()
        path.move(to: CGPoint(x: x, y: baseY - height))
        path.addLine(to: CGPoint(x: x + height * 0.32, y: baseY))
        path.addLine(to: CGPoint(x: x - height * 0.32, y: baseY))
        path.closeSubpath()
        context.fill(path, with: .color(Color(hex: 0x14173A)))
    }

    private static func cabin(_ context: GraphicsContext, x: CGFloat, baseY: CGFloat) {
        let body = CGRect(x: x, y: baseY - 12, width: 18, height: 12)
        context.fill(Path(body), with: .color(Color(hex: 0x2A1E3F)))
        var roof = Path()
        roof.move(to: CGPoint(x: x - 2, y: baseY - 12))
        roof.addLine(to: CGPoint(x: x + 9, y: baseY - 19))
        roof.addLine(to: CGPoint(x: x + 20, y: baseY - 12))
        roof.closeSubpath()
        context.fill(roof, with: .color(Color(hex: 0x1A1230)))
        for dx in [3.0, 11.0] {
            context.fill(Path(CGRect(x: x + CGFloat(dx), y: baseY - 9, width: 3.5, height: 3.5)), with: .color(Color(hex: 0xFFD27A)))
        }
    }

    private static func sign(_ context: GraphicsContext, x: CGFloat, baseY: CGFloat) {
        context.fill(Path(CGRect(x: x + 9, y: baseY - 10, width: 1.2, height: 10)), with: .color(Color(hex: 0x2A1E3F)))
        let board = CGRect(x: x, y: baseY - 15, width: 20, height: 6)
        context.fill(Path(roundedRect: board, cornerRadius: 1), with: .color(Color(hex: 0xE9D8B4)))
        let label = Text(verbatim: "LAKE 2.4 km")
            .font(.system(size: 2.2, weight: .bold, design: .rounded))
            .foregroundStyle(Color(hex: 0x3A2A1A))
        context.draw(label, at: CGPoint(x: board.midX, y: board.midY))
    }
}
