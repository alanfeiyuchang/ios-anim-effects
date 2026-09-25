import SwiftUI

private typealias M = TrailerMath

// MARK: - Catalog data

/// Real catalog numbers and real search results shown in the trailer.
enum TrailerData {
    /// Typed into the app's real search field (`TrailerCopy.search.query`).
    static var query: String { TrailerCopy.current.search.query }
    /// The first demo played on the phone: the finger opens it from the search results (it is the top
    /// "质感交互精选" match for the default query "卡片"), and the prompt card shows its prompt.
    static let heroID = "showcase.photo-play"

    static var effectCount: Int { EffectLibrary.all.count }
    static var categoryCount: Int { EffectCategory.allCases.count }
    static var familyCount: Int { EffectFamilies.all.count }

    /// What the real Search screen lists once the finger has tapped the Signature Interactions chip.
    static let showcaseMatches: [Effect] = EffectLibrary.search(query, category: .showcase, interaction: nil)
    static let showcaseFamilies: [EffectFamily] = EffectFamilies.search(query, category: .showcase, interaction: nil)

    /// Result card the finger opens: the hero's card when it is in the first two rows, else the first card.
    static let heroResultIndex: Int = {
        guard let index = showcaseMatches.firstIndex(where: { $0.id == heroID }), index < 4 else { return 0 }
        return index
    }()

    /// Touches every lazily built catalog table so the heavy first access happens during the slate.
    static func warmUp() {
        // Reads Documents/trailer-copy.json (if any) before anything shows text or searches, and writes
        // Documents/trailer-resolved.json for the record script.
        _ = TrailerCopy.current
        _ = showcaseMatches.count + showcaseFamilies.count + familyCount + heroResultIndex
        _ = EffectLibrary.featured.count
        _ = TrailerScript.taps.count
    }
}

// MARK: - Live demo

/// A real effect demo on its 340 pt authoring canvas, autoplaying like a grid preview.
/// Equatable on the id and clock, so the trailer's per-frame re-render never rebuilds it.
/// `epoch` phase-locks its `.autoplay` loop (see `demoSyncEpoch`) so taps land on the script's beats.
struct TrailerLiveDemo: View, Equatable {
    let effectID: String
    var epoch: Date? = nil

    static func == (lhs: TrailerLiveDemo, rhs: TrailerLiveDemo) -> Bool {
        lhs.effectID == rhs.effectID && lhs.epoch == rhs.epoch
    }

    var body: some View {
        let side = StageMetrics.previewCanvas
        if let effect = EffectLibrary.effect(id: effectID) {
            EffectDemoView(effect: effect, context: DemoContext(params: effect.defaultParams, isPreview: true, language: .zh))
                .frame(width: side, height: side)
                .environment(\.demoAutoplayEnabled, true)
                .environment(\.demoSyncEpoch, epoch)
                .environment(\.appLanguage, .zh)
        }
    }
}

/// A live demo scaled into a square stage of `side` points, on the app's own stage background.
struct TrailerStageTile: View {
    let effectID: String
    var epoch: Date? = nil
    let side: CGFloat
    var cornerRadius: CGFloat = 16
    var backgroundOpacity: Double = 1

    var body: some View {
        let canvas = StageMetrics.previewCanvas
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        ZStack {
            StageBackground()
                .opacity(backgroundOpacity)
            TrailerLiveDemo(effectID: effectID, epoch: epoch)
                .equatable()
                .scaleEffect(side / canvas)
                .frame(width: side, height: side)
        }
        .frame(width: side, height: side)
        .clipShape(shape)
        .overlay(StageRim(cornerRadius: cornerRadius))
    }
}

// MARK: - 30–44 s · 找灵感: the script of the real app screens

/// What the embedded app screens (`TrailerAppScreen`) do over time: Browse scrolls through its hero, the
/// Featured carousel, the family row and the categories; the finger taps the search button; the query is
/// typed into the real search field; the finger taps the "质感交互精选" chip; then it opens a result.
///
/// Positions are in device points of a 402 × 874 pt iPhone 16/17 Pro screen (the app screens are laid out at
/// that size and scaled uniformly into the drawn phone). The Search-screen positions are estimates of the
/// system layout (status bar 62 pt, large-title navigation bar with an always-visible search drawer ≈ 150 pt):
/// if a recording shows the finger off target, adjust `searchContentTop`.
enum TrailerFind {
    /// Browse is mounted a moment before the phone rises, so its first-appearance reveal plays on camera.
    static let browseMount: Double = 29.2
    /// The finger taps the tab bar's search button; Search replaces Browse (like a tab switch).
    static let searchTap: Double = 34.95
    static let searchMount: Double = 34.75
    static let searchSwitch: Double = 35.08
    static let browseUnmount: Double = 35.6
    static let typingStart: Double = 35.8
    /// The finger taps the Signature Interactions chip; the category filter applies on the tap.
    static let chipTap: Double = 37.6
    /// The finger opens a result; the detail page zooms out of it.
    static let cardTap: Double = 42.2
    static let detailOpen: Double = 42.35
    static let appUnmount: Double = 43.4

    // MARK: Browse scroll

    struct Swipe {
        let start: Double
        let duration: Double
        let from: CGFloat
        let to: CGFloat
        /// Finger travel (device points, upward).
        let reach: CGFloat
    }

    /// Two flicks: to the Featured carousel and family row, then down to the category grid.
    static let swipes: [Swipe] = [
        Swipe(start: 30.95, duration: 1.5, from: 0, to: 430, reach: 250),
        Swipe(start: 32.9, duration: 1.6, from: 430, to: 1080, reach: 330),
    ]

    /// Browse's scroll offset: each flick follows the finger, then decelerates (cubic ease-out).
    static func browseScroll(_ t: Double) -> CGFloat {
        var offset: CGFloat = 0
        for swipe in swipes where t >= swipe.start {
            let p: Double = M.progress(t, swipe.start, swipe.duration)
            let q: Double = 1 - p
            let eased: Double = 1 - q * q * q
            offset = M.mix(swipe.from, swipe.to, eased)
        }
        return (offset * 2).rounded() / 2
    }

    // MARK: Typing

    /// When each character of the query lands: 0.35 s apart, tighter for longer queries (done by 36.8 s).
    static let typedAt: [Double] = {
        let count: Int = Array(TrailerData.query).count
        guard count > 1 else { return count == 1 ? [typingStart] : [] }
        let step: Double = min(0.35, 1.0 / Double(count - 1))
        return (0..<count).map { index in typingStart + Double(index) * step }
    }()

    static func typedCount(_ t: Double) -> Int {
        typedAt.filter { t >= $0 }.count
    }

    /// The state handed to the embedded screens this frame (only changes when something visible does).
    static func frame(_ t: Double) -> TrailerAppFrame {
        let fade: Double = M.progress(t, searchSwitch, 0.15)
        let steps: Double = 8
        let searchOpacity: Double = (fade * steps).rounded() / steps
        return TrailerAppFrame(
            showsBrowse: t < browseUnmount,
            showsSearch: t >= searchMount,
            searchOpacity: searchOpacity,
            browseScroll: browseScroll(t),
            typed: typedCount(t),
            filtered: t >= chipTap + 0.02,
            searchSelected: t >= searchSwitch
        )
    }

    // MARK: Layout (device points)

    static let deviceSize = CGSize(width: 402, height: 874)
    static let statusBar: CGFloat = 62
    /// Tab bar (floating, iOS 26 style): 62 pt tall, 21 pt above the bottom edge.
    static let tabBarHeight: CGFloat = 62
    static let tabBarBottom: CGFloat = 21
    static let tabBarY: CGFloat = deviceSize.height - tabBarBottom - tabBarHeight / 2
    static let searchButton = CGPoint(x: deviceSize.width - 20 - tabBarHeight / 2, y: tabBarY)

    /// Top of the Search page's scroll content (status bar + navigation bar, large title and search field).
    static let searchContentTop: CGFloat = statusBar + 150
    /// The filter row: interaction menu (~85 pt), divider, "全部" (~54 pt), then "质感交互精选" (~133 pt).
    static let showcaseChip = CGPoint(x: 246, y: searchContentTop + 16 + 21)

    /// Result card metrics of the real `EffectGrid` (two 178 pt columns, 14 pt gutters).
    static let cardWidth: CGFloat = (deviceSize.width - 32 - 14) / 2
    static let resultStageSide: CGFloat = cardWidth - 16
    static let cardHeight: CGFloat = 250

    /// Centre of result `index`'s preview stage after the chip filtered the grid.
    static func resultStage(_ index: Int) -> CGPoint {
        let familyRow: CGFloat = TrailerData.showcaseFamilies.isEmpty ? 0 : 82
        let gridTop: CGFloat = searchContentTop + 16 + 42 + 14 + familyRow + 18 + 14
        let column = CGFloat(index % 2)
        let row = CGFloat(index / 2)
        let x: CGFloat = 16 + cardWidth / 2 + column * (cardWidth + 14)
        let y: CGFloat = gridTop + 8 + resultStageSide / 2 + row * (cardHeight + 14)
        return CGPoint(x: x, y: y)
    }

    /// A device point of the app screen, on the canvas.
    static func canvasPoint(_ point: CGPoint) -> CGPoint {
        TrailerLayout.screenPoint(point.x * TrailerPhone.unit, point.y * TrailerPhone.unit)
    }

    /// A device length, on the canvas.
    static func canvasLength(_ length: CGFloat) -> CGFloat {
        length * TrailerPhone.unit * TrailerLayout.phoneScale
    }
}
