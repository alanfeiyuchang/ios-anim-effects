import SwiftUI

/// A horizontal drag for Navigation and Morph demos that never traps the detail page's vertical scroll and never
/// leaves a demo stuck mid-drag (the round-3 pattern from `BackgroundsTouchModifier`):
/// - it is attached *simultaneously*, so the page's scroll view keeps vertical swipes;
/// - it only engages after `minimumDistance` of mostly horizontal travel (then follows the finger in any direction);
/// - a `@GestureState` flag also resets on system cancellation (scroll takeover, Control Center pull, multi-touch),
///   so `onEnded` runs exactly once per engaged drag: with the final value on a normal release, or `nil` when the
///   system cancelled the drag (settle from the current state then, without a flick).
private struct PageSafeHorizontalDragModifier: ViewModifier {
    let minimumDistance: CGFloat
    let onChanged: (DragGesture.Value) -> Void
    let onEnded: (DragGesture.Value?) -> Void
    @State private var engaged = false
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
                if !engaged {
                    guard abs(value.translation.width) > abs(value.translation.height) else { return }
                    engaged = true
                }
                onChanged(value)
            }
            .onEnded { value in finish(value) }
    }

    private func finish(_ value: DragGesture.Value?) {
        guard engaged else { return }
        engaged = false
        onEnded(value)
    }
}

extension View {
    /// Horizontal-intent drag that lets vertical swipes scroll the page and reports cancellation as `onEnded(nil)`.
    /// Translations are measured from the touch-down point, like a plain `DragGesture`.
    func pageSafeHorizontalDrag(
        minimumDistance: CGFloat = 10,
        onChanged: @escaping (DragGesture.Value) -> Void,
        onEnded: @escaping (DragGesture.Value?) -> Void
    ) -> some View {
        modifier(PageSafeHorizontalDragModifier(minimumDistance: minimumDistance, onChanged: onChanged, onEnded: onEnded))
    }
}
