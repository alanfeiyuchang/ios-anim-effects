import SwiftUI

// MARK: - Story progress bars

extension Effect {
    static let loadingStoryBars = Effect(
        id: "loading.story-bars",
        category: .loading,
        interaction: .tap,
        name: L("Story Progress Bars", "快拍进度条"),
        summary: L(
            "Segmented bars fill in turn while story pages cross-fade with a slow Ken Burns drift.",
            "分段进度条依次填满，快拍页面伴随缓慢推镜交叉切换。"
        ),
        prompt: L(
            "A 214 × 300 pt story card with 26 pt continuous corners, topped by a row of 3 pt white capsules — one per page, 4 pt apart, at 35% opacity. The current segment fills linearly from left to right over the page duration (3 s), finished ones stay solid, upcoming ones stay empty. When a segment completes, the next page cross-fades in over 0.45 s from 104% scale while the artwork beneath slowly pushes in from 100% to 108% for its whole lifetime (a Ken Burns drift), so the image is never static. Tapping the right two-thirds skips ahead, the left third goes back, each with a selection tick. Header avatar, name and timestamp, plus a frosted reply pill at the bottom, frame it like a real stories viewer. Rhythmic, immersive, effortless.",
            "一张 214 × 300 pt、26 pt 连续圆角的快拍卡片，顶部是一排 3 pt 高的白色胶囊——每页一段、间距 4 pt、透明度 35%。当前段在本页时长（3 秒）内从左到右线性填满，已看完的保持实心，未看的保持空白。一段结束时，下一页在 0.45 秒内从 104% 缩放交叉淡入；画面在整页展示期间从 100% 缓慢推近到 108%（肯·伯恩斯推镜），始终保持微微流动。点击右侧三分之二跳到下一页，左侧三分之一返回上一页，均伴随选择触感。顶部头像、昵称与时间，底部磨砂“回复”胶囊，让它看起来就是一个真实的快拍浏览器。节奏分明、沉浸、毫不费力。"
        ),
        implementation: L(
            "A TimelineView turns the time since the page started into the active segment's fill (scaleEffect(x:anchor: .leading)) and the artwork's drift; a task(id:) sleeps for the remaining duration and advances, and pages swap by .id with an asymmetric transition.",
            "TimelineView 把本页已播放时长换算为当前段的填充（scaleEffect(x:anchor: .leading)）与画面推镜；task(id:) 休眠剩余时长后翻页，页面通过 .id 与非对称转场切换。"
        ),
        apis: ["TimelineView", "task(id:)", "scaleEffect(x:y:anchor:)", "onTapGesture(coordinateSpace:perform:)"],
        tags: ["stories", "segmented progress", "auto advance", "ken burns", "快拍", "分段进度", "自动播放", "故事"],
        params: [
            .slider("duration", L("Page duration", "每页时长"), 1.5...6, default: 3, decimals: 1, unit: "s"),
            .slider("count", L("Segments", "分段数"), 3...6, default: 4, step: 1, decimals: 0),
            .toggle("kenBurns", L("Ken Burns drift", "推镜漂移"), default: true),
        ]
    ) { ctx in
        StoryBarsDemo(ctx: ctx)
    }
}

private struct StoryPage {
    let symbol: String
    let colors: [Color]
    let title: LocalizedText
}

private let storyPages: [StoryPage] = [
    StoryPage(symbol: "sun.haze.fill", colors: [Palette.amber, Palette.coral, Palette.pink], title: L("Golden hour", "黄金时刻")),
    StoryPage(symbol: "mountain.2.fill", colors: [Palette.sky, Palette.blue, Palette.indigo], title: L("Above the clouds", "云端之上")),
    StoryPage(symbol: "leaf.fill", colors: [Palette.mint, Palette.green, Palette.sky], title: L("Forest trail", "林间小径")),
    StoryPage(symbol: "moon.stars.fill", colors: [Palette.violet, Palette.indigo, Color(hex: 0x241B5C)], title: L("Night sky", "星夜")),
    StoryPage(symbol: "water.waves", colors: [Palette.sky, Palette.mint, Palette.blue], title: L("Tide pools", "潮汐")),
    StoryPage(symbol: "flame.fill", colors: [Palette.coral, Palette.red, Palette.amber], title: L("Campfire", "篝火")),
]

private struct StoryTaskKey: Hashable {
    let step: Int
    let duration: Double
    let count: Int
}

private struct StoryBarsDemo: View {
    let ctx: DemoContext
    @State private var step = 0
    @State private var pageStart = Date()

    private let size = CGSize(width: 214, height: 300)
    private var count: Int { min(max(ctx.int("count"), 1), storyPages.count) }
    private var duration: Double { max(ctx["duration"], 0.5) }

    var body: some View {
        let index = step % count
        VStack(spacing: 16) {
            ZStack {
                StoryArtwork(page: storyPages[index], start: pageStart, duration: duration, drift: ctx.bool("kenBurns"), preview: ctx.isPreview)
                    .id(step)
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 1.04)),
                        removal: .opacity
                    ))
                StoryChrome(page: storyPages[index], index: index, count: count, start: pageStart, duration: duration, language: ctx.language, preview: ctx.isPreview)
            }
            .frame(width: size.width, height: size.height)
            .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
            .shadow(color: storyPages[index].colors[0].opacity(0.35), radius: 22, y: 12)
            .contentShape(Rectangle())
            .onTapGesture(coordinateSpace: .local) { location in
                if location.x < size.width / 3 { back() } else { advance(manual: true) }
            }
            DemoHint(text: L("Tap right to skip, left to go back", "点右侧跳过，点左侧返回"), ctx: ctx)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task(id: StoryTaskKey(step: step, duration: duration, count: count)) {
            let remaining = duration - Date().timeIntervalSince(pageStart)
            try? await Task.sleep(for: .seconds(max(remaining, 0.05)))
            guard !Task.isCancelled else { return }
            advance(manual: false)
        }
    }

    private func advance(manual: Bool) {
        if manual && !ctx.isPreview { Haptics.selection() }
        pageStart = Date()
        withAnimation(.smooth(duration: 0.45)) { step += 1 }
    }

    private func back() {
        if !ctx.isPreview { Haptics.selection() }
        pageStart = Date()
        withAnimation(.smooth(duration: 0.45)) { step = max(step - 1, 0) }
    }
}

private struct StoryArtwork: View {
    let page: StoryPage
    let start: Date
    let duration: Double
    let drift: Bool
    let preview: Bool

    var body: some View {
        TimelineView(.animation(minimumInterval: MotionFrameRate.interval(preview: preview), paused: !drift)) { timeline in
            let progress = min(max(timeline.date.timeIntervalSince(start) / duration, 0), 1)
            ZStack {
                LinearGradient(colors: page.colors, startPoint: .topLeading, endPoint: .bottomTrailing)
                RadialGradient(colors: [.white.opacity(0.35), .clear], center: UnitPoint(x: 0.25, y: 0.2), startRadius: 0, endRadius: 180)
                Image(systemName: page.symbol)
                    .font(.system(size: 76, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.9))
                    .shadow(color: .black.opacity(0.15), radius: 10, y: 6)
                    .offset(y: -6)
            }
            .scaleEffect(drift ? 1 + 0.08 * CGFloat(progress) : 1)
        }
    }
}

private struct StoryChrome: View {
    let page: StoryPage
    let index: Int
    let count: Int
    let start: Date
    let duration: Double
    let language: AppLanguage
    let preview: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            TimelineView(.animation(minimumInterval: MotionFrameRate.interval(preview: preview))) { timeline in
                let progress = min(max(timeline.date.timeIntervalSince(start) / duration, 0), 1)
                HStack(spacing: 4) {
                    ForEach(0..<count, id: \.self) { segment in
                        Capsule()
                            .fill(.white.opacity(0.35))
                            .overlay {
                                Capsule()
                                    .fill(.white)
                                    .scaleEffect(x: fill(for: segment, progress: progress), y: 1, anchor: .leading)
                            }
                            .frame(height: 3)
                    }
                }
            }
            .frame(height: 3)
            HStack(spacing: 8) {
                Text(verbatim: "AL")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(width: 28, height: 28)
                    .background(.white.opacity(0.25), in: Circle())
                    .overlay { Circle().strokeBorder(.white.opacity(0.8), lineWidth: 1.5) }
                Text(language == .zh ? "阿兰" : "alan")
                    .font(.footnote.weight(.semibold))
                Text(language == .zh ? "2 小时" : "2h")
                    .font(.footnote)
                    .opacity(0.7)
                Spacer(minLength: 0)
                Image(systemName: "ellipsis")
                    .font(.footnote.weight(.bold))
            }
            .foregroundStyle(.white)
            Spacer(minLength: 0)
            Text(page.title, language)
                .font(.title3.weight(.bold))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.2), radius: 6, y: 2)
            HStack(spacing: 8) {
                Text(language == .zh ? "发送消息" : "Send message")
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.85))
                    .padding(.horizontal, 14)
                    .frame(height: 34)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.ultraThinMaterial, in: Capsule())
                    .overlay { Capsule().strokeBorder(.white.opacity(0.35)) }
                Image(systemName: "heart")
                    .font(.headline)
                    .foregroundStyle(.white)
            }
        }
        .padding(12)
        .environment(\.colorScheme, .dark)
    }

    private func fill(for segment: Int, progress: Double) -> CGFloat {
        if segment < index { return 1 }
        if segment > index { return 0 }
        return CGFloat(progress)
    }
}

// MARK: - Progressive image load

extension Effect {
    static let loadingBlurUp = Effect(
        id: "loading.blur-up",
        category: .loading,
        interaction: .tap,
        name: L("Progressive Image Load", "渐进式图片加载"),
        summary: L(
            "Photos resolve from a soft, tinted blur into crisp detail as each one arrives.",
            "照片从带主色的柔和模糊中逐张清晰显现。"
        ),
        prompt: L(
            "A small gallery — one wide 274 × 128 pt hero photo over two 132 pt squares, 10 pt apart with 18 pt continuous corners. Before its data arrives, each tile shows a pre-blurred (18 pt), 50%-desaturated copy of its own image over a gradient of its dominant colors, zoomed to 112%, with a soft white wash breathing 0 ↔ 16% every 0.9 s. Images land in a random order about 350 ms apart; each one resolves over 0.6 s on a smooth curve — the blurred copy cross-fades out to reveal the sharp, full-color image beneath while both layers settle from 112% to 100% — so detail seems to focus into place rather than pop. The last arrival fires a soft haptic. Calm, photographic, and it never shows an empty box.",
            "一组小画廊——上方一张 274 × 128 pt 的横幅大图，下方两张 132 pt 方图，间距 10 pt、18 pt 连续圆角。数据到达前，每个图块以自身主色渐变为底，叠一张预先模糊（18 pt）、饱和度降到 50% 的同图副本作为占位，整体放大到 112%，并叠一层每 0.9 秒在 0 与 16% 之间呼吸的柔和白色。图片以随机顺序、约 350 毫秒间隔依次到达；每张在 0.6 秒平滑曲线内完成显影——模糊副本淡出，露出下方清晰、全彩的原图，两层同时从 112% 缩放落回 100%——细节像被“对焦”出来，而不是突然弹出。最后一张到达时伴随轻柔触感。安静、有摄影质感，永远不会出现空白方框。"
        ),
        implementation: L(
            "Each tile stacks the sharp image under a pre-blurred, desaturated copy (compositingGroup + blur over a solid gradient, so edges stay filled); loading only animates the copy's opacity and both layers' scale. A task(id:) advances the loaded count in a shuffled order with smooth animations.",
            "每个图块把清晰原图放在底层，上方叠一张预先模糊、降饱和的副本（compositingGroup + blur，并以纯色渐变垫底，边缘不会透明）；加载时只动画副本的透明度与两层的缩放。task(id:) 按随机顺序以平滑动画逐步推进已加载数量。"
        ),
        apis: ["blur(radius:)", "compositingGroup", "saturation", "task(id:)", "phaseAnimator"],
        tags: ["image loading", "blur up", "progressive", "placeholder", "图片加载", "渐进", "模糊占位", "懒加载"],
        params: [
            .slider("stagger", L("Arrival spacing", "到达间隔"), 0.1...0.8, default: 0.35, unit: "s"),
            .slider("blur", L("Placeholder blur", "占位模糊"), 6...30, default: 18, decimals: 0, unit: "pt"),
            .slider("fade", L("Resolve time", "显影时长"), 0.2...1.2, default: 0.6, decimals: 1, unit: "s"),
        ]
    ) { ctx in
        BlurUpDemo(ctx: ctx)
    }
}

private struct BlurUpPhoto {
    let symbol: String
    let colors: [Color]
}

private let blurUpPhotos: [BlurUpPhoto] = [
    BlurUpPhoto(symbol: "sun.horizon.fill", colors: [Palette.amber, Palette.coral, Palette.pink]),
    BlurUpPhoto(symbol: "mountain.2.fill", colors: [Palette.sky, Palette.blue]),
    BlurUpPhoto(symbol: "leaf.fill", colors: [Palette.mint, Palette.green]),
]

private struct BlurUpDemo: View {
    let ctx: DemoContext
    @State private var loadedCount = 0
    @State private var order: [Int] = [1, 0, 2]
    @State private var run = 0

    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 10) {
                tile(0, width: 274, height: 128)
                HStack(spacing: 10) {
                    tile(1, width: 132, height: 132)
                    tile(2, width: 132, height: 132)
                }
            }
            DemoHint(text: L("Tap to reload", "点击重新加载"), ctx: ctx)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .onTapGesture { run += 1 }
        .task(id: run) { await load() }
    }

    private func isLoaded(_ index: Int) -> Bool {
        (order.firstIndex(of: index) ?? 0) < loadedCount
    }

    private func tile(_ index: Int, width: CGFloat, height: CGFloat) -> some View {
        BlurUpTile(photo: blurUpPhotos[index], loaded: isLoaded(index), blur: ctx.cg("blur"))
            .frame(width: width, height: height)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
    }

    private func load() async {
        withAnimation(.easeOut(duration: 0.3)) { loadedCount = 0 }
        order = [0, 1, 2].shuffled()
        try? await Task.sleep(for: .seconds(0.7))
        for count in 1...3 {
            let wait = ctx["stagger"] * Double.random(in: 0.7...1.3)
            try? await Task.sleep(for: .seconds(wait))
            guard !Task.isCancelled else { return }
            withAnimation(.smooth(duration: ctx["fade"])) { loadedCount = count }
            if count == 3 && !ctx.isPreview { Haptics.tap(.soft) }
        }
        guard ctx.isPreview else { return }
        try? await Task.sleep(for: .seconds(2.0))
        guard !Task.isCancelled else { return }
        run += 1
    }
}

private struct BlurUpTile: View {
    let photo: BlurUpPhoto
    let loaded: Bool
    let blur: CGFloat

    var body: some View {
        ZStack {
            // Sharp image underneath; it only settles its scale.
            BlurUpArt(photo: photo)
                .scaleEffect(loaded ? 1 : 1.12)
            // Pre-blurred, desaturated copy on top. Its blur radius never animates —
            // the copy simply cross-fades away, so detail "focuses" into place.
            BlurUpPlaceholder(photo: photo, blur: blur)
                .scaleEffect(loaded ? 1 : 1.12)
                .opacity(loaded ? 0 : 1)
        }
    }
}

private struct BlurUpArt: View {
    let photo: BlurUpPhoto

    var body: some View {
        ZStack {
            LinearGradient(colors: photo.colors, startPoint: .topLeading, endPoint: .bottomTrailing)
            RadialGradient(colors: [.white.opacity(0.4), .clear], center: UnitPoint(x: 0.3, y: 0.25), startRadius: 0, endRadius: 140)
            Image(systemName: photo.symbol)
                .font(.system(size: 44, weight: .semibold))
                .foregroundStyle(.white.opacity(0.92))
                .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
        }
    }
}

private struct BlurUpPlaceholder: View {
    let photo: BlurUpPhoto
    let blur: CGFloat

    var body: some View {
        ZStack {
            // A solid gradient backs the blurred copy so its soft edges never turn transparent.
            LinearGradient(colors: photo.colors, startPoint: .topLeading, endPoint: .bottomTrailing)
            BlurUpArt(photo: photo)
                .compositingGroup()
                .blur(radius: blur)
            Color.white
                .phaseAnimator([0.0, 0.16]) { content, level in
                    content.opacity(level)
                } animation: { _ in
                    .easeInOut(duration: 0.9)
                }
        }
        .saturation(0.5)
        .compositingGroup()
    }
}
