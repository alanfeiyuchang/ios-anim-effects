import SwiftUI
import UIKit
import UIKit.UIGestureRecognizerSubclass

/// Reports every finger that lands on the modified view without taking part in gesture handling:
/// the recognizer fails as soon as it sees the touch, never delays or cancels touches, and runs
/// alongside every other recognizer, so buttons, drags and the page's scroll behave exactly as before.
struct TouchDownObserver: UIGestureRecognizerRepresentable {
    let onTouchDown: () -> Void

    func makeCoordinator(converter: CoordinateSpaceConverter) -> TouchDownObserverCoordinator {
        TouchDownObserverCoordinator()
    }

    func makeUIGestureRecognizer(context: Context) -> TouchDownRecognizer {
        let recognizer = TouchDownRecognizer()
        recognizer.cancelsTouchesInView = false
        recognizer.delaysTouchesBegan = false
        recognizer.delaysTouchesEnded = false
        recognizer.delegate = context.coordinator
        recognizer.onTouchDown = onTouchDown
        return recognizer
    }

    func updateUIGestureRecognizer(_ recognizer: TouchDownRecognizer, context: Context) {
        recognizer.onTouchDown = onTouchDown
    }
}

final class TouchDownRecognizer: UIGestureRecognizer {
    var onTouchDown: (() -> Void)?

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        onTouchDown?()
        state = .failed
    }
}

@MainActor
final class TouchDownObserverCoordinator: NSObject, UIGestureRecognizerDelegate {
    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        true
    }
}
