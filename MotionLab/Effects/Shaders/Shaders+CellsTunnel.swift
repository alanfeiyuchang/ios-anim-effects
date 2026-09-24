import SwiftUI

// Two more "Generative Light" variations: living Voronoi cells that divide where you tap,
// and a hyperspace tunnel you steer with your finger and press to accelerate.

extension Effect {
    static let shaderVoronoiCells = Effect(
        id: "shader.voronoi-cells",
        category: .shaders,
        interaction: .tap,
        name: L("Living Cells", "活体细胞"),
        summary: L(
            "Bioluminescent Voronoi cells wobble and glow — tap and the cells under your finger divide.",
            "会发光的 Voronoi 细胞轻轻蠕动，点击处的细胞随之分裂。"
        ),
        prompt: L(
            "A full-bleed field of organic cells, like bioluminescent tissue under a microscope. The pattern is a Worley (Voronoi) diagram: every cell's nucleus wanders inside its grid square on its own slow sine orbit, so borders continuously slide, pinch and re-form. Cells are filled in deep indigo to sky blue, with rare pink cells, brighter toward their nucleus, and the shared borders glow cyan with an exponential falloff. Tapping makes the tissue divide: within a soft ≈ 110 pt footprint around the finger, cell density doubles over 0.35 s, so each cell there splits into about four smaller, brighter ones whose borders glow up to about 4×, and they merge back over roughly 2.5 s — mitosis on demand. Organic, hypnotic and alive.",
            "满版的有机细胞，如同显微镜下会发光的生物组织。图案是 Worley（Voronoi）图：每个细胞的核在自己的网格内沿各自缓慢的正弦轨道游走，于是细胞边界不断滑动、收缩、重新成形。细胞填充从深靛蓝到天蓝，偶有粉色细胞，越靠近细胞核越亮；相邻细胞的共用边界以指数衰减发出青色辉光。点击会让组织“分裂”：指尖周围约 110pt 的柔和范围内，细胞密度在 0.35 秒内升至 2 倍，每个细胞分成约四个更小更亮的细胞，边界辉光增强到约四倍，随后约 2.5 秒内重新合并。有机而催眠。"
        ),
        implementation: L(
            "A [[stitchable]] color shader searches the 3×3 neighboring grid cells for the nearest and second-nearest animated feature points (F1, F2), glows on F2 − F1, colors each cell by a hash of its id and, after a tap, scales the lookup about the finger by 1 + s·e^(−(r/110)²), a monotonic map that doubles the cell density locally.",
            "[[stitchable]] colorEffect 着色器在 3×3 邻域网格中寻找最近与次近的动态特征点（F1、F2），以 F2 − F1 生成边界辉光，按格子 id 的哈希为细胞上色，点击后以 1 + s·e^(−(r/110)²) 围绕指尖缩放查找坐标（单调映射，不会折叠），使局部细胞密度加倍。"
        ),
        apis: ["colorEffect", "visualEffect", "TimelineView", "onTapGesture(coordinateSpace:perform:)", "Metal"],
        tags: ["voronoi", "cells", "worley", "organic", "细胞", "泰森多边形", "有机", "生物光"],
        params: [
            .slider("density", L("Cell density", "细胞密度"), 3...12, default: 6, decimals: 1),
            .slider("speed", L("Wobble speed", "蠕动速度"), 0.2...3.0, default: 1.0, unit: "×"),
            .slider("glow", L("Border glow", "边界辉光"), 0.2...1.5, default: 0.9),
        ]
    ) { ctx in
        VoronoiCellsDemo(ctx: ctx)
    }

    static let shaderTunnel = Effect(
        id: "shader.tunnel",
        category: .shaders,
        interaction: .gesture,
        name: L("Hyperspace Tunnel", "超空间隧道"),
        summary: L(
            "Fly down an endless neon tunnel — drag to steer the vanishing point, hold to go to warp.",
            "穿行于无尽的霓虹隧道，拖动操控消失点，按住即可进入曲速。"
        ),
        prompt: L(
            "An endless neon tunnel rushes toward the viewer. The wall is a polar-coordinate grid: depth is 0.28 / r plus time, so rings stream outward from the vanishing point and speed up as they approach, while 12 longitudinal lanes twist gently with depth. Line color cycles through a cosine rainbow along the tunnel and the far end fades into a soft white-violet core. Two gestures reach warp: a 150 ms still hold (scroll-safe, with a medium haptic thump) or a sideways drag that steers, easing the vanishing point toward the finger (exponential follow, ≈ 200 ms), both ease travel speed up to 3.2× (≈ 400 ms time constant); a tap gives a 0.45 s kick. On release both drift back; a top readout shows the multiplier. Immersive, fast and arcade-bright.",
            "一条无尽的霓虹隧道迎面冲来。隧道壁是极坐标网格：深度为 0.28 / r 加上时间，于是光环从消失点不断向外涌出、越靠近越快，12 条纵向轨道随深度轻轻扭转。线条颜色沿隧道按余弦彩虹循环，远端融入柔和的白紫色光核。两种手势可进入曲速：静按 150 毫秒（滚动不会误触，伴随中等触感）或横向拖动转向（消失点以约 200 毫秒的指数跟随缓向手指），行进速度都会缓升至 3.2 倍（时间常数约 400 毫秒）；轻点则短促加速 0.45 秒。松手后速度回落、消失点漂回中心，顶部读数显示倍率。沉浸、迅疾、街机般明亮。"
        ),
        implementation: L(
            "A [[stitchable]] color shader maps each pixel to (angle, 0.28 / r + time), draws anti-aliased lane and ring lines with fract() and colors them with a cosine palette; a small model accumulates warp-scaled time and smooths the vanishing point toward the touch every TimelineView frame, while a never-completing long press reports the hold that drives warp.",
            "[[stitchable]] colorEffect 着色器把每个像素映射为（角度，0.28 / r + 时间），用 fract() 绘制抗锯齿的轨道线与环线，并以余弦调色板上色；小型模型在每个 TimelineView 帧中累积按曲速缩放的时间，并让消失点平滑跟随触点；一个永不完成的长按手势报告按住状态以驱动曲速。"
        ),
        apis: ["colorEffect", "visualEffect", "TimelineView(.animation)", "DragGesture", "onLongPressGesture(onPressingChanged:)", "Metal"],
        tags: ["tunnel", "warp", "hyperspace", "neon", "隧道", "曲速", "超空间", "霓虹"],
        params: [
            .slider("speed", L("Cruise speed", "巡航速度"), 0.3...3.0, default: 1.2, unit: "×"),
            .slider("twist", L("Twist", "扭转"), -3...3, default: 1.0, decimals: 1),
            .slider("lanes", L("Lanes", "轨道数"), 4...24, default: 12, step: 1, decimals: 0),
        ]
    ) { ctx in
        TunnelDemo(ctx: ctx)
    }
}

// MARK: - Voronoi cells

private struct VoronoiCellsDemo: View {
    let ctx: DemoContext
    @State private var touch = CGPoint(x: 170, y: 170)
    @State private var pulseStart = Date.distantPast
    @State private var size = CGSize(width: 340, height: 340)

    var body: some View {
        let density = ctx["density"]
        let glow = ctx["glow"]
        ShaderClock(preview: ctx.isPreview, speed: ctx["speed"]) { time in
            let age = Date().timeIntervalSince(pulseStart)
            let pulse = age >= 0 && age < 3 ? age : -1
            let point = touch
            Rectangle()
                .visualEffect { content, proxy in
                    content.colorEffect(
                        ShaderLibrary.mlVoronoiCells(
                            .float2(proxy.size),
                            .float(time),
                            .float(density),
                            .float2(point),
                            .float(pulse),
                            .float(glow)
                        )
                    )
                }
        }
        .contentShape(Rectangle())
        .onTapGesture(coordinateSpace: .local) { location in
            Haptics.tap(.soft)
            emit(at: location)
        }
        .onGeometryChange(for: CGSize.self) { $0.size } action: { size = $0 }
        .autoplay(ctx.isPreview, every: 2.6, delay: 0.5) {
            emit(at: CGPoint(x: CGFloat.random(in: 0.25...0.75) * size.width, y: CGFloat.random(in: 0.25...0.75) * size.height))
        }
        .backgroundsHint(L("Tap to make the cells divide", "点击让细胞分裂"), ctx)
    }

    private func emit(at point: CGPoint) {
        touch = point
        pulseStart = Date()
    }
}

// MARK: - Tunnel

private struct TunnelState {
    let time: Double
    let center: CGPoint
    let warp: Double
}

private final class TunnelModel {
    let clock = BackgroundClock(start: 0)
    var touch: CGPoint?
    /// True while a stationary press-and-hold is down (the never-completing long press).
    var pressing = false
    private var center: CGPoint?
    private var warp: Double = 1

    func step(now: Double, speed: Double, size: CGSize, preview: Bool) -> TunnelState {
        let t = clock.advance(to: now, speed: speed * warp)
        let home = CGPoint(x: size.width / 2, y: size.height / 2)
        var target = home
        if let touch = touch {
            target = touch
        } else if preview {
            target = CGPoint(x: home.x + CGFloat(60 * cos(now * 0.7)), y: home.y + CGFloat(40 * sin(now * 0.9)))
        }
        let current = center ?? home
        let k = CGFloat(clock.follow(rate: 5))
        let next = CGPoint(x: current.x + (target.x - current.x) * k, y: current.y + (target.y - current.y) * k)
        center = next
        let goal: Double = (touch != nil || pressing) ? 3.2 : 1
        warp += (goal - warp) * clock.follow(rate: 2.5)
        return TunnelState(time: t, center: next, warp: warp)
    }
}

private struct TunnelDemo: View {
    let ctx: DemoContext
    @State private var model = TunnelModel()
    /// Bumped on every press change, so a pending warp engage only fires if the finger is still down and still.
    @State private var pressToken = 0
    @State private var size = CGSize(width: 340, height: 340)

    var body: some View {
        let speed = ctx["speed"]
        let twist = ctx["twist"]
        let lanes = ctx["lanes"]
        TimelineView(.animation(minimumInterval: MotionFrameRate.interval(preview: ctx.isPreview))) { timeline in
            let state = model.step(
                now: timeline.date.timeIntervalSinceReferenceDate,
                speed: speed,
                size: size,
                preview: ctx.isPreview
            )
            TunnelSurface(state: state, twist: twist, lanes: lanes)
        }
        .onGeometryChange(for: CGSize.self) { $0.size } action: { size = $0 }
        .contentShape(Rectangle())
        // A long press that never completes reports pressing while the finger stays down and fails as soon as
        // it moves 10 pt, so the page can still scroll (same pattern as Starfield Warp and Synthwave).
        // Sideways drags keep steering through backgroundsTouch, which also holds warp while engaged.
        // pressing turns true at touch-down, so warp and the haptic wait for a 150 ms still hold: a page scroll
        // that starts on the stage moves 10 pt (failing the press) before it engages.
        .onLongPressGesture(minimumDuration: 60, maximumDistance: 10, perform: {}, onPressingChanged: { pressing in
            pressToken += 1
            guard pressing else {
                model.pressing = false
                return
            }
            let token = pressToken
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(0.15))
                guard token == pressToken, !model.pressing else { return }
                model.pressing = true
                Haptics.tap(.medium)
            }
        })
        .backgroundsTouch { location in model.touch = location } onEnded: { model.touch = nil }
        .backgroundsHint(L("Hold to warp · drag sideways to steer at warp", "按住进入曲速 · 横向拖动边加速边转向"), ctx)
    }
}

private struct TunnelSurface: View {
    let state: TunnelState
    let twist: Double
    let lanes: Double

    var body: some View {
        let time = state.time
        let center = state.center
        let tw = twist
        let ln = lanes
        Rectangle()
            .visualEffect { content, proxy in
                content.colorEffect(
                    ShaderLibrary.mlTunnel(.float2(proxy.size), .float(time), .float2(center), .float(tw), .float(ln))
                )
            }
            .overlay(alignment: .top) {
                Text(verbatim: String(format: "WARP ×%.1f", state.warp))
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .monospacedDigit()
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .demoGlass(Capsule(), material: .ultraThinMaterial)
                    .environment(\.colorScheme, .dark)
                    .padding(.top, 16)
                    .allowsHitTesting(false)
            }
    }
}
