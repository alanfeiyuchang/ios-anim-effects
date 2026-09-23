import SwiftUI

extension Effect {
    static let showcasePinRoute = Effect(
        id: "showcase.pin-route",
        category: .showcase,
        interaction: .tap,
        name: L("Pin Drop & Route", "落钉连线"),
        summary: L(
            "Tap the map to drop a bouncing pin with a ripple; a dashed route arcs in from the previous stop.",
            "点击地图落下弹跳图钉并泛起涟漪，虚线路线从上一站以弧线绘制过来。"
        ),
        prompt: L(
            "A dark stylised map card (faint street grid, a teal bay) shows a trip as a chain of pinned stops. Tapping anywhere drops a white-and-orange pin from 90 pt above on a spring (response 0.5 s, damping 0.65), so it lands with a visible overshoot bounce and a medium haptic. From 250 ms an orange ring ripples out from its base, scaling 0.4→3.2 and fading over 900 ms. At the same time a dashed orange route (3 pt, 6/5 dash, soft glow) draws itself from the previous pin to the new one along a gently bowed quadratic arc, trimming 0→1 over 0.8 s ease-in-out. The trip distance above rolls to its new total. Once the stop limit is reached, the oldest pin shrinks away with its leg. The newest pin is highlighted in orange, earlier ones turn graphite. It feels exploratory, precise and alive.",
            "暗色风格化地图卡片上是一段多站点行程。点击任意处，一枚白橙图钉从 90pt 高处以弹簧（响应 0.5 秒、阻尼 0.65）落下，明显过冲回弹，伴随中等触感。落地 250 毫秒后钉脚泛起橙色涟漪，900 毫秒内从 0.4 放大到 3.2 并淡出；同时一条橙色虚线路线（3pt，虚线 6/5，带柔光）沿微拱的二次曲线从上一枚图钉画到新图钉，0.8 秒缓入缓出。里程滚动到新总数。达到站点上限时，最早的图钉连同路段一起缩回下一站并消失。最新图钉为橙色，其余为石墨色。"
        ),
        implementation: L(
            "Pins live in an array and are placed with position(); insertion uses an asymmetric offset+opacity transition inside a spring withAnimation, so the spring overshoot becomes the bounce. Each leg is a quadratic-curve Shape whose trim animates on appear, and each pin's ripple is an onAppear-driven Circle.",
            "图钉存放在数组中并通过 position() 定位；插入使用非对称的偏移+透明度过渡，包在弹簧 withAnimation 中，弹簧过冲即成弹跳。每段路线是二次曲线 Shape，出现时动画 trim；每枚图钉的涟漪是 onAppear 驱动的 Circle。"
        ),
        apis: ["onTapGesture(coordinateSpace:perform:)", "AnyTransition.offset", "trim(from:to:)", "contentTransition(.numericText)", "Canvas"],
        tags: ["map", "pin", "route", "ripple", "drop", "地图", "图钉", "路线", "涟漪"],
        params: [
            .slider("bounce", L("Drop bounce", "落地弹性"), 0...0.6, default: 0.35),
            .slider("routeTime", L("Route draw time", "路线绘制时长"), 0.3...2, default: 0.8, unit: "s"),
            .slider("maxPins", L("Max stops", "最多站点"), 2...6, default: 4, step: 1, decimals: 0),
        ]
    ) { ctx in
        TravelPinRouteDemo(ctx: ctx)
    }
}

// MARK: - Model

private struct TravelMapPin: Identifiable, Equatable {
    let id: Int
    let point: CGPoint
}

// MARK: - Demo

private struct TravelPinRouteDemo: View {
    let ctx: DemoContext
    /// Seeded with a short route so the stage reads as a planned trip before the first tap.
    @State private var pins: [TravelMapPin] = [
        TravelMapPin(id: 0, point: CGPoint(x: 64, y: 176)),
        TravelMapPin(id: 1, point: CGPoint(x: 140, y: 92)),
        TravelMapPin(id: 2, point: CGPoint(x: 228, y: 160)),
    ]
    @State private var nextID = 3

    private static let demoPoints: [CGPoint] = [
        CGPoint(x: 140, y: 92),
        CGPoint(x: 228, y: 160),
        CGPoint(x: 116, y: 196),
        CGPoint(x: 214, y: 70),
        CGPoint(x: 62, y: 104),
    ]

    /// Fixed map size; the card hugs it so it keeps a margin inside both the 340 pt preview and ~360 pt detail stage.
    private static let mapSize = CGSize(width: 276, height: 228)

    private var zh: Bool { ctx.language == .zh }

    private var totalKm: Int {
        guard pins.count > 1 else { return 0 }
        var sum: CGFloat = 0
        for index in 1..<pins.count {
            let a = pins[index - 1].point
            let b = pins[index].point
            sum += hypot(b.x - a.x, b.y - a.y)
        }
        return Int(sum * 3.2)
    }

    var body: some View {
        SignatureStage {
            VStack(spacing: 0) {
                Spacer(minLength: 0)
                VStack(alignment: .leading, spacing: 12) {
                    header
                    map
                }
                .padding(14)
                .frame(width: Self.mapSize.width + 28)
                .signatureCard()
                Spacer(minLength: 0)
                DemoHint(text: L("Tap the map to drop pins", "点击地图放置图钉"), ctx: ctx)
                    .padding(.bottom, 14)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .autoplay(ctx.isPreview, every: 1.4) {
            drop(at: Self.demoPoints[nextID % Self.demoPoints.count])
        }
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text(zh ? "我的路线" : "My route")
                    .signatureEyebrow()
                Text(zh ? "\(pins.count) 个站点" : "\(pins.count) stops")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.white)
                    .contentTransition(.numericText(value: Double(pins.count)))
            }
            Spacer(minLength: 0)
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(totalKm, format: .number)
                    .font(Signature.number(24))
                    .foregroundStyle(Color.white)
                    .contentTransition(.numericText(value: Double(totalKm)))
                Text("km")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(Signature.textSecondary)
            }
        }
        .padding(.horizontal, 4)
    }

    private var map: some View {
        ZStack {
            TravelMapBackdrop()
            ForEach(Array(pins.enumerated().dropFirst()), id: \.element.id) { index, pin in
                TravelRouteLeg(from: pins[index - 1].point, to: pin.point, duration: ctx["routeTime"], still: ctx.isStill)
                    .transition(legRemoval(toward: pin.point))
            }
            ForEach(pins) { pin in
                TravelPinMarker(isLatest: pin.id == pins.last?.id, still: ctx.isStill)
                    .position(pin.point)
                    .transition(
                        .asymmetric(
                            insertion: AnyTransition.offset(y: -90).combined(with: .opacity),
                            removal: AnyTransition.scale(scale: 0.3).combined(with: .opacity)
                        )
                    )
            }
        }
        .frame(width: Self.mapSize.width, height: Self.mapSize.height)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .contentShape(Rectangle())
        .onTapGesture(coordinateSpace: .local) { location in
            drop(at: location)
        }
    }

    /// The oldest leg retracts into the pin it led to and fades, alongside its start pin shrinking away.
    private func legRemoval(toward point: CGPoint) -> AnyTransition {
        let anchor = UnitPoint(x: point.x / Self.mapSize.width, y: point.y / Self.mapSize.height)
        return .asymmetric(
            insertion: .identity,
            removal: AnyTransition.scale(scale: 0.2, anchor: anchor).combined(with: .opacity)
        )
    }

    private func drop(at point: CGPoint) {
        if !ctx.isPreview { Haptics.tap(.medium) }
        let limit = max(ctx.int("maxPins"), 2)
        withAnimation(.spring(response: 0.5, dampingFraction: 1 - ctx["bounce"])) {
            pins.append(TravelMapPin(id: nextID, point: point))
            nextID += 1
            while pins.count > limit { pins.removeFirst() }
        }
    }
}

// MARK: - Map pieces

private struct TravelMapBackdrop: View {
    var body: some View {
        Canvas { context, size in
            let w = size.width
            let h = size.height
            context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(Color(hex: 0x1E2126)))

            var bay = Path()
            bay.move(to: CGPoint(x: w * 0.58, y: h))
            bay.addCurve(
                to: CGPoint(x: w, y: h * 0.40),
                control1: CGPoint(x: w * 0.68, y: h * 0.68),
                control2: CGPoint(x: w * 0.84, y: h * 0.50)
            )
            bay.addLine(to: CGPoint(x: w, y: h))
            bay.closeSubpath()
            context.fill(bay, with: .color(Color(hex: 0x173A48)))

            let park = Path(roundedRect: CGRect(x: w * 0.14, y: h * 0.12, width: w * 0.22, height: h * 0.2), cornerRadius: 8)
            context.fill(park, with: .color(Color(hex: 0x223127)))

            var streets = Path()
            for i in 1..<8 {
                let x = w * CGFloat(i) / 8 + CGFloat(i % 3) * 5
                streets.move(to: CGPoint(x: x, y: 0))
                streets.addLine(to: CGPoint(x: x - 18, y: h))
            }
            for i in 1..<6 {
                let y = h * CGFloat(i) / 6
                streets.move(to: CGPoint(x: 0, y: y))
                streets.addLine(to: CGPoint(x: w, y: y + 10))
            }
            context.stroke(streets, with: .color(Color.white.opacity(0.07)), lineWidth: 1)

            var avenue = Path()
            avenue.move(to: CGPoint(x: 0, y: h * 0.78))
            avenue.addQuadCurve(to: CGPoint(x: w, y: h * 0.18), control: CGPoint(x: w * 0.5, y: h * 0.62))
            context.stroke(avenue, with: .color(Color.white.opacity(0.13)), lineWidth: 3)
        }
        .allowsHitTesting(false)
    }
}

private struct TravelLegShape: Shape {
    let from: CGPoint
    let to: CGPoint

    func path(in rect: CGRect) -> Path {
        let distance = hypot(to.x - from.x, to.y - from.y)
        let control = CGPoint(x: (from.x + to.x) / 2, y: (from.y + to.y) / 2 - distance * 0.25)
        var path = Path()
        path.move(to: from)
        path.addQuadCurve(to: to, control: control)
        return path
    }
}

private struct TravelRouteLeg: View {
    let from: CGPoint
    let to: CGPoint
    let duration: Double
    @State private var drawn: Bool

    /// Still snapshots never run `onAppear`, so their legs start fully drawn.
    init(from: CGPoint, to: CGPoint, duration: Double, still: Bool) {
        self.from = from
        self.to = to
        self.duration = duration
        _drawn = State(initialValue: still)
    }

    var body: some View {
        TravelLegShape(from: from, to: to)
            .trim(from: 0, to: drawn ? 1 : 0)
            .stroke(Signature.accent, style: StrokeStyle(lineWidth: 3, lineCap: .round, dash: [6, 5]))
            .shadow(color: Signature.accent.opacity(0.6), radius: 4)
            .allowsHitTesting(false)
            .onAppear {
                withAnimation(.easeInOut(duration: duration).delay(0.15)) { drawn = true }
            }
    }
}

private struct TravelPinMarker: View {
    let isLatest: Bool
    @State private var ripple: Bool

    /// Still snapshots never run `onAppear`, so their ripple starts already spent (invisible).
    init(isLatest: Bool, still: Bool) {
        self.isLatest = isLatest
        _ripple = State(initialValue: still)
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Signature.accent, lineWidth: 2)
                .frame(width: 18, height: 18)
                .scaleEffect(ripple ? 3.2 : 0.4)
                .opacity(ripple ? 0 : 0.9)
            Ellipse()
                .fill(Color.black.opacity(0.45))
                .frame(width: 12, height: 4)
            Image(systemName: "mappin.circle.fill")
                .font(.system(size: 26))
                .symbolRenderingMode(.palette)
                .foregroundStyle(Color.white, isLatest ? Signature.accent : Color(hex: 0x3A3F48))
                .shadow(color: Color.black.opacity(0.4), radius: 4, y: 2)
                .offset(y: -16)
                .animation(.easeInOut(duration: 0.3), value: isLatest)
        }
        .allowsHitTesting(false)
        .onAppear {
            withAnimation(.easeOut(duration: 0.9).delay(0.25)) { ripple = true }
        }
    }
}
