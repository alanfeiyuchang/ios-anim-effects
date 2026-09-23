import SwiftUI

extension Effect {
    static let showcaseGearChecklist = Effect(
        id: "showcase.gear-checklist",
        category: .showcase,
        interaction: .tap,
        name: L("Gear Checklist", "装备清单"),
        summary: L("Tick off your kit: checks draw themselves, each item's icon flies into the ring and it fills to lime.", "逐项勾选装备：对勾自行描绘，物品图标飞进进度环，最终变为青柠色。"),
        prompt: L(
            "A dark SUMMIT KIT checklist card: a title, a progress ring with a rolling “2/5” count, and five gear rows (glyph tile, name, detail, round check). Tapping a row presses it to 97%; its check fills with the orange gradient from 20% on a bouncy spring (response 0.35 s, damping 0.6), a dark checkmark draws itself 80 ms later, and the name dims to 45% with a strike-through. A glowing copy of the row's glyph then flies a quadratic arc (~28 pt above the straight path, ~0.55 s, fast-out slow-in) into the ring, shrinking to half size and fading at the very end. The ring gulps it with a 1.14 swell and bouncy settle as its orange arc sweeps to the new fraction. The last item turns the ring lime, swaps the count for a checkmark, retitles the card “All packed” and fires a success haptic. Satisfying.",
            "深色“登顶装备”清单：标题、带滚动计数（“2/5”）的进度环和五行装备。点击一行，整行轻压到 97%，勾选圆以弹性弹簧（响应 0.35 秒、阻尼 0.6）从 20% 填满橙色，对勾 80 毫秒后描出，名称淡到 45% 并加删除线。随后该行图标的发光副本沿二次弧线（高出直线约 28pt，约 0.55 秒）飞进进度环，途中缩到一半、末段淡出；圆环放大到 1.14 再弹性回落，橙色弧线扫到新比例。最后一件入环时圆环变青柠色、计数换成对勾，标题变为“装备齐全”并触发成功触觉。"
        ),
        implementation: L(
            "A Set of checked ids drives the checks; onGeometryChange records each glyph tile and the ring in a named coordinate space, and an Animatable flyer view interpolates a quadratic Bézier between them. A second Set of landed ids feeds the ring, whose keyframeAnimator swells on each arrival; the check is a trimmed custom Shape.",
            "已勾选 id 的 Set 驱动对勾；onGeometryChange 在命名坐标空间里记录每个图标方块与进度环的位置，一个遵循 Animatable 的飞行视图在两者之间按二次贝塞尔插值。另一个“已落入” Set 驱动进度环，每次落入由 keyframeAnimator 放大一下；对勾是 trim 的自定义 Shape。"
        ),
        apis: ["onGeometryChange(for:of:action:)", "Animatable", "keyframeAnimator", "Shape.trim(from:to:)", "coordinateSpace(.named(_:))"],
        tags: ["checklist", "fly to target", "progress ring", "packing", "清单", "飞入", "进度环", "打包"],
        params: [
            .slider("flight", L("Flight time", "飞行时长"), 0.3...1.2, default: 0.55, unit: "s"),
            .slider("arc", L("Arc height", "弧线高度"), 0...60, default: 28, decimals: 0, unit: "pt"),
            .toggle("strike", L("Strike-through", "删除线"), default: true),
        ]
    ) { ctx in
        SportGearDemo(ctx: ctx)
    }
}

private struct GearItem: Identifiable {
    let id: Int
    let symbol: String
    let name: LocalizedText
    let detail: LocalizedText
}

private struct GearFlight: Identifiable {
    let id: Int
    let symbol: String
    let from: CGPoint
    let to: CGPoint
}

private struct SportGearDemo: View {
    let ctx: DemoContext
    @State private var checked: Set<Int> = [1]
    /// Items whose glyph has reached the ring; the ring and title count these, not the taps.
    @State private var landed: Set<Int> = [1]
    @State private var flights: [GearFlight] = []
    @State private var flightSerial = 0
    /// Stored landing tasks, cancelled when the demo goes away.
    @State private var cleanups: [Int: Task<Void, Never>] = [:]
    @State private var ringHits = 0
    @State private var tileCenters: [Int: CGPoint] = [:]
    @State private var ringCenter: CGPoint = .zero

    private static let space = "gearCard"
    private static let items: [GearItem] = [
        GearItem(id: 0, symbol: "shield.lefthalf.filled", name: L("Helmet", "头盔"), detail: L("Size M · MIPS", "M 码 · MIPS")),
        GearItem(id: 1, symbol: "eyeglasses", name: L("Goggles", "雪镜"), detail: L("Low-light lens", "弱光镜片")),
        GearItem(id: 2, symbol: "hand.raised.fill", name: L("Gloves", "手套"), detail: L("Gore-Tex shell", "Gore-Tex 外层")),
        GearItem(id: 3, symbol: "antenna.radiowaves.left.and.right", name: L("Avalanche beacon", "雪崩信标"), detail: L("Battery 92%", "电量 92%")),
        GearItem(id: 4, symbol: "cup.and.saucer.fill", name: L("Thermos", "保温壶"), detail: L("Hot ginger tea", "热姜茶")),
    ]

    private var allPacked: Bool { landed.count == Self.items.count }

    var body: some View {
        SignatureStage {
            VStack(spacing: 0) {
                Spacer()
                card
                Spacer()
                DemoHint(text: L("Tap items to pack them", "点击物品即可打包"), ctx: ctx)
                    .padding(.bottom, 14)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .autoplay(ctx.isPreview, every: 1.1, delay: 0.6) { previewTick() }
        .onDisappear { cancelCleanups() }
    }

    private var card: some View {
        VStack(spacing: 10) {
            header
            VStack(spacing: 2) {
                ForEach(Self.items) { item in
                    row(item)
                }
            }
        }
        .padding(14)
        .frame(width: 292)
        .coordinateSpace(.named(Self.space))
        .overlay {
            ZStack {
                ForEach(flights) { flight in
                    GearFlyer(flight: flight, duration: max(ctx["flight"], 0.1), arc: ctx.cg("arc"))
                }
            }
            .allowsHitTesting(false)
        }
        .signatureCard()
    }

    private var header: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                SportEyebrowRow(title: L("Summit kit", "登顶装备")(ctx.language), symbol: "backpack.fill")
                Text(allPacked ? L("All packed", "装备齐全") : L("Pack your gear", "整理装备"), ctx.language)
                    .font(.system(size: 19, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.white)
                    .contentTransition(.opacity)
            }
            Spacer(minLength: 0)
            GearRing(count: landed.count, total: Self.items.count, hits: ringHits)
                .onGeometryChange(for: CGPoint.self) { proxy in
                    let frame = proxy.frame(in: .named(Self.space))
                    return CGPoint(x: frame.midX, y: frame.midY)
                } action: { center in
                    ringCenter = center
                }
        }
        .padding(.horizontal, 4)
    }

    private func row(_ item: GearItem) -> some View {
        let isChecked = checked.contains(item.id)
        return Button {
            toggle(item.id)
        } label: {
            HStack(spacing: 11) {
                Image(systemName: item.symbol)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(isChecked ? Signature.accent : Color.white.opacity(0.85))
                    .frame(width: 28, height: 28)
                    .background(Color.white.opacity(isChecked ? 0.04 : 0.08), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .onGeometryChange(for: CGPoint.self) { proxy in
                        let frame = proxy.frame(in: .named(Self.space))
                        return CGPoint(x: frame.midX, y: frame.midY)
                    } action: { center in
                        tileCenters[item.id] = center
                    }
                VStack(alignment: .leading, spacing: 1) {
                    Text(item.name, ctx.language)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .strikethrough(ctx.bool("strike") && isChecked, color: Color.white.opacity(0.45))
                        .foregroundStyle(Color.white.opacity(isChecked ? 0.45 : 1))
                    Text(item.detail, ctx.language)
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundStyle(Signature.textSecondary)
                }
                Spacer(minLength: 0)
                GearCheck(checked: isChecked)
            }
            .padding(.horizontal, 8)
            .frame(height: 38)
            .background(Color.white.opacity(isChecked ? 0 : 0.035), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .contentShape(Rectangle())
        }
        .buttonStyle(SportPressStyle(scale: 0.97, dim: 0.04))
    }

    private func toggle(_ id: Int) {
        if checked.contains(id) {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                checked.remove(id)
                landed.remove(id)
            }
        } else {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                _ = checked.insert(id)
            }
            launch(id)
        }
        if !ctx.isPreview { Haptics.tap(.light) }
    }

    /// Sends a copy of the row's glyph along an arc into the ring; the ring counts it when it lands.
    private func launch(_ id: Int) {
        guard let from = tileCenters[id], let item = Self.items.first(where: { $0.id == id }) else {
            landed.insert(id)
            return
        }
        flightSerial += 1
        let flight = GearFlight(id: flightSerial, symbol: item.symbol, from: from, to: ringCenter)
        flights.append(flight)
        let duration = max(ctx["flight"], 0.1)
        // Captured now: autoplay (and the detail intro) mute haptics only for the synchronous part.
        let muted = ctx.isPreview || Haptics.isMuted
        cleanups[flight.id] = Task { @MainActor in
            try? await Task.sleep(for: .seconds(duration))
            guard !Task.isCancelled else { return }
            cleanups[flight.id] = nil
            flights.removeAll { $0.id == flight.id }
            guard checked.contains(id) else { return }
            let wasPacked = allPacked
            withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                _ = landed.insert(id)
            }
            ringHits += 1
            if !muted && allPacked && !wasPacked { Haptics.success() }
        }
    }

    private func cancelCleanups() {
        for task in cleanups.values { task.cancel() }
        cleanups = [:]
    }

    private func previewTick() {
        if let next = Self.items.first(where: { !checked.contains($0.id) }) {
            toggle(next.id)
        } else {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                checked = []
                landed = []
            }
        }
    }
}

/// Owns the flight clock: progress runs 0 → 1 once on appear.
private struct GearFlyer: View {
    let flight: GearFlight
    let duration: Double
    let arc: CGFloat
    @State private var progress: CGFloat = 0

    var body: some View {
        GearFlyerGlyph(symbol: flight.symbol, from: flight.from, to: flight.to, arc: arc, progress: progress)
            .onAppear {
                withAnimation(.timingCurve(0.3, 0, 0.2, 1, duration: duration)) { progress = 1 }
            }
    }
}

/// Animatable so every interpolated progress re-evaluates the quadratic arc, not just the end points.
private struct GearFlyerGlyph: View, Animatable {
    let symbol: String
    let from: CGPoint
    let to: CGPoint
    let arc: CGFloat
    var progress: CGFloat

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    private var point: CGPoint {
        let t = progress
        let u = 1 - t
        let control = CGPoint(x: (from.x + to.x) / 2, y: min(from.y, to.y) - arc)
        let x = u * u * from.x + 2 * u * t * control.x + t * t * to.x
        let y = u * u * from.y + 2 * u * t * control.y + t * t * to.y
        return CGPoint(x: x, y: y)
    }

    var body: some View {
        Image(systemName: symbol)
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(Signature.accent)
            .frame(width: 28, height: 28)
            .background(Signature.accent.opacity(0.18), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .shadow(color: Signature.accent.opacity(0.5), radius: 6)
            .scaleEffect(1 - 0.5 * progress)
            .opacity(progress > 0.92 ? Double((1 - progress) / 0.08) : 1)
            .position(point)
    }
}

private struct GearRing: View {
    let count: Int
    let total: Int
    /// Bumped each time a glyph lands: the ring gulps it with a quick swell.
    let hits: Int

    private var done: Bool { count == total }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.1), lineWidth: 5)
            Circle()
                .trim(from: 0, to: CGFloat(count) / CGFloat(max(total, 1)))
                .stroke(
                    done ? AnyShapeStyle(Signature.lime) : AnyShapeStyle(Signature.accentGradient),
                    style: StrokeStyle(lineWidth: 5, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: (done ? Signature.lime : Signature.accent).opacity(0.6), radius: 5)
                .animation(.spring(response: 0.5, dampingFraction: 0.75), value: count)
            if done {
                Image(systemName: "checkmark")
                    .font(.system(size: 17, weight: .heavy))
                    .foregroundStyle(Signature.lime)
                    .transition(.scale(scale: 0.3).combined(with: .opacity))
            } else {
                Text(verbatim: "\(count)/\(total)")
                    .font(Signature.number(14))
                    .foregroundStyle(Color.white)
                    .contentTransition(.numericText(value: Double(count)))
                    .transition(.opacity)
            }
        }
        .frame(width: 52, height: 52)
        .scaleEffect(done ? 1.08 : 1)
        .animation(.spring(response: 0.4, dampingFraction: 0.55), value: done)
        .keyframeAnimator(initialValue: 1.0, trigger: hits) { content, scale in
            content.scaleEffect(scale)
        } keyframes: { _ in
            KeyframeTrack(\.self) {
                CubicKeyframe(1.14, duration: 0.1)
                SpringKeyframe(1.0, duration: 0.4, spring: .bouncy)
            }
        }
    }
}

private struct GearCheck: View {
    let checked: Bool

    var body: some View {
        ZStack {
            Circle()
                .strokeBorder(Color.white.opacity(checked ? 0 : 0.28), lineWidth: 1.5)
            Circle()
                .fill(Signature.accentGradient)
                .scaleEffect(checked ? 1 : 0.2)
                .opacity(checked ? 1 : 0)
                .shadow(color: Signature.accent.opacity(checked ? 0.6 : 0), radius: 5)
            GearCheckShape()
                .trim(from: 0, to: checked ? 1 : 0)
                .stroke(Signature.ink, style: StrokeStyle(lineWidth: 2.2, lineCap: .round, lineJoin: .round))
                .frame(width: 10, height: 8)
                .animation(checked ? Animation.easeOut(duration: 0.22).delay(0.08) : Animation.easeIn(duration: 0.1), value: checked)
        }
        .frame(width: 22, height: 22)
        .animation(.spring(response: 0.35, dampingFraction: 0.6), value: checked)
    }
}

private struct GearCheckShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.38, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        return path
    }
}
