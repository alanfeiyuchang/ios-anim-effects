import SwiftUI

extension Effect {
    static let inputsGrowScrubber = Effect(
        id: "inputs.grow-scrubber",
        category: .inputs,
        interaction: .gesture,
        name: L("Grow-on-Grab Scrubber", "按住变粗的进度条"),
        summary: L("A hairline media scrubber that swells when grabbed, with fine-scrubbing as you slide down.", "细如发丝的播放进度条，按住即膨胀，手指下移可精细拖动。"),
        prompt: L(
            "A Now Playing scrubber in the style of Apple Music: a knobless 6 pt hairline track under the song title with elapsed and remaining times beneath. Touching it anywhere grabs it: the bar swells to 18 pt tall and 104% wide on a smooth spring (response 0.3 s, damping 0.8), the fill brightens from secondary grey to full primary, and the time labels grow bold and slide 6 pt down to make room. Movement is relative, and dragging the finger below the bar slows the scrub rate — full speed, then half-speed past 40 pt and fine (¼) past 90 pt — with a capsule label that swaps in via a blur transition to announce the mode. Releasing shrinks everything back in 350 ms. Quiet at rest, generous and precise in the hand.",
            "仿 Apple Music 的“正在播放”进度条：歌名下方是一条无滑块的 6pt 细线轨道，下面是已播放与剩余时间。按住任意处即“抓起”：进度条以顺滑弹簧（响应 0.3 秒、阻尼 0.8）膨胀到 18pt 高、104% 宽，填充由次级灰提亮为主色，时间标签加粗并下移 6pt。拖动为相对位移，手指向下离开进度条会降低速率——正常、超过 40pt 半速、超过 90pt 精细（¼ 速），一枚胶囊标签以模糊过渡提示当前模式。松手后 350 毫秒内收回。静时低调，握时精准。"
        ),
        implementation: L(
            "A DragGesture tracks the last x to apply incremental, rate-scaled changes; the vertical translation picks the scrub rate, and the grabbed state animates the bar's frame height, a horizontal scaleEffect and the label offsets.",
            "DragGesture 记录上一次的 x，按速率缩放后增量更新进度；纵向位移决定拖动速率，“抓起”状态驱动进度条的高度、横向 scaleEffect 与标签偏移。"
        ),
        apis: ["DragGesture", "frame(height:)", "scaleEffect(x:y:)", "transition(.blurReplace)", "numericText"],
        tags: ["slider", "scrubber", "media", "fine scrubbing", "滑块", "进度条", "播放器", "精细拖动"],
        params: [
            .slider("thickness", L("Grabbed thickness", "按住时粗细"), 10...30, default: 18, decimals: 0, unit: "pt"),
            .slider("response", L("Grow response", "膨胀响应"), 0.15...0.7, default: 0.3, unit: "s"),
            .toggle("fine", L("Fine scrubbing", "精细拖动"), default: true),
        ]
    ) { ctx in
        GrowScrubberDemo(ctx: ctx)
    }
}

private enum ScrubRate: Int {
    case full
    case half
    case fine

    var factor: Double {
        switch self {
        case .full: return 1
        case .half: return 0.5
        case .fine: return 0.25
        }
    }

    var label: LocalizedText {
        switch self {
        case .full: return L("Hi-Speed Scrubbing", "高速拖动")
        case .half: return L("Half-Speed Scrubbing", "半速拖动")
        case .fine: return L("Fine Scrubbing", "精细拖动")
        }
    }
}

private struct GrowScrubberDemo: View {
    let ctx: DemoContext
    @State private var progress: Double = 0.36
    @State private var grabbed = false
    @State private var rate: ScrubRate = .full
    @State private var lastX: CGFloat = 0
    @State private var step = 0

    private let width: CGFloat = 270
    private let duration = 222

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            card
            Spacer()
            DemoHint(text: L("Hold the bar, then slide your finger down", "按住进度条，再把手指往下移"), ctx: ctx)
                .padding(.bottom, 18)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 2.4, delay: 0.3) { previewScrub() }
    }

    private func clock(_ seconds: Int) -> String {
        String(format: "%d:%02d", seconds / 60, seconds % 60)
    }

    private var card: some View {
        let elapsed = Int(progress * Double(duration))
        return VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Palette.aurora)
                    .frame(width: 46, height: 46)
                    .overlay(Image(systemName: "waveform").foregroundStyle(.white))
                VStack(alignment: .leading, spacing: 2) {
                    Text(L("Northern Lights", "北方之光"), ctx.language)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                    Text(verbatim: "Aster Vale")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
            }
            bar
            HStack {
                Text(clock(elapsed))
                Spacer(minLength: 0)
                if grabbed && ctx.bool("fine") {
                    Text(rate.label, ctx.language)
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(Palette.indigo)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Palette.indigo.opacity(0.12), in: Capsule())
                        .id(rate)
                        .transition(.blurReplace)
                }
                Spacer(minLength: 0)
                Text("-" + clock(duration - elapsed))
            }
            .font(.caption.weight(grabbed ? .bold : .medium).monospacedDigit())
            .foregroundStyle(grabbed ? Color.primary : Color.secondary)
            .offset(y: grabbed ? 6 : 0)
            .animation(.spring(response: ctx["response"], dampingFraction: 0.8), value: grabbed)
            .animation(.smooth(duration: 0.25), value: rate)
        }
        .padding(18)
        .frame(width: width + 36)
        .demoCard(cornerRadius: 26)
    }

    private var bar: some View {
        let height: CGFloat = grabbed ? ctx.cg("thickness") : 6
        return ZStack(alignment: .leading) {
            Capsule().fill(Color.primary.opacity(0.1))
            Capsule()
                .fill(grabbed ? Color.primary : Color.secondary)
                .frame(width: max(width * CGFloat(progress), height))
        }
        .frame(width: width, height: height)
        .scaleEffect(x: grabbed ? 1.04 : 1, y: 1)
        .shadow(color: .black.opacity(grabbed ? 0.12 : 0), radius: 8, y: 4)
        .frame(height: 30)
        .contentShape(Rectangle())
        .gesture(drag)
        .animation(.spring(response: ctx["response"], dampingFraction: 0.8), value: grabbed)
    }

    private var drag: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                if !grabbed {
                    grabbed = true
                    lastX = value.location.x
                    Haptics.tap(.soft)
                }
                let newRate = rateFor(depth: value.translation.height)
                if newRate != rate {
                    rate = newRate
                    Haptics.selection()
                }
                let dx: CGFloat = value.location.x - lastX
                lastX = value.location.x
                let delta: Double = Double(dx / width) * rate.factor
                progress = (progress + delta).clamped(to: 0...1)
            }
            .onEnded { _ in
                withAnimation(.smooth(duration: 0.35)) {
                    grabbed = false
                    rate = .full
                }
            }
    }

    private func rateFor(depth: CGFloat) -> ScrubRate {
        guard ctx.bool("fine") else { return .full }
        if depth > 90 { return .fine }
        if depth > 40 { return .half }
        return .full
    }

    private func previewScrub() {
        step += 1
        let forward = step % 2 == 1
        grabbed = true
        rate = .full
        withAnimation(.smooth(duration: 0.6)) { progress = forward ? 0.62 : 0.3 }
        Task {
            try? await Task.sleep(for: .seconds(0.7))
            if ctx.bool("fine") { rate = .half }
            withAnimation(.smooth(duration: 0.6)) { progress += forward ? 0.05 : -0.05 }
            try? await Task.sleep(for: .seconds(0.8))
            withAnimation(.smooth(duration: 0.35)) {
                grabbed = false
                rate = .full
            }
        }
    }
}
