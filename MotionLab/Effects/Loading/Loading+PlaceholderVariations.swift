import SwiftUI

// MARK: - Breathing skeleton

extension Effect {
    static let loadingBreathingSkeleton = Effect(
        id: "loading.breathing-skeleton",
        category: .loading,
        interaction: .state,
        name: L("Breathing Skeleton", "呼吸骨架屏"),
        summary: L("Skeleton rows breathe in a top-down wave, then real rows rise in one by one.", "骨架行自上而下波浪式呼吸，随后真实内容逐行升起。"),
        prompt: L(
            "A three-row inbox card in skeleton state: 40 pt circles and two text bars per row, no shimmer. Instead every block breathes between 6% and 16% label opacity on a 1.4 s ease-in-out cycle, each row starting 0.15 s after the one above, so a soft wave rolls down the list. After about 2.4 s the data lands: each skeleton row fades out as its real row — gradient avatar, bold name, preview text and time — rises 12 pt into place and fades in on a spring (response 0.45 s, damping 0.85), staggered 80 ms top to bottom. Calm, low-distraction, respectful of attention.",
            "一张三行的收件箱卡片处于骨架态：每行一个 40 pt 圆形与两条文字条，没有流光。取而代之的是所有色块以 1.4 秒缓入缓出周期在 6% 与 16% 文字色透明度之间呼吸，每行比上一行晚 0.15 秒开始，一道柔和的波浪沿列表向下传递。约 2.4 秒后数据到达：每一行骨架淡出，对应的真实内容——渐变头像、粗体姓名、预览文字与时间——以弹簧（响应 0.45 秒、阻尼 0.85）上升 12 pt 落位并淡入，自上而下间隔 80 毫秒。平静、低干扰、尊重注意力。"
        ),
        implementation: L(
            "A TimelineView evaluates a phase-shifted cosine per row for the breathing; a loaded flag swaps each row with an asymmetric offset + opacity transition delayed by its index.",
            "TimelineView 为每行计算相位错开的余弦实现呼吸；加载标志以按序号延迟的非对称位移 + 透明度转场替换每一行。"
        ),
        apis: ["TimelineView", "transition(.asymmetric(insertion:removal:))", "spring(response:dampingFraction:).delay", "opacity"],
        tags: ["skeleton", "breathing", "placeholder", "inbox", "骨架屏", "呼吸", "占位", "收件箱"],
        params: [
            .slider("period", L("Breath cycle", "呼吸周期"), 0.6...3.0, default: 1.4, decimals: 1, unit: "s"),
            .slider("stagger", L("Row stagger", "行间错峰"), 0...0.4, default: 0.15, unit: "s"),
            .slider("wait", L("Load time", "加载时长"), 1...5, default: 2.4, decimals: 1, unit: "s"),
        ]
    ) { ctx in
        BreathingSkeletonDemo(ctx: ctx)
    }
}

private struct InboxSample {
    let initials: String
    let colors: [Color]
    let name: LocalizedText
    let preview: LocalizedText
    let time: String
}

private struct BreathingSkeletonDemo: View {
    let ctx: DemoContext
    @State private var loaded = false
    @State private var run = 0

    private let samples: [InboxSample] = [
        InboxSample(initials: "AK", colors: [Palette.sky, Palette.blue], name: L("Alex Kim", "金亚历"), preview: L("Final specs attached", "最终规格已附上"), time: "9:41"),
        InboxSample(initials: "MJ", colors: [Palette.pink, Palette.violet], name: L("Mia Jensen", "米娅"), preview: L("Can we move the sync?", "同步会能改时间吗？"), time: "9:12"),
        InboxSample(initials: "SL", colors: [Palette.mint, Palette.green], name: L("Sara Lopez", "萨拉"), preview: L("Invoice #2031 paid", "发票 #2031 已付款"), time: "8:57"),
    ]

    var body: some View {
        VStack(spacing: 18) {
            VStack(spacing: 0) {
                ForEach(0..<3, id: \.self) { index in
                    rowSlot(index)
                    if index < 2 { Divider().padding(.leading, 66) }
                }
            }
            .frame(width: 288)
            .padding(.vertical, 6)
            .demoCard()
            DemoHint(text: L("Tap to reload", "点击重新加载"), ctx: ctx)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .onTapGesture { run += 1 }
        .task(id: run) { await play() }
    }

    private func rowSlot(_ index: Int) -> some View {
        let delay: Double = Double(index) * 0.08
        let rise = AnyTransition.asymmetric(
            insertion: AnyTransition.offset(y: 12).combined(with: .opacity),
            removal: .opacity
        )
        return ZStack {
            if loaded {
                InboxRow(sample: samples[index], language: ctx.language)
                    .transition(rise)
            } else {
                SkeletonBreathRow(index: index, period: max(ctx["period"], 0.2), stagger: ctx["stagger"])
                    .transition(.opacity)
            }
        }
        .frame(height: 64)
        .animation(.spring(response: 0.45, dampingFraction: 0.85).delay(loaded ? delay : 0), value: loaded)
    }

    private func play() async {
        loaded = false
        try? await Task.sleep(for: .seconds(ctx["wait"]))
        guard !Task.isCancelled else { return }
        loaded = true
        try? await Task.sleep(for: .seconds(2.4))
        if ctx.isPreview && !Task.isCancelled { run += 1 }
    }
}

private struct SkeletonBreathRow: View {
    let index: Int
    let period: Double
    let stagger: Double

    var body: some View {
        TimelineView(.animation) { timeline in
            let t: Double = timeline.date.timeIntervalSinceReferenceDate - Double(index) * stagger
            let wave: Double = 0.5 - 0.5 * cos(2 * .pi * t / period)
            let alpha: Double = 0.06 + 0.1 * wave
            HStack(spacing: 12) {
                Circle().frame(width: 40, height: 40)
                VStack(alignment: .leading, spacing: 8) {
                    Capsule().frame(width: 110, height: 11)
                    Capsule().frame(width: 170, height: 9)
                }
                Spacer(minLength: 0)
            }
            .foregroundStyle(Color.primary.opacity(alpha))
            .padding(.horizontal, 14)
        }
    }
}

private struct InboxRow: View {
    let sample: InboxSample
    let language: AppLanguage

    var body: some View {
        HStack(spacing: 12) {
            Text(sample.initials)
                .font(.caption.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 40, height: 40)
                .background(LinearGradient(colors: sample.colors, startPoint: .top, endPoint: .bottom), in: Circle())
            VStack(alignment: .leading, spacing: 3) {
                Text(sample.name, language)
                    .font(.subheadline.weight(.semibold))
                Text(sample.preview, language)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
            Text(sample.time)
                .font(.caption2.monospacedDigit())
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 14)
    }
}

// MARK: - Mosaic resolve

extension Effect {
    static let loadingMosaicResolve = Effect(
        id: "loading.mosaic-resolve",
        category: .loading,
        interaction: .state,
        name: L("Mosaic Resolve", "马赛克渐显"),
        summary: L("An image resolves from chunky blocks to full detail in doubling steps.", "图片从粗大的色块按倍数逐级细化到完整细节。"),
        prompt: L(
            "A social post card with an avatar row, a 264 × 168 pt image and two caption lines. The image arrives progressively like an interlaced download: it first appears as a 4-column mosaic of flat color blocks averaged from the scene, then every 0.45 s the grid doubles — 8, 16, 32 columns — each new resolution cross-fading over the previous one in 0.25 s, until a final 96-column pass lands and a 0.5 pt blur melts the last grid lines away. Each step ticks a light haptic. The scene is a sunset over layered violet mountains. Nostalgic, informative, crisp.",
            "一张社交动态卡片：头像行、一幅 264 × 168 pt 的图片和两行说明。图片像隔行扫描下载一样逐级到达：先以 4 列的纯色马赛克出现（颜色取自画面采样），随后每 0.45 秒网格加倍——8、16、32 列——每一级在 0.25 秒内交叉淡入覆盖上一级，最后 96 列的一遍落定，再以 0.5 pt 模糊抹去残余网格线。每一级伴随一次轻触感。画面是层叠紫色山峦上的日落。怀旧、信息明确、清爽利落。"
        ),
        implementation: L(
            "A Canvas samples a procedural scene at each cell center and fills rectangles; the column count is state, and each level is keyed with id() so it cross-fades as a transition.",
            "Canvas 在每个格子中心采样程序化画面并填充矩形；列数为状态值，每一级用 id() 区分，以转场方式交叉淡入。"
        ),
        apis: ["Canvas", "id(_:)", "transition(.opacity)", "drawingGroup()"],
        tags: ["progressive", "mosaic", "pixel", "image loading", "渐进加载", "马赛克", "像素", "图片加载"],
        params: [
            .slider("step", L("Step time", "每级时长"), 0.2...1.2, default: 0.45, unit: "s"),
            .slider("start", L("First grid", "初始列数"), 2...8, default: 4, step: 1, decimals: 0),
        ]
    ) { ctx in
        MosaicResolveDemo(ctx: ctx)
    }
}

private struct MosaicResolveDemo: View {
    let ctx: DemoContext
    @State private var columns = 0
    @State private var run = 0

    var body: some View {
        let zh = ctx.language == .zh
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 10) {
                    Circle().fill(Palette.sunset).frame(width: 30, height: 30)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(zh ? "林晓" : "Lin Xiao").font(.subheadline.weight(.semibold))
                        Text(zh ? "大理 · 刚刚" : "Dali · just now").font(.caption2).foregroundStyle(.secondary)
                    }
                }
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.primary.opacity(0.06))
                    if columns > 0 {
                        MosaicCanvas(columns: columns)
                            .blur(radius: columns >= 96 ? 0.5 : 0)
                            .id(columns)
                            .transition(.opacity)
                    }
                }
                .frame(width: 264, height: 168)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                PlaceholderLines(count: 2)
            }
            .padding(14)
            .demoCard()
            DemoHint(text: L("Tap to reload", "点击重新加载"), ctx: ctx)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .onTapGesture { run += 1 }
        .task(id: run) { await play() }
    }

    private func play() async {
        withAnimation(.easeOut(duration: 0.2)) { columns = 0 }
        try? await Task.sleep(for: .seconds(0.6))
        var levels: [Int] = []
        var n: Int = max(ctx.int("start"), 1)
        while n < 64 {
            levels.append(n)
            n *= 2
        }
        levels.append(96)
        for level in levels {
            if Task.isCancelled { return }
            withAnimation(.easeInOut(duration: 0.25)) { columns = level }
            if !ctx.isPreview { Haptics.tap(.soft) }
            try? await Task.sleep(for: .seconds(ctx["step"]))
        }
        try? await Task.sleep(for: .seconds(2.0))
        if ctx.isPreview && !Task.isCancelled { run += 1 }
    }
}

private struct MosaicCanvas: View {
    let columns: Int

    var body: some View {
        Canvas { context, size in
            let cell: CGFloat = size.width / CGFloat(columns)
            let rows: Int = Int((size.height / cell).rounded(.up))
            for row in 0..<rows {
                for column in 0..<columns {
                    let x: CGFloat = CGFloat(column) * cell
                    let y: CGFloat = CGFloat(row) * cell
                    let u: Double = Double((x + cell / 2) / size.width)
                    let v: Double = Double(min((y + cell / 2) / size.height, 1))
                    let rect = CGRect(x: x, y: y, width: cell + 0.5, height: cell + 0.5)
                    context.fill(Path(rect), with: .color(MosaicScene.color(u: u, v: v)))
                }
            }
        }
        .drawingGroup()
    }
}

/// A procedural sunset: sky gradient, sun disc, two mountain ridges.
private enum MosaicScene {
    static func color(u: Double, v: Double) -> Color {
        let ridgeFar: Double = 0.58 + 0.08 * sin(u * 9 + 0.5) + 0.04 * sin(u * 23)
        let ridgeNear: Double = 0.76 + 0.06 * sin(u * 13 + 2) + 0.03 * sin(u * 31)
        if v > ridgeNear { return Color(.sRGB, red: 0.16, green: 0.11, blue: 0.3, opacity: 1) }
        if v > ridgeFar { return Color(.sRGB, red: 0.38, green: 0.26, blue: 0.55, opacity: 1) }
        let dx: Double = u - 0.68
        let dy: Double = (v - 0.4) * 0.64
        let sun: Double = sqrt(dx * dx + dy * dy)
        if sun < 0.09 { return Color(.sRGB, red: 1.0, green: 0.88, blue: 0.55, opacity: 1) }
        let glow: Double = max(0, 1 - sun / 0.35) * 0.25
        let r: Double = min(1, 0.36 + 0.64 * v + glow)
        let g: Double = min(1, 0.5 + 0.12 * v + glow * 0.8)
        let b: Double = min(1, 0.98 - 0.5 * v + glow * 0.2)
        return Color(.sRGB, red: r, green: g, blue: b, opacity: 1)
    }
}
