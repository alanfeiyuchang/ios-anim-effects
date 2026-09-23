import SwiftUI

extension Effect {
    static let gesturesPinchRotate = Effect(
        id: "gestures.pinch-rotate",
        category: .gestures,
        interaction: .gesture,
        name: L("Pinch, Zoom & Rotate", "捏合缩放与旋转"),
        summary: L("Two-finger zoom and twist with soft limits and a springy settle.", "双指缩放与旋转，带柔性边界与弹性归位。"),
        prompt: L(
            "A 210 × 150 pt photo card (24 pt continuous corners, sunset gradient with mountain and sun glyphs, soft shadow) responds to simultaneous pinch and rotation. Scale and angle follow the fingers directly; beyond the comfortable range (0.6×–2.5×) the scale is rubber-banded so it resists instead of hitting a wall, and a rule-of-thirds grid fades in while the gesture is active. On lift the card either springs fully back to 1× / 0° or keeps its zoom and snaps rotation to the nearest 90° (spring response ≈ 0.5 s, damping ≈ 0.7, one gentle overshoot). A capsule readout shows ×scale and degrees in tabular digits. Double-tap resets. It should feel like handling a real print on glass.",
            "一张 210 × 150pt 的照片卡片（24pt 连续圆角、日落渐变配山峦与太阳图标、柔和投影）支持双指同时捏合与旋转。缩放与角度直接跟随手指；超出舒适区间（0.6×–2.5×）后缩放经橡皮筋衰减，产生阻力而非生硬截断；手势进行中淡入三分构图网格。抬起手指后，卡片或以弹簧完全回到 1× / 0°，或保留缩放并把角度吸附到最近的 90°（弹簧响应约 0.5 秒、阻尼约 0.7，轻微过冲一次）。底部胶囊实时显示倍率与角度（等宽数字），双击可复位。手感如同在玻璃上摆弄一张真实照片。"
        ),
        implementation: L(
            "MagnifyGesture.simultaneously(with: RotateGesture()) drives scale and degrees; out-of-range scale passes through rubberBand, and onEnded springs back or snaps to 90° steps.",
            "MagnifyGesture.simultaneously(with: RotateGesture()) 同时驱动缩放与角度；越界缩放经 rubberBand 衰减，onEnded 中弹簧复位或吸附到 90° 整数倍。"
        ),
        apis: ["MagnifyGesture", "RotateGesture", "simultaneously(with:)", "rubberBand", "spring(response:dampingFraction:)"],
        tags: ["pinch", "zoom", "rotate", "magnify", "multitouch", "捏合", "缩放", "旋转", "双指"],
        params: [
            .choice("mode", L("On release", "松手行为"), [L("Spring back", "弹回原状"), L("Snap to 90°", "吸附 90°")]),
            .slider("response", L("Spring response", "弹簧响应"), 0.2...1.0, default: 0.5, unit: "s"),
            .slider("damping", L("Damping", "阻尼"), 0.3...1.0, default: 0.7),
        ]
    ) { ctx in
        PinchRotateDemo(ctx: ctx)
    }
}

private struct PinchRotateDemo: View {
    let ctx: DemoContext
    @State private var scale: CGFloat = 1
    @State private var degrees: Double = 0
    @State private var baseScale: CGFloat = 1
    @State private var baseDegrees: Double = 0
    @State private var isActive = false

    private let minScale: CGFloat = 0.6
    private let maxScale: CGFloat = 2.5

    var body: some View {
        VStack(spacing: 18) {
            PhotoCard(showGrid: isActive)
                .scaleEffect(displayScale(scale))
                .rotationEffect(.degrees(degrees))
                .gesture(pinchGesture)
                .onTapGesture(count: 2) { reset() }
                .frame(maxHeight: .infinity)
            readout
            DemoHint(text: L("Pinch and twist with two fingers", "双指捏合并旋转"), ctx: ctx)
        }
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 1.7) { autoStep() }
    }

    private var readout: some View {
        HStack(spacing: 10) {
            Label(String(format: "×%.2f", Double(displayScale(scale))), systemImage: "arrow.up.left.and.arrow.down.right")
            Divider().frame(height: 14)
            Label(String(format: "%.0f°", degrees), systemImage: "rotate.right")
        }
        .font(.footnote.weight(.semibold).monospacedDigit())
        .foregroundStyle(.secondary)
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(.regularMaterial, in: Capsule())
        .zIndex(-1)
    }

    private var pinchGesture: some Gesture {
        MagnifyGesture()
            .simultaneously(with: RotateGesture())
            .onChanged { value in
                if !isActive {
                    withAnimation(.easeOut(duration: 0.2)) { isActive = true }
                }
                let magnification = value.first?.magnification ?? 1
                let rotation = value.second?.rotation.degrees ?? 0
                scale = baseScale * magnification
                degrees = baseDegrees + rotation
            }
            .onEnded { _ in settle() }
    }

    private func displayScale(_ raw: CGFloat) -> CGFloat {
        if raw > maxScale { return maxScale + rubberBand(raw - maxScale, limit: 0.6) }
        if raw < minScale { return minScale - rubberBand(minScale - raw, limit: 0.25) }
        return raw
    }

    private func settle() {
        let snap = ctx.int("mode") == 1
        let finalScale = snap ? displayScale(scale).clamped(to: 1...maxScale) : 1
        let finalDegrees = snap ? (degrees / 90).rounded() * 90 : 0
        withAnimation(.spring(response: ctx["response"], dampingFraction: ctx["damping"])) {
            scale = finalScale
            degrees = finalDegrees
            isActive = false
        }
        baseScale = finalScale
        baseDegrees = finalDegrees
        if !ctx.isPreview { Haptics.tap(.soft) }
    }

    private func reset() {
        withAnimation(.spring(response: ctx["response"], dampingFraction: ctx["damping"])) {
            scale = 1
            degrees = 0
        }
        baseScale = 1
        baseDegrees = 0
    }

    private func autoStep() {
        if scale == 1 && degrees == 0 {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.85)) {
                scale = 1.35
                degrees = 18
                isActive = true
            }
        } else {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.62)) {
                scale = 1
                degrees = 0
                isActive = false
            }
        }
    }
}

private struct PhotoCard: View {
    let showGrid: Bool

    var body: some View {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .fill(Palette.sunset)
            .overlay(alignment: .topTrailing) {
                Image(systemName: "sun.max.fill")
                    .font(.system(size: 26))
                    .foregroundStyle(.white.opacity(0.9))
                    .padding(18)
            }
            .overlay(alignment: .bottomLeading) {
                Image(systemName: "mountain.2.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(.white.opacity(0.85))
                    .padding(.leading, 18)
                    .padding(.bottom, 10)
            }
            .overlay { ThirdsGrid().opacity(showGrid ? 1 : 0) }
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .frame(width: 210, height: 150)
            .shadow(color: Palette.coral.opacity(0.35), radius: 22, y: 12)
    }
}

private struct ThirdsGrid: View {
    var body: some View {
        Canvas { context, size in
            var path = Path()
            for i in 1...2 {
                let x = size.width * CGFloat(i) / 3
                let y = size.height * CGFloat(i) / 3
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: size.height))
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
            }
            context.stroke(path, with: .color(.white.opacity(0.6)), lineWidth: 0.75)
        }
        .allowsHitTesting(false)
    }
}
