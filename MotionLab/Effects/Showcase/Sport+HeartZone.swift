import SwiftUI

extension Effect {
    static let showcaseHeartZone = Effect(
        id: "showcase.heart-zone",
        category: .showcase,
        interaction: .tap,
        name: L("Heart-Rate Zone Ring", "心率区间环"),
        summary: L("A five-zone gauge with a beating heart; tap to sprint and watch the needle climb into the red.", "五段心率仪表配合跳动的心形；点击冲刺，指针一路攀升进入红区。"),
        prompt: L(
            "A dark HEART RATE widget with a 270° gauge split into five rounded zone arcs (white, ice blue, lime, orange, hot red) separated by small gaps; the active zone is fully opaque and 2 pt thicker, the others dim to 30%. A white indicator dot travels along the arc on a spring as the BPM drifts, the rounded BPM numeral rolls digit by digit, and a zone label (\"Zone 3 · Aerobic\") cross-fades when the zone changes. The heart glyph bounces on every beat at the real tempo while a soft halo swells 40% and fades in 0.45 s. Tap to sprint: the BPM climbs toward 93% of max, dragging the dot into the red zone; tap again to recover. Alive, rhythmic and physiological.",
            "深色“心率”小组件：270° 仪表被分为五段圆头区间弧（白、冰蓝、青柠、橙、火红），段间留有小缝；当前区间完全不透明并加粗 2pt，其余降到 30%。心率漂移时，一颗白色指示点以弹簧沿弧线移动，圆体心率数字逐位滚动，区间标签（“3 区 · 有氧”）在切换时交叉淡入。心形图标按真实节拍逐拍弹跳，同时一圈柔光放大 40% 并在 0.45 秒内消散。点击进入冲刺：心率向最大值的 93% 攀升，指示点被一路拖入红区；再点一次开始恢复。鲜活、有节奏、充满生理感。"
        ),
        implementation: L(
            "One task loop drifts the BPM toward a target inside withAnimation; a second loop sleeps 60/BPM seconds per beat and bumps a counter that drives .symbolEffect(.bounce) and a halo. The dot is an offset circle rotated by rotationEffect so it follows the arc.",
            "一个 task 循环在 withAnimation 中让心率向目标值漂移；另一个循环每拍休眠 60/BPM 秒并递增计数，驱动 .symbolEffect(.bounce) 与光晕。指示点是偏移后再用 rotationEffect 旋转的圆点，因此沿弧线移动。"
        ),
        apis: ["symbolEffect(.bounce, value:)", "Circle().trim", "rotationEffect", "contentTransition(.numericText(value:))", "task(id:)"],
        tags: ["heart rate", "gauge", "zones", "fitness", "心率", "仪表盘", "区间", "运动"],
        params: [
            .slider("maxHR", L("Max heart rate", "最大心率"), 170...210, default: 190, step: 1, decimals: 0, unit: " bpm"),
            .slider("response", L("Needle spring", "指针弹簧响应"), 0.2...1.0, default: 0.5, unit: "s"),
            .toggle("halo", L("Beat halo", "心跳光晕"), default: true),
        ]
    ) { ctx in
        SportHeartDemo(ctx: ctx)
    }
}

private enum HeartZones {
    static let colors: [Color] = [Color.white.opacity(0.75), Color(hex: 0x8FD3FF), Signature.lime, Signature.accent, Signature.accentHot]
    static let names: [LocalizedText] = [
        L("Warm-up", "热身"), L("Easy", "轻松"), L("Aerobic", "有氧"), L("Threshold", "乳酸阈"), L("Max", "极限"),
    ]
    /// The gauge covers 50%…100% of max HR, one zone per 10%.
    static func fraction(bpm: Int, maxHR: Double) -> Double {
        ((Double(bpm) / maxHR - 0.5) / 0.5).clamped(to: 0...1)
    }

    static func zone(bpm: Int, maxHR: Double) -> Int {
        min(4, Int(fraction(bpm: bpm, maxHR: maxHR) * 5))
    }
}

private struct SportHeartDemo: View {
    let ctx: DemoContext
    @State private var bpm = 128
    @State private var sprinting = false
    @State private var beats = 0
    @State private var halo: Double = 0
    /// Detail intro: sprints, then recovers on its own so the stage doesn't stay pinned in the red zone.
    @State private var recoverTask: Task<Void, Never>?

    private var maxHR: Double { max(ctx["maxHR"], 120) }

    var body: some View {
        SignatureStage {
            VStack(spacing: 0) {
                Spacer()
                card
                Spacer()
                DemoHint(text: L("Tap to sprint / recover", "点击冲刺或恢复"), ctx: ctx)
                    .padding(.bottom, 14)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        // Keyed on max HR too: the loop captures `ctx`, so the drift target follows the slider.
        .task(id: "\(sprinting)-\(maxHR)") { await drift() }
        .task { await beat() }
        .autoplay(ctx.isPreview, every: 4.5, delay: 1.5) {
            if ctx.isPreview { toggleSprint() } else { introSprint() }
        }
        .onDisappear { recoverTask?.cancel() }
    }

    private var card: some View {
        let zone = HeartZones.zone(bpm: bpm, maxHR: maxHR)
        return VStack(spacing: 6) {
            SportEyebrowRow(title: L("Heart rate", "心率")(ctx.language), symbol: "waveform.path.ecg", trailing: sprinting ? L("Sprint", "冲刺")(ctx.language) : L("Cruise", "巡航")(ctx.language))
            ZStack {
                HeartGauge(activeZone: zone)
                HeartIndicator(fraction: HeartZones.fraction(bpm: bpm, maxHR: maxHR))
                    .animation(.spring(response: ctx["response"], dampingFraction: 0.7), value: bpm)
                HeartCenter(bpm: bpm, zone: zone, beats: beats, halo: ctx.bool("halo") ? halo : 0, language: ctx.language)
            }
            .frame(width: 200, height: 200)
        }
        .padding(20)
        .frame(width: 280)
        .signatureCard()
        .sportCardTap {
            recoverTask?.cancel()
            recoverTask = nil
            toggleSprint()
        }
    }

    private func toggleSprint() {
        sprinting.toggle()
        if !ctx.isPreview { Haptics.tap(.medium) }
    }

    private func introSprint() {
        recoverTask?.cancel()
        sprinting = true
        recoverTask = Task {
            try? await Task.sleep(for: .seconds(3.2))
            guard !Task.isCancelled else { return }
            sprinting = false
            recoverTask = nil
        }
    }

    private func drift() async {
        while !Task.isCancelled {
            let target = Int(maxHR * (sprinting ? 0.93 : 0.66))
            let gap = target - bpm
            let stepSize = max(1, min(abs(gap) / 3, 9))
            let move = gap == 0 ? 0 : (gap > 0 ? stepSize : -stepSize)
            let next = bpm + move + Int.random(in: -1...1)
            withAnimation(.snappy(duration: 0.35)) { bpm = next }
            try? await Task.sleep(for: .milliseconds(650))
        }
    }

    private func beat() async {
        while !Task.isCancelled {
            beats += 1
            halo = 1
            try? await Task.sleep(for: .milliseconds(20))
            withAnimation(.easeOut(duration: 0.45)) { halo = 0 }
            let interval = 60.0 / Double(max(bpm, 40))
            try? await Task.sleep(for: .seconds(max(0.25, interval - 0.02)))
        }
    }
}

private struct HeartGauge: View {
    let activeZone: Int

    var body: some View {
        ZStack {
            ForEach(0..<5, id: \.self) { index in
                let start = CGFloat(0.75 * Double(index) / 5 + 0.006)
                let end = CGFloat(0.75 * Double(index + 1) / 5 - 0.006)
                let active = index == activeZone
                Circle()
                    .trim(from: start, to: end)
                    .stroke(HeartZones.colors[index], style: StrokeStyle(lineWidth: active ? 12 : 10, lineCap: .round))
                    .opacity(active ? 1 : 0.3)
                    .shadow(color: active ? HeartZones.colors[index].opacity(0.6) : .clear, radius: 8)
                    .animation(.easeInOut(duration: 0.3), value: active)
            }
        }
        .rotationEffect(.degrees(135))
        .padding(8)
    }
}

private struct HeartIndicator: View {
    let fraction: Double

    var body: some View {
        Circle()
            .fill(Color.white)
            .frame(width: 14, height: 14)
            .overlay(Circle().strokeBorder(Signature.ink, lineWidth: 3))
            .shadow(color: .black.opacity(0.5), radius: 4)
            .offset(x: 92)
            .rotationEffect(.degrees(135 + 270 * fraction))
    }
}

private struct HeartCenter: View {
    let bpm: Int
    let zone: Int
    let beats: Int
    let halo: Double
    let language: AppLanguage

    private var zoneLabel: String {
        let name = HeartZones.names[zone](language)
        return language == .zh ? "\(zone + 1) 区 · \(name)" : "Zone \(zone + 1) · \(name)"
    }

    var body: some View {
        VStack(spacing: 2) {
            ZStack {
                Circle()
                    .fill(HeartZones.colors[zone].opacity(0.35))
                    .frame(width: 26, height: 26)
                    .scaleEffect(CGFloat(1 + 0.4 * (1 - halo)))
                    .opacity(halo * 0.8)
                    .blur(radius: 4)
                Image(systemName: "heart.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(HeartZones.colors[zone])
                    .symbolEffect(.bounce, value: beats)
            }
            Text("\(bpm)")
                .font(Signature.number(46))
                .foregroundStyle(Color.white)
                .contentTransition(.numericText(value: Double(bpm)))
            Text(zoneLabel)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(HeartZones.colors[zone])
                .contentTransition(.interpolate)
                .animation(.easeInOut(duration: 0.3), value: zone)
        }
    }
}
