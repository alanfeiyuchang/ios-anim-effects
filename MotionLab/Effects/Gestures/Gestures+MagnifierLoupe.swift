import SwiftUI

extension Effect {
    static let gesturesMagnifierLoupe = Effect(
        id: "gestures.magnifier-loupe",
        category: .gestures,
        interaction: .gesture,
        name: L("Magnifier Loupe", "放大镜取色"),
        summary: L("A floating loupe that follows your finger and renders the swatches beneath at 3×.", "跟随手指的悬浮放大镜，以 3 倍清晰呈现下方色块。"),
        prompt: L(
            "A 12×9 grid of tiny colour swatches (hue across, brightness down, each labelled with an unreadable 3 pt hex code) fills a 300×225 pt panel. Touching it pops a 100 pt circular loupe 78 pt above the finger, springing from 40% to 100% from its bottom edge (response 0.3 s, damping 0.7); it flips below the finger near the top edge and slides inward near the sides so the lens never leaves the panel. Inside, the content is re-rendered rather than upscaled at 3× around the touch point, so the labels turn crisp, with a crosshair on the sampled swatch, a 3 pt white rim, a soft shadow and a capsule beneath showing the colour and hex value. The loupe tracks the finger with zero latency and shrinks away on lift.",
            "一块 300×225 pt 的面板铺满 12×9 的迷你色块（横向变色相、纵向变明度，每块标着 3 pt、肉眼难辨的色值）。按下时，100 pt 的圆形放大镜在手指上方 78 pt 处以底边为锚点从 40% 弹到 100%（响应 0.3 秒、阻尼 0.7）；靠近顶部就翻到指下，靠近两侧就向内平移，镜片始终不出面板。镜内以触点为中心按 3 倍重新绘制而非位图放大，色值变得清晰可读；十字准星标出取样点，3 pt 白边与柔和投影让镜片浮起，下方胶囊显示色块与色值。放大镜零延迟跟手，抬指即缩小消失。精准、专业，又带点魔法感。"
        ),
        implementation: L(
            "The swatch scene is a GraphicsContext drawing function; the loupe is a second Canvas that translates and scales its context around the touch point before drawing the same scene, clipped to a circle. The loupe view is Animatable so programmatic moves stay in sync.",
            "色块场景封装为 GraphicsContext 绘制函数；放大镜是第二个 Canvas，先围绕触点平移并缩放上下文再绘制同一场景，最后裁剪为圆形。放大镜视图遵循 Animatable，程序驱动移动时内容与位置保持同步。"
        ),
        apis: ["Canvas", "GraphicsContext.scaleBy", "DragGesture", "Animatable", "clipShape"],
        tags: ["magnifier", "loupe", "zoom", "color picker", "eyedropper", "放大镜", "取色器", "放大", "吸管"],
        params: [
            .slider("zoom", L("Zoom", "放大倍率"), 1.5...5, default: 3, unit: "×"),
            .slider("size", L("Loupe size", "镜片尺寸"), 70...130, default: 100, step: 1, decimals: 0, unit: "pt"),
        ]
    ) { ctx in
        MagnifierDemo(ctx: ctx)
    }
}

private enum SwatchScene {
    static let columns = 12
    static let rows = 9
    static let size = CGSize(width: 300, height: 225)
    static var cell: CGFloat { size.width / CGFloat(columns) }

    static func components(column: Int, row: Int) -> (r: Double, g: Double, b: Double) {
        let hue = Double(column) / Double(columns)
        let saturation = 0.45 + 0.5 * Double(row) / Double(rows - 1)
        let brightness = 1 - 0.55 * Double(row) / Double(rows - 1)
        return hsbToRGB(h: hue, s: saturation, v: brightness)
    }

    static func color(column: Int, row: Int) -> Color {
        let c = components(column: column, row: row)
        return Color(.sRGB, red: c.r, green: c.g, blue: c.b, opacity: 1)
    }

    static func hex(column: Int, row: Int) -> String {
        let c = components(column: column, row: row)
        return String(format: "#%02X%02X%02X", Int((c.r * 255).rounded()), Int((c.g * 255).rounded()), Int((c.b * 255).rounded()))
    }

    static func hsbToRGB(h: Double, s: Double, v: Double) -> (r: Double, g: Double, b: Double) {
        let scaled = (h - floor(h)) * 6
        let sector = Int(scaled) % 6
        let f = scaled - floor(scaled)
        let p = v * (1 - s)
        let q = v * (1 - f * s)
        let t = v * (1 - (1 - f) * s)
        switch sector {
        case 0: return (v, t, p)
        case 1: return (q, v, p)
        case 2: return (p, v, t)
        case 3: return (p, q, v)
        case 4: return (t, p, v)
        default: return (v, p, q)
        }
    }

    static func cellIndex(at point: CGPoint) -> (column: Int, row: Int) {
        let column = Int(point.x / cell).clamped(to: 0...(columns - 1))
        let row = Int(point.y / cell).clamped(to: 0...(rows - 1))
        return (column, row)
    }

    /// Draws the scene; `visible` (in scene coordinates) lets the loupe skip cells it can't show.
    static func draw(_ context: GraphicsContext, visible: CGRect? = nil) {
        for row in 0..<rows {
            for column in 0..<columns {
                let rect = CGRect(x: CGFloat(column) * cell, y: CGFloat(row) * cell, width: cell, height: cell).insetBy(dx: 1.5, dy: 1.5)
                if let visible, !visible.intersects(rect) { continue }
                context.fill(Path(roundedRect: rect, cornerRadius: 4, style: .continuous), with: .color(color(column: column, row: row)))
                let label = Text(hex(column: column, row: row))
                    .font(.system(size: 3, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.9))
                context.draw(label, at: CGPoint(x: rect.midX, y: rect.maxY - 3.5))
            }
        }
    }
}

private struct MagnifierDemo: View {
    let ctx: DemoContext
    @State private var point = CGPoint(x: 150, y: 110)
    @State private var isActive: Bool
    @State private var touching = false

    init(ctx: DemoContext) {
        self.ctx = ctx
        // Still snapshots never run onAppear: show the loupe out.
        _isActive = State(initialValue: ctx.isStill)
    }

    var body: some View {
        VStack(spacing: 16) {
            ZStack(alignment: .topLeading) {
                SwatchCanvas()
                    .gesture(dragGesture)

                LoupeView(
                    x: point.x,
                    y: point.y,
                    zoom: ctx.cg("zoom"),
                    diameter: ctx.cg("size"),
                    visible: isActive
                )
                .allowsHitTesting(false)
            }
            .frame(width: SwatchScene.size.width, height: SwatchScene.size.height)
            .padding(10)
            .demoCard(cornerRadius: 24)
            DemoHint(text: L("Touch and drag over the swatches", "在色块上按住并拖动"), ctx: ctx)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear { if ctx.isPreview { isActive = true } }
        .autoplay(ctx.isPreview, every: 1.0, delay: 0.3) { wander() }
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                touching = true
                point = CGPoint(
                    x: value.location.x.clamped(to: 0...SwatchScene.size.width),
                    y: value.location.y.clamped(to: 0...SwatchScene.size.height)
                )
                if !isActive {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { isActive = true }
                    if !ctx.isPreview { Haptics.tap(.light) }
                }
            }
            .onEnded { _ in
                touching = false
                withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) { isActive = false }
            }
    }

    private func wander() {
        guard !touching else { return }
        if !isActive {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { isActive = true }
        }
        let target = CGPoint(
            x: CGFloat.random(in: 30...(SwatchScene.size.width - 30)),
            y: CGFloat.random(in: 40...(SwatchScene.size.height - 20))
        )
        withAnimation(.spring(response: 0.7, dampingFraction: 0.82)) { point = target }
        guard !ctx.isPreview else { return }
        // Arrival intro in the detail stage: show the loupe gliding once, then tuck it away.
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(1.2))
            guard !touching else { return }
            withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) { isActive = false }
        }
    }
}

/// Animatable so the magnified content and the lens position interpolate together.
private struct LoupeView: View, Animatable {
    var x: CGFloat
    var y: CGFloat
    let zoom: CGFloat
    let diameter: CGFloat
    let visible: Bool

    var animatableData: AnimatablePair<CGFloat, CGFloat> {
        get { AnimatablePair(x, y) }
        set {
            x = newValue.first
            y = newValue.second
        }
    }

    var body: some View {
        let lift = diameter / 2 + 28
        let above = y - lift
        let flipped = above < diameter / 2 - 30
        let centerY = flipped ? y + lift : above
        // Keep the whole lens inside the panel horizontally; the crosshair still shows the touched point.
        let half = diameter / 2
        let lensX = x.clamped(to: min(half - 4, SwatchScene.size.width / 2)...max(SwatchScene.size.width - half + 4, SwatchScene.size.width / 2))
        let cell = SwatchScene.cellIndex(at: CGPoint(x: x, y: y))

        VStack(spacing: 8) {
            lens
            HStack(spacing: 6) {
                Circle()
                    .fill(SwatchScene.color(column: cell.column, row: cell.row))
                    .frame(width: 10, height: 10)
                Text(SwatchScene.hex(column: cell.column, row: cell.row))
                    .font(.caption2.weight(.semibold).monospaced())
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.regularMaterial, in: Capsule())
        }
        .scaleEffect(visible ? 1 : 0.4, anchor: flipped ? .top : .bottom)
        .opacity(visible ? 1 : 0)
        .position(x: lensX, y: centerY + 16)
    }

    private var lens: some View {
        Canvas { context, size in
            context.translateBy(x: size.width / 2 - zoom * x, y: size.height / 2 - zoom * y)
            context.scaleBy(x: zoom, y: zoom)
            let reach = diameter / 2 / max(zoom, 0.1) + SwatchScene.cell
            SwatchScene.draw(context, visible: CGRect(x: x - reach, y: y - reach, width: reach * 2, height: reach * 2))
        }
        .frame(width: diameter, height: diameter)
        .background(Palette.surface)
        .clipShape(Circle())
        .overlay {
            ZStack {
                Rectangle().frame(width: 1, height: 14)
                Rectangle().frame(width: 14, height: 1)
            }
            .foregroundStyle(.white)
            .shadow(color: .black.opacity(0.5), radius: 1)
        }
        .overlay(Circle().strokeBorder(.white, lineWidth: 3))
        .shadow(color: .black.opacity(0.28), radius: 14, y: 8)
    }
}

/// Static base layer; having no inputs keeps it from redrawing while the loupe moves.
private struct SwatchCanvas: View {
    var body: some View {
        Canvas { context, _ in
            SwatchScene.draw(context)
        }
        .frame(width: SwatchScene.size.width, height: SwatchScene.size.height)
    }
}
