import SwiftUI

/// 75-second promotional trailer ("one-take" motion graphics), shown instead of the app with
/// `-ML_trailer YES` and recorded by `scripts/record-trailer.sh`.
///
/// One clock drives everything: `t` = seconds since the white lead-in slate ended, read from a
/// `TimelineView(.animation)`. The scenes are authored on a longer "source" clock and `TrailerEdit` maps
/// the cut's time onto it (full speed while anything moves, fast-forward through holds), so the cut
/// follows the voice-over. Every scene is a pure function of its source time, so the cut is
/// deterministic; the embedded real effect demos run their own preview autoplay, phase-locked to the same
/// clock through `demoSyncEpoch`, and the embedded real app screens (Browse, Search) are driven by it too.
///
/// Layout: a fixed canvas 390 pt wide, 9:16 (390 × 693⅓ pt, default) or 3:4 (390 × 520 pt) picked with
/// `-ML_trailerAspect`, scaled to the screen width and centred vertically on #0B0B0D, so the recording
/// can be cropped exactly (see the script for the crop math). The bottom 18 % of the canvas is a clean
/// caption band (`TrailerCanvas.contentBottom`) for the voice-over subtitles.
///
/// Every authored line of text (and the voice-over script) comes from `TrailerCopy` (defaults in code,
/// overridable with `Documents/trailer-copy.json`, which the record script copies from `trailer/copy.json`).
///
/// Cut (s): 0 hook (prism digits) · 4.3 can't describe it · 13.8 don't know what's possible · 18.6 Motionary ·
/// 23.8 find it (real Browse + Search) · 33.2 feel it (detail pages) · 43.1 favourites (day/night switch,
/// gear checklist) · 52.4 copy the prompt · 61.9 web + app · 68 open source (GitHub) · 71 end card, 75.4 out.
/// `-ML_trailerFrom <seconds>` starts at a later point of the cut (previews only).
struct TrailerView: View {
    @State private var start: Date?

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let scale = width / TrailerCanvas.width
            ZStack {
                TrailerCanvas.ink
                if let start {
                    let origin = start.addingTimeInterval(TrailerCanvas.leadIn - CatalogTools.trailerStartOffset)
                    TimelineView(.animation) { _ in
                        // The wall clock, not the timeline entry's date: under load an entry can be rendered
                        // late, and the embedded demos' own autoplay (phase-locked through `demoSyncEpoch`)
                        // runs on the wall clock, so the finger and the demos must read the same clock.
                        let t = Date().timeIntervalSince(origin)
                        ZStack {
                            TrailerStage(cut: t, cutOrigin: origin)
                                .frame(width: TrailerCanvas.width, height: TrailerCanvas.height)
                                .clipped()
                                .scaleEffect(scale)
                                .frame(width: width, height: TrailerCanvas.height * scale)
                            if t < 0 {
                                Color.white
                            }
                        }
                        .frame(width: proxy.size.width, height: proxy.size.height)
                    }
                } else {
                    Color.white
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .ignoresSafeArea()
        .statusBarHidden(true)
        .persistentSystemOverlays(.hidden)
        .onAppear {
            // Simulated taps must never buzz, even though autoplay resets `isMuted` after each action.
            Haptics.isMuted = true
            Haptics.quiet(for: 24 * 60 * 60)
            // Build the catalog tables during the slate, not mid-shot.
            TrailerData.warmUp()
            if start == nil { start = Date() }
        }
    }
}

/// Maps the cut's clock onto the scenes' source clock: a continuous piecewise-linear curve through
/// `knots` (cut time, source time). Slope 1 wherever something moves or a live demo plays; steeper only
/// through holds (static frames, drifting ambience) and the empty beat between two scenes.
enum TrailerEdit {
    /// Length of the cut, in seconds (the record script cuts exactly this much); `copy.edit` may override it.
    static let duration: Double = TrailerCopy.current.edit?.duration ?? 75.4

    /// The copy file's `edit.knots` when it has a valid set (another voice-over), else the default cut's.
    static let knots: [(cut: Double, source: Double)] = {
        let custom: [(cut: Double, source: Double)] = (TrailerCopy.current.edit?.knots ?? []).compactMap { pair in
            pair.count == 2 ? (cut: pair[0], source: pair[1]) : nil
        }
        let increasing = zip(custom, custom.dropFirst()).allSatisfy { $0.cut < $1.cut && $0.source <= $1.source }
        return custom.count >= 2 && increasing ? custom : defaultKnots
    }()

    /// The Chinese voice-over's cut (75.4 s).
    static let defaultKnots: [(cut: Double, source: Double)] = [
        (0, 0),
        (3.2, 3.2), (3.5, 5.0),        // hook: the number has landed; skip most of the hold
        (15.7, 17.2), (18.0, 22.7),    // pain → unknown; the unknown tiles float faster for a moment
        (22.3, 27.0), (23.8, 29.7),    // Motionary; its last pillar beats and exit run a little faster
        (28.27, 35.3),                 // Browse scrolls at 1.25×
        (30.57, 37.6), (31.2, 38.23),  // search typed, the chip tapped
        (31.55, 41.6),                 // results hold (no finger on screen)
        (32.3, 42.35),                 // a result opens; from here on the demos play in real time
        (52.6, 62.65), (52.75, 70.0),  // the phone leaves; jump over the empty beat to the prompt card
        (68.05, 85.3),                 // prompt, web + app
        (75.4, 92.65),                 // open source (GitHub), end card
    ]

    /// Source time for cut time `t` (slope 1 before the first and after the last knot).
    static func source(_ t: Double) -> Double {
        guard let first = knots.first, let last = knots.last else { return t }
        if t <= first.cut { return first.source + (t - first.cut) }
        if t >= last.cut { return last.source + (t - last.cut) }
        for index in 1..<knots.count where t < knots[index].cut {
            let a = knots[index - 1]
            let b = knots[index]
            return a.source + (t - a.cut) * (b.source - a.source) / (b.cut - a.cut)
        }
        return last.source + (t - last.cut)
    }

    /// `source(t) − t` of the knot span `t` is in: constant through a span, so wall-clock things keyed to
    /// the source clock (demo autoplay epochs) stay put while it plays; they only move at a knot.
    static func offset(_ t: Double) -> Double {
        guard knots.count > 1 else { return 0 }
        var span = knots[0]
        for knot in knots where knot.cut <= t {
            span = knot
        }
        return span.source - span.cut
    }
}

/// Every scene, stacked back to front, each mounted only around its (source) time window.
private struct TrailerStage: View {
    /// Cut time: seconds since the slate ended.
    let cut: Double
    let cutOrigin: Date

    var body: some View {
        let t: Double = cut < 0 ? cut : TrailerEdit.source(cut)
        // The wall-clock date at which the source clock read 0, so `origin + x` is when source time x plays.
        let origin: Date = cutOrigin.addingTimeInterval(-TrailerEdit.offset(max(cut, 0)))
        ZStack {
            TrailerBackdrop(t: max(cut, 0), cue: max(t, 0))
            // Two groups keep the builder small (and the type checker fast).
            Group {
                if t < 6.3 {
                    TrailerHookScene(t: max(t, 0))
                }
                if t >= 5.6 && t < 16.2 {
                    TrailerPainScene(t: t)
                }
                if t >= 15.4 && t < 24.4 {
                    TrailerUnknownScene(t: t)
                }
                if t >= 23.5 && t < 30.2 {
                    TrailerIntroScene(t: t)
                }
            }
            Group {
                if t >= TrailerFind.browseMount && t < TrailerPhoneScene.exitStart + 0.8 {
                    TrailerPhoneScene(t: t, origin: origin)
                }
                if t >= 69.9 && t < 80.2 {
                    TrailerPromptScene(t: t)
                }
                if t >= 78.9 && t < TrailerOutroScene.condenseStart + 2.4 {
                    TrailerOutroScene(t: t, origin: origin)
                }
                if t >= TrailerOutroScene.condenseStart - 0.2 {
                    TrailerEndScene(t: min(t, 110))
                }
            }
            TrailerTouchLayer(t: t)
        }
        .frame(width: TrailerCanvas.width, height: TrailerCanvas.height)
        .environment(\.colorScheme, .dark)
        .allowsHitTesting(false)
    }
}
