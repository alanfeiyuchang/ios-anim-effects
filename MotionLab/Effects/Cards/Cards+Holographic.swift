import SwiftUI

extension Effect {
    static let cardsHolographic = Effect(
        id: "cards.holographic",
        category: .cards,
        interaction: .gesture,
        name: L("Holographic Foil", "镭射全息卡"),
        summary: L("A collectible card whose rainbow foil shifts and sparkles as you tilt it.", "收藏卡片的彩虹镭射箔随倾斜流动、闪烁。"),
        prompt: L(
            "A dark 190×264 pt collectible card with 16 pt corners and a glowing emblem is coated in holographic foil: a rainbow angular gradient seen through diagonal stripe bands in screen blend. Dragging tilts it up to 12° in perspective on a heavy follow spring (response 0.45 s) while the foil reacts continuously: the gradient centre slides with the finger, its hue angle turns up to ±120° horizontally and ±60° vertically, and the bands drift sideways, so colour sweeps across like prismatic foil. A narrow white sheen crosses diagonally in plus-lighter blend, sparkle glyphs twinkle out of phase and a violet under-glow shifts against the tilt. Release is slow and under-damped (response 0.8 s, damping 0.5), so the card overshoots and rocks once before settling.",
            "一张 190×264 pt、16 pt 圆角的深色收藏卡，中央是发光徽记，覆着一层镭射箔：彩虹角向渐变透过斜向条纹、以滤色模式叠加。拖动时卡片由偏重的跟手弹簧（响应 0.45 秒）带着透视倾斜，最多 12°；渐变中心随手指滑动，色相角随横向拖动最多转 ±120°、纵向 ±60°，条纹横向漂移，色彩像棱镜箔一样流转。细窄白光以加亮模式斜扫而过，星芒错相闪烁，紫色底光朝倾斜反方向偏移。松手回弹缓慢且欠阻尼（响应 0.8 秒、阻尼 0.5），卡片越过原位、来回摇一下才停稳。"
        ),
        implementation: L(
            "An AngularGradient masked by striped LinearGradient bands is blended with .screen over the card; its center/angle, a .plusLighter sheen and the rotation3DEffect tilt are all driven by the normalised drag position; a TimelineView supplies the sparkle clock and an idle sway until the first touch.",
            "用条纹 LinearGradient 作为遮罩的 AngularGradient 以 .screen 混合在卡面上；其中心与角度、.plusLighter 光带及 rotation3DEffect 倾斜均由归一化拖动位置驱动；TimelineView 提供星芒时钟，并在首次触摸前驱动待机摇摆。"
        ),
        apis: ["AngularGradient", "blendMode(.screen)", "mask", "rotation3DEffect", "DragGesture"],
        tags: ["holographic", "foil", "rainbow", "iridescent", "镭射", "全息", "彩虹", "闪卡"],
        params: [
            .slider("intensity", L("Foil intensity", "镭射强度"), 0...1, default: 0.8),
            .slider("angle", L("Max tilt", "最大倾角"), 0...25, default: 12, step: 1, decimals: 0, unit: "°"),
            .toggle("sparkle", L("Sparkles", "星芒"), default: true),
            .slider("release", L("Release spring", "松手回弹"), 0.3...1.2, default: 0.8, unit: "s"),
        ]
    ) { ctx in
        CardsHoloDemo(ctx: ctx)
    }
}

private struct CardsHoloDemo: View {
    let ctx: DemoContext
    @State private var point: CGSize = .zero
    /// Until the first touch the card sways on its own so the foil is alive on arrival.
    @State private var touched = false

    var body: some View {
        VStack(spacing: 22) {
            TimelineView(.animation(minimumInterval: MotionFrameRate.interval(preview: ctx.isPreview))) { timeline in
                let t = timeline.date.timeIntervalSinceReferenceDate
                CardsHoloCard(
                    point: touched ? point : sway(at: t),
                    intensity: ctx["intensity"],
                    maxAngle: ctx["angle"],
                    sparkle: ctx.bool("sparkle"),
                    // Sparkles twinkle on their own clock; the tilt shifts their phase further.
                    sparklePhase: t.truncatingRemainder(dividingBy: 1_000) * 0.7,
                    language: ctx.language
                )
            }
            .gesture(drag)
            DemoHint(text: L("Drag to tilt the foil", "拖动让镭射流动"), ctx: ctx)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// Idle figure-of-eight sway (full swing in previews, gentler on the detail stage).
    private func sway(at t: Double) -> CGSize {
        let amount = ctx.isPreview ? 1.0 : 0.55
        return CGSize(width: sin(t * 0.9) * 0.9 * amount, height: sin(t * 1.4) * 0.6 * amount)
    }

    private var drag: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                if !touched {
                    // Continue from wherever the idle sway left the card.
                    point = sway(at: Date().timeIntervalSinceReferenceDate)
                    touched = true
                }
                let size = CardsHoloCard.size
                let x = (value.location.x / size.width - 0.5) * 2
                let y = (value.location.y / size.height - 0.5) * 2
                withAnimation(.interactiveSpring(response: 0.45, dampingFraction: 0.75)) {
                    point = CGSize(width: x.clamped(to: -1...1), height: y.clamped(to: -1...1))
                }
            }
            .onEnded { _ in
                // Heavy, under-damped release: the card visibly overshoots and rocks once before settling.
                withAnimation(.spring(response: ctx["release"], dampingFraction: 0.5)) {
                    point = .zero
                }
            }
    }
}

private struct CardsHoloCard: View {
    static let size = CGSize(width: 190, height: 264)
    static let rainbow: [Color] = [
        Color(hex: 0xFF5E7E), Color(hex: 0xFFB86B), Color(hex: 0xFFF06B), Color(hex: 0x6BFFB0),
        Color(hex: 0x6BD5FF), Color(hex: 0x8F6BFF), Color(hex: 0xFF6BE0), Color(hex: 0xFF5E7E),
    ]
    static let stripeStops: [Gradient.Stop] = (0...12).map { i in
        Gradient.Stop(color: .white.opacity(i.isMultiple(of: 2) ? 0.95 : 0.2), location: Double(i) / 12)
    }

    let point: CGSize
    let intensity: Double
    let maxAngle: Double
    let sparkle: Bool
    let sparklePhase: Double
    var language: AppLanguage = .en

    private var shape: RoundedRectangle { RoundedRectangle(cornerRadius: 16, style: .continuous) }

    var body: some View {
        CardsHoloFace(language: language)
            .overlay { foil }
            .overlay { sheen }
            .overlay { if sparkle { CardsHoloSparkles(phase: sparklePhase + Double(point.width + point.height)) } }
            .clipShape(shape)
            .overlay { shape.strokeBorder(Color.white.opacity(0.35), lineWidth: 1) }
            .rotation3DEffect(.degrees(-Double(point.height) * maxAngle), axis: (x: 1, y: 0, z: 0), perspective: 0.5)
            .rotation3DEffect(.degrees(Double(point.width) * maxAngle), axis: (x: 0, y: 1, z: 0), perspective: 0.5)
            .shadow(color: Palette.violet.opacity(0.4), radius: 26, x: -point.width * 14, y: 14 - point.height * 6)
    }

    private var foil: some View {
        AngularGradient(
            colors: CardsHoloCard.rainbow,
            center: UnitPoint(x: 0.5 + point.width * 0.6, y: 0.5 + point.height * 0.6),
            angle: .degrees(Double(point.width) * 120 + Double(point.height) * 60)
        )
        .mask {
            LinearGradient(
                stops: CardsHoloCard.stripeStops,
                startPoint: UnitPoint(x: -0.3 + point.width * 0.3, y: 0),
                endPoint: UnitPoint(x: 1.3 + point.width * 0.3, y: 1)
            )
        }
        .blendMode(.screen)
        .opacity(intensity * 0.75)
        .allowsHitTesting(false)
    }

    private var sheen: some View {
        LinearGradient(
            stops: [
                .init(color: .clear, location: 0.38),
                .init(color: .white.opacity(0.45), location: 0.5),
                .init(color: .clear, location: 0.62),
            ],
            startPoint: UnitPoint(x: -0.4 + point.width * 0.6, y: -0.4 + point.height * 0.4),
            endPoint: UnitPoint(x: 1.4 + point.width * 0.6, y: 1.4 + point.height * 0.4)
        )
        .blendMode(.plusLighter)
        .allowsHitTesting(false)
    }
}

private struct CardsHoloFace: View {
    let language: AppLanguage

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Text(verbatim: "PRISM")
                    .font(.system(size: 15, weight: .heavy, design: .rounded))
                    .tracking(2)
                Spacer(minLength: 0)
                Text(verbatim: "No. 042")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .opacity(0.7)
            }
            emblem
                .frame(maxHeight: .infinity)
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline) {
                    Text(L("Voltage Sprite", "电光精灵"), language)
                        .font(.system(size: 13, weight: .bold))
                    Spacer(minLength: 0)
                    Text(verbatim: "HP 120")
                        .font(.system(size: 9, weight: .heavy, design: .rounded))
                        .opacity(0.75)
                }
                Text(L("Surge — when fully charged, doubles its speed for one turn.", "涌动——充能完毕时，下一回合速度翻倍。"), language)
                    .font(.system(size: 9, weight: .medium))
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .opacity(0.7)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .foregroundStyle(.white)
        .padding(16)
        .frame(width: 190, height: 264)
        .background(
            LinearGradient(
                colors: [Color(hex: 0x1B1A3A), Color(hex: 0x2A1F4F), Color(hex: 0x14142B)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    private var emblem: some View {
        ZStack {
            Circle()
                .fill(RadialGradient(colors: [Palette.violet.opacity(0.9), Palette.indigo.opacity(0.15)], center: .center, startRadius: 4, endRadius: 70))
            Circle()
                .strokeBorder(Color.white.opacity(0.25), lineWidth: 1)
            Image(systemName: "bolt.fill")
                .font(.system(size: 54, weight: .bold))
                .foregroundStyle(.white)
                .shadow(color: Palette.pink.opacity(0.8), radius: 12)
        }
        .frame(width: 128, height: 128)
    }
}

private struct CardsHoloSparkles: View {
    let phase: Double

    private static let spots: [CGPoint] = [
        CGPoint(x: -62, y: -92), CGPoint(x: 58, y: -70), CGPoint(x: -40, y: -20), CGPoint(x: 70, y: 6),
        CGPoint(x: -70, y: 48), CGPoint(x: 30, y: 60), CGPoint(x: -10, y: 104), CGPoint(x: 64, y: 100),
        CGPoint(x: 8, y: -110), CGPoint(x: -78, y: -50),
    ]

    var body: some View {
        ZStack {
            ForEach(CardsHoloSparkles.spots.indices, id: \.self) { i in
                let spot = CardsHoloSparkles.spots[i]
                let twinkle = abs(sin(Double(i) * 1.7 + phase * 3.2))
                Image(systemName: "sparkle")
                    .font(.system(size: CGFloat(7 + (i % 3) * 3), weight: .bold))
                    .foregroundStyle(.white)
                    .opacity(0.15 + 0.85 * twinkle)
                    .scaleEffect(0.6 + 0.4 * twinkle)
                    .offset(x: spot.x, y: spot.y)
            }
        }
        .blendMode(.plusLighter)
        .allowsHitTesting(false)
    }
}
