import SwiftUI

/// 90-second promotional trailer ("one-take" motion graphics), shown instead of the app with
/// `-ML_trailer YES` and recorded by `scripts/record-trailer.sh`.
///
/// One clock drives everything: `t` = seconds since the white lead-in slate ended, read from a
/// `TimelineView(.animation)`. Every scene is a pure function of `t`, so the cut is deterministic;
/// the embedded real effect demos run their own preview autoplay, phase-locked to the same clock
/// through `demoSyncEpoch`, and the embedded real app screens (Browse, Search) are driven by it too.
///
/// Layout: a fixed canvas 390 pt wide, 9:16 (390 × 693⅓ pt, default) or 3:4 (390 × 520 pt) picked with
/// `-ML_trailerAspect`, scaled to the screen width and centred vertically on #0B0B0D, so the recording
/// can be cropped exactly (see the script for the crop math). The bottom 18 % of the canvas is a clean
/// caption band (`TrailerCanvas.contentBottom`) for the voice-over subtitles.
///
/// Every authored line of text (and the voice-over script) comes from `TrailerCopy` (defaults in code,
/// overridable with `Documents/trailer-copy.json`, which the record script copies from `trailer/copy.json`).
///
/// Timeline (s): 0 hook (prism digits) · 6 can't describe it · 16 don't know what's possible · 24 Motionary ·
/// 30 find it (real Browse + Search) · 44 feel it (detail pages) · 60 tune it · 70 copy the prompt ·
/// 80 web + app · 87 end card. `-ML_trailerFrom <seconds>` starts at a later point (previews only).
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
                if t >= TrailerFind.browseMount && t < 70.6 {
                    TrailerPhoneScene(t: t, origin: origin)
                }
                if t >= 69.9 && t < 80.2 {
                    TrailerPromptScene(t: t)
                }
                if t >= 78.9 && t < 88.8 {
                    TrailerOutroScene(t: t, origin: origin)
                }
                if t >= 86.2 {
                    TrailerEndScene(t: min(t, 100))
                }
            }
            TrailerTouchLayer(t: t)
        }
        .frame(width: TrailerCanvas.width, height: TrailerCanvas.height)
        .environment(\.colorScheme, .dark)
        .allowsHitTesting(false)
    }
}
