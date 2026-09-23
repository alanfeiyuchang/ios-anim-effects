import SwiftUI

extension Effect {
    static let showcaseTransitLine = Effect(
        id: "showcase.transit-line",
        category: .showcase,
        interaction: .tap,
        name: L("Live Transit Line", "地铁线路实况"),
        summary: L(
            "A glowing train dot rides a vertical metro line, lighting each station as it arrives.",
            "发光的列车圆点沿竖向地铁线行进，每到一站就点亮站点。"
        ),
        prompt: L(
            "A dark \"Line 2 · Northbound\" card with five stations stacked 40 pt apart along a 4 pt vertical track. A glowing orange train dot glides from station to station on a 1.0 s ease-in-out, and the track behind it fills orange as it goes. When the train arrives, that station's ring fills and pops to 140% before springing back (response 0.35 s, damping 0.5), its name brightens to white, the \"Next\" tag slides to the following station and the minutes-to-terminus counter rolls down. Passed stations stay orange, upcoming ones stay graphite. The train advances every 1.8 s and loops back to the first station at the end; tapping any station sends the train straight there, a light haptic marking its arrival. Calm, legible and quietly alive.",
            "暗色“2 号线 · 北行”卡片，五个站点沿 4pt 竖向轨道每 40pt 排列。一颗发光的橙色列车圆点以 1.0 秒 ease-in-out 逐站滑行，经过的轨道填成橙色。到站时该站圆环填满、弹到 140% 再以弹簧（响应 0.35 秒、阻尼 0.5）回落，站名变白，“下一站”标记滑到后一站，距终点分钟数向下滚动。已过的站保持橙色，未到的为石墨色。列车每 1.8 秒前进一站，到终点回首站循环；点击任意站点，列车直接驶去，到站时轻触一下。冷静而鲜活。"
        ),
        implementation: L(
            "A station index drives the train's y offset and the track fill height inside one easeInOut withAnimation; each station ring runs a keyframeAnimator keyed on its own arrival counter, the minutes-to-terminus counter uses numericText, and a task(id:) loop advances the index.",
            "站点序号在同一个 easeInOut withAnimation 中驱动列车的 y 偏移与轨道填充高度；每个站点圆环以各自的到站计数触发 keyframeAnimator，距终点分钟数使用 numericText，task(id:) 循环推进站点序号。"
        ),
        apis: ["task(id:)", "keyframeAnimator", "contentTransition(.numericText)", "easeInOut(duration:)", "shadow"],
        tags: ["metro", "transit", "timeline", "live", "地铁", "公交", "时间轴", "实时"],
        params: [
            .slider("travel", L("Travel time", "行驶时长"), 0.4...1.6, default: 1.0, unit: "s"),
            .slider("dwell", L("Dwell time", "停站时长"), 0.3...2.0, default: 0.8, unit: "s"),
            .toggle("pulse", L("Arrival pop", "到站弹跳"), default: true),
        ]
    ) { ctx in
        TravelTransitLineDemo(ctx: ctx)
    }
}

private struct TravelTransitLineDemo: View {
    let ctx: DemoContext
    @State private var current = 0
    @State private var arrivals: [Int] = [0, 0, 0, 0, 0]
    @State private var runID = 0

    private static let rowHeight: CGFloat = 40
    private static let stations: [LocalizedText] = [
        L("Harbour Front", "港湾前"),
        L("Old Market", "老市场"),
        L("Central", "中央站"),
        L("Museum Quarter", "博物馆区"),
        L("North Park", "北公园"),
    ]

    private var zh: Bool { ctx.language == .zh }

    var body: some View {
        SignatureStage {
            VStack(spacing: 0) {
                Spacer(minLength: 0)
                card
                Spacer(minLength: 0)
                DemoHint(text: L("Tap a station to send the train", "点击站点让列车驶去"), ctx: ctx)
                    .padding(.bottom, 14)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .task(id: runID) {
            await loop()
        }
        // Shows the tap interaction too: previews (and the detail intro) send the train two stops ahead.
        .autoplay(ctx.isPreview, every: 3.6, delay: 1.6) {
            send(to: (current + 2) % Self.stations.count)
        }
    }

    private var card: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            ZStack(alignment: .topLeading) {
                track
                VStack(spacing: 0) {
                    ForEach(Self.stations.indices, id: \.self) { index in
                        stationRow(index)
                    }
                }
                train
            }
        }
        .padding(18)
        .frame(width: 290)
        .signatureCard()
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 3) {
                Text(zh ? "2 号线 · 北行" : "Line 2 · Northbound")
                    .signatureEyebrow()
                Text(Self.stations[current], ctx.language)
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.white)
                    .contentTransition(.opacity)
            }
            Spacer(minLength: 0)
            VStack(alignment: .trailing, spacing: 3) {
                Text(zh ? "距终点" : "To terminus")
                    .signatureEyebrow()
                HStack(alignment: .firstTextBaseline, spacing: 3) {
                    Text(terminusMinutes, format: .number)
                        .font(Signature.number(20))
                        .foregroundStyle(Signature.accent)
                        .contentTransition(.numericText(value: Double(terminusMinutes)))
                    Text(zh ? "分" : "min")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(Signature.textSecondary)
                }
            }
        }
    }

    private var terminusMinutes: Int { (Self.stations.count - 1 - current) * 3 }

    /// Graphite rail and the orange progress behind the train.
    private var track: some View {
        let h = Self.rowHeight
        let totalHeight = h * CGFloat(Self.stations.count - 1)
        let travelled = h * CGFloat(current)
        return ZStack(alignment: .top) {
            Capsule()
                .fill(Color.white.opacity(0.1))
                .frame(width: 4, height: totalHeight)
            Capsule()
                .fill(Signature.accentGradient)
                .frame(width: 4, height: max(travelled, 4))
                .shadow(color: Signature.accent.opacity(0.6), radius: 4)
        }
        .frame(width: 22)
        .padding(.top, h / 2)
    }

    /// Drawn above the station rings so the train sits on top of the stop it serves.
    private var train: some View {
        let travelled = Self.rowHeight * CGFloat(current)
        return Circle()
            .fill(Signature.accent)
            .frame(width: 16, height: 16)
            .overlay(Circle().fill(Color.white).frame(width: 6, height: 6))
            .shadow(color: Signature.accent.opacity(0.9), radius: 8)
            .offset(x: 3, y: Self.rowHeight / 2 - 8 + travelled)
            .allowsHitTesting(false)
    }

    private func stationRow(_ index: Int) -> some View {
        let passed = index <= current
        let isNext = index == current + 1
        return HStack(spacing: 14) {
            Circle()
                .strokeBorder(passed ? Signature.accent : Color.white.opacity(0.25), lineWidth: 2)
                .background(Circle().fill(passed ? Signature.accent.opacity(0.35) : Signature.card))
                .frame(width: 14, height: 14)
                .keyframeAnimator(initialValue: CGFloat(1), trigger: arrivals[index]) { content, scale in
                    content.scaleEffect(scale)
                } keyframes: { _ in
                    KeyframeTrack(\.self) {
                        CubicKeyframe(1.4, duration: 0.12)
                        SpringKeyframe(1, duration: 0.45, spring: Spring(response: 0.35, dampingRatio: 0.5))
                    }
                }
                .frame(width: 22)
            Text(Self.stations[index], ctx.language)
                .font(.system(size: 14, weight: index == current ? .bold : .medium, design: .rounded))
                .foregroundStyle(passed ? Color.white : Signature.textSecondary)
            Spacer(minLength: 0)
            if isNext {
                HStack(spacing: 4) {
                    Image(systemName: "tram.fill")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Signature.accent)
                    Text(zh ? "下一站 · 3 分" : "Next · 3 min")
                        .signatureEyebrow()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .frame(height: Self.rowHeight)
        .contentShape(Rectangle())
        .onTapGesture { send(to: index) }
    }

    private func arrive(at index: Int) {
        withAnimation(.easeInOut(duration: ctx["travel"])) { current = index }
        let muted = Haptics.isMuted
        let travel = ctx["travel"]
        let pulse = ctx.bool("pulse")
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(travel * 0.9))
            if pulse { arrivals[index] += 1 }
            if !muted { Haptics.tap() }
        }
    }

    private func send(to index: Int) {
        guard index != current else { return }
        arrive(at: index)
        // Restart the loop so the train dwells at the chosen station before moving on.
        runID += 1
    }

    private func loop() async {
        while !Task.isCancelled {
            try? await Task.sleep(for: .seconds(ctx["travel"] + ctx["dwell"]))
            guard !Task.isCancelled else { return }
            let next = (current + 1) % Self.stations.count
            // Automatic arrivals stay silent; only a station you tap ticks.
            Haptics.isMuted = true
            arrive(at: next)
            Haptics.isMuted = false
        }
    }
}
