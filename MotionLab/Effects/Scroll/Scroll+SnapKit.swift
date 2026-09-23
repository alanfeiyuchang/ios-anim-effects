import SwiftUI

/// Snaps the resting scroll offset to whole multiples of `pitch` along one axis.
/// Used with plain spacer padding so that at offset `i * pitch`, item `i` is exactly centered.
struct ScrollStrideSnap: ScrollTargetBehavior {
    let pitch: CGFloat
    var axis: Axis = .horizontal

    func updateTarget(_ target: inout ScrollTarget, context: TargetContext) {
        guard pitch > 0 else { return }
        switch axis {
        case .horizontal:
            target.rect.origin.x = (target.rect.minX / pitch).rounded() * pitch
        case .vertical:
            target.rect.origin.y = (target.rect.minY / pitch).rounded() * pitch
        }
    }
}
