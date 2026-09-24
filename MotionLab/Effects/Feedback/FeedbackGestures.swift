import SwiftUI

/// The list of a pull-to-refresh demo, pulled the native way: when `live`, the rows sit in their own vertical
/// `ScrollView` that always bounces, and the pull is that scroll view's top overscroll. The inner scroll view owns
/// the drag, so the detail page doesn't move with it, and the system bounce gives the rubber band and the spring home.
/// - `onPull(overscroll, byFinger)` reports the overscroll (≥ 0) on every change, with whether a finger is on it;
/// - `onRelease()` runs once when the finger lifts (or the system cancels the touch);
/// - `hold` shifts the rows down without touching the scroll view: the scripted pull of previews and the hold
///   height while refreshing.
/// Previews and stills (`live == false`) show the plain rows, shifted by `hold`.
struct FeedbackRefreshList<Content: View>: View {
    let live: Bool
    let hold: CGFloat
    let onPull: (CGFloat, Bool) -> Void
    let onRelease: () -> Void
    let content: Content

    @State private var fingerDown = false

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
            ScrollView(.vertical) {
                content.offset(y: hold)
            }
            .scrollIndicators(.hidden)
            .scrollBounceBehavior(.always)
            .onScrollGeometryChange(for: CGFloat.self) { geometry in
                max(0, -(geometry.contentOffset.y + geometry.contentInsets.top))
            } action: { _, overscroll in
                onPull(overscroll, fingerDown)
            }
            .onScrollPhaseChange { oldPhase, newPhase in
                fingerDown = newPhase == .tracking || newPhase == .interacting
                if oldPhase == .interacting && newPhase != .interacting { onRelease() }
            }
        } else {
            content.offset(y: hold)
        }
    }
}
