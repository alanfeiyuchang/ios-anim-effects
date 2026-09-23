import SwiftUI

extension Effect {
    static let loadingDownloadButton = Effect(
        id: "loading.download-button",
        category: .loading,
        interaction: .tap,
        name: L("Download Button", "下载按钮"),
        summary: L("An App Store-style GET pill that becomes a progress ring, then OPEN.", "App Store 式“获取”胶囊变为进度环，再变成“打开”。"),
        prompt: L(
            "An app row with a gradient icon, a title and a trailing 88 × 36 pt tinted pill reading GET in bold blue. On tap the label shrinks and blurs away while the pill springs into a 36 pt circle (response 0.45 s, damping 0.8); a short quarter arc spins around the hairline track while 'waiting', then a determinate blue arc with round caps fills clockwise from 12 o'clock in small linear steps, with a 11 pt rounded stop square popping in at the center. At 100% the circle springs back out into a pill that now reads OPEN, with a success haptic. Tapping during download cancels back to GET.",
            "一行应用条目：左侧渐变图标与标题，右侧是一枚 88 × 36 pt 的浅蓝胶囊，蓝色粗体写着“获取”。点击后文字缩小、模糊消失，胶囊以弹簧（响应 0.45 秒、阻尼 0.8）收缩成 36 pt 圆形；“等待中”时一段四分之一圆弧沿细轨道旋转，随后蓝色圆头进度弧从 12 点方向顺时针以细小的线性步进填满，圆心弹出一个 11 pt 的圆角“停止”方块。到达 100% 时圆形弹性舒展回胶囊，文字变为“打开”，并伴随成功触感。下载途中再次点击则取消并回到“获取”。"
        ),
        implementation: L(
            "A four-phase enum drives the capsule frame, a TimelineView waiting arc and a trimmed progress circle whose value is stepped by an async task.",
            "四段状态驱动胶囊尺寸、TimelineView 等待圆弧与 trim 进度圆，进度由异步任务逐步推进。"
        ),
        apis: ["frame(width:height:)", "trim(from:to:)", "TimelineView", "Task.sleep(for:)"],
        tags: ["download", "app store", "get", "progress ring", "下载", "获取", "进度环", "应用商店"],
        params: [
            .slider("speed", L("Download speed", "下载速度"), 0.4...2.5, default: 1.0),
            .slider("response", L("Spring response", "弹簧响应"), 0.2...0.9, default: 0.45, unit: "s"),
            .slider("damping", L("Damping", "阻尼"), 0.4...1.0, default: 0.8),
        ]
    ) { ctx in
        DownloadButtonDemo(ctx: ctx)
    }
}

private enum DownloadPhase: Equatable {
    case idle
    case waiting
    case downloading
    case done
}

private struct DownloadButtonDemo: View {
    let ctx: DemoContext
    @State private var phase: DownloadPhase = .idle
    @State private var progress: Double = 0
    @State private var token = 0

    private var spring: Animation {
        .spring(response: ctx["response"], dampingFraction: ctx["damping"])
    }

    var body: some View {
        VStack(spacing: 24) {
            HStack(spacing: 14) {
                appIcon
                VStack(alignment: .leading, spacing: 3) {
                    Text(ctx.language == .zh ? "动效词典" : "Motion Lexicon")
                        .font(.headline)
                    Text(ctx.language == .zh ? "设计工具" : "Design Tools")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 8)
                Button(action: tap) {
                    DownloadFace(phase: phase, progress: progress, language: ctx.language)
                }
                .buttonStyle(.plain)
            }
            .padding(16)
            .frame(width: 310)
            .demoCard()
            DemoHint(text: L("Tap GET", "点击“获取”"), ctx: ctx)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 2.4, delay: 0.6) {
            if phase == .idle || phase == .done { tap() }
        }
    }

    private var appIcon: some View {
        RoundedRectangle(cornerRadius: 13, style: .continuous)
            .fill(Palette.primary)
            .frame(width: 56, height: 56)
            .overlay {
                Image(systemName: "sparkles")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(.white)
            }
    }

    private func tap() {
        switch phase {
        case .idle:
            begin()
        case .waiting, .downloading, .done:
            token += 1
            if !ctx.isPreview { Haptics.tap() }
            withAnimation(spring) {
                phase = .idle
                progress = 0
            }
        }
    }

    private func begin() {
        token += 1
        let current = token
        let speed = ctx["speed"]
        let live = !ctx.isPreview
        if live { Haptics.tap(.medium) }
        withAnimation(spring) { phase = .waiting }
        Task {
            try? await Task.sleep(for: .seconds(0.7))
            guard token == current else { return }
            withAnimation(.easeInOut(duration: 0.25)) { phase = .downloading }
            while progress < 1 {
                try? await Task.sleep(for: .seconds(0.12))
                guard token == current else { return }
                let step = Double.random(in: 0.02...0.08) * speed
                withAnimation(.linear(duration: 0.12)) { progress = min(1, progress + step) }
            }
            try? await Task.sleep(for: .seconds(0.3))
            guard token == current else { return }
            withAnimation(spring) { phase = .done }
            if live { Haptics.success() }
        }
    }
}

private struct DownloadFace: View {
    let phase: DownloadPhase
    let progress: Double
    let language: AppLanguage

    private let side: CGFloat = 36

    var body: some View {
        let circular = phase == .waiting || phase == .downloading
        let title = phase == .done ? (language == .zh ? "打开" : "OPEN") : (language == .zh ? "获取" : "GET")
        ZStack {
            Capsule()
                .fill(Palette.blue.opacity(circular ? 0 : 0.14))
            Capsule()
                .strokeBorder(Color.primary.opacity(circular ? 0.12 : 0), lineWidth: 3)
            if phase == .waiting {
                DownloadWaitingArc()
                    .transition(.opacity)
            }
            if phase == .downloading {
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(Palette.blue, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .padding(1.5)
                    .transition(.opacity)
                RoundedRectangle(cornerRadius: 2.5, style: .continuous)
                    .fill(Palette.blue)
                    .frame(width: 11, height: 11)
                    .transition(AnyTransition.scale(scale: 0.2).combined(with: .opacity))
            }
            Text(title)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(Palette.blue)
                .fixedSize()
                .opacity(circular ? 0 : 1)
                .scaleEffect(circular ? 0.6 : 1)
                .blur(radius: circular ? 4 : 0)
        }
        .frame(width: circular ? side : 88, height: side)
        .contentShape(Capsule())
    }
}

private struct DownloadWaitingArc: View {
    var body: some View {
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            Circle()
                .trim(from: 0, to: 0.25)
                .stroke(Palette.blue, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .rotationEffect(.degrees(t.truncatingRemainder(dividingBy: 1) * 360))
                .padding(1.5)
        }
    }
}
