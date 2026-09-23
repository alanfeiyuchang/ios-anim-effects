import SwiftUI

extension Effect {
    static let showcaseAltitudeRuler = Effect(
        id: "showcase.altitude-ruler",
        category: .showcase,
        interaction: .gesture,
        name: L("Altitude Ruler Picker", "海拔刻度尺"),
        summary: L("A horizontal tick ruler that ticks under your finger, glides with momentum and snaps to 10 m.", "横向刻度尺：拖动时逐格触感，松手带惯性滑行并吸附到 10 米整。"),
        prompt: L(
            "A dark DROP-IN ALTITUDE card with a huge rounded \"2,250 m\" readout above a horizontal ruler: fine ticks every 10 m, medium every 50 m, tall labelled ticks every 100 m, all fading toward the edges, with a glowing orange center needle. Dragging slides the ruler 1:1 while the readout rolls digit by digit and a selection haptic fires on every tick crossed; beyond the 800 m / 3,000 m ends the ruler rubber-bands. On release it keeps gliding by a share of the flick's predicted distance and lands on the nearest 10 m tick with a spring (0.55 s, damping ≈0.82) plus a soft landing haptic. Precise, mechanical and tactile, like a physical dial.",
            "深色“起滑海拔”卡片：超大圆体读数“2,250 m”下方是横向刻度尺——10 米细刻度、50 米中刻度、100 米带数字长刻度，向两端淡出，中央一根发光橙色指针。拖动时刻度尺 1:1 跟手，读数逐位滚动，每越过一格触发选择触感；超出 800 米或 3,000 米端点时带橡皮筋阻尼。松手后按甩动的预测距离继续滑行一段，再以弹簧（0.55 秒、阻尼约 0.82）落在最近的 10 米刻度上，并柔和地触感一下。精准、机械，像拨动一只实体拨盘。"
        ),
        implementation: L(
            "The ruler is an Animatable view whose Canvas draws only the visible ticks for the interpolated position, so the spring snap animates the drawing itself; DragGesture's predictedEndTranslation provides momentum.",
            "刻度尺是一个 Animatable 视图，其 Canvas 只按插值后的位置绘制可见刻度，因此吸附弹簧能直接驱动绘制；惯性来自 DragGesture 的 predictedEndTranslation。"
        ),
        apis: ["Canvas", "Animatable", "DragGesture.predictedEndTranslation", "contentTransition(.numericText(value:))", "UISelectionFeedbackGenerator"],
        tags: ["ruler", "picker", "dial", "momentum", "刻度尺", "选择器", "惯性", "吸附"],
        params: [
            .slider("spacing", L("Tick spacing", "刻度间距"), 8...20, default: 12, decimals: 0, unit: "pt"),
            .slider("momentum", L("Momentum", "惯性"), 0...1, default: 0.5),
            .slider("damping", L("Snap damping", "吸附阻尼"), 0.5...1.0, default: 0.82),
        ]
    ) { ctx in
        SportAltitudeDemo(ctx: ctx)
    }
}

private enum AltitudeScale {
    static let base = 800
    static let step = 10
    static let tickCount = 221   // 800 … 3,000 m
    static var maxIndex: CGFloat { CGFloat(tickCount - 1) }

    static func value(at position: CGFloat) -> Int {
        let index = Int(position.rounded()).clamped(to: 0...(tickCount - 1))
        return base + index * step
    }
}

private struct SportAltitudeDemo: View {
    let ctx: DemoContext
    /// Position in tick units (fractional while dragging).
    @State private var position: CGFloat = 145
    @State private var dragStart: CGFloat?
    @State private var lastIndex = 145
    /// The settle in flight, so a grab catches the ruler where it is on screen.
    @State private var inFlight: AltitudeSettle?

    private var spacing: CGFloat { max(ctx.cg("spacing"), 4) }

    var body: some View {
        SignatureStage {
            VStack(spacing: 0) {
                Spacer()
                card
                Spacer()
                DemoHint(text: L("Drag or flick the ruler", "拖动或快速拨动刻度尺"), ctx: ctx)
                    .padding(.bottom, 16)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .autoplay(ctx.isPreview, every: 2.0, delay: 0.6) { randomJump() }
    }

    private var card: some View {
        VStack(alignment: .leading, spacing: 14) {
            SportEyebrowRow(title: L("Drop-in altitude", "起滑海拔")(ctx.language), symbol: "mountain.2.fill", trailing: "Nordkette")
            AltitudeReadout(value: AltitudeScale.value(at: position), language: ctx.language)
            ZStack {
                AltitudeRuler(position: position, spacing: spacing)
                AltitudeNeedle()
            }
            .frame(height: 76)
            .contentShape(Rectangle())
            .gesture(dragGesture)
        }
        .padding(20)
        .frame(width: 300)
        .signatureCard()
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                let start: CGFloat = dragStart ?? grab()
                var p = start - value.translation.width / spacing
                if p < 0 {
                    p = rubberBand(p * spacing, limit: 40) / spacing
                } else if p > AltitudeScale.maxIndex {
                    p = AltitudeScale.maxIndex + rubberBand((p - AltitudeScale.maxIndex) * spacing, limit: 40) / spacing
                }
                position = p
                let index = Int(p.rounded()).clamped(to: 0...(AltitudeScale.tickCount - 1))
                if index != lastIndex {
                    lastIndex = index
                    if !ctx.isPreview { Haptics.selection() }
                }
            }
            .onEnded { value in
                let start = dragStart ?? position
                dragStart = nil
                let predicted = start - value.predictedEndTranslation.width / spacing
                let target = (position + (predicted - position) * ctx.cg("momentum"))
                    .rounded()
                    .clamped(to: 0...AltitudeScale.maxIndex)
                settle(to: target)
                if !ctx.isPreview { Haptics.tap(.soft) }
            }
    }

    /// Halts a settle in flight at the value on screen and starts the drag from there.
    private func grab() -> CGFloat {
        let onScreen: CGFloat = inFlight?.value(at: .now) ?? position
        inFlight = nil
        var still = Transaction()
        still.disablesAnimations = true
        withTransaction(still) { position = onScreen }
        dragStart = onScreen
        return onScreen
    }

    private func settle(to target: CGFloat) {
        let spring = Spring(response: 0.55, dampingRatio: ctx["damping"])
        inFlight = AltitudeSettle(from: position, delta: target - position, start: .now, spring: spring)
        withAnimation(.spring(spring)) { position = target }
        lastIndex = Int(target)
    }

    private func randomJump() {
        let target = CGFloat(Int.random(in: 30...200))
        settle(to: target)
    }
}

/// A settle described by its start, so the position on screen can be computed at any moment.
private struct AltitudeSettle {
    let from: CGFloat
    let delta: CGFloat
    let start: Date
    let spring: Spring

    func value(at date: Date) -> CGFloat {
        let elapsed: Double = date.timeIntervalSince(start)
        guard elapsed < spring.settlingDuration else { return from + delta }
        let moved: CGFloat = spring.value(target: delta, initialVelocity: 0, time: elapsed)
        return from + moved
    }
}

private struct AltitudeReadout: View {
    let value: Int
    let language: AppLanguage

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value.formatted())
                    .font(Signature.number(46))
                    .foregroundStyle(Color.white)
                    .contentTransition(.numericText(value: Double(value)))
                    .animation(.snappy(duration: 0.25), value: value)
                Text(verbatim: "m")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(Signature.textSecondary)
            }
            Text("+\((value - 860).formatted()) m " + L("above base", "高于山脚")(language))
                .font(.system(size: 11, weight: .medium, design: .rounded).monospacedDigit())
                .foregroundStyle(Signature.textSecondary)
        }
    }
}

private struct AltitudeNeedle: View {
    var body: some View {
        VStack(spacing: 0) {
            Image(systemName: "arrowtriangle.down.fill")
                .font(.system(size: 9))
                .foregroundStyle(Signature.accent)
            Capsule()
                .fill(Signature.accentGradient)
                .frame(width: 3, height: 48)
                .shadow(color: Signature.accent.opacity(0.9), radius: 6)
            Spacer(minLength: 0)
        }
        .allowsHitTesting(false)
    }
}

/// Animatable so a spring on `position` re-renders the Canvas at every intermediate value.
private struct AltitudeRuler: View, Animatable {
    var position: CGFloat
    let spacing: CGFloat

    var animatableData: CGFloat {
        get { position }
        set { position = newValue }
    }

    var body: some View {
        Canvas { context, size in
            let mid = size.width / 2
            let offset = -position * spacing
            let first = max(0, Int(((-offset - mid) / spacing).rounded(.down)))
            let last = min(AltitudeScale.tickCount - 1, Int(((-offset + mid) / spacing).rounded(.up)))
            guard first <= last else { return }
            for i in first...last {
                let x = mid + CGFloat(i) * spacing + offset
                let major = i % 10 == 0
                let medium = i % 5 == 0
                let height: CGFloat = major ? 34 : (medium ? 22 : 13)
                let fade = max(0.08, 1 - Double(abs(x - mid) / mid) * 0.95)
                let rect = CGRect(x: x - 1, y: 12, width: 2, height: height)
                let alpha = fade * (major ? 0.95 : 0.45)
                context.fill(Path(roundedRect: rect, cornerRadius: 1), with: .color(Color.white.opacity(alpha)))
                if major {
                    let label = Text("\(AltitudeScale.base + i * AltitudeScale.step)")
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.white.opacity(fade * 0.7))
                    context.draw(label, at: CGPoint(x: x, y: size.height - 10))
                }
            }
        }
    }
}
