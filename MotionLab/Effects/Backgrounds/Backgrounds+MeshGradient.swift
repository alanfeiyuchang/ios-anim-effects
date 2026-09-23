import SwiftUI

extension Effect {
    static let backgroundsMeshGradient = Effect(
        id: "backgrounds.mesh-gradient",
        category: .backgrounds,
        interaction: .loop,
        name: L("Living Mesh Gradient", "流动网格渐变"),
        summary: L(
            "An iOS 18 mesh gradient whose control points drift like silk — drag to pull it.",
            "iOS 18 网格渐变，控制点如丝绸般缓慢漂移，拖动即可牵引色彩。"
        ),
        prompt: L(
            "A full-bleed 3×3 mesh gradient in nine harmonised hues. The four corners stay pinned while the four edge midpoints glide along their edges and the centre point wanders on an incommensurate sine/cosine Lissajous path (periods of roughly 8–12 s, never visibly repeating), so colour pools swell, fold and bleed into one another like light moving through silk. Touching the canvas pulls the centre vertex toward the finger with an exponential ease (time constant ≈ 160 ms) and releases it back to rest just as softly. A bold, soft-shadowed title floats on top. The mood is calm, expensive and alive — an ambient hero backdrop in the spirit of Apple's wallpapers and Stripe's landing pages.",
            "全屏 3×3 网格渐变，由九种相互协调的颜色构成。四个角点固定，四条边的中点沿边缘滑动，中心点沿互不整除的正弦/余弦李萨如轨迹游走（周期约 8–12 秒，肉眼看不出循环），色块因此不断膨胀、折叠、相互晕染，如同光线穿过丝绸。手指按住画面时，中心顶点以指数缓动（时间常数约 160 毫秒）被牵向手指，松手后同样柔和地回到原位。上方悬浮一行带柔和投影的粗体标题。整体安静、高级、富有生命力，适合作为 Apple 壁纸或 Stripe 官网式的氛围主视觉。"
        ),
        implementation: L(
            "TimelineView(.animation) recomputes the nine SIMD2<Float> mesh points every frame from accumulated, speed-scaled time; a DragGesture feeds a smoothed target for the centre vertex.",
            "TimelineView(.animation) 每帧依据累积的速度缩放时间重新计算九个 SIMD2<Float> 网格点；DragGesture 为中心顶点提供经平滑处理的目标位置。"
        ),
        apis: ["MeshGradient", "TimelineView(.animation)", "SIMD2<Float>", "DragGesture", "onGeometryChange"],
        tags: ["mesh", "gradient", "wallpaper", "ambient", "网格渐变", "渐变", "壁纸", "氛围"],
        params: [
            .choice("palette", L("Palette", "配色"), [L("Aurora", "极光"), L("Sunset", "日落"), L("Ocean", "深海"), L("Candy", "糖果")]),
            .slider("speed", L("Drift speed", "漂移速度"), 0.1...2.0, default: 0.7, unit: "×"),
            .slider("amplitude", L("Drift amplitude", "漂移幅度"), 0.0...0.3, default: 0.16),
        ]
    ) { ctx in
        MeshGradientDemo(ctx: ctx)
    }
}

private enum MeshPalette {
    static func colors(_ index: Int) -> [Color] {
        let hexes: [UInt32]
        switch index {
        case 1:
            hexes = [0xFFB36B, 0xFF7A5C, 0xFF5FA2, 0xFFC247, 0xFF6B6B, 0xB86BFF, 0xFF8A5B, 0xD9468F, 0x5B2A86]
        case 2:
            hexes = [0x0A2A5E, 0x1D4ED8, 0x0EA5E9, 0x1E3A8A, 0x22D3EE, 0x38BDF8, 0x0F766E, 0x14B8A6, 0x6366F1]
        case 3:
            hexes = [0xFFD1E8, 0xFFB5D8, 0xC9B8FF, 0xFFE1C6, 0xFF9AC9, 0xA7C7FF, 0xFFF1B8, 0xB8F0E0, 0xD8B8FF]
        default:
            hexes = [0x0B1026, 0x1B2A6B, 0x3A1C71, 0x0FB5AE, 0x6E7BFF, 0xA46BFF, 0x21D4A8, 0x3AC4FF, 0xFF5FA2]
        }
        return hexes.map { Color(hex: $0) }
    }
}

private final class MeshModel {
    let clock = BackgroundClock()
    var size: CGSize = .zero
    var touch: CGPoint?
    private var center = SIMD2<Double>(0.5, 0.5)

    func points(now: Double, speed: Double, amplitude: Double) -> [SIMD2<Float>] {
        let t = clock.advance(to: now, speed: speed)
        var target = SIMD2<Double>(0.5, 0.5)
        if let touch = touch, size.width > 0, size.height > 0 {
            let x = Double(touch.x / size.width).clamped(to: 0.08...0.92)
            let y = Double(touch.y / size.height).clamped(to: 0.08...0.92)
            target = SIMD2<Double>(x, y)
        }
        center += (target - center) * clock.follow(rate: 6)

        let a = amplitude
        let cx = center.x + a * 0.8 * sin(t * 1.13)
        let cy = center.y + a * 0.8 * cos(t * 0.87)
        return [
            Self.point(0, 0), Self.point(0.5 + a * sin(t * 0.91), 0), Self.point(1, 0),
            Self.point(0, 0.5 + a * cos(t * 0.73 + 1.2)), Self.point(cx, cy), Self.point(1, 0.5 + a * sin(t * 0.79 + 2.4)),
            Self.point(0, 1), Self.point(0.5 + a * cos(t * 1.07 + 0.6), 1), Self.point(1, 1),
        ]
    }

    private static func point(_ x: Double, _ y: Double) -> SIMD2<Float> {
        SIMD2<Float>(Float(x), Float(y))
    }
}

private struct MeshGradientDemo: View {
    let ctx: DemoContext
    @State private var model = MeshModel()

    var body: some View {
        TimelineView(.animation) { timeline in
            MeshGradient(
                width: 3,
                height: 3,
                points: model.points(
                    now: timeline.date.timeIntervalSinceReferenceDate,
                    speed: ctx["speed"],
                    amplitude: ctx["amplitude"]
                ),
                colors: MeshPalette.colors(ctx.int("palette"))
            )
        }
        .overlay {
            BackgroundSampleTitle(
                title: L("Good evening", "晚上好"),
                subtitle: L("Your day, beautifully in motion", "让每一天都优雅流动"),
                language: ctx.language,
                color: ctx.int("palette") == 3 ? Color.black.opacity(0.72) : .white
            )
        }
        .contentShape(Rectangle())
        .gesture(drag)
        .onGeometryChange(for: CGSize.self) { proxy in
            proxy.size
        } action: { newSize in
            model.size = newSize
        }
        .backgroundsHint(L("Drag to pull the gradient", "拖动以牵引渐变"), ctx)
    }

    private var drag: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in model.touch = value.location }
            .onEnded { _ in model.touch = nil }
    }
}
