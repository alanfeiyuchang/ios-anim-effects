import SwiftUI
import UIKit

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

/// Directions a `PageSafePan` may begin in (the dominant axis and sign of the drag's first movement).
struct PageSafePanDirections: OptionSet {
    let rawValue: Int
    static let down = PageSafePanDirections(rawValue: 1 << 0)
    static let up = PageSafePanDirections(rawValue: 1 << 1)
    static let right = PageSafePanDirections(rawValue: 1 << 2)
    static let left = PageSafePanDirections(rawValue: 1 << 3)
}

/// How a `PageSafePan` ended normally: the translation since it began and the finger's velocity (pt/s).
struct PageSafePanEnd {
    let translation: CGSize
    let velocity: CGSize

    /// Where a flick would carry the translation, like `DragGesture.Value.predictedEndTranslation`.
    var predictedEndTranslation: CGSize {
        CGSize(width: translation.width + velocity.width * 0.25, height: translation.height + velocity.height * 0.25)
    }
}

/// A UIKit pan bridged with iOS 18's `UIGestureRecognizerRepresentable`, for drags that share an axis with the
/// detail page's scroll (a vertical pull) and so can't use `pageSafeHorizontalDrag`:
/// - it only begins when the drag's first movement heads mostly in one of `directions`; any other swipe fails it at
///   once and the page scrolls as usual;
/// - once it begins, every enclosing scroll view's pan waits for it to fail, so the page never moves along with it;
/// - `onChanged` gets the translation since the pan began (from zero, without the ~10 pt start-up hysteresis);
/// - `onEnded` runs exactly once per begun pan: with the final values on release, or `nil` when the system
///   cancelled it (settle from the current state then, without a flick).
/// `isEnabled == false` disables the recognizer, so it never delays the page's scroll.
/// `onBegan`, when set, gets the touch-down point in the modified view's local space just before the first
/// `onChanged` (e.g. to anchor a scale at the grabbed point).
struct PageSafePan: UIGestureRecognizerRepresentable {
    var directions: PageSafePanDirections
    var isEnabled: Bool = true
    let onChanged: (CGSize) -> Void
    let onEnded: (PageSafePanEnd?) -> Void
    var onBegan: ((CGPoint) -> Void)? = nil

    func makeCoordinator(converter: CoordinateSpaceConverter) -> PageSafePanCoordinator {
        PageSafePanCoordinator(directions: directions)
    }

    func makeUIGestureRecognizer(context: Context) -> UIPanGestureRecognizer {
        let pan = UIPanGestureRecognizer()
        pan.maximumNumberOfTouches = 1
        pan.delegate = context.coordinator
        pan.isEnabled = isEnabled
        return pan
    }

    func updateUIGestureRecognizer(_ recognizer: UIPanGestureRecognizer, context: Context) {
        context.coordinator.directions = directions
        if recognizer.isEnabled != isEnabled { recognizer.isEnabled = isEnabled }
    }

    func handleUIGestureRecognizerAction(_ recognizer: UIPanGestureRecognizer, context: Context) {
        let coordinator = context.coordinator
        switch recognizer.state {
        case .began:
            if let onBegan {
                // The pan begins after a few points of travel; step back to where the finger first touched.
                let location: CGPoint = context.converter.location(in: .local)
                let travel: CGPoint = recognizer.translation(in: recognizer.view)
                onBegan(CGPoint(x: location.x - travel.x, y: location.y - travel.y))
            }
            recognizer.setTranslation(.zero, in: recognizer.view)
            coordinator.engaged = true
            onChanged(.zero)
        case .changed:
            guard coordinator.engaged else { return }
            let t = recognizer.translation(in: recognizer.view)
            onChanged(CGSize(width: t.x, height: t.y))
        case .ended:
            guard coordinator.engaged else { return }
            coordinator.engaged = false
            let t = recognizer.translation(in: recognizer.view)
            let v = recognizer.velocity(in: recognizer.view)
            onEnded(PageSafePanEnd(translation: CGSize(width: t.x, height: t.y), velocity: CGSize(width: v.x, height: v.y)))
        case .cancelled, .failed:
            guard coordinator.engaged else { return }
            coordinator.engaged = false
            onEnded(nil)
        default:
            break
        }
    }
}

/// Delegate of `PageSafePan`: the direction test and the page-scroll failure requirement.
@MainActor
final class PageSafePanCoordinator: NSObject, UIGestureRecognizerDelegate {
    var directions: PageSafePanDirections
    /// True between `.began` and the matching end, so `onEnded` runs once per pan.
    var engaged = false

    init(directions: PageSafePanDirections) {
        self.directions = directions
    }

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let pan = gestureRecognizer as? UIPanGestureRecognizer else { return true }
        let velocity = pan.velocity(in: pan.view)
        let translation = pan.translation(in: pan.view)
        // Velocity says where the finger is heading now; a very slow drag falls back to the travel so far.
        let d = abs(velocity.x) + abs(velocity.y) > 20 ? velocity : translation
        let vertical = abs(d.y) > abs(d.x)
        if directions.contains(.down) && vertical && d.y > 0 { return true }
        if directions.contains(.up) && vertical && d.y < 0 { return true }
        if directions.contains(.right) && !vertical && d.x > 0 {
            // A rightward swipe that starts at the window's left edge belongs to the navigation stack's
            // interactive pop, so leave it to that edge pan.
            let startX: CGFloat = pan.location(in: nil).x - translation.x
            return startX > 24
        }
        if directions.contains(.left) && !vertical && d.x < 0 { return true }
        return false
    }

    /// Enclosing scroll views' pans wait for this one to fail.
    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        guard let scrollView = otherGestureRecognizer.view as? UIScrollView else { return false }
        return otherGestureRecognizer === scrollView.panGestureRecognizer
    }

    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        false
    }
}

/// Faint screen content for tab-bar demos in grid previews and still thumbnails, so a thumbnail reads as an app
/// screen rather than a lone bar on a blank stage. Demos show it only when `ctx.isPreview || ctx.isStill`; the
/// detail stage is unchanged. It never takes touches.
struct NavigationScreenPlaceholder: View {
    var rows: Int = 3
    var showsTitle: Bool = true

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if showsTitle {
                Capsule()
                    .fill(Color.primary.opacity(0.14))
                    .frame(width: 120, height: 12)
                    .padding(.leading, 4)
            }
            ForEach(0..<rows, id: \.self) { _ in
                row
            }
        }
        .frame(width: 290)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private var row: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .fill(Color.primary.opacity(0.08))
                .frame(width: 28, height: 28)
            PlaceholderLines(count: 2, color: Color.primary.opacity(0.08))
        }
        .padding(.horizontal, 10)
        .frame(height: 44)
        .background(Color.primary.opacity(0.035), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}
