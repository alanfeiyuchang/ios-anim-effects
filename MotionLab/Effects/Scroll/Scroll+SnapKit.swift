import SwiftUI

/// Snaps the resting scroll offset to whole multiples of `stride` along one axis.
/// Used with plain spacer padding so that at offset `i * stride`, item `i` is exactly centered.
struct ScrollStrideSnap: ScrollTargetBehavior {
    let stride: CGFloat
    var axis: Axis = .horizontal

    func updateTarget(_ target: inout ScrollTarget, context: TargetContext) {
        guard stride > 0 else { return }
        switch axis {
        case .horizontal:
            target.rect.origin.x = (target.rect.minX / stride).rounded() * stride
        case .vertical:
            target.rect.origin.y = (target.rect.minY / stride).rounded() * stride
        }
    }
}

/// Linear interpolation used by the scroll variations.
func scrollKitMix(_ a: CGFloat, _ b: CGFloat, _ t: CGFloat) -> CGFloat { a + (b - a) * t }
