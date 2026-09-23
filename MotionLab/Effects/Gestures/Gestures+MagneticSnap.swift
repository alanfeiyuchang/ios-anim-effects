import SwiftUI

extension Effect {
    static let gesturesMagneticSnap = Effect(
        id: "gestures.magnetic-snap",
        category: .gestures,
        interaction: .gesture,
        name: L("Magnetic Snap Grid", "磁吸网格"),
        summary: L("A tile that gets pulled toward the nearest anchor while dragged, then clicks into place.", "拖动时被最近锚点吸过去、松手后“咔哒”落位的方块。"),
        prompt: L(
            "A 62 pt rounded tile (18 pt continuous corners, mint-to-sky gradient) sits on one of nine anchor dots laid out in a 3 × 3 grid, 92 pt apart. While dragged it follows the finger 1:1 until it comes within the magnet radius of an anchor; from there it is pulled toward it by up to 55%, growing stronger as the distance shrinks, so the tile visibly leans into the slot. The anchor under attraction blooms a 34 pt ring on a spring (response 0.3 s, damping 0.6) and a selection haptic ticks each time the target changes. On release the tile snaps to the nearest anchor on a spring (response 0.38 s, damping 0.68) with one small overshoot. Precise, confident and tactile.",
            "一个62pt的圆角方块（18pt连续圆角，薄荷绿到天蓝渐变）停在3 × 3共九个锚点之一上，锚点间距92pt。拖动时方块1:1跟手，一旦进入某个锚点的磁吸半径，就会被向锚点方向拉拢，最多拉过55%，距离越近吸力越强，方块明显“倒向”格位。被吸引的锚点以弹簧（响应0.3秒、阻尼0.6）绽开一圈34pt的光环，目标每切换一次就触发一次选择触感。松手后方块以弹簧（响应0.38秒、阻尼0.68）吸附到最近锚点，带一次轻微过冲。精准、笃定、手感清脆。"
        ),
        implementation: L(
            "The drag translation gives a raw point; the nearest anchor within the radius blends it toward the anchor by strength × (1 − d / radius). onEnded commits the nearest anchor with a spring and resets the translation in the same transaction.",
            "拖拽位移得到原始坐标；若半径内存在最近锚点，则按 强度 ×（1 − 距离 / 半径）向锚点插值。onEnded 在同一动画事务中提交最近锚点并清零位移。"
        ),
        apis: ["DragGesture", "offset", "spring(response:dampingFraction:)", "Haptics.selection"],
        tags: ["magnetic", "snap", "grid", "detent", "磁吸", "吸附", "网格", "拖拽"],
        params: [
            .slider("radius", L("Magnet radius", "磁吸半径"), 20...90, default: 54, step: 1, decimals: 0, unit: "pt"),
            .slider("strength", L("Pull strength", "吸力"), 0.2...0.9, default: 0.55),
            .slider("damping", L("Snap damping", "吸附阻尼"), 0.4...1.0, default: 0.68),
        ]
    ) { ctx in
        MagneticSnapDemo(ctx: ctx)
    }
}

private struct MagneticSnapDemo: View {
    let ctx: DemoContext
    @State private var home = 4
    @State private var drag: CGSize = .zero
    @State private var dragging = false
    @State private var hover: Int?

    private let spacing: CGFloat = 92
    private let tileSize: CGFloat = 62

    var body: some View {
        let raw = rawPoint
        let target = nearest(to: raw)
        let shown = attracted(raw, anchorIndex: target)
        ZStack {
            ForEach(0..<9, id: \.self) { index in
                let point = anchor(index)
                MagnetAnchor(active: hover == index)
                    .offset(x: point.x, y: point.y)
            }
            tile
                .offset(x: shown.x, y: shown.y)
                .gesture(dragGesture)
        }
        .frame(width: 300, height: 300)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(alignment: .bottom) {
            DemoHint(text: L("Drag the tile near another dot", "把方块拖向其他圆点"), ctx: ctx)
                .padding(.bottom, 6)
        }
        .autoplay(ctx.isPreview, every: 1.6) { simulate() }
    }

    private var tile: some View {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(LinearGradient(colors: [Palette.mint, Palette.sky], startPoint: .topLeading, endPoint: .bottomTrailing))
            .frame(width: tileSize, height: tileSize)
            .overlay {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.white)
            }
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(.white.opacity(0.3), lineWidth: 1))
            .scaleEffect(dragging ? 1.08 : 1)
            .shadow(color: Palette.sky.opacity(dragging ? 0.45 : 0.3), radius: dragging ? 18 : 10, y: dragging ? 12 : 6)
    }

    private var rawPoint: CGPoint {
        let origin = anchor(home)
        return CGPoint(x: origin.x + drag.width, y: origin.y + drag.height)
    }

    private func anchor(_ index: Int) -> CGPoint {
        let column = CGFloat(index % 3) - 1
        let row = CGFloat(index / 3) - 1
        return CGPoint(x: column * spacing, y: row * spacing)
    }

    private func distance(_ a: CGPoint, _ b: CGPoint) -> CGFloat {
        let dx: CGFloat = a.x - b.x
        let dy: CGFloat = a.y - b.y
        return (dx * dx + dy * dy).squareRoot()
    }

    private func nearest(to point: CGPoint) -> Int {
        var best = 0
        var bestDistance = CGFloat.greatestFiniteMagnitude
        for index in 0..<9 {
            let d = distance(point, anchor(index))
            if d < bestDistance {
                bestDistance = d
                best = index
            }
        }
        return best
    }

    private func attracted(_ raw: CGPoint, anchorIndex: Int) -> CGPoint {
        let target = anchor(anchorIndex)
        let radius = max(ctx.cg("radius"), 1)
        let d = distance(raw, target)
        guard d < radius else { return raw }
        let pull: CGFloat = ctx.cg("strength") * (1 - d / radius)
        return CGPoint(x: raw.x + (target.x - raw.x) * pull, y: raw.y + (target.y - raw.y) * pull)
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                if !dragging {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) { dragging = true }
                }
                drag = value.translation
                let point = rawPoint
                let candidate = nearest(to: point)
                let inRange = distance(point, anchor(candidate)) < ctx.cg("radius")
                let newHover: Int? = inRange ? candidate : nil
                if newHover != hover {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { hover = newHover }
                    if newHover != nil && !ctx.isPreview { Haptics.selection() }
                }
            }
            .onEnded { _ in release() }
    }

    private func release() {
        let landing = nearest(to: rawPoint)
        withAnimation(.spring(response: 0.38, dampingFraction: ctx["damping"])) {
            home = landing
            drag = .zero
            dragging = false
            hover = nil
        }
        if !ctx.isPreview { Haptics.tap(.medium) }
    }

    private func simulate() {
        var target = Int.random(in: 0..<9)
        if target == home { target = (home + 4) % 9 }
        let from = anchor(home)
        let to = anchor(target)
        let jitterX = CGFloat.random(in: -26...26)
        let jitterY = CGFloat.random(in: -26...26)
        withAnimation(.easeInOut(duration: 0.6)) {
            drag = CGSize(width: to.x - from.x + jitterX, height: to.y - from.y + jitterY)
            dragging = true
            hover = target
        }
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.7))
            withAnimation(.spring(response: 0.38, dampingFraction: ctx["damping"])) {
                home = target
                drag = .zero
                dragging = false
                hover = nil
            }
        }
    }
}

private struct MagnetAnchor: View {
    let active: Bool

    var body: some View {
        ZStack {
            Circle()
                .strokeBorder(Palette.mint.opacity(active ? 0.9 : 0), lineWidth: 2)
                .background(Circle().fill(Palette.mint.opacity(active ? 0.14 : 0)))
                .frame(width: 34, height: 34)
                .scaleEffect(active ? 1 : 0.4)
            Circle()
                .fill(active ? AnyShapeStyle(Palette.mint) : AnyShapeStyle(Color.primary.opacity(0.18)))
                .frame(width: 8, height: 8)
        }
        .frame(width: 70, height: 70)
    }
}
