import Foundation

/// Families (variation groups) of `EffectCategory.feedback`.
///
/// To add a variation: append the effect to `FeedbackEffects.all`, then add one
/// `"<effect id>": "<family id>",` line to `membership` below. Each effect id may appear only once
/// (a duplicate dictionary key traps at launch). See docs/FAMILIES.md.
enum FeedbackFamilies {
    static let all: [EffectFamily] = [
        EffectFamily(
            id: "feedback.toast",
            category: .feedback,
            name: L("Toasts & Banners", "吐司与横幅"),
            summary: L("Transient messages that slide, blur or stretch in and politely leave.", "滑入、模糊浮现或伸展出现、再礼貌退场的临时消息。"),
            symbol: "text.bubble.fill"
        ),
        EffectFamily(
            id: "feedback.success",
            category: .feedback,
            name: L("Success", "成功反馈"),
            summary: L("Checks, confirmations and celebrations for a job well done.", "对勾、确认与庆祝：告诉用户“完成了”。"),
            symbol: "checkmark.seal.fill"
        ),
        EffectFamily(
            id: "feedback.error",
            category: .feedback,
            name: L("Errors & Validation", "错误与校验"),
            summary: L("Shakes, hints and color shifts that say 'not quite'.", "以抖动、提示与颜色变化表达“还不对”。"),
            symbol: "exclamationmark.triangle.fill"
        ),
        EffectFamily(
            id: "feedback.badge",
            category: .feedback,
            name: L("Badges & Reactions", "角标与回应"),
            summary: L("Counters and emoji reactions that hop, roll and fly into place.", "跳动、滚动并飞到位的计数角标与表情回应。"),
            symbol: "app.badge.fill"
        ),
        EffectFamily(
            id: "feedback.overlay",
            category: .feedback,
            name: L("Alerts & Overlays", "弹窗与引导"),
            summary: L("Modal alerts and coach marks that dim, blur and spotlight.", "变暗、模糊背景并聚焦的弹窗与引导层。"),
            symbol: "rectangle.on.rectangle"
        ),
        EffectFamily(
            id: "feedback.refresh",
            category: .feedback,
            name: L("Pull to Refresh", "下拉刷新"),
            summary: L("Custom refresh indicators driven by the pull distance.", "由下拉距离驱动的自定义刷新指示器。"),
            symbol: "arrow.clockwise"
        ),
    ]

    static let membership: [String: String] = [
        // Toasts & banners
        "feedback.toast": "feedback.toast",
        "feedback.island-pill": "feedback.toast",
        "feedback.connection-banner": "feedback.toast",
        "feedback.undo-snackbar": "feedback.toast",
        "feedback.stacked-banners": "feedback.toast",
        "feedback.hinge-toast": "feedback.toast",
        "feedback.morph-toast": "feedback.toast",
        // Success
        "feedback.success-check": "feedback.success",
        "feedback.confetti": "feedback.success",
        "feedback.copy-confirm": "feedback.success",
        "feedback.spark-burst": "feedback.success",
        "feedback.level-up": "feedback.success",
        // Errors & validation
        "feedback.error-shake": "feedback.error",
        "feedback.inline-validation": "feedback.error",
        "feedback.jelly-deny": "feedback.error",
        "feedback.limit-bounce": "feedback.error",
        "feedback.faceid-fail": "feedback.error",
        // Badges & reactions
        "feedback.badge-bounce": "feedback.badge",
        "feedback.reaction-picker": "feedback.badge",
        "feedback.cart-fly": "feedback.badge",
        "feedback.presence-ping": "feedback.badge",
        "feedback.floating-hearts": "feedback.badge",
        // Alerts & overlays
        "feedback.alert-pop": "feedback.overlay",
        "feedback.coach-spotlight": "feedback.overlay",
        "feedback.receding-sheet": "feedback.overlay",
        "feedback.tip-popover": "feedback.overlay",
        "feedback.drop-alert": "feedback.overlay",
        // Pull to refresh
        "feedback.pull-refresh": "feedback.refresh",
        "feedback.goo-refresh": "feedback.refresh",
        "feedback.sun-refresh": "feedback.refresh",
        "feedback.letter-refresh": "feedback.refresh",
        "feedback.dots-refresh": "feedback.refresh",
    ]
}
