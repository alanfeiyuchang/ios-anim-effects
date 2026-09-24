import SwiftUI

extension Effect {
    static let cardsRimLight = Effect(
        id: "cards.rim-light",
        category: .cards,
        interaction: .gesture,
        name: L("Rim Light Tilt", "边缘光倾斜"),
        summary: L("Drag a light around a dark card: its edge catches the light and a specular band sweeps across.", "拖动光源绕着深色卡片移动：卡片边缘被点亮，镜面光带随之扫过。"),
        prompt: L(
            "A midnight-blue 250×158 pt card floats almost still while the finger acts as a light source. The edge nearest the light glows with a 2.5 pt white rim plus a 6 pt blurred halo that fades out within ±60° along the border, a soft specular band slides across the face the opposite way, and the shadow falls away from the light. The card itself barely turns (at most 2°); all the motion is in the light, which trails the finger on a heavy spring (response 0.55 s, damping 0.72), and on release drifts back to a third of its offset over a slow spring (response 0.9 s). Before the first touch the light orbits the card, moody and cinematic like a product shot.",
            "一张250×158 pt的午夜蓝卡片几乎静止地悬浮着，手指就是光源。离光最近的边缘亮起2.5 pt白色轮廓光，外加6 pt模糊光晕，沿边框在±60°内渐隐；一道柔和镜面光带朝反方向扫过卡面，投影则落向背光一侧。卡片本身几乎不转（最多2°），动的只有光：它以厚重的弹簧（响应0.55秒、阻尼0.72）慢半拍地追随手指，松手后再以缓慢弹簧（响应0.9秒）退回到三分之一的位置。未触摸前光源绕卡片缓缓旋转，氛围感十足，宛如产品大片。"
        ),
        implementation: L(
            "The light position (±1 at the card's edges, up to ±1.24 in a 30 pt margin around it: the card takes a drag at once, the margin only a mostly horizontal one, so vertical swipes still scroll the page) sets an AngularGradient stroke whose peak angle is atan2 of the light, an offset specular stripe with plusLighter blending and two rotation3DEffects; a TimelineView orbits the light until the first touch.",
            "光源位置（卡片边缘为 ±1，在卡片外 30 pt 边距内可到 ±1.24；卡片上立即跟手，边距内仅响应以水平为主的拖动，竖向滑动仍可滚动页面）决定 AngularGradient 描边的峰值角度（取 atan2），并驱动以 plusLighter 混合的偏移镜面光带与两个 rotation3DEffect；首次触摸前由 TimelineView 让光源环绕。"
        ),
        apis: ["AngularGradient(stops:center:angle:)", "rotation3DEffect", "blendMode(.plusLighter)", "TimelineView", "DragGesture"],
        tags: ["rim light", "glare", "tilt", "specular", "轮廓光", "高光", "倾斜", "光泽"],
        params: [
            .slider("lag", L("Follow lag", "跟随滞后"), 0.2...1.0, default: 0.55, unit: "s"),
            .slider("rim", L("Rim intensity", "轮廓光强度"), 0...1, default: 0.9),
            .slider("angle", L("Max tilt", "最大倾斜"), 0...3, default: 2, step: 0.5, decimals: 1, unit: "°"),
        ]
    ) { ctx in
        CardsRimLightDemo(ctx: ctx)
    }
}

private struct CardsRimLightDemo: View {
    let ctx: DemoContext
    @State private var light: CGSize = CGSize(width: 0.6, height: -0.5)
    @State private var touched = false
    /// True while a finger is down; the light eases back only once per touch.
    @State private var held = false
    /// Resets on system cancellation too, so a stolen touch still lets the light drift back.
    @GestureState private var pressing = false

    /// Half the card size: the card's edges map to ±1.
    private let halfCard = CGSize(width: 125, height: 79)
    /// The card plus a 30 pt margin, so the light can be dragged just beside it, not only over it.
    private let area = CGSize(width: 310, height: 218)
    private let cardSize = CGSize(width: 250, height: 158)

    var body: some View {
        VStack(spacing: 30) {
            TimelineView(.animation(minimumInterval: MotionFrameRate.interval(preview: ctx.isPreview), paused: touched)) { timeline in
                let orbit = idleLight(at: timeline.date.timeIntervalSinceReferenceDate)
                CardsRimLitCard(
                    light: touched ? light : orbit,
                    rim: ctx["rim"],
                    maxAngle: ctx["angle"]
                )
            }
            .frame(width: area.width, height: area.height)
            .contentShape(Rectangle())
            .overlay { cardHitArea }
            // Beside the card, only a mostly horizontal drag moves the light, so vertical swipes scroll the page.
            .pageSafeHorizontalDrag(minimumDistance: 8) { value in
                moveLight(to: value.location)
            } onEnded: { _ in
                release()
            }
            DemoHint(text: L("Drag around the card to move the light", "在卡片周围拖动以移动光源"), ctx: ctx)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onChange(of: pressing) { _, isPressing in
            if !isPressing { release() }
        }
    }

    private func idleLight(at t: Double) -> CGSize {
        CGSize(width: cos(t * 0.9), height: sin(t * 0.9) * 0.9)
    }

    /// The card itself claims a drag at once (like its tilt siblings).
    private var cardHitArea: some View {
        Color.clear
            .frame(width: cardSize.width, height: cardSize.height)
            .contentShape(Rectangle())
            .gesture(drag)
    }

    private var drag: some Gesture {
        DragGesture(minimumDistance: 0)
            .updating($pressing) { _, state, _ in state = true }
            .onChanged { value in
                // Card-local → touch-area coordinates (the card is centred in the area).
                moveLight(to: CGPoint(
                    x: value.location.x + (area.width - cardSize.width) / 2,
                    y: value.location.y + (area.height - cardSize.height) / 2
                ))
            }
            .onEnded { _ in release() }
    }

    /// `location` is in the touch area's coordinates.
    private func moveLight(to location: CGPoint) {
        if !touched {
            light = idleLight(at: Date().timeIntervalSinceReferenceDate)
            touched = true
        }
        if !held {
            held = true
            Haptics.tap(.soft)
        }
        // Relative to the card centre: the card's edges are ±1, the light may sit just outside (±1.24).
        let x: CGFloat = (location.x - area.width / 2) / halfCard.width
        let y: CGFloat = (location.y - area.height / 2) / halfCard.height
        withAnimation(.spring(response: ctx["lag"], dampingFraction: 0.72)) {
            light = CGSize(width: x.clamped(to: -1.3...1.3), height: y.clamped(to: -1.3...1.3))
        }
    }

    /// Single, guarded end of a touch (lift or system cancellation).
    private func release() {
        guard held else { return }
        held = false
        withAnimation(.spring(response: 0.9, dampingFraction: 0.8)) {
            light = CGSize(width: light.width / 3, height: light.height / 3)
        }
    }
}

/// Animatable so the rim angle and the specular band travel with the lagging spring, not just the tilt.
private struct CardsRimLitCard: View, Animatable {
    var light: CGSize
    let rim: Double
    let maxAngle: Double

    var animatableData: CGSize.AnimatableData {
        get { light.animatableData }
        set { light.animatableData = newValue }
    }

    private var shape: RoundedRectangle { RoundedRectangle(cornerRadius: 18, style: .continuous) }

    var body: some View {
        let peak: Double = atan2(Double(light.height), Double(light.width))
        let strength = min(Double(hypot(light.width, light.height)), 1)
        let shadowX: CGFloat = -light.width * 18
        let shadowY: CGFloat = 16 - light.height * 10
        // The light may sit just outside the card (±1.3); the tilt stays capped at the card's edge (±1).
        let tiltX: Double = Double(light.width.clamped(to: -1...1))
        let tiltY: Double = Double(light.height.clamped(to: -1...1))
        CardsCreditCard(theme: 1, last4: "5530")
            .overlay { specular }
            .clipShape(shape)
            .overlay { rimStroke(peak: peak, strength: strength) }
            .rotation3DEffect(.degrees(-tiltY * maxAngle), axis: (x: 1, y: 0, z: 0), perspective: 0.55)
            .rotation3DEffect(.degrees(tiltX * maxAngle), axis: (x: 0, y: 1, z: 0), perspective: 0.55)
            .shadow(color: .black.opacity(0.3), radius: 20, x: shadowX, y: shadowY)
    }

    private var specular: some View {
        LinearGradient(
            colors: [.clear, Color.white.opacity(0.22 * rim), .clear],
            startPoint: .leading,
            endPoint: .trailing
        )
        .frame(width: 90, height: 320)
        .rotationEffect(.degrees(24))
        .offset(x: -light.width * 120, y: -light.height * 40)
        .blendMode(.plusLighter)
        .allowsHitTesting(false)
    }

    private func rimStroke(peak: Double, strength: Double) -> some View {
        let stops: [Gradient.Stop] = [
            .init(color: .clear, location: 0),
            .init(color: .clear, location: 1.0 / 3.0),
            .init(color: Color.white.opacity(rim * (0.35 + 0.65 * strength)), location: 0.5),
            .init(color: .clear, location: 2.0 / 3.0),
            .init(color: .clear, location: 1),
        ]
        // The gradient peaks at location 0.5, i.e. 180° after its start angle.
        let gradient = AngularGradient(stops: stops, center: .center, angle: .radians(peak - Double.pi))
        return ZStack {
            shape.strokeBorder(gradient, lineWidth: 6).blur(radius: 6)
            shape.strokeBorder(gradient, lineWidth: 2.5)
        }
        .allowsHitTesting(false)
    }
}
