import SwiftUI

// MARK: - Layout anchors shared by scenes and the finger script

/// Canvas positions that more than one scene refers to, per aspect (`TrailerCanvas.pick(3:4, 9:16)`).
enum TrailerLayout {
    /// Centre of the two-line headline that tops most scenes.
    static let headlineY: CGFloat = TrailerCanvas.pick(58, 128)
    /// Where the pain scene's words collapse, and the unknown tiles are born.
    static let painCollapse = TrailerCanvas.point(195, 250, 330)

    // Phone (the app's detail page on an iPhone, see `TrailerPhone`)
    /// Headline above the phone: higher and a touch smaller than elsewhere, so the phone can be big.
    static let phoneHeadlineY: CGFloat = TrailerCanvas.pick(46, 96)
    /// The phone is authored at 9:16 size (`TrailerPhone.bodySize`) and scaled uniformly for 3:4.
    static let phoneScale: CGFloat = TrailerCanvas.pick(TrailerPhone.classicBodyHeight / TrailerPhone.bodySize.height, 1)
    static let phoneCenter = TrailerCanvas.point(195, 88 + TrailerPhone.classicBodyHeight / 2, 146 + TrailerPhone.bodySize.height / 2)

    /// Maps a point in the phone's screen coordinates (`TrailerPhone.screenSize`) onto the canvas.
    static func screenPoint(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
        let screen = TrailerPhone.screenSize
        let dx: CGFloat = (x - screen.width / 2) * phoneScale
        let dy: CGFloat = (y - screen.height / 2) * phoneScale
        return CGPoint(x: phoneCenter.x + dx, y: phoneCenter.y + dy)
    }

    /// The demo "stage card" inside the phone screen, in canvas coordinates.
    static let demoOrigin: CGPoint = screenPoint(TrailerPhone.stageRect.minX, TrailerPhone.stageRect.minY)
    static let demoSide: CGFloat = TrailerPhone.stageRect.width * phoneScale
    static let stageCorner: CGFloat = TrailerPhone.stageCorner * phoneScale
    static var demoCenter: CGPoint {
        CGPoint(x: demoOrigin.x + demoSide / 2, y: demoOrigin.y + demoSide / 2)
    }

    /// Maps a point of a demo's 340 × 340 authoring canvas onto the phone stage.
    static func demoPoint(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
        let scale = demoSide / StageMetrics.previewCanvas
        return CGPoint(x: demoOrigin.x + x * scale, y: demoOrigin.y + y * scale)
    }

    // Prompt card (the chat panel and the web window share its centre)
    static let promptCenter = TrailerCanvas.point(195, 257, 356)
    static let promptSize = CGSize(width: 334, height: TrailerCanvas.pick(270, 300))
    private static let promptTopLeft = CGPoint(x: promptCenter.x - promptSize.width / 2, y: promptCenter.y - promptSize.height / 2)
    /// The 中/EN toggle (84 × 28, right of the header row, card padding 18).
    static let segmentZh = CGPoint(x: promptTopLeft.x + promptSize.width - 18 - 84 + 21, y: promptTopLeft.y + 18 + 14)
    static let segmentEn = CGPoint(x: segmentZh.x + 42, y: segmentZh.y)
    /// Width of the copy button: 104 pt, wider for longer `TrailerCopy.prompt` button labels (max 160).
    static let copyButtonWidth: CGFloat = {
        let copy = TrailerCopy.current.prompt
        let text: CGFloat = max(TrailerCopy.estimatedWidth(copy.copyButton, size: 13), TrailerCopy.estimatedWidth(copy.copiedButton, size: 13))
        let natural: CGFloat = text + 12 + 5 + 30
        return min(max(104, natural), 160)
    }()
    /// The copy button (`copyButtonWidth` × 32, bottom right).
    static let copyButton = CGPoint(x: promptTopLeft.x + promptSize.width - 18 - copyButtonWidth / 2, y: promptTopLeft.y + promptSize.height - 18 - 16)
}

// MARK: - Script

struct TrailerTap {
    let time: Double
    let point: CGPoint
    /// How long the finger stays down.
    var hold: Double = 0.14
    /// Small detent ticks (slider) get a ring pulse but no badge.
    var isTick = false
    /// A drag: the finger slides from `point` to `to` while it is down.
    var to: CGPoint? = nil
    /// No ripple and no badge (a scroll flick, which has no haptic).
    var silent = false
    /// Whether the "触感" badge pops (off for the first tap of a double tap).
    var badge = true

    /// Where the finger is when it lifts.
    var endPoint: CGPoint { to ?? point }
}

struct TrailerFingerState {
    var point: CGPoint
    var opacity: Double
    var pressed: Double

    static let hidden = TrailerFingerState(point: CGPoint(x: 195, y: 260), opacity: 0, pressed: 0)
}

/// The scripted finger: when it is on screen, where it goes and every tap it makes.
enum TrailerScript {
    /// Windows in which the finger is visible (the tune drag window is driven by `TrailerTune`).
    static let segments: [ClosedRange<Double>] = [
        30.55...35.45, 37.0...38.1, 41.6...42.65,
        43.25...47.5, 47.85...49.0, 51.35...54.0, 54.75...58.25,
        60.4...69.3,
        72.9...76.3,
        82.55...86.1,
    ]
    static let tuneSegment: ClosedRange<Double> = 60.4...69.3

    /// A point of a demo's 340 × 340 canvas on the phone's detail stage.
    private static func stage(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
        TrailerLayout.demoPoint(x, y)
    }

    /// A device point of the embedded app screens.
    private static func app(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
        TrailerFind.canvasPoint(CGPoint(x: x, y: y))
    }

    static let taps: [TrailerTap] = {
        let flicks: [TrailerTap] = TrailerFind.swipes.enumerated().map { pair -> TrailerTap in
            let swipe = pair.element
            let x: CGFloat = pair.offset == 0 ? 300 : 292
            let y: CGFloat = pair.offset == 0 ? 690 : 720
            return TrailerTap(
                time: swipe.start - 0.02,
                point: TrailerScript.app(x, y),
                hold: 0.34,
                to: TrailerScript.app(x, y - swipe.reach),
                silent: true
            )
        }
        var list: [TrailerTap] = flicks
        list += [
            // Find: the tab bar's search button, the Signature Interactions chip, then a result.
            TrailerTap(time: TrailerFind.searchTap, point: TrailerFind.canvasPoint(TrailerFind.searchButton)),
            TrailerTap(time: TrailerFind.chipTap, point: TrailerFind.canvasPoint(TrailerFind.showcaseChip)),
            TrailerTap(time: TrailerFind.cardTap, point: TrailerFind.canvasPoint(TrailerFind.resultStage(TrailerData.heroResultIndex))),
            // Feel: photo-play (play, pause), summit-badge, save-burst (double tap, bookmark), board-card (two flips).
            TrailerTap(time: 43.8, point: TrailerScript.stage(170, 150)),
            TrailerTap(time: 47.0, point: TrailerScript.stage(170, 150)),
            TrailerTap(time: 48.4, point: TrailerScript.stage(170, 150), hold: 0.2),
            TrailerTap(time: 51.88, point: TrailerScript.stage(170, 133), hold: 0.06, badge: false),
            TrailerTap(time: 52.0, point: TrailerScript.stage(170, 133), hold: 0.1),
            TrailerTap(time: 53.5, point: TrailerScript.stage(272, 265)),
            TrailerTap(time: 55.3, point: TrailerScript.stage(170, 160)),
            TrailerTap(time: 57.7, point: TrailerScript.stage(170, 160)),
            // Prompt: EN, back to 中, copy.
            TrailerTap(time: 73.4, point: TrailerLayout.segmentEn),
            TrailerTap(time: 74.9, point: TrailerLayout.segmentZh),
            TrailerTap(time: 75.8, point: TrailerLayout.copyButton),
        ]
        // Outro: the phone beside the web page gets played too.
        for time in TrailerOutroScene.phoneTapTimes {
            list.append(TrailerTap(time: time, point: TrailerOutroScene.phoneTapPoint))
        }
        for press in TrailerTune.presses {
            list.append(TrailerTap(time: press.start, point: TrailerTune.knobPoint(row: press.row, t: press.start), hold: press.end - press.start))
        }
        for tick in TrailerTune.ticks {
            list.append(TrailerTap(time: tick.time, point: tick.point, isTick: true))
        }
        return list.sorted { $0.time < $1.time }
    }()

    /// Real (non-tick) taps inside a finger segment, in time order.
    private static let tapsBySegment: [[TrailerTap]] = TrailerScript.segments.map { segment in
        TrailerScript.taps.filter { !$0.isTick && segment.contains($0.time) }
    }

    static func finger(at t: Double) -> TrailerFingerState {
        guard let segmentIndex = segments.firstIndex(where: { $0.contains(t) }) else { return .hidden }
        let segment = segments[segmentIndex]
        let fadeIn = TrailerMath.progress(t, segment.lowerBound, 0.3)
        let fadeOut = 1 - TrailerMath.progress(t, segment.upperBound - 0.3, 0.3)
        let opacity = min(fadeIn, fadeOut)
        if segment == tuneSegment {
            return TrailerFingerState(point: TrailerTune.fingerPoint(t), opacity: opacity, pressed: TrailerTune.pressed(t))
        }
        let list = tapsBySegment[segmentIndex]
        let previous = list.last(where: { $0.time <= t })
        let next = list.first(where: { $0.time > t })
        var pressed: Double = 0
        let point: CGPoint
        if let previous, t <= previous.time + previous.hold {
            if let to = previous.to {
                let p = TrailerMath.easeInOut(TrailerMath.progress(t, previous.time, previous.hold))
                point = TrailerMath.mix(previous.point, to, p)
            } else {
                point = previous.point
            }
            pressed = min(1, 1 - TrailerMath.progress(t, previous.time + previous.hold - 0.06, 0.06))
        } else if let next {
            let from = previous?.endPoint ?? CGPoint(x: next.point.x + 70, y: next.point.y + 120)
            let departure = previous.map { $0.time + $0.hold + 0.06 } ?? segment.lowerBound
            let arrival = next.time - 0.1
            let p = TrailerMath.easeInOut(TrailerMath.progress(t, departure, max(arrival - departure, 0.05)))
            var moved = TrailerMath.mix(from, next.point, p)
            moved.y -= CGFloat(sin(p * Double.pi)) * 16
            point = moved
            // The finger dips just before contact.
            pressed = 0.35 * TrailerMath.progress(t, next.time - 0.06, 0.06)
        } else if let previous {
            let leave = previous.time + previous.hold + 0.15
            let p = TrailerMath.easeIn(TrailerMath.progress(t, leave, max(segment.upperBound - leave, 0.1)))
            let end = previous.endPoint
            point = TrailerMath.mix(end, CGPoint(x: end.x + 60, y: end.y + 40), p)
        } else {
            point = CGPoint(x: 300, y: 380)
        }
        return TrailerFingerState(point: point, opacity: opacity, pressed: pressed)
    }

    /// Device shake: the sum of every recent tap's decaying buzz inside `window`.
    static func buzz(_ t: Double, window: ClosedRange<Double> = 34.5...69.5) -> Double {
        var total: Double = 0
        for tap in taps where !tap.isTick && !tap.silent && window.contains(tap.time) {
            total += TrailerMath.buzz(t - tap.time)
        }
        return total
    }
}

// MARK: - Finger, ripples and the haptic badge

/// Draws the finger indicator plus, for every tap in the last second, concentric ripple rings and
/// a "触感" pulse badge with a little waveform: the trailer's way of showing a haptic.
struct TrailerTouchLayer: View {
    let t: Double

    var body: some View {
        let finger = TrailerScript.finger(at: t)
        let active = TrailerScript.taps.indices.filter { index in
            let tap = TrailerScript.taps[index]
            let elapsed = t - tap.time
            return !tap.silent && elapsed >= 0 && elapsed < 1.1
        }
        ZStack {
            ForEach(active, id: \.self) { index in
                let tap = TrailerScript.taps[index]
                TrailerRipple(point: tap.point, elapsed: t - tap.time, small: tap.isTick)
            }
            TrailerFinger(state: finger)
            ForEach(active, id: \.self) { index in
                let tap = TrailerScript.taps[index]
                if !tap.isTick && tap.badge {
                    TrailerHapticBadge(point: tap.point, elapsed: t - tap.time)
                }
            }
        }
        .frame(width: TrailerCanvas.width, height: TrailerCanvas.height)
        .allowsHitTesting(false)
    }
}

private struct TrailerFinger: View {
    let state: TrailerFingerState

    var body: some View {
        let press = CGFloat(TrailerMath.clamp(state.pressed))
        ZStack {
            Circle()
                .fill(Color.white.opacity(0.16 + 0.22 * Double(press)))
            Circle()
                .strokeBorder(Color.white.opacity(0.85), lineWidth: 1.5)
            Circle()
                .fill(Color.white.opacity(0.9))
                .frame(width: 7, height: 7)
        }
        .frame(width: 40, height: 40)
        .scaleEffect(1 - 0.18 * press)
        .shadow(color: Color.black.opacity(0.4), radius: 8, x: 0, y: 4)
        .opacity(state.opacity)
        .position(state.point)
    }
}

private struct TrailerRipple: View {
    let point: CGPoint
    let elapsed: Double
    var small = false

    var body: some View {
        let reach: Double = small ? 26 : 104
        ZStack {
            ForEach(0..<(small ? 1 : 3), id: \.self) { ring in
                let local = elapsed - Double(ring) * 0.09
                let p = TrailerMath.progress(local, 0, small ? 0.4 : 0.75)
                Circle()
                    .strokeBorder(TrailerStyle.emberRing, lineWidth: CGFloat(2.2 - 1.4 * p))
                    .frame(width: CGFloat(18 + reach * TrailerMath.easeOut(p)), height: CGFloat(18 + reach * TrailerMath.easeOut(p)))
                    .opacity(local > 0 ? (1 - p) * (small ? 0.6 : 0.9) : 0)
            }
            if !small {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Palette.ember.opacity(0.55), Palette.ember.opacity(0)],
                            center: .center,
                            startRadius: 0,
                            endRadius: 36
                        )
                    )
                    .frame(width: 72, height: 72)
                    .opacity(1 - TrailerMath.progress(elapsed, 0, 0.4))
            }
        }
        .position(point)
    }
}

private struct TrailerHapticBadge: View {
    let point: CGPoint
    let elapsed: Double

    var body: some View {
        let pop = TrailerMath.spring(elapsed, response: 0.42, damping: 0.58)
        let out = TrailerMath.progress(elapsed, 0.72, 0.3)
        let x = min(max(point.x + 30, 56), TrailerCanvas.width - 56)
        let y = max(point.y - 46, 22)
        HStack(spacing: 5) {
            TrailerWaveform(elapsed: elapsed)
            Text(verbatim: TrailerCopy.current.touch.hapticBadge)
                .font(.system(size: 12, weight: .heavy))
                .lineLimit(1)
        }
        .foregroundStyle(Palette.onAccent)
        .padding(.horizontal, 9)
        .padding(.vertical, 5)
        .background(Palette.accentFill, in: Capsule())
        .overlay(Capsule().strokeBorder(Color.white.opacity(0.35), lineWidth: 0.6))
        .shadow(color: Palette.accentGlow, radius: 10, x: 0, y: 4)
        .scaleEffect(CGFloat(0.4 + 0.6 * pop))
        .opacity(min(1, pop * 2) * (1 - out))
        .offset(y: -CGFloat(out) * 10)
        .position(x: x, y: y)
    }
}

/// Five bars pulsing like a haptic waveform, decaying after the tap.
private struct TrailerWaveform: View {
    let elapsed: Double

    var body: some View {
        HStack(alignment: .center, spacing: 1.5) {
            ForEach(0..<5, id: \.self) { bar in
                let energy = exp(-elapsed * 2.6)
                let wave = abs(sin(elapsed * 24 + Double(bar) * 1.3))
                Capsule()
                    .frame(width: 2, height: CGFloat(3 + 9 * wave * energy + (bar == 2 ? 2 : 0)))
            }
        }
        .frame(height: 14)
    }
}
