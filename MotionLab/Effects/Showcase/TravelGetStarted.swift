import SwiftUI

extension Effect {
    static let showcaseGetStarted = Effect(
        id: "showcase.get-started",
        category: .showcase,
        interaction: .tap,
        name: L("Get Started Pill", "开始按钮展开"),
        summary: L(
            "A shimmering onboarding pill with a nudging arrow squashes on press, then blooms into a full-width sheet.",
            "带流光文字和跃动箭头的引导胶囊，按下先挤压，再舒展成通栏面板。"
        ),
        prompt: L(
            "An onboarding screen over a golden-hour mountain photo ends in a cream “Get Started” pill (56 pt tall) with a lime circular arrow badge. At rest, an orange highlight band sweeps across the label every 2.2 s, and the arrow nudges 6 pt to the right on a loop (ease-out push, springy return). The instant a finger touches down, the pill squashes like jelly (x 108%, y 95%) on a quick ~160 ms spring and holds while pressed; on release its background morphs via shared geometry into a full-width rounded sheet on a spring (response 0.5 s, damping 0.78). The title flies into the sheet header while the photo behind scales to 106%, blurs 6 pt and dims 15%. The sheet’s fields fade and rise 10 pt one after another at 50 ms intervals. A medium haptic confirms the press. It feels eager, elastic and welcoming.",
            "引导页以金色时刻雪山照为背景，底部是 56pt 高的奶油白“立即开始”胶囊，带青柠色圆形箭头徽章。静止时橙色高光每 2.2 秒扫过文字，箭头循环右推 6pt。按下瞬间，胶囊以约 160 毫秒快速弹簧像果冻般挤压（横 108%、纵 95%）并保持；松手后背景借共享几何以弹簧（响应 0.5 秒、阻尼 0.78）变形为通栏圆角面板，标题飞入面板顶部，背后照片放大到 106%、模糊 6pt、压暗 15%，面板内容相隔 50 毫秒依次淡入上移 10pt。按下一次中等触感。"
        ),
        implementation: L(
            "A custom ButtonStyle squashes the pill from configuration.isPressed on touch-down; the release action runs a withAnimation(_:completion:) chain — the matchedGeometryEffect morph from pill to sheet, then the staggered body reveal. The shimmer is a TimelineView-driven gradient masked by the label, and the arrow uses phaseAnimator.",
            "自定义 ButtonStyle 读取 configuration.isPressed，在按下瞬间挤压胶囊；松手后的动作用 withAnimation(_:completion:) 串联：先由 matchedGeometryEffect 把胶囊变形为面板，再错峰显示面板内容。流光是 TimelineView 驱动、以文字为遮罩的渐变，箭头使用 phaseAnimator。"
        ),
        apis: ["ButtonStyle", "matchedGeometryEffect", "withAnimation(_:completion:)", "phaseAnimator", "TimelineView"],
        tags: ["onboarding", "get started", "shimmer", "expand", "引导页", "开始", "流光", "展开"],
        params: [
            .slider("stretch", L("Squash amount", "挤压幅度"), 0...0.2, default: 0.08),
            .slider("response", L("Spring response", "弹簧响应"), 0.3...0.9, default: 0.5, unit: "s"),
            .slider("damping", L("Damping", "阻尼"), 0.5...1, default: 0.78),
            .toggle("shimmer", L("Label shimmer", "文字流光"), default: true),
        ]
    ) { ctx in
        TravelGetStartedDemo(ctx: ctx)
    }
}

// MARK: - Demo

private struct TravelGetStartedDemo: View {
    let ctx: DemoContext
    @Namespace private var ns
    @State private var squeezed = false
    @State private var expanded = false
    @State private var showBody = false
    /// Detail intro: morphs open, then closes the sheet again so the stage doesn't stay covered.
    @State private var introTask: Task<Void, Never>?

    private var zh: Bool { ctx.language == .zh }
    private var spring: Animation { .spring(response: ctx["response"], dampingFraction: ctx["damping"]) }

    var body: some View {
        SignatureStage {
            VStack(spacing: 12) {
                stageCard
                DemoHint(text: L("Tap Get Started, then ✕ to close", "点击「立即开始」，再点 ✕ 收起"), ctx: ctx)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .autoplay(ctx.isPreview, every: 2.4) {
            if ctx.isPreview { toggle() } else { playIntro() }
        }
        .onDisappear { cancelIntro() }
    }

    private var stageCard: some View {
        ZStack(alignment: .bottom) {
            TravelOnboardingBackdrop(zh: zh, dimmed: expanded)
            if expanded {
                TravelStartSheet(ns: ns, zh: zh, showBody: showBody, onClose: userToggle)
                    .padding(12)
            } else {
                TravelStartPill(
                    ns: ns,
                    zh: zh,
                    stretch: ctx.cg("stretch"),
                    squeezed: squeezed,
                    shimmer: ctx.bool("shimmer"),
                    preview: ctx.isPreview,
                    onTap: userExpand
                )
                .padding(.bottom, 24)
            }
        }
        .frame(width: 300, height: 320)
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .signatureCard(cornerRadius: 30)
    }

    /// Autoplay path: simulate the touch-down squash, then release into the morph.
    private func toggle() {
        // Captured now: autoplay (and the detail intro) mute haptics only for the synchronous part.
        let muted = Haptics.isMuted
        if expanded {
            if !ctx.isPreview && !muted { Haptics.tap() }
            collapse()
        } else {
            withAnimation(.spring(response: 0.16, dampingFraction: 0.7)) {
                squeezed = true
            } completion: {
                morph(silent: muted)
            }
        }
    }

    private func collapse() {
        withAnimation(.easeOut(duration: 0.12)) {
            showBody = false
        } completion: {
            withAnimation(spring) { expanded = false }
        }
    }

    private func userToggle() {
        cancelIntro()
        toggle()
    }

    private func userExpand() {
        cancelIntro()
        expand()
    }

    /// Detail intro: the full squash → morph → sheet run, then a silent close.
    private func playIntro() {
        cancelIntro()
        if !expanded { toggle() }
        introTask = Task {
            try? await Task.sleep(for: .seconds(2.6))
            guard !Task.isCancelled else { return }
            if expanded { collapse() }
            introTask = nil
        }
    }

    private func cancelIntro() {
        introTask?.cancel()
        introTask = nil
    }

    /// Release: the ButtonStyle already squashed on touch-down, so morph straight away.
    private func expand() {
        morph(silent: false)
    }

    private func morph(silent: Bool) {
        guard !expanded else { return }
        if !ctx.isPreview && !silent { Haptics.tap(.medium) }
        withAnimation(spring) {
            squeezed = false
            expanded = true
        } completion: {
            withAnimation(.easeOut(duration: 0.3)) { showBody = true }
        }
    }
}

// MARK: - Backdrop

private struct TravelOnboardingBackdrop: View {
    let zh: Bool
    let dimmed: Bool

    var body: some View {
        ZStack(alignment: .topLeading) {
            LandscapeArt(seed: 0)
            LinearGradient(colors: [.clear, Color.black.opacity(0.88)], startPoint: .top, endPoint: .bottom)
            VStack(alignment: .leading, spacing: 8) {
                Text(zh ? "旅行 · 2026" : "Travel · 2026")
                    .signatureEyebrow()
                Spacer(minLength: 0)
                Text(zh ? "探索世界，\n按你的方式" : "Explore the world,\nyour way")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.white)
                Text(zh ? "规划路线、收藏灵感、随时出发。" : "Plan routes, save spots, go anytime.")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.65))
            }
            .padding(22)
            .padding(.bottom, 84)
        }
        .scaleEffect(dimmed ? 1.06 : 1)
        .blur(radius: dimmed ? 6 : 0)
        .brightness(dimmed ? -0.15 : 0)
    }
}

// MARK: - Pill

private struct TravelStartPill: View {
    let ns: Namespace.ID
    let zh: Bool
    let stretch: CGFloat
    let squeezed: Bool
    let shimmer: Bool
    let preview: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                TravelShimmerLabel(text: zh ? "立即开始" : "Get Started", active: shimmer, preview: preview)
                    .matchedGeometryEffect(id: "title", in: ns)
                TravelArrowBadge()
            }
            .padding(.leading, 26)
            .padding(.trailing, 6)
            .frame(height: 56)
            .background {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(Signature.paper)
                    .matchedGeometryEffect(id: "sheet", in: ns)
                    .shadow(color: Signature.accent.opacity(0.35), radius: 18, y: 8)
            }
        }
        .buttonStyle(TravelSquashStyle(stretch: stretch, forced: squeezed))
    }
}

/// Jelly squash on touch-down (x grows, y shrinks), sprung back on release. `forced` lets autoplay simulate a press.
private struct TravelSquashStyle: ButtonStyle {
    let stretch: CGFloat
    let forced: Bool

    func makeBody(configuration: Configuration) -> some View {
        let down = configuration.isPressed || forced
        return configuration.label
            .scaleEffect(x: down ? 1 + stretch : 1, y: down ? 1 - stretch * 0.6 : 1)
            .animation(.spring(response: 0.16, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

private struct TravelShimmerLabel: View {
    let text: String
    let active: Bool
    let preview: Bool

    var body: some View {
        let label = Text(text).font(.system(size: 17, weight: .bold, design: .rounded))
        label
            .foregroundStyle(Signature.ink)
            .overlay {
                if active {
                    TimelineView(.animation(minimumInterval: MotionFrameRate.interval(preview: preview))) { timeline in
                        let t = timeline.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 2.2) / 2.2
                        let x = CGFloat(-0.4 + 1.8 * t)
                        LinearGradient(
                            colors: [.clear, Signature.accent, .clear],
                            startPoint: UnitPoint(x: x - 0.3, y: 0.5),
                            endPoint: UnitPoint(x: x + 0.3, y: 0.5)
                        )
                    }
                    .mask { label }
                }
            }
    }
}

private struct TravelArrowBadge: View {
    var body: some View {
        Image(systemName: "arrow.right")
            .font(.system(size: 16, weight: .bold))
            .foregroundStyle(Color.black)
            .phaseAnimator([false, true]) { content, nudged in
                content.offset(x: nudged ? 4 : -2)
            } animation: { nudged in
                nudged ? Animation.easeOut(duration: 0.35) : Animation.spring(response: 0.5, dampingFraction: 0.55)
            }
            .frame(width: 44, height: 44)
            .background(Signature.lime, in: Circle())
    }
}

// MARK: - Sheet

private struct TravelStartSheet: View {
    let ns: Namespace.ID
    let zh: Bool
    let showBody: Bool
    let onClose: () -> Void

    private var fields: [(String, String)] {
        zh
            ? [("magnifyingglass", "想去哪里？"), ("calendar", "7月8日 – 7月12日"), ("person.2.fill", "2 位旅客")]
            : [("magnifyingglass", "Where to?"), ("calendar", "Jul 8 – Jul 12"), ("person.2.fill", "2 travelers")]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            ForEach(Array(fields.enumerated()), id: \.offset) { index, field in
                TravelSheetField(symbol: field.0, title: field.1)
                    .opacity(showBody ? 1 : 0)
                    .offset(y: showBody ? 0 : 10)
                    .animation(.spring(response: 0.4, dampingFraction: 0.8).delay(Double(index) * 0.05), value: showBody)
            }
            cta
                .opacity(showBody ? 1 : 0)
                .offset(y: showBody ? 0 : 10)
                .animation(.spring(response: 0.4, dampingFraction: 0.8).delay(0.15), value: showBody)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Signature.paper)
                .matchedGeometryEffect(id: "sheet", in: ns)
                .shadow(color: Color.black.opacity(0.4), radius: 20, y: 10)
        }
    }

    private var header: some View {
        HStack {
            Text(zh ? "立即开始" : "Get Started")
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundStyle(Signature.ink)
                .matchedGeometryEffect(id: "title", in: ns)
            Spacer(minLength: 0)
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Signature.ink)
                    .frame(width: 26, height: 26)
                    .background(Color.black.opacity(0.08), in: Circle())
            }
            .buttonStyle(.plain)
        }
    }

    private var cta: some View {
        Text(zh ? "开始规划" : "Start planning")
            .font(.system(size: 14, weight: .bold, design: .rounded))
            .foregroundStyle(Color.white)
            .frame(maxWidth: .infinity)
            .frame(height: 42)
            .background(Signature.accentGradient, in: Capsule())
    }
}

private struct TravelSheetField: View {
    let symbol: String
    let title: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: symbol)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Signature.accentHot)
                .frame(width: 18)
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Signature.ink.opacity(0.75))
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .frame(height: 36)
        .background(Color.black.opacity(0.05), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}
