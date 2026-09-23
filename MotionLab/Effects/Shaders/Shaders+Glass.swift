import SwiftUI

extension Effect {
    static let shaderGlassmorphism = Effect(
        id: "shader.glassmorphism",
        category: .shaders,
        interaction: .gesture,
        name: L("Frosted Glass Card", "磨砂玻璃卡片"),
        summary: L("A frosted card over drifting color, with a tilt-reactive sheen.", "漂浮色块上的磨砂卡片，倾斜时高光随之流动。"),
        prompt: L(
            "A frosted-glass card floats above slowly drifting, heavily blurred color orbs (pink, indigo, amber) that orbit on 7–12 s loops. The card uses a background blur with a 1 pt white hairline rim fading diagonally from 60% to 10% opacity and a soft drop shadow. Dragging tilts it up to ±12° in 3D; a diagonal specular sheen slides across the glass opposite the tilt and the orbs parallax behind it, then everything springs back (response 0.5 s, damping 0.7). Calm, luminous and physical.",
            "一张磨砂玻璃卡片悬浮于缓慢漂移、高度模糊的彩色光球（粉、靛蓝、琥珀）之上，光球以 7～12 秒周期环绕。卡片采用背景模糊，边缘为 1pt 白色细描边、不透明度沿对角由 60% 渐变到 10%，并带柔和投影。拖动时卡片在 3D 空间中倾斜最多 ±12°，一道斜向高光沿与倾斜相反的方向滑过玻璃，背后的光球产生视差；松手后一切以弹簧（响应 0.5 秒、阻尼 0.7）回正。宁静、通透、富有实体感。"
        ),
        implementation: L(
            "Blurred circles animated by TimelineView sit beneath a RoundedRectangle filled with .ultraThinMaterial; DragGesture drives rotation3DEffect and the offset of a gradient sheen overlay.",
            "TimelineView 驱动的模糊圆形位于 .ultraThinMaterial 圆角矩形之下；DragGesture 驱动 rotation3DEffect 与渐变高光层的位移。"
        ),
        apis: ["ultraThinMaterial", "rotation3DEffect", "TimelineView", "DragGesture", "blur"],
        tags: ["glass", "glassmorphism", "frosted", "blur", "磨砂", "玻璃拟态", "毛玻璃", "模糊"],
        params: [
            .slider("maxTilt", L("Max tilt", "最大倾斜"), 0...25, default: 12, decimals: 0, unit: "°"),
            .choice("material", L("Material", "材质"), [L("Ultra thin", "极薄"), L("Thin", "薄"), L("Regular", "常规")]),
        ]
    ) { ctx in
        GlassmorphismDemo(ctx: ctx)
    }

    static let shaderLiquidGlassLens = Effect(
        id: "shader.liquid-glass-lens",
        category: .shaders,
        interaction: .gesture,
        name: L("Liquid Glass Lens", "液态玻璃透镜"),
        summary: L("Drag a Liquid Glass droplet that refracts the content beneath.", "拖动一滴液态玻璃，实时折射下方内容。"),
        prompt: L(
            "A Liquid Glass droplet (iOS 26 material) rests over a colorful grid of content. As the finger drags it, the glass refracts and lenses whatever is beneath in real time, its rim catching specular light, and it stretches up to 12% along its direction of travel while narrowing across it, springing round again (response 0.35 s, damping 0.6) when released. A tap makes it pulse and flex like a water bead. The effect conveys a physical, optical layer floating over the UI.",
            "一滴液态玻璃（iOS 26 材质）停在一片色彩丰富的内容网格之上。手指拖动时，玻璃实时折射并透镜化下方内容，边缘捕捉镜面高光，并沿运动方向拉长最多 12%、垂直方向相应收窄，松手后以弹簧（响应 0.35 秒、阻尼 0.6）回弹成正圆。点击时它会像水珠一样脉动、形变。整体传达出一层悬浮于界面之上的真实光学材质。"
        ),
        implementation: L(
            "On iOS 26 the droplet uses .glassEffect(.regular.interactive(), in: Circle()); earlier systems fall back to .ultraThinMaterial with a gradient rim. Velocity from DragGesture drives a scale squash.",
            "iOS 26 上使用 .glassEffect(.regular.interactive(), in: Circle())；更早系统回退为 .ultraThinMaterial 加渐变描边。DragGesture 的速度驱动挤压缩放。"
        ),
        apis: ["glassEffect", "Glass.interactive()", "DragGesture", "scaleEffect", "ultraThinMaterial"],
        tags: ["liquid glass", "ios 26", "refraction", "lens", "液态玻璃", "折射", "透镜", "玻璃"],
        params: [
            .slider("size", L("Droplet size", "水滴尺寸"), 70...160, default: 110, decimals: 0, unit: "pt"),
            .toggle("tint", L("Tinted glass", "着色玻璃"), default: false),
        ],
        requirement: "iOS 26"
    ) { ctx in
        LiquidLensDemo(ctx: ctx)
    }
}

// MARK: - Glassmorphism

private struct GlassmorphismDemo: View {
    let ctx: DemoContext
    @State private var drag: CGSize = .zero

    private var material: Material {
        switch ctx.int("material") {
        case 1: return .thinMaterial
        case 2: return .regularMaterial
        default: return .ultraThinMaterial
        }
    }

    var body: some View {
        let maxTilt = ctx["maxTilt"]
        let nx = Double(drag.width / 140).clamped(to: -1...1)
        let ny = Double(drag.height / 140).clamped(to: -1...1)
        ZStack {
            ShaderClock { time in
                GlassOrbs(time: time, parallax: CGSize(width: -nx * 18, height: -ny * 18))
            }
            glassCard(nx: nx, ny: ny)
                .rotation3DEffect(.degrees(nx * maxTilt), axis: (x: 0, y: 1, z: 0), perspective: 0.6)
                .rotation3DEffect(.degrees(-ny * maxTilt), axis: (x: 1, y: 0, z: 0), perspective: 0.6)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    withAnimation(.interactiveSpring(response: 0.25, dampingFraction: 0.8)) { drag = value.translation }
                }
                .onEnded { _ in
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) { drag = .zero }
                }
        )
        .autoplay(ctx.isPreview, every: 1.4, delay: 0.2) {
            withAnimation(.spring(response: 0.9, dampingFraction: 0.7)) {
                drag = drag == .zero ? CGSize(width: CGFloat.random(in: -110...110), height: CGFloat.random(in: -90...90)) : .zero
            }
        }
    }

    private func glassCard(nx: Double, ny: Double) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: "wave.3.right.circle.fill")
                    .font(.title)
                Spacer()
                Text("PLUS")
                    .font(.system(size: 18, weight: .heavy, design: .rounded))
                    .italic()
            }
            Spacer()
            Text("•••• 2046")
                .font(.system(size: 22, weight: .semibold, design: .monospaced))
            Text(ctx.language == .zh ? "动效词典 会员卡" : "Motion Lexicon Member")
                .font(.footnote.weight(.medium))
                .opacity(0.8)
        }
        .foregroundStyle(.white)
        .padding(22)
        .frame(width: 250, height: 160)
        .background(material, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            LinearGradient(
                colors: [.clear, .white.opacity(0.35), .clear],
                startPoint: UnitPoint(x: 0.2 - nx * 0.5, y: 0 - ny * 0.5),
                endPoint: UnitPoint(x: 0.8 - nx * 0.5, y: 1 - ny * 0.5)
            )
            .blendMode(.plusLighter)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .allowsHitTesting(false)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(LinearGradient(colors: [.white.opacity(0.6), .white.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.25), radius: 24, x: -nx * 10, y: 16 - ny * 6)
        .environment(\.colorScheme, .dark)
    }
}

private struct GlassOrbs: View {
    let time: Double
    let parallax: CGSize

    var body: some View {
        ZStack {
            orb(Palette.pink, size: 170, x: cos(time / 1.4) * 70, y: sin(time / 1.9) * 60 - 30)
            orb(Palette.indigo, size: 200, x: sin(time / 1.7) * 80 + 20, y: cos(time / 1.3) * 50 + 40)
            orb(Palette.amber, size: 120, x: cos(time / 1.1 + 2) * 90, y: sin(time / 1.5 + 1) * 80)
        }
        // Offsets don't grow layout bounds, so without a full-size frame the drawingGroup
        // rasterizes (and the blur clips) to a ~200 pt box, leaving hard-edged colour slabs.
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .offset(parallax)
        .blur(radius: 30)
        .drawingGroup()
    }

    private func orb(_ color: Color, size: CGFloat, x: Double, y: Double) -> some View {
        Circle()
            .fill(color)
            .frame(width: size, height: size)
            .offset(x: x, y: y)
    }
}

// MARK: - Liquid glass lens

private struct LiquidLensDemo: View {
    let ctx: DemoContext
    @State private var position: CGPoint?
    @State private var squash: CGSize = .zero
    @State private var pulse = false
    @State private var size: CGSize = CGSize(width: 340, height: 340)

    var body: some View {
        let diameter = ctx.cg("size")
        let point = position ?? CGPoint(x: size.width / 2, y: size.height / 2)
        ZStack {
            LensBackdrop()
            LensDroplet(diameter: diameter, tinted: ctx.bool("tint"))
                .scaleEffect(x: 1 + squash.width, y: 1 + squash.height)
                .scaleEffect(pulse ? 1.12 : 1)
                .position(point)
        }
        .onGeometryChange(for: CGSize.self) { $0.size } action: { size = $0 }
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    position = value.location
                    let vx = (value.velocity.width / 3000).clamped(to: -0.12...0.12)
                    let vy = (value.velocity.height / 3000).clamped(to: -0.12...0.12)
                    withAnimation(.interactiveSpring(response: 0.2, dampingFraction: 0.7)) {
                        squash = CGSize(width: abs(vx) - abs(vy), height: abs(vy) - abs(vx))
                    }
                }
                .onEnded { _ in
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) { squash = .zero }
                }
        )
        .simultaneousGesture(TapGesture().onEnded { flex() })
        .autoplay(ctx.isPreview, every: 1.5, delay: 0.2) {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.65)) {
                position = CGPoint(
                    x: CGFloat.random(in: 80...max(81, size.width - 80)),
                    y: CGFloat.random(in: 80...max(81, size.height - 80))
                )
            }
        }
    }

    private func flex() {
        Haptics.tap(.soft)
        withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) { pulse = true }
        Task {
            try? await Task.sleep(for: .seconds(0.18))
            withAnimation(.spring(response: 0.4, dampingFraction: 0.45)) { pulse = false }
        }
    }
}

private struct LensBackdrop: View {
    private let symbols = ["sun.max.fill", "moon.stars.fill", "cloud.bolt.fill", "leaf.fill", "flame.fill", "drop.fill",
                           "sparkles", "bolt.fill", "heart.fill", "star.fill", "music.note", "camera.fill"]

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(hex: 0xFDEBFF), Color(hex: 0xDDE6FF)], startPoint: .top, endPoint: .bottom)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 14), count: 4), spacing: 14) {
                ForEach(symbols.indices, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Palette.spectrum[index % Palette.spectrum.count].gradient)
                        .aspectRatio(1, contentMode: .fit)
                        .overlay {
                            Image(systemName: symbols[index])
                                .font(.title2.weight(.semibold))
                                .foregroundStyle(.white)
                        }
                }
            }
            .padding(24)
        }
    }
}

private struct LensDroplet: View {
    let diameter: CGFloat
    let tinted: Bool

    var body: some View {
        #if compiler(>=6.2)
        if #available(iOS 26.0, *) {
            Circle()
                .fill(Color.clear)
                .frame(width: diameter, height: diameter)
                .glassEffect(glass, in: Circle())
        } else {
            fallback
        }
        #else
        fallback
        #endif
    }

    #if compiler(>=6.2)
    @available(iOS 26.0, *)
    private var glass: Glass {
        tinted ? Glass.regular.tint(Palette.violet.opacity(0.35)).interactive() : Glass.regular.interactive()
    }
    #endif

    private var fallback: some View {
        Circle()
            .fill(.ultraThinMaterial)
            .overlay {
                Circle().fill(tinted ? Palette.violet.opacity(0.18) : Color.clear)
            }
            .overlay {
                Circle()
                    .strokeBorder(
                        LinearGradient(colors: [.white.opacity(0.9), .white.opacity(0.15), .white.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing),
                        lineWidth: 1.5
                    )
            }
            .overlay(alignment: .topLeading) {
                Ellipse()
                    .fill(.white.opacity(0.55))
                    .frame(width: diameter * 0.32, height: diameter * 0.16)
                    .blur(radius: 4)
                    .offset(x: diameter * 0.18, y: diameter * 0.14)
            }
            .frame(width: diameter, height: diameter)
            .shadow(color: .black.opacity(0.18), radius: 14, y: 8)
    }
}
