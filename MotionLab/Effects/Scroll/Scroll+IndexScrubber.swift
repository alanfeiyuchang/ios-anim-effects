import SwiftUI

extension Effect {
    static let scrollIndexScrubber = Effect(
        id: "scroll.index-scrubber",
        category: .scroll,
        interaction: .gesture,
        name: L("A–Z Index Scrubber", "A–Z 索引条"),
        summary: L("Scrub a side index: letters magnify under the thumb, a bubble previews the letter and the list jumps.", "在侧边索引上滑动：指下字母放大，气泡预览字母，列表随之跳转。"),
        prompt: L(
            "A contacts list grouped by initial has a slim A–Z index on its right edge, 10 pt semibold rounded letters on an 11 pt pitch. Sliding a thumb along it scrubs a dock-like fisheye: the letter underneath swells to 190% and pushes 14 pt left, and its neighbours magnify on a cosine falloff that fades out three letters away, all on a tight spring (response 0.25 s, damping 0.8). A 56 pt gradient bubble pops in beside the thumb, tracks it and rolls to each new letter like a numeric counter. Every new letter jumps the list without animation to that section, or the next one that exists, with a selection tick; lifting the finger shrinks the bubble away and relaxes the index.",
            "按首字母分组的联系人列表右侧有一条纤细的A–Z索引，字母为10 pt半粗圆体，每格11 pt。手指沿索引滑动，会出现程序坞式的鱼眼：指下字母放大到190%并向左凸出14 pt，相邻字母按余弦衰减依次放大，三格外恢复原样，全程由紧致弹簧（响应0.25秒、阻尼0.8）跟手。一个56 pt的渐变气泡在指旁弹出，跟着手指移动，像数字滚动一样切换字母。每换一个字母，列表都无动画地直接跳到对应分组（没有就跳到下一个），并轻轻一震；松手后气泡缩回消失，索引恢复平静。"
        ),
        implementation: L(
            "A DragGesture on the index maps location.y to a letter; ScrollViewReader.scrollTo jumps to the section id, each letter's scaleEffect/offset is a falloff of its distance from the active index, and UISelectionFeedbackGenerator ticks on every change.",
            "索引上的 DragGesture 将 location.y 换算为字母；ScrollViewReader.scrollTo 跳转到对应分组的 id，每个字母的 scaleEffect 与 offset 由其到当前索引的距离衰减计算，UISelectionFeedbackGenerator 在每次切换时触发。"
        ),
        apis: ["DragGesture", "ScrollViewReader", "scaleEffect(_:anchor:)", "UISelectionFeedbackGenerator", "contentTransition(.numericText())"],
        tags: ["index", "scrubber", "alphabet", "contacts", "fisheye", "索引", "字母", "通讯录", "快速定位"],
        params: [
            .slider("magnify", L("Magnification", "放大倍率"), 0...1.5, default: 0.9),
            .slider("reach", L("Falloff reach", "衰减范围"), 1...5, default: 3, step: 1, decimals: 0, unit: ""),
            .toggle("bubble", L("Letter bubble", "字母气泡"), default: true),
        ]
    ) { ctx in
        ScrollIndexDemo(ctx: ctx)
    }
}

private struct ScrollIndexSection {
    let letter: String
    let names: [LocalizedText]
}

private let scrollIndexLetters: [String] = "ABCDEFGHIJKLMNOPQRSTUVWXYZ".map { String($0) }

private let scrollIndexSections: [ScrollIndexSection] = [
    ScrollIndexSection(letter: "A", names: [L("Ava Collins", "安然"), L("Aiden Park", "艾米")]),
    ScrollIndexSection(letter: "B", names: [L("Bella Hart", "白露"), L("Ben Ortiz", "包晨")]),
    ScrollIndexSection(letter: "C", names: [L("Chloe Reed", "陈思远"), L("Caleb Stone", "程悦")]),
    ScrollIndexSection(letter: "D", names: [L("Daniel Wu", "邓宁")]),
    ScrollIndexSection(letter: "E", names: [L("Emma Lane", "鄂晴")]),
    ScrollIndexSection(letter: "F", names: [L("Finn Brooks", "方可"), L("Freya Moss", "冯雪")]),
    ScrollIndexSection(letter: "G", names: [L("Grace Kim", "高远")]),
    ScrollIndexSection(letter: "H", names: [L("Hana Sato", "何夕"), L("Henry Cole", "胡桃")]),
    ScrollIndexSection(letter: "J", names: [L("Jade Rivera", "江澄"), L("Jonah Fox", "金沐")]),
    ScrollIndexSection(letter: "K", names: [L("Kai Lopez", "孔乐")]),
    ScrollIndexSection(letter: "L", names: [L("Lena Park", "林晓"), L("Leo Grant", "陆鸣"), L("Lily Chen", "刘星")]),
    ScrollIndexSection(letter: "M", names: [L("Maya Singh", "马骁"), L("Miles Dunn", "孟夏")]),
    ScrollIndexSection(letter: "N", names: [L("Nora Blake", "宁静")]),
    ScrollIndexSection(letter: "O", names: [L("Oscar Hale", "欧阳朗")]),
    ScrollIndexSection(letter: "P", names: [L("Priya Nair", "潘越")]),
    ScrollIndexSection(letter: "R", names: [L("Ruby Walsh", "任舟"), L("Ryan Moore", "阮青")]),
    ScrollIndexSection(letter: "S", names: [L("Sofia Ruiz", "宋雨"), L("Sam Taylor", "孙一"), L("Sara Ali", "苏禾")]),
    ScrollIndexSection(letter: "T", names: [L("Theo Grey", "唐果")]),
    ScrollIndexSection(letter: "V", names: [L("Violet Ames", "魏然")]),
    ScrollIndexSection(letter: "W", names: [L("Will Harper", "王珂"), L("Wren Ellis", "吴桐")]),
    ScrollIndexSection(letter: "X", names: [L("Xavier Bell", "许诺")]),
    ScrollIndexSection(letter: "Y", names: [L("Yara Haddad", "杨帆"), L("Yuki Mori", "叶知秋")]),
    ScrollIndexSection(letter: "Z", names: [L("Zoe Fraser", "张弛"), L("Zane Cooper", "周屿")]),
]

private enum ScrollIndexMetrics {
    static let letterHeight: CGFloat = 11
    /// Vertical padding inside the index capsule, above the first letter.
    static let inset: CGFloat = 6
    static var indexHeight: CGFloat { letterHeight * CGFloat(scrollIndexLetters.count) }
}

private struct ScrollIndexDemo: View {
    let ctx: DemoContext
    /// Index into `scrollIndexLetters` under the finger, or nil when not scrubbing.
    @State private var active: Int?
    @State private var autoStep = 0
    /// True while the detail stage's one-shot intro scrub runs, so it stays silent.
    @State private var demoing = false
    /// The running intro scrub, cancelled if the demo leaves the screen.
    @State private var introTask: Task<Void, Never>?
    /// True while a real finger scrubs the index.
    @State private var held = false
    /// Resets on system cancellation too, so a stolen touch never leaves the bubble up.
    @GestureState private var pressing = false

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(scrollIndexSections.indices, id: \.self) { s in
                        ScrollIndexSectionView(section: scrollIndexSections[s], language: ctx.language)
                            .id(scrollIndexSections[s].letter)
                    }
                }
                .padding(.leading, 16)
                .padding(.trailing, 40)
                .padding(.vertical, 16)
            }
            .scrollIndicators(.hidden)
            .overlay(alignment: .trailing) {
                ScrollIndexBar(
                    active: active,
                    magnify: ctx["magnify"],
                    reach: max(ctx["reach"], 1),
                    showsBubble: ctx.bool("bubble")
                )
                // Widen the touch target beyond the 22 pt letter column.
                .padding(.leading, 10)
                .contentShape(Rectangle())
                .gesture(scrub(proxy))
                .padding(.trailing, 4)
            }
            .overlay(alignment: .bottom) { hint }
            .onChange(of: active) { _, newValue in
                if !ctx.isPreview && !demoing && newValue != nil { Haptics.selection() }
            }
            .autoplay(ctx.isPreview, every: 0.32, delay: 0.5) { autoScrub(proxy) }
            .onChange(of: pressing) { _, isPressing in
                if !isPressing { endHold() }
            }
            .onDisappear {
                introTask?.cancel()
                introTask = nil
            }
        }
    }

    @ViewBuilder
    private var hint: some View {
        if !ctx.isPreview {
            DemoHint(text: L("Slide along the A–Z index", "沿 A–Z 索引滑动"), ctx: ctx)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(.regularMaterial, in: Capsule())
                .padding(.bottom, 12)
                .opacity(active == nil ? 1 : 0)
                .animation(.easeOut(duration: 0.2), value: active == nil)
                .allowsHitTesting(false)
        }
    }

    private func scrub(_ proxy: ScrollViewProxy) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .updating($pressing) { _, state, _ in state = true }
            .onChanged { value in
                if !held {
                    held = true
                    introTask?.cancel()
                    introTask = nil
                    demoing = false
                }
                let raw = Int(((value.location.y - ScrollIndexMetrics.inset) / ScrollIndexMetrics.letterHeight).rounded(.down))
                select(raw.clamped(to: 0...(scrollIndexLetters.count - 1)), proxy)
            }
            .onEnded { _ in endHold() }
    }

    /// Release or system cancellation: the bubble and fisheye fold away.
    private func endHold() {
        guard held else { return }
        held = false
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { active = nil }
    }

    private func select(_ index: Int, _ proxy: ScrollViewProxy) {
        guard index != active else { return }
        withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) { active = index }
        // Jump straight to the section (or the next existing one), like the native index.
        let letter = scrollIndexLetters[index]
        let target = scrollIndexSections.first { $0.letter >= letter } ?? scrollIndexSections[scrollIndexSections.count - 1]
        var instant = Transaction()
        instant.disablesAnimations = true
        withTransaction(instant) {
            proxy.scrollTo(target.letter, anchor: .top)
        }
    }

    /// Preview: sweep the thumb down the index, rest, then back up, releasing in between.
    private func autoScrub(_ proxy: ScrollViewProxy) {
        guard ctx.isPreview else {
            introScrub(proxy)
            return
        }
        let path: [Int?] = [1, 3, 6, 9, 11, 13, 16, 18, nil, nil, 17, 14, 10, 7, 4, 1, nil, nil]
        if let index = path[autoStep % path.count] {
            select(index, proxy)
        } else if active != nil {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { active = nil }
        }
        autoStep += 1
    }

    /// Detail stage, once on arrival: a quick sweep down and back, then release and return to the top.
    private func introScrub(_ proxy: ScrollViewProxy) {
        guard !demoing, !held, active == nil else { return }
        demoing = true
        introTask = Task { @MainActor in
            defer { demoing = false }
            for index in [1, 4, 7, 10, 12, 9, 5] {
                guard !Task.isCancelled else { return }
                select(index, proxy)
                try? await Task.sleep(for: .milliseconds(170))
            }
            try? await Task.sleep(for: .milliseconds(250))
            guard !Task.isCancelled else { return }
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { active = nil }
            withAnimation(.smooth(duration: 0.5)) { proxy.scrollTo(scrollIndexSections[0].letter, anchor: .top) }
        }
    }
}

private struct ScrollIndexSectionView: View {
    let section: ScrollIndexSection
    let language: AppLanguage

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(verbatim: section.letter)
                .font(.footnote.weight(.bold))
                .foregroundStyle(.secondary)
                .padding(.top, 10)
            ForEach(section.names.indices, id: \.self) { i in
                ScrollIndexRow(name: section.names[i], seed: section.letter.unicodeScalars.first.map { Int($0.value) } ?? 0, offset: i, language: language)
            }
        }
    }
}

private struct ScrollIndexRow: View {
    let name: LocalizedText
    let seed: Int
    let offset: Int
    let language: AppLanguage

    var body: some View {
        let colors = ScrollKit.colors(seed + offset)
        let label = name(language)
        HStack(spacing: 12) {
            Text(verbatim: String(label.prefix(1)))
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 34, height: 34)
                .background(LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing), in: Circle())
            Text(verbatim: label)
                .font(.subheadline.weight(.medium))
            Spacer(minLength: 0)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background(Palette.elevated, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

/// The vertical A–Z strip with fisheye magnification and the floating letter bubble.
private struct ScrollIndexBar: View {
    let active: Int?
    let magnify: Double
    let reach: Double
    let showsBubble: Bool

    var body: some View {
        VStack(spacing: 0) {
            ForEach(scrollIndexLetters.indices, id: \.self) { i in
                let lift = falloff(i)
                Text(verbatim: scrollIndexLetters[i])
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundStyle(i == active ? AnyShapeStyle(Palette.primary) : AnyShapeStyle(Palette.indigo))
                    .frame(width: 22, height: ScrollIndexMetrics.letterHeight)
                    .scaleEffect(1 + CGFloat(magnify * lift), anchor: .trailing)
                    .offset(x: -CGFloat(lift) * 14)
                    .zIndex(lift)
            }
        }
        .padding(.vertical, ScrollIndexMetrics.inset)
        .background {
            Capsule()
                .fill(Color.primary.opacity(active == nil ? 0 : 0.06))
        }
        .overlay(alignment: .topTrailing) {
            if showsBubble, let active {
                bubble(active)
                    .offset(
                        x: -56,
                        y: ScrollIndexMetrics.inset + (CGFloat(active) + 0.5) * ScrollIndexMetrics.letterHeight - 28
                    )
                    .transition(.scale(scale: 0.4, anchor: .trailing).combined(with: .opacity))
            }
        }
        .frame(height: ScrollIndexMetrics.indexHeight + ScrollIndexMetrics.inset * 2)
    }

    /// 1 at the active letter, easing to 0 `reach` letters away (cosine falloff).
    private func falloff(_ i: Int) -> Double {
        guard let active else { return 0 }
        let d = Double(abs(i - active))
        guard d < reach else { return 0 }
        return 0.5 + 0.5 * cos(.pi * d / reach)
    }

    private func bubble(_ index: Int) -> some View {
        Text(verbatim: scrollIndexLetters[index])
            .font(.system(size: 28, weight: .heavy, design: .rounded))
            .foregroundStyle(.white)
            .contentTransition(.numericText(value: Double(index)))
            .frame(width: 56, height: 56)
            .background(Palette.primary, in: Circle())
            .shadow(color: Palette.indigo.opacity(0.35), radius: 12, y: 6)
    }
}
