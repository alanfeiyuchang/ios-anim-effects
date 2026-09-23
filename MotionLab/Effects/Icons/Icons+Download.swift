import SwiftUI

extension Effect {
    static let iconsDownload = Effect(
        id: "icons.download",
        category: .icons,
        interaction: .tap,
        name: L("Download → Done", "下载 → 完成"),
        summary: L("Arrow becomes a progress ring, then resolves into a check.", "箭头化为进度环，最终变成对勾。"),
        prompt: L(
            "A file row ends in a circular download control. On tap the arrow glyph swaps (replace transition) for a small stop square while a thin track ring appears and a gradient progress arc sweeps clockwise from 12 o'clock, easing in and out over ~2.2 s; the percentage beneath counts up in lock-step with tabular digits. When the arc closes, the ring fills green, the stop icon replaces into a bold checkmark with a bounce and a success haptic, and the caption changes to \"Open\". Tapping mid-download cancels and the arc springs back to zero. Clear, trustworthy state communication.",
            "文件行末尾是一个圆形下载控件。点击后，箭头图标以替换过渡变为小方块停止键，同时出现一圈细轨道环，一段渐变进度弧从 12 点方向顺时针扫过，以缓入缓出在约 2.2 秒内完成；下方百分比以等宽数字同步递增。进度弧闭合时圆环填充为绿色，停止键替换为粗体对勾并轻弹一下，触发成功触感，说明文字变为“打开”。下载途中再次点击即取消，进度弧以弹簧回到零。状态传达清晰、值得信赖。"
        ),
        implementation: L(
            "A state enum drives the glyph (.contentTransition(.symbolEffect(.replace))) and a trimmed Circle; progress animates with withAnimation(_:completion:) and an Animatable percentage label.",
            "状态枚举驱动图标（.contentTransition(.symbolEffect(.replace))）与 trim 的圆环；进度通过 withAnimation(_:completion:) 动画，并配合遵循 Animatable 的百分比标签。"
        ),
        apis: ["withAnimation(_:completionCriteria:_:completion:)", "trim(from:to:)", "contentTransition(.symbolEffect(.replace))", "Animatable"],
        tags: ["download", "progress", "ring", "done", "下载", "进度", "进度环", "完成"],
        params: [
            .slider("duration", L("Download time", "下载时长"), 1...5, default: 2.2, unit: "s"),
            .slider("ring", L("Ring width", "环宽"), 2...8, default: 4, decimals: 0, unit: "pt"),
            .toggle("percent", L("Show percentage", "显示百分比"), default: true),
        ]
    ) { ctx in
        DownloadDemo(ctx: ctx)
    }
}

private enum DownloadState {
    case idle, downloading, done
}

private struct DownloadDemo: View {
    let ctx: DemoContext
    @State private var state: DownloadState = .idle
    @State private var progress: Double = 0
    @State private var run = 0

    var body: some View {
        VStack(spacing: 18) {
            HStack(spacing: 14) {
                Image(systemName: "doc.zipper")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(Palette.blue)
                    .frame(width: 48, height: 48)
                    .background(Palette.blue.opacity(0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                VStack(alignment: .leading, spacing: 3) {
                    Text(L("Design-Assets.zip", "设计素材.zip"), ctx.language)
                        .font(.headline)
                    caption
                }
                Spacer(minLength: 0)
                DownloadButton(state: state, progress: progress, lineWidth: ctx.cg("ring")) { tap() }
            }
            .padding(16)
            .frame(width: 300)
            .demoCard(cornerRadius: 22)
            DemoHint(text: L("Tap the button", "点击按钮"), ctx: ctx)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: ctx["duration"] + 1.4, delay: 0.3) { autoStep() }
    }

    @ViewBuilder
    private var caption: some View {
        switch state {
        case .idle:
            Text(verbatim: "248 MB").font(.subheadline).foregroundStyle(.secondary)
        case .downloading:
            if ctx.bool("percent") {
                PercentLabel(progress: progress)
            } else {
                Text(L("Downloading…", "下载中…"), ctx.language).font(.subheadline).foregroundStyle(.secondary)
            }
        case .done:
            Text(L("Ready · Open", "已完成 · 打开"), ctx.language).font(.subheadline.weight(.semibold)).foregroundStyle(Palette.green)
        }
    }

    private func autoStep() {
        if state == .done {
            tap()
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(0.5))
                tap()
            }
        } else {
            tap()
        }
    }

    private func tap() {
        switch state {
        case .idle:
            start()
        case .downloading, .done:
            run += 1
            withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
                state = .idle
                progress = 0
            }
        }
    }

    private func start() {
        run += 1
        let current = run
        let duration = ctx["duration"]
        withAnimation(.snappy) { state = .downloading }
        if !ctx.isPreview { Haptics.tap(.light) }
        Task { @MainActor in
            // Let the ring and percentage label mount at 0 before the long progress animation starts.
            try? await Task.sleep(for: .milliseconds(80))
            guard current == run else { return }
            withAnimation(.easeInOut(duration: duration)) {
                progress = 1
            } completion: {
                guard current == run else { return }
                withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) { state = .done }
                if !ctx.isPreview { Haptics.success() }
            }
        }
    }
}

private struct DownloadButton: View {
    let state: DownloadState
    let progress: Double
    let lineWidth: CGFloat
    let action: () -> Void

    private var symbol: String {
        switch state {
        case .idle: return "arrow.down"
        case .downloading: return "stop.fill"
        case .done: return "checkmark"
        }
    }

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(state == .done ? AnyShapeStyle(Palette.green) : AnyShapeStyle(Palette.blue.opacity(0.12)))
                Circle()
                    .stroke(Palette.blue.opacity(state == .downloading ? 0.18 : 0), lineWidth: lineWidth)
                Circle()
                    .trim(from: 0, to: state == .done ? 0 : progress)
                    .stroke(Palette.ocean, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Image(systemName: symbol)
                    .font(.system(size: state == .downloading ? 14 : 20, weight: .bold))
                    .foregroundStyle(state == .done ? Color.white : Palette.blue)
                    .contentTransition(.symbolEffect(.replace))
                    .symbolEffect(.bounce, value: state == .done)
            }
            .frame(width: 52, height: 52)
        }
        .buttonStyle(.plain)
    }
}

private struct PercentLabel: View, Animatable {
    var progress: Double

    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    var body: some View {
        Text(verbatim: "\(Int((progress * 100).rounded()))%")
            .font(.subheadline.weight(.semibold))
            .monospacedDigit()
            .foregroundStyle(Palette.blue)
    }
}
