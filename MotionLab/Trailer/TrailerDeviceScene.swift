import SwiftUI

private typealias M = TrailerMath

// MARK: - 21–44 s · Feel it on the phone, then tune it

/// A phone-like detail stage. The opened search result (`TrailerHeroLayer`) lands on its stage card
/// and plays first; then real demos take turns (each swap zooms through depth), a scripted finger
/// taps them on the beats their own `.autoplay` loops are phase-locked to, and finally a parameter
/// sheet slides up over a spring lab whose sliders the finger scrubs.
struct TrailerPhoneScene: View {
    let t: Double
    let origin: Date

    /// Outgoing demo: sinks back, blurs and fades.
    static func swapOut(_ t: Double, at start: Double) -> Double {
        M.easeIn(M.progress(t, start, 0.45))
    }

    /// Incoming demo: rises out of depth on a spring.
    static func swapIn(_ t: Double, at start: Double) -> Double {
        M.spring(t, at: start, response: 0.55, damping: 0.8)
    }

    /// Demos after the hero, with the times their taps land (see `TrailerScript.taps`).
    /// `epochOffset` = first tap − the demo's autoplay delay, so `demoSyncEpoch` fires it on the tap.
    private struct Slot {
        let id: String
        let mount: ClosedRange<Double>
        let enter: Double
        let leave: Double
        let epochOffset: Double
    }

    private static let slots: [Slot] = [
        // showcase.board-card: delay 0.8, every 2.4 → flips at 26.3 and 28.7.
        Slot(id: "showcase.board-card", mount: 24.9...29.8, enter: 25.45, leave: 29.1, epochOffset: 25.5),
        // buttons.depth-press: delay 0.6, toggles every 0.8 → presses at 30.0 and 31.6.
        Slot(id: "buttons.depth-press", mount: 28.6...33.4, enter: 29.3, leave: 32.75, epochOffset: 29.4),
        // inputs.squash-toggle: delay 0.4, every 1.3 → taps at 33.5 and 34.8.
        Slot(id: "inputs.squash-toggle", mount: 32.2...36.4, enter: 32.9, leave: 35.55, epochOffset: 33.1),
    ]

    var body: some View {
        let appear = M.spring(t, at: 20.85, response: 0.7, damping: 0.85)
        let exit = M.easeInOut(M.progress(t, 43.85, 0.6))
        let buzz = CGFloat(TrailerScript.buzz(t) * 2.4)
        ZStack {
            TrailerHeadline(
                title: "在手机上直接玩",
                subtitle: "每一下都有触感",
                reveal: M.progress(t, 21.3, 0.9),
                exit: M.easeIn(M.progress(t, 35.45, 0.5))
            )
            .position(x: 195, y: 58)
            if t > 35.8 {
                TrailerHeadline(
                    title: "参数实时可调",
                    subtitle: "弹簧 · 阻尼 · 响应，随手试",
                    reveal: M.progress(t, 36.0, 0.9),
                    exit: M.easeIn(M.progress(t, 43.7, 0.5))
                )
                .position(x: 195, y: 58)
            }
            ZStack {
                PhoneBody(t: t, appear: appear)
                ForEach(Self.slots.indices, id: \.self) { index in
                    let slot = Self.slots[index]
                    if slot.mount.contains(t) {
                        demo(slot)
                    }
                }
                if t > 35.2 {
                    TrailerSpringLab(t: t)
                        .scaleEffect(CGFloat(0.9 + 0.1 * Self.swapIn(t, at: 35.75)))
                        .blur(radius: CGFloat(1 - M.clamp(Self.swapIn(t, at: 35.75))) * 10)
                        .opacity(M.clamp(Self.swapIn(t, at: 35.75) * 1.6))
                        .position(TrailerLayout.demoCenter)
                }
            }
            .frame(width: TrailerCanvas.width, height: TrailerCanvas.height)
            .offset(x: buzz)
            .scaleEffect(CGFloat(1 - 0.1 * exit))
            .blur(radius: CGFloat(exit) * 12)
            .opacity(1 - exit)
        }
        .frame(width: TrailerCanvas.width, height: TrailerCanvas.height)
    }

    private func demo(_ slot: Slot) -> some View {
        let enter = Self.swapIn(t, at: slot.enter)
        let leave = Self.swapOut(t, at: slot.leave)
        return TrailerStageTile(
            effectID: slot.id,
            epoch: origin.addingTimeInterval(slot.epochOffset),
            side: TrailerLayout.demoSide,
            cornerRadius: 24
        )
        .scaleEffect(CGFloat((0.9 + 0.1 * enter) * (1 - 0.12 * leave)))
        .blur(radius: CGFloat((1 - M.clamp(enter)) * 10 + leave * 10))
        .opacity(M.clamp(enter * 1.6) * (1 - leave))
        .position(TrailerLayout.demoCenter)
    }
}

/// The phone: glossy bezel, screen, and a header naming the demo on stage.
private struct PhoneBody: View {
    let t: Double
    let appear: Double

    /// Real names and categories from the catalog (the lab is the trailer's own demo).
    private static let titles: [(start: Double, name: String, tag: String)] = [
        label(0, TrailerData.heroID),
        label(25.45, "showcase.board-card"),
        label(29.3, "buttons.depth-press"),
        label(32.9, "inputs.squash-toggle"),
        (35.75, "弹簧参数", "实时预览"),
    ]

    private static func label(_ start: Double, _ id: String) -> (start: Double, name: String, tag: String) {
        guard let effect = EffectLibrary.effect(id: id) else { return (start, id, "") }
        return (start, effect.name.zh, effect.category.title.zh)
    }

    var body: some View {
        let size = TrailerLayout.phoneSize
        let outer = RoundedRectangle(cornerRadius: 46, style: .continuous)
        let screen = RoundedRectangle(cornerRadius: 39, style: .continuous)
        ZStack {
            outer.fill(LinearGradient(colors: [Color(hex: 0x2C2C33), Color(hex: 0x121215)], startPoint: .top, endPoint: .bottom))
            outer.strokeBorder(TrailerStyle.rim, lineWidth: 1.2)
            screen
                .fill(Color(hex: 0x0D0D10))
                .padding(7)
            screen
                .strokeBorder(Color.white.opacity(0.06), lineWidth: 0.75)
                .padding(7)
            header
                .frame(maxHeight: .infinity, alignment: .top)
                .padding(.top, 13)
        }
        .frame(width: size.width, height: size.height)
        .shadow(color: Color.black.opacity(0.6), radius: 30, x: 0, y: 20)
        .shadow(color: Palette.ember.opacity(0.12), radius: 40, x: 0, y: 0)
        .scaleEffect(CGFloat(0.9 + 0.1 * appear))
        .opacity(M.clamp(appear * 1.5))
        .position(TrailerLayout.phoneCenter)
    }

    private var header: some View {
        ZStack {
            ForEach(Self.titles.indices, id: \.self) { index in
                titleRow(index)
            }
        }
        .frame(width: 230, height: 22)
    }

    private func titleRow(_ index: Int) -> some View {
        let entry = Self.titles[index]
        let next: Double = index + 1 < Self.titles.count ? Self.titles[index + 1].start : 999
        let enter = index == 0 ? 1 : M.easeOut(M.progress(t, entry.start, 0.35))
        let leave = M.easeIn(M.progress(t, next - 0.2, 0.3))
        let pulse = min(1, abs(TrailerScript.buzz(t)) * 3)
        return HStack(spacing: 6) {
            Text(verbatim: entry.name)
                .font(.system(size: 13, weight: .heavy))
                .foregroundStyle(Color.white)
            Text(verbatim: entry.tag)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(Palette.accent)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Palette.ember.opacity(0.16), in: Capsule())
            Spacer(minLength: 0)
            Image(systemName: "waveform")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(Palette.accentFill)
                .scaleEffect(CGFloat(1 + 0.35 * pulse))
                .opacity(0.45 + 0.55 * pulse)
        }
        .offset(y: CGFloat((1 - enter) * 10 - leave * 10))
        .opacity(enter * (1 - leave))
    }
}

// MARK: - Tune: spring lab + parameter sheet

/// The scripted slider values and the finger that scrubs them.
enum TrailerTune {
    struct Press {
        let row: Int
        let start: Double
        let end: Double
    }

    struct Tick {
        let time: Double
        let point: CGPoint
    }

    static let presses: [Press] = [
        Press(row: 0, start: 36.9, end: 38.3),
        Press(row: 0, start: 38.9, end: 40.35),
        Press(row: 0, start: 40.85, end: 42.0),
        Press(row: 1, start: 42.3, end: 43.25),
    ]

    static let dampingRange: ClosedRange<Double> = 0.1...1.0
    static let responseRange: ClosedRange<Double> = 0.2...1.0
    /// Slider track in canvas space (see `TrailerSpringLab`: sheet at demo origin + (8, 160)).
    static let trackMinX: CGFloat = 148
    static let trackWidth: CGFloat = 120
    static let rowY: [CGFloat] = [332, 366]

    static func damping(_ t: Double) -> Double {
        var value = 0.7
        value = M.mix(value, 0.2, M.easeInOut(M.progress(t, 37.05, 1.1)))
        value = M.mix(value, 1.0, M.easeInOut(M.progress(t, 39.05, 1.15)))
        value = M.mix(value, 0.5, M.easeInOut(M.progress(t, 41.0, 0.85)))
        return value
    }

    static func response(_ t: Double) -> Double {
        M.mix(0.55, 0.3, M.easeInOut(M.progress(t, 42.4, 0.75)))
    }

    static func normalized(row: Int, t: Double) -> Double {
        let range = row == 0 ? dampingRange : responseRange
        let value = row == 0 ? damping(t) : response(t)
        return M.clamp((value - range.lowerBound) / (range.upperBound - range.lowerBound))
    }

    static func knobPoint(row: Int, t: Double) -> CGPoint {
        CGPoint(x: trackMinX + trackWidth * CGFloat(normalized(row: row, t: t)), y: rowY[min(max(row, 0), 1)])
    }

    static func pressed(_ t: Double) -> Double {
        for press in presses where t >= press.start - 0.06 && t <= press.end + 0.08 {
            let down = M.progress(t, press.start - 0.06, 0.06)
            let up = 1 - M.progress(t, press.end, 0.08)
            return min(down, up)
        }
        return 0
    }

    static func fingerPoint(_ t: Double) -> CGPoint {
        let first = knobPoint(row: 0, t: 36.9)
        if t < 36.85 {
            let p = M.easeInOut(M.progress(t, 36.4, 0.45))
            return M.mix(CGPoint(x: first.x + 70, y: first.y + 50), first, p)
        }
        let hover = CGFloat(1 - pressed(t)) * 6
        if t < 42.05 {
            let knob = knobPoint(row: 0, t: t)
            return CGPoint(x: knob.x, y: knob.y + hover)
        }
        if t < 42.3 {
            let p = M.easeInOut(M.progress(t, 42.05, 0.22))
            return M.mix(knobPoint(row: 0, t: t), knobPoint(row: 1, t: t), p)
        }
        let knob = knobPoint(row: 1, t: t)
        if t < 43.3 { return CGPoint(x: knob.x, y: knob.y + hover) }
        let p = M.easeIn(M.progress(t, 43.3, 0.3))
        return M.mix(knob, CGPoint(x: knob.x + 60, y: knob.y + 40), p)
    }

    /// Detent ticks: every 10 % of travel while a knob is dragged gets a tiny ring (selection haptic).
    static let ticks: [Tick] = {
        var list: [Tick] = []
        for press in TrailerTune.presses {
            var step = Int((TrailerTune.normalized(row: press.row, t: press.start) * 10).rounded(.down))
            var time = press.start
            while time <= press.end {
                let current = Int((TrailerTune.normalized(row: press.row, t: time) * 10).rounded(.down))
                if current != step {
                    step = current
                    list.append(Tick(time: time, point: TrailerTune.knobPoint(row: press.row, t: time)))
                }
                time += 1.0 / 60.0
            }
        }
        return list
    }()
}

/// Self-contained demo for the tune beat: an ember block ping-pongs on a spring driven by the live
/// damping/response values, with its step-response curve drawn underneath and a parameter sheet.
private struct TrailerSpringLab: View {
    let t: Double

    private let side = TrailerLayout.demoSide
    private static let cycle: Double = 1.3
    private static let start: Double = 35.8

    var body: some View {
        let damping = TrailerTune.damping(t)
        let response = TrailerTune.response(t)
        let sheet = M.spring(t, at: 36.15, response: 0.55, damping: 0.8)
        let shape = RoundedRectangle(cornerRadius: 24, style: .continuous)
        ZStack(alignment: .topLeading) {
            StageBackground()
            curve(damping: damping, response: response)
            lane(damping: damping, response: response)
            sheetView(damping: damping, response: response)
                .offset(x: 8, y: 160 + CGFloat(1 - sheet) * 100)
                .opacity(M.clamp(sheet * 2))
        }
        .frame(width: side, height: side)
        .clipShape(shape)
        .overlay(StageRim(cornerRadius: 24))
    }

    private func phase(_ time: Double) -> (elapsed: Double, forward: Bool) {
        let local = max(time - Self.start, 0)
        let index = (local / Self.cycle).rounded(.down)
        return (local - index * Self.cycle, Int(index) % 2 == 0)
    }

    private func blockX(at time: Double, damping: Double, response: Double) -> CGFloat {
        let (elapsed, forward) = phase(time)
        let value = M.spring(elapsed, response: response, damping: damping)
        let left: CGFloat = 36
        let right: CGFloat = side - 36
        return forward ? M.mix(left, right, value) : M.mix(right, left, value)
    }

    private func lane(damping: Double, response: Double) -> some View {
        ZStack(alignment: .topLeading) {
            Capsule()
                .fill(Color.white.opacity(0.06))
                .frame(width: side - 40, height: 4)
                .offset(x: 20, y: 36)
            ForEach(0..<4, id: \.self) { ghost in
                let x = blockX(at: t - Double(ghost) * 0.035, damping: damping, response: response)
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(Palette.accentFill)
                    .frame(width: 30, height: 30)
                    .shadow(color: ghost == 0 ? Palette.accentGlow : Color.clear, radius: 12, x: 0, y: 4)
                    .opacity(ghost == 0 ? 1 : 0.22 / Double(ghost))
                    .offset(x: x - 15, y: 23)
            }
        }
    }

    private func curve(damping: Double, response: Double) -> some View {
        let left: CGFloat = 18
        let width: CGFloat = side - 36
        let base: CGFloat = 144
        let amplitude: CGFloat = 60
        let elapsed = phase(t).elapsed
        let headX = left + width * CGFloat(min(elapsed / Self.cycle, 1))
        let headY = base - amplitude * CGFloat(M.spring(elapsed, response: response, damping: damping))
        return ZStack(alignment: .topLeading) {
            Path { path in
                path.move(to: CGPoint(x: left, y: base - amplitude))
                path.addLine(to: CGPoint(x: left + width, y: base - amplitude))
            }
            .stroke(Color.white.opacity(0.22), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
            Path { path in
                path.move(to: CGPoint(x: left, y: base))
                path.addLine(to: CGPoint(x: left + width, y: base))
            }
            .stroke(Color.white.opacity(0.1), lineWidth: 1)
            Path { path in
                let samples = 90
                for sample in 0...samples {
                    let tau = Self.cycle * Double(sample) / Double(samples)
                    let point = CGPoint(
                        x: left + width * CGFloat(Double(sample) / Double(samples)),
                        y: base - amplitude * CGFloat(M.spring(tau, response: response, damping: damping))
                    )
                    if sample == 0 { path.move(to: point) } else { path.addLine(to: point) }
                }
            }
            .stroke(Palette.accentFill, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
            .shadow(color: Palette.accentGlow, radius: 6, x: 0, y: 0)
            Circle()
                .fill(Color.white)
                .frame(width: 8, height: 8)
                .shadow(color: Palette.ember, radius: 6, x: 0, y: 0)
                .offset(x: headX - 4, y: headY - 4)
            Text(verbatim: "目标")
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(Color.white.opacity(0.45))
                .offset(x: left + width - 22, y: base - amplitude - 14)
        }
    }

    private func sheetView(damping: Double, response: Double) -> some View {
        let sheetShape = RoundedRectangle(cornerRadius: 18, style: .continuous)
        return ZStack(alignment: .topLeading) {
            TrailerGlass(shape: sheetShape, frosted: true, shadowOpacity: 0.35)
            sliderRow(title: "阻尼", value: damping, row: 0, y: 22)
            sliderRow(title: "响应", value: response, row: 1, y: 56)
        }
        .frame(width: side - 16, height: 78)
    }

    private func sliderRow(title: String, value: Double, row: Int, y: CGFloat) -> some View {
        let fraction = CGFloat(TrailerTune.normalized(row: row, t: t))
        let track: CGFloat = TrailerTune.trackWidth
        let trackX: CGFloat = 68
        let active = TrailerTune.presses.contains { $0.row == row && t >= $0.start && t <= $0.end }
        return ZStack(alignment: .topLeading) {
            Text(verbatim: title)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(Color.white.opacity(0.85))
                .offset(x: 14, y: y - 8)
            Capsule()
                .fill(Color.white.opacity(0.12))
                .frame(width: track, height: 4)
                .offset(x: trackX, y: y - 2)
            Capsule()
                .fill(Palette.accentFill)
                .frame(width: max(track * fraction, 4), height: 4)
                .offset(x: trackX, y: y - 2)
            Circle()
                .fill(Color.white)
                .frame(width: 18, height: 18)
                .shadow(color: Color.black.opacity(0.35), radius: 4, x: 0, y: 2)
                .scaleEffect(active ? 1.2 : 1)
                .offset(x: trackX + track * fraction - 9, y: y - 9)
            Text(verbatim: String(format: "%.2f", value))
                .font(.system(size: 12, weight: .heavy, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(TrailerStyle.emberText)
                .offset(x: trackX + track + 10, y: y - 8)
        }
    }
}
