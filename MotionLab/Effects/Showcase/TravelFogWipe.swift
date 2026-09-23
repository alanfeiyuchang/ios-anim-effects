import SwiftUI

extension Effect {
    static let showcaseFogWipe = Effect(
        id: "showcase.fog-wipe",
        category: .showcase,
        interaction: .gesture,
        name: L("Fog Wipe Reveal", "擦除雾气"),
        summary: L(
            "Drag anywhere to wipe frosted fog off a travel photo; the glass slowly fogs up again.",
            "手指划过即可擦去照片上的雾气，停手后玻璃又慢慢重新起雾。"
        ),
        prompt: L(
            "A full-bleed travel photo card (280 × 260 pt, 26 pt continuous corners) sits under a frosted fog layer — a system blur material washed with only ~6% white, so the scene stays recognisable — with a small “Drag anywhere to wipe the fog” pill at the bottom. As the finger moves, a soft round brush (~44 pt, edges feathered by a ~10 pt blur) erases the fog along the exact stroke, revealing the crisp photo like wiping a steamed-up window; a soft haptic ticks as each stroke begins and the pill fades out over 300 ms. Each cleared stroke holds for 1.2 s, then fades back linearly over ~3.5 s as the glass re-fogs. On arrival a ghost finger draws one wavy wipe over ~1 s and lets it re-fog, teaching the gesture without words. Tactile and playful.",
            "全幅旅行照片卡片（280 × 260pt，26pt 连续圆角）上盖着一层磨砂雾：系统模糊材质只叠约 6% 白色，照片仍可辨认，底部是“随意拖动，擦去雾气”提示胶囊。手指滑动时，一支约 44pt、边缘经约 10pt 模糊羽化的圆形笔刷沿轨迹擦掉雾层，露出清晰原图，像擦拭起雾的车窗；每次落笔轻触一下，提示胶囊 300 毫秒内淡出。每道擦痕保留 1.2 秒，再用约 3.5 秒线性回凝。进入时一根“隐形手指”约 1 秒擦出一道波浪痕迹再回雾，无需文字即可教会手势。可触而俏皮。"
        ),
        implementation: L(
            "The fog is a blurred copy of the photo masked by a Rectangle minus a Canvas of accumulated drag strokes (blendMode(.destinationOut) inside compositingGroup); a TimelineView fades each stroke back by age.",
            "雾层是照片的模糊副本，遮罩为「整块矩形减去 Canvas 中累积的拖动笔画」（在 compositingGroup 中使用 blendMode(.destinationOut)）；TimelineView 按笔画时长让其逐渐回凝。"
        ),
        apis: ["Canvas", "TimelineView", "mask(alignment:_:)", "blendMode(.destinationOut)", "compositingGroup", "DragGesture"],
        tags: ["fog", "wipe", "scratch", "reveal", "mask", "擦除", "雾气", "刮刮乐", "揭示"],
        params: [
            .slider("brush", L("Brush size", "笔刷大小"), 20...80, default: 44, decimals: 0, unit: "pt"),
            .slider("frost", L("Fog density", "雾气浓度"), 4...30, default: 9, decimals: 0),
            .toggle("regrow", L("Fog regrows", "雾气回凝"), default: true),
            .slider("regrowTime", L("Regrow time", "回凝时长"), 1...8, default: 3.5, decimals: 1, unit: "s"),
        ]
    ) { ctx in
        TravelFogDemo(ctx: ctx)
    }
}

// MARK: - Model

private struct TravelFogStroke {
    var points: [CGPoint]
    /// Last time the stroke was extended; regrowth is measured from here.
    var touched: Date
    /// The on-arrival demonstration stroke always re-fogs, even with regrowth turned off.
    var isDemo = false
}

// MARK: - Demo

private struct TravelFogDemo: View {
    let ctx: DemoContext
    @State private var strokes: [TravelFogStroke] = []
    @State private var isDrawing = false
    @State private var demoRunning = false
    @State private var demoTask: Task<Void, Never>?

    private var zh: Bool { ctx.language == .zh }
    private var regrowAfter: Double? { ctx.bool("regrow") ? ctx["regrowTime"] : nil }

    var body: some View {
        SignatureStage {
            VStack(spacing: 14) {
                photo
                controls
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        // Drop strokes once they have fully re-fogged so the hole TimelineView can pause again.
        .task(id: "\(strokes.count)-\(isDrawing)-\(demoRunning)") {
            guard !isDrawing, !demoRunning, !strokes.isEmpty else { return }
            let regrow = regrowAfter ?? ctx["regrowTime"]
            try? await Task.sleep(for: .seconds(TravelFogHoles.hold + regrow + 0.1))
            guard !Task.isCancelled else { return }
            prune()
        }
        .onAppear(perform: startDemoWipe)
        .onDisappear { demoTask?.cancel() }
    }

    /// Detail stage: a ghost finger wipes one wavy stroke so the gesture is self-explanatory.
    private func startDemoWipe() {
        guard !ctx.isPreview, strokes.isEmpty else { return }
        demoTask?.cancel()
        demoTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.7))
            guard !Task.isCancelled else { return }
            let steps = 36
            func point(_ i: Int) -> CGPoint {
                let u = Double(i) / Double(steps)
                return CGPoint(x: 280 * (0.12 + 0.76 * u), y: 260 * (0.56 + 0.15 * sin(u * .pi * 2.5)))
            }
            demoRunning = true
            strokes.append(TravelFogStroke(points: [point(0)], touched: Date(), isDemo: true))
            for i in 1...steps {
                try? await Task.sleep(for: .milliseconds(28))
                guard !Task.isCancelled, demoRunning, let last = strokes.indices.last, strokes[last].isDemo else { return }
                strokes[last].points.append(point(i))
                strokes[last].touched = Date()
            }
            demoRunning = false
        }
    }

    private var photo: some View {
        ZStack {
            LandscapeArt(seed: 1)
            fog
            // Soft top scrim keeps the white title legible over the bright frosted glass.
            LinearGradient(colors: [Color.black.opacity(0.34), .clear], startPoint: .top, endPoint: .center)
                .allowsHitTesting(false)
            TravelFogChrome(zh: zh, hintVisible: !isDrawing && strokes.isEmpty)
        }
        .frame(width: 280, height: 260)
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .signatureCard()
        .contentShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .gesture(wipe)
    }

    private var fog: some View {
        // A system material blurs the photo underneath it (true frosted glass), so the wiped holes
        // reveal the sharp photo. Thicker materials read as denser fog.
        Rectangle()
            .fill(fogMaterial)
            .environment(\.colorScheme, .light)
            .overlay(Color.white.opacity(0.02 + ctx["frost"] / 300))
            .overlay(
                LinearGradient(
                    colors: [Color.white.opacity(0.1), .clear, Color.white.opacity(0.05)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .mask {
                ZStack {
                    Rectangle()
                    // Only composite the hole layer when there is something to erase; an empty blurred
                    // layer under destinationOut punched stray blocky holes into the fog.
                    if ctx.isPreview || !strokes.isEmpty {
                        TravelFogHoles(
                            strokes: strokes,
                            brush: ctx.cg("brush"),
                            regrowAfter: regrowAfter,
                            demoRegrow: ctx["regrowTime"],
                            isPreview: ctx.isPreview
                        )
                        .blendMode(.destinationOut)
                    }
                }
                .compositingGroup()
            }
            .allowsHitTesting(false)
    }

    private var fogMaterial: Material {
        switch ctx["frost"] {
        case ..<10: return .ultraThinMaterial
        case ..<18: return .thinMaterial
        case ..<25: return .regularMaterial
        default: return .thickMaterial
        }
    }

    @ViewBuilder private var controls: some View {
        if !ctx.isPreview {
            Button(action: reset) {
                Label(zh ? "重新起雾" : "Fog it up again", systemImage: "arrow.counterclockwise")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Signature.textPrimary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Signature.cardHigh, in: Capsule())
                    .overlay(Capsule().strokeBorder(Signature.hairline))
            }
            .buttonStyle(.plain)
        }
    }

    private var wipe: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                if demoRunning {
                    // A real finger takes over from the ghost stroke.
                    demoTask?.cancel()
                    demoRunning = false
                }
                let now = Date()
                if isDrawing, let last = strokes.indices.last {
                    strokes[last].points.append(value.location)
                    strokes[last].touched = now
                } else {
                    isDrawing = true
                    strokes.append(TravelFogStroke(points: [value.location], touched: now))
                    Haptics.tap(.soft)
                }
            }
            .onEnded { _ in
                isDrawing = false
                prune()
            }
    }

    private func prune() {
        let now = Date()
        let demoRegrow = ctx["regrowTime"]
        strokes.removeAll { stroke in
            guard let regrow = regrowAfter ?? (stroke.isDemo ? demoRegrow : nil) else { return false }
            return now.timeIntervalSince(stroke.touched) > TravelFogHoles.hold + regrow
        }
    }

    private func reset() {
        Haptics.tap()
        demoTask?.cancel()
        demoRunning = false
        strokes.removeAll()
    }
}

// MARK: - Holes (the erased part of the fog)

private struct TravelFogHoles: View {
    static let hold: Double = 1.2

    let strokes: [TravelFogStroke]
    let brush: CGFloat
    let regrowAfter: Double?
    let demoRegrow: Double
    let isPreview: Bool

    private var paused: Bool {
        guard !isPreview else { return false }
        return strokes.isEmpty || (regrowAfter == nil && !strokes.contains { $0.isDemo })
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: MotionFrameRate.interval(preview: isPreview), paused: paused)) { timeline in
            Canvas { context, size in
                let now = timeline.date
                // Feather the brush inside the Canvas rather than blurring the whole (often empty) layer.
                context.addFilter(.blur(radius: brush * 0.22))
                for stroke in strokes {
                    draw(stroke.points, alpha: alpha(for: stroke, now: now), in: &context)
                }
                if isPreview {
                    drawDemoStroke(now: now, size: size, in: &context)
                }
            }
        }
    }

    private func alpha(for stroke: TravelFogStroke, now: Date) -> Double {
        guard let regrow = regrowAfter ?? (stroke.isDemo ? demoRegrow : nil) else { return 1 }
        let age = now.timeIntervalSince(stroke.touched) - Self.hold
        return age <= 0 ? 1 : max(0, 1 - age / regrow)
    }

    private func draw(_ points: [CGPoint], alpha: Double, in context: inout GraphicsContext) {
        guard alpha > 0, let first = points.first else { return }
        let shading = GraphicsContext.Shading.color(Color.white.opacity(alpha))
        let dot = CGRect(x: first.x - brush / 2, y: first.y - brush / 2, width: brush, height: brush)
        context.fill(Path(ellipseIn: dot), with: shading)
        guard points.count > 1 else { return }
        var path = Path()
        path.addLines(points)
        context.stroke(path, with: shading, style: StrokeStyle(lineWidth: brush, lineCap: .round, lineJoin: .round))
    }

    /// Preview only: a wavy stroke draws itself across the photo, then the fog regrows.
    private func drawDemoStroke(now: Date, size: CGSize, in context: inout GraphicsContext) {
        let cycle = 4.2
        let t = now.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: cycle)
        let progress = min(t / 2.0, 1)
        let fade: Double = t < 2.8 ? 1 : max(0, 1 - (t - 2.8) / 1.2)
        let steps = 48
        let count = Int(Double(steps) * progress)
        guard count > 1 else { return }
        let points: [CGPoint] = (0...count).map { i in
            let u = Double(i) / Double(steps)
            let x = size.width * CGFloat(0.1 + 0.8 * u)
            let y = size.height * CGFloat(0.5 + 0.2 * sin(u * .pi * 3))
            return CGPoint(x: x, y: y)
        }
        draw(points, alpha: fade, in: &context)
    }
}

// MARK: - Chrome

private struct TravelFogChrome: View {
    let zh: Bool
    let hintVisible: Bool

    var body: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(zh ? "精选目的地" : "Featured")
                        .signatureEyebrow()
                    Text(zh ? "蔚蓝海岸" : "Azure Coast")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.white)
                }
                .shadow(color: .black.opacity(0.3), radius: 6, y: 1)
                Spacer(minLength: 0)
                Image(systemName: "cloud.fog.fill")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.white)
                    .frame(width: 34, height: 34)
                    .background(Color.black.opacity(0.25), in: Circle())
            }
            Spacer(minLength: 0)
            hint
        }
        .padding(16)
        .allowsHitTesting(false)
    }

    private var hint: some View {
        HStack(spacing: 8) {
            Image(systemName: "hand.draw.fill")
            Text(zh ? "随意拖动，擦去雾气" : "Drag anywhere to wipe the fog")
        }
        .font(.system(size: 12, weight: .semibold, design: .rounded))
        .foregroundStyle(Color.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.black.opacity(0.35), in: Capsule())
        .frame(maxWidth: .infinity)
        .opacity(hintVisible ? 1 : 0)
        .animation(.easeOut(duration: 0.3), value: hintVisible)
    }
}
