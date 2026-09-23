import SwiftUI

extension Effect {
    static let iconsBookmarkSave = Effect(
        id: "icons.bookmark-save",
        category: .icons,
        interaction: .tap,
        name: L("Bookmark Ribbon", "书签丝带"),
        summary: L("The ribbon stretches down like cloth, fills top-to-bottom and flicks out two sparks.", "丝带像布料一样向下拉伸，自上而下填色，并甩出两粒火花。"),
        prompt: L(
            "A 44×58 pt bookmark ribbon, outlined in 3 pt, sits in the corner of an article card. Tapping Save stretches the ribbon downward from its top edge to 125% height in 110 ms, as if tugged, then springs back through 94% to 100% (bouncy keyframes over ~0.5 s). While it stretches, an amber-to-coral fill pours in from top to bottom over 350 ms, and two small sparks flick out left and right of the notch and fade within 400 ms. A 'Saved' pill slides out beside it and retracts after 1.2 s. Unsaving squashes the ribbon to 90% and drains the fill upward in 250 ms. A light haptic accompanies each state. It feels tactile and fabric-like rather than a flat icon swap.",
            "文章卡片角落有一枚 44×58 pt、3 pt 描边的书签丝带。点击收藏时，丝带以上边缘为锚点在 110 毫秒内向下拉伸到 125% 高度，像被人扯了一下，随后经过 94% 弹回 100%（约 0.5 秒的弹性关键帧）。拉伸的同时，琥珀到珊瑚的渐变色在 350 毫秒内自上而下灌满丝带，缺口两侧各甩出一粒小火花，并在 400 毫秒内消散。旁边滑出一枚「已收藏」小胶囊，1.2 秒后收回。取消收藏时丝带压扁到 90%，填色在 250 毫秒内向上退去。每次状态变化伴随轻触感。像真实布料一样有手感，而不是扁平的图标替换。"
        ),
        implementation: L(
            "A custom notched-ribbon Shape is stroked and filled; the fill is masked by a top-anchored Rectangle whose height animates, a keyframeAnimator keyed to the tap count drives scaleEffect(y:anchor: .top), and sparks are offset circles animated with a separate trigger.",
            "自定义带缺口的丝带 Shape 先描边再填充；填充被一个顶部锚定、高度可动画的 Rectangle 遮罩；以点击次数为触发器的 keyframeAnimator 驱动 scaleEffect(y:anchor: .top)，火花是带位移动画的小圆点，由单独的触发器驱动。"
        ),
        apis: ["Shape", "keyframeAnimator", "mask(alignment:_:)", "scaleEffect(x:y:anchor:)", "transition(.move)"],
        tags: ["bookmark", "save", "ribbon", "favorite", "书签", "收藏", "丝带", "保存"],
        params: [
            .slider("stretch", L("Stretch", "拉伸"), 1.0...1.5, default: 1.25),
            .slider("fill", L("Fill duration", "填色时长"), 0.15...1.0, default: 0.35, unit: "s"),
            .toggle("sparks", L("Sparks", "火花"), default: true),
        ]
    ) { ctx in
        BookmarkSaveDemo(ctx: ctx)
    }
}

/// A ribbon with a V notch at the bottom.
private struct RibbonShape: Shape {
    func path(in rect: CGRect) -> Path {
        let radius: CGFloat = 5
        let notch: CGFloat = rect.height * 0.22
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY + radius))
        path.addQuadCurve(to: CGPoint(x: rect.minX + radius, y: rect.minY), control: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - radius, y: rect.minY))
        path.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.minY + radius), control: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY - notch))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

private struct BookmarkSaveDemo: View {
    let ctx: DemoContext
    @State private var saved = false
    @State private var saves = 0
    @State private var unsaves = 0
    @State private var toast = false
    @State private var token = 0

    private let size = CGSize(width: 44, height: 58)

    var body: some View {
        VStack(spacing: 18) {
            card
            DemoHint(text: L("Tap the bookmark", "点击书签"), ctx: ctx)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 1.8) { toggle() }
    }

    private var card: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(L("DESIGN NOTES", "设计笔记"), ctx.language)
                        .font(.caption2.weight(.heavy))
                        .foregroundStyle(Palette.coral)
                    Text(L("Why springs beat curves", "为什么弹簧胜过曲线"), ctx.language)
                        .font(.headline)
                }
                Spacer(minLength: 8)
                ribbonButton
            }
            .overlay(alignment: .topTrailing) {
                savedPill
                    .padding(.trailing, size.width + 8)
            }
            PlaceholderLines(count: 3)
        }
        .padding(18)
        .frame(width: 300)
        .demoCard()
    }

    private var savedPill: some View {
        ZStack {
            if toast {
                Text(L("Saved", "已收藏"), ctx.language)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .frame(height: 24)
                    .background(Palette.coral, in: Capsule())
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .frame(width: 64, alignment: .trailing)
        .clipped()
        .padding(.top, 16)
    }

    private var ribbonButton: some View {
        let stretch: CGFloat = ctx.cg("stretch")
        return Button { toggle() } label: {
            ZStack {
                RibbonShape()
                    .fill(LinearGradient(colors: [Palette.amber, Palette.coral], startPoint: .top, endPoint: .bottom))
                    .mask(alignment: .top) {
                        Rectangle().frame(height: saved ? size.height : 0)
                    }
                RibbonShape()
                    .stroke(saved ? Palette.coral : Color.primary.opacity(0.6), style: StrokeStyle(lineWidth: 3, lineJoin: .round))
            }
            .frame(width: size.width, height: size.height)
            .keyframeAnimator(initialValue: CGFloat(1), trigger: saves) { content, scale in
                content.scaleEffect(x: 1, y: scale, anchor: .top)
            } keyframes: { _ in
                KeyframeTrack(\.self) {
                    CubicKeyframe(stretch, duration: 0.11)
                    SpringKeyframe(CGFloat(0.94), duration: 0.16, spring: .snappy)
                    SpringKeyframe(CGFloat(1), duration: 0.3, spring: .bouncy)
                }
            }
            .keyframeAnimator(initialValue: CGFloat(1), trigger: unsaves) { content, scale in
                content.scaleEffect(x: 1, y: scale, anchor: .top)
            } keyframes: { _ in
                KeyframeTrack(\.self) {
                    CubicKeyframe(CGFloat(0.9), duration: 0.1)
                    SpringKeyframe(CGFloat(1), duration: 0.3, spring: .bouncy)
                }
            }
            .overlay(alignment: .bottom) {
                if ctx.bool("sparks") {
                    BookmarkSparks(trigger: saves)
                        .offset(y: 4)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func toggle() {
        Haptics.tap(.light)
        token += 1
        let current = token
        let fill: Double = ctx["fill"]
        if saved {
            unsaves += 1
            withAnimation(.easeIn(duration: 0.25)) {
                saved = false
                toast = false
            }
            return
        }
        saves += 1
        withAnimation(.easeOut(duration: fill)) { saved = true }
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { toast = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            guard current == token else { return }
            withAnimation(.easeIn(duration: 0.25)) { toast = false }
        }
    }
}

/// Two sparks that flick out sideways from the notch whenever `trigger` changes.
private struct BookmarkSparks: View {
    let trigger: Int

    var body: some View {
        ZStack {
            spark(direction: -1)
            spark(direction: 1)
        }
        .allowsHitTesting(false)
    }

    /// Hidden at rest (progress 1) and at the very start; fades out as the spark travels.
    static func opacity(_ progress: CGFloat) -> Double {
        let p = Double(progress)
        if p < 0.02 || p > 0.98 { return 0 }
        return 1 - p
    }

    private func spark(direction: CGFloat) -> some View {
        Circle()
            .fill(Palette.amber)
            .frame(width: 6, height: 6)
            .keyframeAnimator(initialValue: CGFloat(1), trigger: trigger) { content, progress in
                content
                    .offset(x: direction * 26 * progress, y: -6 * progress)
                    .scaleEffect(1 - 0.6 * progress)
                    .opacity(BookmarkSparks.opacity(progress))
            } keyframes: { _ in
                KeyframeTrack(\.self) {
                    LinearKeyframe(CGFloat(0), duration: 0.001)
                    LinearKeyframe(CGFloat(0), duration: 0.08)
                    CubicKeyframe(CGFloat(1), duration: 0.4)
                }
            }
    }
}
