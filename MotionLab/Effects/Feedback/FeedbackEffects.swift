enum FeedbackEffects {
    static let all: [Effect] = [
        .feedbackToast,
        .feedbackSuccessCheck,
        .feedbackErrorShake,
        .feedbackInlineValidation,
        .feedbackConfetti,
        .feedbackIsland,
        .feedbackConnectionBanner,
        .feedbackBadgeBounce,
        .feedbackUndoSnackbar,
        .feedbackAlertPop,
        .feedbackStackedBanners,
        .feedbackSpotlight,
        .feedbackCopy,
        .feedbackReactionPicker,
        .feedbackPullRefresh,
        // Toast variations
        .feedbackHingeToast,
        .feedbackMorphToast,
        // Success variations
        .feedbackSparkBurst,
        .feedbackLevelUp,
        // Error variations
        .feedbackJellyDeny,
        .feedbackLimitBounce,
        .feedbackFaceIDFail,
        // Badge variations
        .feedbackCartFly,
        .feedbackPresencePing,
        .feedbackFloatingHearts,
        // Overlay variations
        .feedbackRecedingSheet,
        .feedbackTipPopover,
        .feedbackDropAlert,
        // Refresh variations
        .feedbackGooRefresh,
        .feedbackSunRefresh,
        .feedbackLetterRefresh,
        .feedbackDotsRefresh,
    ]
}
