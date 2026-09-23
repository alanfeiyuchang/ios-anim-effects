import Foundation

/// Families (variation groups) of `EffectCategory.gestures`.
///
/// To add a variation: append the effect to `GestureEffects.all`, then add one
/// `"<effect id>": "<family id>",` line to `membership` below. Each effect id may appear only once
/// (a duplicate dictionary key traps at launch). See docs/FAMILIES.md.
enum GesturesFamilies {
    static let all: [EffectFamily] = [
        EffectFamily(
            id: "gestures.drag-spring",
            category: .gestures,
            name: L("Drag & Spring", "拖拽与弹簧"),
            summary: L("Objects that resist, stretch, trail and snap back while dragged.", "拖动时产生阻力、拉伸、拖尾并回弹的物体。"),
            symbol: "hand.draw.fill"
        ),
        EffectFamily(
            id: "gestures.throw",
            category: .gestures,
            name: L("Throw & Snap", "抛掷与吸附"),
            summary: L("Flick with velocity: glide, bounce off walls, snap to corners or dismiss.", "带速度甩出：滑行、撞墙反弹、吸附角落或关闭。"),
            symbol: "arrow.up.forward.circle.fill"
        ),
        EffectFamily(
            id: "gestures.physics",
            category: .gestures,
            name: L("Physics Toys", "物理模拟"),
            summary: L("Simulated ropes, pendulums and charge-ups you can play with.", "可以把玩的绳索、摆球与蓄力模拟。"),
            symbol: "atom"
        ),
        EffectFamily(
            id: "gestures.list",
            category: .gestures,
            name: L("List Gestures", "列表手势"),
            summary: L("Swipe actions and drag-to-reorder on list rows.", "列表行上的左滑操作与拖拽排序。"),
            symbol: "arrow.up.arrow.down"
        ),
        EffectFamily(
            id: "gestures.pinch",
            category: .gestures,
            name: L("Pinch, Zoom & Loupe", "捏合缩放与放大镜"),
            summary: L("Two-finger zoom, rotate and magnify with soft limits.", "带柔性边界的双指缩放、旋转与放大。"),
            symbol: "plus.magnifyingglass"
        ),
        EffectFamily(
            id: "gestures.slide-confirm",
            category: .gestures,
            name: L("Slide to Confirm", "滑动确认"),
            summary: L("Tracks whose knob must travel the full length to commit.", "需把滑块拖到尽头才会执行的确认轨道。"),
            symbol: "chevron.right.2"
        ),
    ]

    static let membership: [String: String] = [
        // Drag & spring
        "gestures.rubber-band": "gestures.drag-spring",
        "gestures.jelly-stretch": "gestures.drag-spring",
        "gestures.spring-chain": "gestures.drag-spring",
        "gestures.gooey-blobs": "gestures.drag-spring",
        // Throw & snap
        "gestures.fling-inertia": "gestures.throw",
        "gestures.pip-snap": "gestures.throw",
        "gestures.drag-dismiss": "gestures.throw",
        // Physics toys
        "gestures.charge-burst": "gestures.physics",
        "gestures.verlet-rope": "gestures.physics",
        "gestures.newtons-cradle": "gestures.physics",
        // List gestures
        "gestures.swipe-actions": "gestures.list",
        "gestures.drag-reorder": "gestures.list",
        // Pinch, zoom & loupe
        "gestures.pinch-rotate": "gestures.pinch",
        "gestures.magnifier-loupe": "gestures.pinch",
        "gestures.photo-viewer": "gestures.pinch",
        // Slide to confirm
        "gestures.slide-to-confirm": "gestures.slide-confirm",
    ]
}
