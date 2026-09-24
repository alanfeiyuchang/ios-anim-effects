import SwiftUI

extension Effect {
    static let iconsRadarPing = Effect(
        id: "icons.radar-ping",
        category: .icons,
        interaction: .loop,
        name: L("Radar Ping", "雷达搜寻"),
        summary: L("A sweeping beam and sonar rings; nearby dots flare as the beam passes.", "扫描光束配合声呐波纹，光束掠过时附近的点亮起。"),
        prompt: L(
            "A location glyph sits in a glossy blue disc at the centre of a faint circular grid. Three sonar rings leave the disc one after another, each expanding from 36 pt to the full 250 pt radar over 2.4 s on an ease-out while fading from 45% to 0, so a new ring is always on its way, and the disc breathes ±4% in sync. A conic beam with a bright leading edge and a 70° fading tail rotates once every 3 s. Five nearby-device dots sit at fixed bearings; as the beam passes, each flares to 150% with a glow and decays over about 0.8 s. A tap fires a bright mint ping ring and one forced 0.8 s beam sweep that lights every dot in turn. Calm, continuous and alive, like a device quietly searching.",
            "定位图标放在一枚带光泽的蓝色圆盘里，位于淡淡的圆形网格中央。三道声呐波纹依次离开圆盘，每道在2.4秒内以缓出曲线从36 pt扩散到250 pt的整个雷达范围，透明度从45%降到0，于是总有新的波纹在路上，圆盘也随之做±4%的呼吸。一道锥形扫描光束带着明亮前缘和70°渐隐尾迹，每3秒转一圈。五个“附近设备”小点固定在不同方位，光束扫过时放大到150%并发光，再在约0.8秒内衰减。轻点发出一道明亮的薄荷色探测波，光束0.8秒强扫一圈，依次点亮光点。平静、持续，像设备在安静地搜寻。"
        ),
        implementation: L(
            "A TimelineView(.animation) derives ring radii from phase-shifted time, rotates an AngularGradient beam, and computes each dot's flare from the angular distance behind the beam; the layers are flattened with drawingGroup().",
            "TimelineView(.animation) 用错开相位的时间计算波纹半径，旋转 AngularGradient 光束，并根据每个点落后于光束的角距离计算它的亮起程度；各图层用 drawingGroup() 合成。"
        ),
        apis: ["TimelineView(.animation)", "AngularGradient", "Circle", "drawingGroup()", "rotationEffect"],
        tags: ["radar", "ping", "sonar", "searching", "雷达", "搜寻", "声呐", "定位"],
        params: [
            .slider("sweep", L("Beam period", "扫描周期"), 1.0...6.0, default: 3.0, unit: "s"),
            .slider("rings", L("Ring period", "波纹周期"), 1.0...5.0, default: 2.4, unit: "s"),
            .slider("decay", L("Dot afterglow", "光点余辉"), 0.2...2.0, default: 0.8, unit: "s"),
        ]
    ) { ctx in
        RadarPingDemo(ctx: ctx)
    }
}

private struct RadarBlip {
    let bearing: Double   // degrees, 0 = right, clockwise
    let distance: CGFloat // 0…1 of the radius
}

private let radarBlips: [RadarBlip] = [
    RadarBlip(bearing: 28, distance: 0.62),
    RadarBlip(bearing: 102, distance: 0.84),
    RadarBlip(bearing: 168, distance: 0.48),
    RadarBlip(bearing: 236, distance: 0.76),
    RadarBlip(bearing: 312, distance: 0.55),
]

/// A tap-fired ping: an extra bright ring plus one fast forced sweep of the beam.
private struct RadarPulse {
    /// Seconds since the tap.
    let elapsed: Double
    /// Beam angle when the tap landed; the forced sweep starts there.
    let fromAngle: Double

    static let sweepDuration: Double = 0.8
    static let ringDuration: Double = 1.2

    var isActive: Bool { elapsed >= 0 && elapsed < max(Self.sweepDuration, Self.ringDuration) + 2 }
    /// Forced-sweep progress 0…1, or nil once it has finished.
    var sweep: Double? { elapsed >= 0 && elapsed < Self.sweepDuration ? elapsed / Self.sweepDuration : nil }
    var angle: Double { fromAngle + 360 * min(max(elapsed / Self.sweepDuration, 0), 1) }
}

private struct RadarPingDemo: View {
    let ctx: DemoContext
    private let size: CGFloat = 250
    /// Reference-date seconds of the last tap-fired ping.
    @State private var pingTime: Double = -.infinity

    var body: some View {
        VStack(spacing: 18) {
            TimelineView(.animation(minimumInterval: MotionFrameRate.interval(preview: ctx.isPreview))) { timeline in
                let now: Double = timeline.date.timeIntervalSinceReferenceDate
                radar(time: now.truncatingRemainder(dividingBy: 3_600), pulse: pulse(at: now))
            }
            DemoHint(text: L("Tap to send a ping", "点击发出一次探测"), ctx: ctx)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .onTapGesture { ping() }
    }

    private func ping() {
        guard !ctx.isPreview, !ctx.isStill else { return }
        Haptics.tap(.medium)
        pingTime = Date().timeIntervalSinceReferenceDate
    }

    private func pulse(at now: Double) -> RadarPulse? {
        guard pingTime.isFinite else { return nil }
        let start = pingTime.truncatingRemainder(dividingBy: 3_600)
        let pulse = RadarPulse(elapsed: now - pingTime, fromAngle: beamAngle(time: start))
        return pulse.isActive ? pulse : nil
    }

    private func beamAngle(time: Double) -> Double {
        (time / max(ctx["sweep"], 0.2)).truncatingRemainder(dividingBy: 1) * 360
    }

    private func radar(time: Double, pulse: RadarPulse?) -> some View {
        let sweepPeriod: Double = max(ctx["sweep"], 0.2)
        let beam: Double = beamAngle(time: time)
        let ringPeriod: Double = max(ctx["rings"], 0.2)
        let breath: Double = sin((time / ringPeriod) * 2 * Double.pi * 3)
        let kick: Double = pulse.map { $0.elapsed < 0.4 ? sin(Double.pi * $0.elapsed / 0.4) : 0 } ?? 0
        let pingPhase: Double = pulse.map { $0.elapsed / RadarPulse.ringDuration } ?? 1
        let sweepOpacity: Double = pulse?.sweep.map { 1 - $0 * $0 } ?? 0
        return ZStack {
            grid
            ForEach(0..<3, id: \.self) { index in
                ring(phase: ringPhase(time: time, index: index, period: ringPeriod))
            }
            pingRing(phase: pingPhase)
            beamView(angle: beam)
            beamView(angle: pulse?.angle ?? beam)
                .opacity(sweepOpacity)
            ForEach(radarBlips.indices, id: \.self) { index in
                blip(radarBlips[index], beam: beam, period: sweepPeriod, pulse: pulse)
            }
            core(scale: 1 + 0.04 * CGFloat(breath) + 0.1 * CGFloat(kick))
        }
        .frame(width: size, height: size)
        .drawingGroup()
    }

    /// The tap-fired ring: brighter and thicker than the idle ones, out to the rim in 1.2 s.
    private func pingRing(phase: Double) -> some View {
        let p: Double = min(max(phase, 0), 1)
        let eased: Double = 1 - pow(1 - p, 3)
        let diameter: CGFloat = 58 + (size - 58) * CGFloat(eased)
        return Circle()
            .stroke(Palette.mint.opacity(0.85 * (1 - p)), lineWidth: 3 + 3 * CGFloat(1 - p))
            .frame(width: diameter, height: diameter)
    }

    private func ringPhase(time: Double, index: Int, period: Double) -> Double {
        let shifted: Double = time / period + Double(index) / 3
        return shifted - shifted.rounded(.down)
    }

    private var grid: some View {
        ZStack {
            Circle().stroke(Palette.sky.opacity(0.18), lineWidth: 1)
            Circle().stroke(Palette.sky.opacity(0.14), lineWidth: 1).padding(size * 0.17)
            Circle().stroke(Palette.sky.opacity(0.1), lineWidth: 1).padding(size * 0.34)
            Rectangle().fill(Palette.sky.opacity(0.1)).frame(width: 1)
            Rectangle().fill(Palette.sky.opacity(0.1)).frame(height: 1)
        }
    }

    private func ring(phase: Double) -> some View {
        let eased: Double = 1 - pow(1 - phase, 3)
        let diameter: CGFloat = 36 + (size - 36) * CGFloat(eased)
        return Circle()
            .stroke(Palette.sky.opacity(0.45 * (1 - phase)), lineWidth: 2)
            .frame(width: diameter, height: diameter)
    }

    private func beamView(angle: Double) -> some View {
        let gradient = AngularGradient(
            stops: [
                .init(color: Palette.sky.opacity(0), location: 0),
                .init(color: Palette.sky.opacity(0), location: 1 - 70.0 / 360),
                .init(color: Palette.sky.opacity(0.45), location: 0.995),
                .init(color: Palette.sky.opacity(0), location: 1),
            ],
            center: .center,
            angle: .zero
        )
        return Circle()
            .fill(gradient)
            .rotationEffect(.degrees(angle))
    }

    /// Flare left by the forced sweep: it passes `bearing` at a known moment, then decays like the idle beam.
    private func pulseFlare(bearing: Double, pulse: RadarPulse?) -> Double {
        guard let pulse else { return 0 }
        var ahead: Double = (bearing - pulse.fromAngle).truncatingRemainder(dividingBy: 360)
        if ahead < 0 { ahead += 360 }
        let secondsSince: Double = pulse.elapsed - ahead / 360 * RadarPulse.sweepDuration
        guard secondsSince >= 0 else { return 0 }
        return max(0, 1 - secondsSince / max(ctx["decay"], 0.05))
    }

    private func blip(_ item: RadarBlip, beam: Double, period: Double, pulse: RadarPulse?) -> some View {
        var behind: Double = beam - item.bearing
        if behind < 0 { behind += 360 }
        let secondsSince: Double = behind / 360 * period
        let idle: Double = max(0, 1 - secondsSince / max(ctx["decay"], 0.05))
        let flare: Double = max(idle, pulseFlare(bearing: item.bearing, pulse: pulse))
        let radians: Double = item.bearing * Double.pi / 180
        let radius: CGFloat = size / 2 * item.distance
        let x: CGFloat = radius * CGFloat(cos(radians))
        let y: CGFloat = radius * CGFloat(sin(radians))
        return Circle()
            .fill(Palette.mint)
            .frame(width: 8, height: 8)
            .scaleEffect(1 + 0.5 * CGFloat(flare))
            .shadow(color: Palette.mint.opacity(flare), radius: 6)
            .opacity(0.35 + 0.65 * flare)
            .offset(x: x, y: y)
    }

    private func core(scale: CGFloat) -> some View {
        Image(systemName: "location.fill")
            .font(.system(size: 24, weight: .bold))
            .foregroundStyle(.white)
            .frame(width: 58, height: 58)
            .background(Palette.ocean, in: Circle())
            .overlay(Circle().strokeBorder(.white.opacity(0.35), lineWidth: 1))
            .shadow(color: Palette.blue.opacity(0.45), radius: 12, y: 4)
            .scaleEffect(scale)
    }
}
