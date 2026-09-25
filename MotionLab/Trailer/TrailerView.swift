import SwiftUI

/// 60-second promotional trailer ("one-take" motion graphics), shown instead of the app with
/// `-ML_trailer YES` and recorded by `scripts/record-trailer.sh`.
///
/// One clock drives everything: `t` = seconds since the white lead-in slate ended, read from a
/// `TimelineView(.animation)`. Every scene is a pure function of `t`, so the cut is deterministic;
/// the embedded real effect demos run their own preview autoplay, phase-locked to the same clock
/// through `demoSyncEpoch`.
///
/// Layout: a fixed canvas 390 pt wide, 9:16 (390 × 693⅓ pt, default) or 3:4 (390 × 520 pt) picked with
/// `-ML_trailerAspect`, scaled to the screen width and centred vertically on #0B0B0D, so the recording
/// can be cropped exactly (see the script for the crop math). The bottom 18 % of the canvas is a clean
/// caption band (`TrailerCanvas.contentBottom`).
///
/// Every authored line of on-screen text comes from `TrailerCopy` (defaults in code, overridable with
/// `Documents/trailer-copy.json`, which the record script copies from `trailer/copy.json`).
///
/// Timeline (s): 0 hook · 5 pain · 10 search · 21 feel it (phone) · 36 tune · 44 prompt · 52 web · 57 end card.
struct TrailerView: View {
    @State private var start: Date?

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let scale = width / TrailerCanvas.width
            ZStack {
                TrailerCanvas.ink
                if let start {
                    let origin = start.addingTimeInterval(TrailerCanvas.leadIn)
                    TimelineView(.animation) { timeline in
                        let t = timeline.date.timeIntervalSince(origin)
                        ZStack {
                            TrailerStage(t: t, origin: origin)
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

/// Every scene, stacked back to front, each mounted only around its time window.
private struct TrailerStage: View {
    let t: Double
    let origin: Date

    var body: some View {
        ZStack {
            TrailerBackdrop(t: max(t, 0))
            if t < 5.8 {
                TrailerHookScene(t: max(t, 0))
            }
            if t >= 4.9 && t < 10.7 {
                TrailerPainScene(t: t)
            }
            if t >= 9.9 && t < 21.5 {
                TrailerSearchScene(t: t)
            }
            if t >= 20.6 && t < 44.6 {
                TrailerPhoneScene(t: t, origin: origin)
            }
            if t >= 11.4 && t < 26.0 {
                TrailerHeroLayer(t: t, origin: origin)
            }
            if t >= 43.8 && t < 52.6 {
                TrailerPromptScene(t: t)
            }
            if t >= 51.5 && t < 58.3 {
                TrailerWebScene(t: t)
            }
            if t >= 56.8 {
                TrailerEndScene(t: min(t, 70))
            }
            TrailerTouchLayer(t: t)
        }
        .frame(width: TrailerCanvas.width, height: TrailerCanvas.height)
        .environment(\.colorScheme, .dark)
        .allowsHitTesting(false)
    }
}
