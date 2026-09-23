import SwiftUI
import UIKit

/// Whether the branded launch intro may play.
///
/// It is skipped when Reduce Motion or VoiceOver is on, when any `-ML_*` launch argument is present
/// (automated screenshots), when the `ML_noIntro` default is true (`-ML_noIntro YES`), and after it
/// has played once in this process.
enum LaunchIntro {
    nonisolated(unsafe) static var didFinish = false

    /// Evaluated once per process.
    static let isEligible: Bool = {
        let arguments = ProcessInfo.processInfo.arguments
        if arguments.contains(where: { $0.hasPrefix("-ML_") }) { return false }
        if UserDefaults.standard.bool(forKey: "ML_noIntro") { return false }
        if UIAccessibility.isReduceMotionEnabled || UIAccessibility.isVoiceOverRunning { return false }
        return true
    }()

    static var shouldPlay: Bool { isEligible && !didFinish }
}

/// ~1.15 s cold-start intro: three ember orbs pop in along a diagonal trail, gather and
/// melt into one (metaball), then the merged orb blooms into a ring that opens a circular window onto
/// the app underneath. Tap anywhere to skip.
struct LaunchIntroView: View {
    /// Called when the circular reveal starts (the UI below may begin its own entrance).
    let onReveal: () -> Void
    /// Called when the intro is done and should be removed.
    let onFinish: () -> Void

    @State private var start = Date()
    @State private var didReveal = false
    @State private var didFinish = false

    static let revealTime: Double = 0.68
    static let duration: Double = 1.15

    var body: some View {
        TimelineView(.animation) { timeline in
            let elapsed = timeline.date.timeIntervalSince(start)
            IntroCanvas(time: min(max(elapsed, 0), Self.duration))
        }
        .ignoresSafeArea()
        .contentShape(Rectangle())
        .onTapGesture { skip() }
        .task { await run() }
        .accessibilityHidden(true)
    }

    private func run() async {
        try? await Task.sleep(for: .seconds(Self.revealTime))
        guard !Task.isCancelled else { return }
        reveal()
        try? await Task.sleep(for: .seconds(Self.duration - Self.revealTime))
        guard !Task.isCancelled else { return }
        finish()
    }

    private func reveal() {
        guard !didReveal else { return }
        didReveal = true
        Haptics.tap(.soft)
        onReveal()
    }

    private func finish() {
        guard !didFinish else { return }
        didFinish = true
        LaunchIntro.didFinish = true
        onFinish()
    }

    private func skip() {
        guard !didFinish else { return }
        if !didReveal {
            didReveal = true
            onReveal()
        }
        finish()
    }
}

// MARK: - Frame

private struct IntroCanvas: View {
    let time: Double

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let state = IntroState(time: time, size: size)
            ZStack {
                IntroPalette.backdrop
                if state.isMerging {
                    IntroOrbCluster(orbs: state.orbs, screen: size)
                } else {
                    IntroBloom(radius: state.ringRadius, core: state.coreOpacity, screen: size)
                }
            }
            .frame(width: size.width, height: size.height)
            .mask {
                IntroHoleShape(radius: state.holeRadius)
                    .fill(style: FillStyle(eoFill: true))
            }
            .opacity(state.opacity)
        }
    }
}

/// Three orbs rendered as one gooey metaball (blur + alpha threshold), filled with the ember gradient
/// and a white-hot core.
private struct IntroOrbCluster: View {
    let orbs: [IntroState.Orb]
    let screen: CGSize
    private let side: CGFloat = 320

    var body: some View {
        ZStack {
            IntroPalette.gradient(frame: side, screen: screen)
            RadialGradient(
                colors: [Color.white.opacity(0.8), Color.white.opacity(0)],
                center: .center,
                startRadius: 0,
                endRadius: 46
            )
        }
        .frame(width: side, height: side)
        .mask {
            Canvas { context, size in
                context.addFilter(.alphaThreshold(min: 0.5, color: .white))
                context.addFilter(.blur(radius: 9))
                context.drawLayer { layer in
                    for orb in orbs {
                        let rect = CGRect(
                            x: size.width / 2 + orb.offset.width - orb.radius,
                            y: size.height / 2 + orb.offset.height - orb.radius,
                            width: orb.radius * 2,
                            height: orb.radius * 2
                        )
                        layer.fill(Path(ellipseIn: rect), with: .color(.white))
                    }
                }
            }
        }
        .shadow(color: IntroPalette.glow, radius: 20)
    }
}

/// The merged orb growing into a ring (its centre is cut away by the hole mask).
private struct IntroBloom: View {
    let radius: CGFloat
    let core: Double
    let screen: CGSize

    var body: some View {
        let diameter = max(radius * 2, 1)
        ZStack {
            IntroPalette.gradient(frame: diameter, screen: screen)
            RadialGradient(
                colors: [Color.white.opacity(0.8), Color.white.opacity(0)],
                center: .center,
                startRadius: 0,
                endRadius: 46
            )
            .opacity(core)
        }
        .frame(width: diameter, height: diameter)
        .clipShape(Circle())
        .shadow(color: IntroPalette.glow, radius: 20)
    }
}

/// A full-screen rectangle with a circular hole (filled even-odd).
private struct IntroHoleShape: Shape {
    var radius: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path(rect)
        if radius > 0.5 {
            let hole = CGRect(x: rect.midX - radius, y: rect.midY - radius, width: radius * 2, height: radius * 2)
            path.addEllipse(in: hole)
        }
        return path
    }
}

// MARK: - Timeline

private struct IntroState {
    struct Orb {
        var offset: CGSize
        var radius: CGFloat
    }

    let orbs: [Orb]
    let isMerging: Bool
    let ringRadius: CGFloat
    let holeRadius: CGFloat
    let coreOpacity: Double
    let opacity: Double

    /// The icon's trail (small → medium → large, bottom-left to top-right), spread a little wider.
    private static let starts: [Orb] = [
        Orb(offset: CGSize(width: -74, height: 40), radius: 20),
        Orb(offset: CGSize(width: -8, height: 2), radius: 26),
        Orb(offset: CGSize(width: 54, height: -38), radius: 34),
    ]
    private static let mergedRadius: CGFloat = 40

    init(time t: Double, size: CGSize) {
        let gather = IntroEase.inOutCubic(Self.progress(t, from: 0.34, length: 0.32))
        let pull = CGFloat(1 - gather)
        var list: [Orb] = []
        for (index, orb) in Self.starts.enumerated() {
            let popStart = 0.04 + 0.07 * Double(index)
            let pop = CGFloat(IntroEase.outBack(Self.progress(t, from: popStart, length: 0.3)))
            let grown: CGFloat = orb.radius + (Self.mergedRadius - orb.radius) * CGFloat(gather)
            let offset = CGSize(width: orb.offset.width * pull, height: orb.offset.height * pull)
            list.append(Orb(offset: offset, radius: max(grown * pop, 0)))
        }
        orbs = list

        let revealTime = LaunchIntroView.revealTime
        let revealLength = LaunchIntroView.duration - revealTime
        let reveal = IntroEase.inOutCubic(Self.progress(t, from: revealTime, length: revealLength))
        isMerging = t < revealTime

        let width = size.width
        let height = size.height
        let halfDiagonal: CGFloat = (width * width + height * height).squareRoot() / 2
        let e = CGFloat(reveal)
        let outer: CGFloat = Self.mergedRadius + (halfDiagonal + 120 - Self.mergedRadius) * e
        let thickness: CGFloat = 40 + 60 * e
        ringRadius = outer
        holeRadius = max(0, outer - thickness)
        coreOpacity = 1 - reveal
        let fadeStart = LaunchIntroView.duration - 0.16
        opacity = 1 - Self.progress(t, from: fadeStart, length: 0.16)
    }

    private static func progress(_ t: Double, from start: Double, length: Double) -> Double {
        guard length > 0 else { return t >= start ? 1 : 0 }
        return min(max((t - start) / length, 0), 1)
    }
}

private enum IntroEase {
    static func inOutCubic(_ x: Double) -> Double {
        if x < 0.5 { return 4 * x * x * x }
        let f = -2 * x + 2
        return 1 - f * f * f / 2
    }

    static func outBack(_ x: Double) -> Double {
        let c1 = 1.70158
        let c3 = c1 + 1
        let f = x - 1
        return 1 + c3 * f * f * f + c1 * f * f
    }
}

private enum IntroPalette {
    /// The shell's ember palette: deep ember → hot orange → orange → amber → pale gold.
    static let stops: [Gradient.Stop] = [
        Gradient.Stop(color: Color(hex: 0x3A1204), location: 0),
        Gradient.Stop(color: Color(hex: 0xD2410F), location: 0.4),
        Gradient.Stop(color: Color(hex: 0xFF5E3A), location: 0.52),
        Gradient.Stop(color: Color(hex: 0xFF7A1A), location: 0.66),
        Gradient.Stop(color: Color(hex: 0xFFB45C), location: 0.84),
        Gradient.Stop(color: Color(hex: 0xFFE2AE), location: 1),
    ]
    static let glow = Color(hex: 0xFF6A1A, opacity: 0.55)
    /// Near-black ink in dark mode (the dark page colour), the system background in light mode
    /// (which matches the generated launch screen, so the hand-off never flashes).
    static let backdrop = Color.adaptive(light: 0xFFFFFF, dark: 0x0B0B0D)

    /// The full-screen diagonal gradient expressed in the unit space of a `frame`-sized square centred
    /// on screen, so the orbs, the bloom and the ring all sample the same colours as they grow.
    static func gradient(frame: CGFloat, screen: CGSize) -> LinearGradient {
        let side = max(frame, 1)
        let halfWidth = screen.width / (2 * side)
        let halfHeight = screen.height / (2 * side)
        let start = UnitPoint(x: 0.5 - halfWidth, y: 0.5 - halfHeight)
        let end = UnitPoint(x: 0.5 + halfWidth, y: 0.5 + halfHeight)
        return LinearGradient(stops: stops, startPoint: start, endPoint: end)
    }
}
