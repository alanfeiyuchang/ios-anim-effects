import SwiftUI

/// A pull-to-refresh drag that never traps the detail page's vertical scroll and never leaves a demo stuck mid-pull:
/// - it is attached *simultaneously*, so the page's scroll view still receives every swipe;
/// - it only engages when the touch starts within `startZone` pt of the view's top edge and the first
///   `minimumDistance` of travel is mostly downward. Upward and sideways swipes are rejected for the rest of
///   that touch and simply scroll the page;
/// - a `@GestureState` flag also resets on system cancellation (scroll takeover, Control Center pull, multi-touch),
///   so `onEnded` runs exactly once per engaged pull: with the final value on a normal release, or `nil` when the
///   system cancelled the drag.
private struct PageSafePullDownModifier: ViewModifier {
    let minimumDistance: CGFloat
    let startZone: CGFloat
    let onChanged: (DragGesture.Value) -> Void
    let onEnded: (DragGesture.Value?) -> Void

    private enum Phase {
        case idle, engaged, rejected
    }

    @State private var phase: Phase = .idle
    @GestureState private var touching = false

    func body(content: Content) -> some View {
        content
            .simultaneousGesture(drag)
            .onChange(of: touching) { _, isTouching in
                if !isTouching { finish(nil) }
            }
    }

    private var drag: some Gesture {
        DragGesture(minimumDistance: minimumDistance)
            .updating($touching) { _, state, _ in state = true }
            .onChanged { value in
                switch phase {
                case .rejected:
                    return
                case .idle:
                    let dx: CGFloat = value.translation.width
                    let dy: CGFloat = value.translation.height
                    guard value.startLocation.y <= startZone, dy > 0, dy > abs(dx) else {
                        phase = .rejected
                        return
                    }
                    phase = .engaged
                case .engaged:
                    break
                }
                onChanged(value)
            }
            .onEnded { value in finish(value) }
    }

    private func finish(_ value: DragGesture.Value?) {
        let wasEngaged = phase == .engaged
        phase = .idle
        if wasEngaged { onEnded(value) }
    }
}

extension View {
    /// Downward-only pull for pull-to-refresh demos: engages on a mostly downward drag that starts within
    /// `startZone` pt of the top, lets every other swipe scroll the page, and reports cancellation as `onEnded(nil)`.
    /// Translations are measured from the touch-down point, like a plain `DragGesture`.
    func pageSafePullDown(
        minimumDistance: CGFloat = 6,
        startZone: CGFloat = 120,
        onChanged: @escaping (DragGesture.Value) -> Void,
        onEnded: @escaping (DragGesture.Value?) -> Void
    ) -> some View {
        modifier(PageSafePullDownModifier(minimumDistance: minimumDistance, startZone: startZone, onChanged: onChanged, onEnded: onEnded))
    }
}
