import SwiftUI

extension Effect {
    static let feedbackSpotlight = Effect(
        id: "feedback.coach-spotlight",
        category: .feedback,
        interaction: .tap,
        name: L("Coach-Mark Spotlight", "引导聚光灯"),
        summary: L("A dimmed overlay with a pulsing cut-out that glides between features.", "暗色遮罩上的镂空光圈脉动，在功能点之间滑行。"),
        prompt: L(
            "An onboarding overlay dims a mock app screen with 55% black, leaving a circular cut-out around the current target (22 pt radius for toolbar icons, 34 pt for the floating action button) outlined by a crisp white hairline. Two soft white rings continuously pulse outward from the cut-out edge by 16 pt and fade every 1.4 s to draw the eye. A rounded tooltip with a title, a step counter and a 'Next' action sits beside the hole. Advancing glides the hole's center and radius together with the tooltip on a single spring (response 0.55 s, damping 0.78), so the light appears to slide across the interface. Guiding, gentle, never pushy.",
            "新手引导遮罩以 55% 黑色压暗一个模拟应用界面，只在当前目标处留出圆形镂空（工具栏图标半径 22 pt，悬浮按钮 34 pt），边缘勾一条清晰的白色细线。两圈柔和的白色光环每 1.4 秒从镂空边缘向外扩散 16 pt 并淡出，持续吸引视线。镂空旁是一枚圆角提示气泡：标题、步骤计数与“下一步”操作。切换步骤时，镂空的圆心与半径连同提示气泡一起沿同一条弹簧（响应 0.55 秒、阻尼 0.78）滑行，仿佛一束光在界面上移动。引导性强、温和、绝不强迫。"
        ),
        implementation: L(
            "An animatable even-odd Shape (rect minus circle) interpolates center and radius via AnimatablePair; a TimelineView draws the pulse rings and the tooltip moves with position().",
            "一个可动画的奇偶填充 Shape（矩形减圆）通过 AnimatablePair 插值圆心与半径；TimelineView 绘制脉冲光环，提示气泡用 position() 移动。"
        ),
        apis: ["Shape", "AnimatablePair", "FillStyle(eoFill:)", "TimelineView", "position(x:y:)"],
        tags: ["onboarding", "coach mark", "spotlight", "tooltip", "新手引导", "聚光灯", "提示", "镂空"],
        params: [
            .slider("dim", L("Dim", "遮罩浓度"), 0.2...0.8, default: 0.55),
            .slider("response", L("Spring response", "弹簧响应"), 0.3...1.0, default: 0.55, unit: "s"),
            .toggle("pulse", L("Pulse rings", "脉冲光环"), default: true),
        ]
    ) { ctx in
        SpotlightDemo(ctx: ctx)
    }
}

private struct SpotlightStep {
    let center: CGPoint
    let radius: CGFloat
    let title: LocalizedText
    let tooltipBelow: Bool
}

private enum SpotlightLayout {
    static let size = CGSize(width: 300, height: 260)
    static let steps: [SpotlightStep] = [
        SpotlightStep(center: CGPoint(x: 196, y: 34), radius: 22, title: L("Share with your team", "与团队分享"), tooltipBelow: true),
        SpotlightStep(center: CGPoint(x: 236, y: 34), radius: 22, title: L("Save to favorites", "加入收藏"), tooltipBelow: true),
        SpotlightStep(center: CGPoint(x: 256, y: 216), radius: 34, title: L("Create something new", "开始新的创作"), tooltipBelow: false),
    ]
}

private struct SpotlightDemo: View {
    let ctx: DemoContext
    @State private var step = 0

    var body: some View {
        let current = SpotlightLayout.steps[step % SpotlightLayout.steps.count]
        VStack(spacing: 16) {
            ZStack {
                SpotlightMockScreen()
                SpotlightHole(center: current.center, radius: current.radius)
                    .fill(Color.black.opacity(ctx["dim"]), style: FillStyle(eoFill: true))
                Circle()
                    .strokeBorder(Color.white.opacity(0.9), lineWidth: 1.5)
                    .frame(width: current.radius * 2, height: current.radius * 2)
                    .position(current.center)
                if ctx.bool("pulse") {
                    SpotlightPulse(radius: current.radius)
                        .position(current.center)
                }
                SpotlightTooltip(title: current.title, index: step % SpotlightLayout.steps.count, total: SpotlightLayout.steps.count, language: ctx.language)
                    .position(tooltipPosition(for: current))
            }
            .frame(width: SpotlightLayout.size.width, height: SpotlightLayout.size.height)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay { RoundedRectangle(cornerRadius: 24, style: .continuous).strokeBorder(Palette.stroke) }
            .shadow(color: .black.opacity(0.12), radius: 18, y: 10)
            .contentShape(Rectangle())
            .onTapGesture { advance() }
            DemoHint(text: L("Tap to go to the next tip", "点击进入下一条提示"), ctx: ctx)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 1.8, delay: 1.0) { advance() }
    }

    private func tooltipPosition(for step: SpotlightStep) -> CGPoint {
        let x = min(max(step.center.x, 100), SpotlightLayout.size.width - 100)
        let offset = step.radius + 42
        let y = step.tooltipBelow ? step.center.y + offset : step.center.y - offset
        return CGPoint(x: x, y: y)
    }

    private func advance() {
        if !ctx.isPreview { Haptics.selection() }
        withAnimation(.spring(response: ctx["response"], dampingFraction: 0.78)) { step += 1 }
    }
}

private struct SpotlightHole: Shape {
    var center: CGPoint
    var radius: CGFloat

    var animatableData: AnimatablePair<AnimatablePair<CGFloat, CGFloat>, CGFloat> {
        get { AnimatablePair(AnimatablePair(center.x, center.y), radius) }
        set {
            center = CGPoint(x: newValue.first.first, y: newValue.first.second)
            radius = newValue.second
        }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path(rect)
        path.addEllipse(in: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2))
        return path
    }
}

private struct SpotlightPulse: View {
    let radius: CGFloat

    var body: some View {
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            ZStack {
                ForEach(0..<2, id: \.self) { index in
                    let age = (t / 1.4 + Double(index) * 0.5).truncatingRemainder(dividingBy: 1)
                    let side = (radius + 16 * CGFloat(age)) * 2
                    Circle()
                        .stroke(Color.white.opacity(0.7 * (1 - age)), lineWidth: 2)
                        .frame(width: side, height: side)
                }
            }
        }
        .frame(width: (radius + 18) * 2, height: (radius + 18) * 2)
        .allowsHitTesting(false)
    }
}

private struct SpotlightTooltip: View {
    let title: LocalizedText
    let index: Int
    let total: Int
    let language: AppLanguage

    var body: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title, language)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                Text("\(index + 1) / \(total)")
                    .font(.caption2.weight(.medium).monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            Text(language == .zh ? "下一步" : "Next")
                .font(.caption.weight(.bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Palette.primary, in: Capsule())
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(Palette.elevated, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: .black.opacity(0.25), radius: 12, y: 6)
        .fixedSize()
    }
}

private struct SpotlightMockScreen: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 18) {
                Text("Library")
                    .font(.title3.weight(.bold))
                Spacer()
                Image(systemName: "square.and.arrow.up")
                    .frame(width: 22)
                Image(systemName: "heart")
                    .frame(width: 22)
                Image(systemName: "ellipsis")
                    .frame(width: 22)
            }
            .font(.body.weight(.semibold))
            .foregroundStyle(Palette.indigo)
            .frame(height: 44)
            HStack(spacing: 10) {
                RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Palette.aurora)
                RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Palette.sunset)
            }
            .frame(height: 96)
            PlaceholderLines(count: 3)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .frame(width: SpotlightLayout.size.width, height: SpotlightLayout.size.height)
        .background(Palette.elevated)
        .overlay(alignment: .bottomTrailing) {
            Image(systemName: "plus")
                .font(.title2.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(Palette.primary, in: Circle())
                .shadow(color: Palette.indigo.opacity(0.35), radius: 10, y: 5)
                .position(x: 256, y: 216)
        }
    }
}
