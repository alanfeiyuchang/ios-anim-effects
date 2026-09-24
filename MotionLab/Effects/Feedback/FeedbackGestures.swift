import SwiftUI

/// The list of a pull-to-refresh demo. When `live`, a UIKit pan (`PageSafePan`, down only) pulls the plain rows
/// down: it only begins on a mostly downward drag, so upward and sideways swipes fail it at once and scroll the
/// detail page as usual, and once it begins the page's scroll view waits for it, so the page never moves with it.
/// - `onPull(pull, byFinger)` reports the rubber-banded pull (≥ 0) on every change, with whether a finger is on it;
/// - `onRelease()` runs once when the finger lifts (or the system cancels the touch), before the pull springs home;
/// - `hold` shifts the rows down on its own: the scripted pull of previews and the hold height while refreshing.
/// Previews and stills (`live == false`) show the plain rows, shifted by `hold`.
struct FeedbackRefreshList<Content: View>: View {
    let live: Bool
    let hold: CGFloat
    let onPull: (CGFloat, Bool) -> Void
    let onRelease: () -> Void
    let content: Content

    /// The finger's rubber-banded pull; springs back to 0 after the release.
    @State private var drag: CGFloat = 0

    init(
        live: Bool,
        hold: CGFloat,
        onPull: @escaping (CGFloat, Bool) -> Void,
        onRelease: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.live = live
        self.hold = hold
        self.onPull = onPull
        self.onRelease = onRelease
        self.content = content()
    }

    var body: some View {
        if live {
            content
                .offset(y: hold + drag)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .contentShape(Rectangle())
                .gesture(PageSafePan(directions: .down, onChanged: pullChanged, onEnded: pullEnded))
        } else {
            content.offset(y: hold)
        }
    }

    private func pullChanged(_ translation: CGSize) {
        // Native-like resistance: 72 pt of pull takes ~130 pt of finger travel, 100 pt ~215 pt.
        let value = rubberBand(max(translation.height, 0), limit: 240, coefficient: 0.8)
        drag = value
        onPull(value, true)
    }

    /// The host decides first (it still sees the full pull), then the pull springs home: its hold `shift` grows in
    /// the same spring when it starts a refresh, so the rows glide from the finger to the hold height.
    /// A system cancellation (`nil`) counts as a release, like lifting the finger.
    private func pullEnded(_ end: PageSafePanEnd?) {
        onRelease()
        withAnimation(.spring(response: 0.4, dampingFraction: 0.9)) {
            drag = 0
            onPull(0, false)
        }
    }
}
