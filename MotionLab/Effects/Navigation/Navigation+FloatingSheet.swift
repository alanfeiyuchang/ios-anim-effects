import SwiftUI

extension Effect {
    static let navigationFloatingSheet = Effect(
        id: "navigation.floating-sheet",
        category: .navigation,
        interaction: .gesture,
        name: L("Floating to Edge Sheet", "悬浮到贴边面板"),
        summary: L(
            "A floating glass mini player grows into a full Now Playing sheet, its margins and corners melting into the screen edges.",
            "悬浮的玻璃迷你播放条长成完整的“正在播放”面板，边距与圆角逐渐融入屏幕边缘。"
        ),
        prompt: L(
            "Over full-bleed album art, a single-row glass mini player (artwork, title, play and skip) floats 12 pt above the bottom and in from the sides with 30 pt corners. Dragging it up, or tapping, moves through three detents: 72 pt mini player, 190 pt controls, full sheet. Every property follows the height: margins shrink from 12 pt to 0, bottom corners flatten while top corners ease from 30 to 24 pt, glass turns into an opaque surface, and the scrubber, transport and 'Up Next' fade in as room appears. The sheet tracks the finger 1:1, rubber-bands past the ends and springs (response 0.45 s, damping 0.8) to the detent nearest the projected end, with a light tick each time. Floating becomes grounded in one gesture.",
            "整屏专辑封面之上，一条单行玻璃迷你播放条（封面、歌名、播放与下一首）悬浮在距底部与两侧 12 pt 处，圆角 30 pt。向上拖动或轻点，依次经过三档：72 pt 迷你条、190 pt 控制区、全屏面板。一切都随高度变化：边距从 12 pt 收到 0，底部圆角渐平、顶部圆角由 30 缓到 24 pt，玻璃渐变为不透明表面；进度条、播放控件与“待播清单”随空间出现依次淡入。面板 1:1 跟手，越界有橡皮筋阻尼，松手按预测终点以弹簧（响应 0.45 秒、阻尼 0.8）吸附到最近档位，每档一记轻触。一个手势，由悬浮到贴边。"
        ),
        implementation: L(
            "Sheet height is the only state; margins, corner radii (UnevenRoundedRectangle) and the opacity of an opaque layer over the material are all interpolated from it in body, so drag and spring stay in lockstep.",
            "面板高度是唯一的状态；边距、圆角（UnevenRoundedRectangle）以及叠在材质上的不透明层的透明度都在 body 中由高度插值得出，因此拖拽与弹簧始终同步。"
        ),
        apis: ["UnevenRoundedRectangle", "DragGesture", "predictedEndTranslation", "Material", "spring(response:dampingFraction:)"],
        tags: ["sheet", "detents", "now playing", "mini player", "面板", "档位", "正在播放", "迷你播放器"],
        params: [
            .slider("response", L("Spring response", "弹簧响应"), 0.25...0.8, default: 0.45, unit: "s"),
            .slider("damping", L("Damping", "阻尼"), 0.55...1.0, default: 0.8),
            .toggle("glass", L("Glass when compact", "紧凑时为玻璃"), default: true),
        ]
    ) { ctx in
        FloatingSheetDemo(ctx: ctx)
    }
}

private struct FloatingSheetDemo: View {
    let ctx: DemoContext
    @State private var height: CGFloat = 72
    @State private var dragStart: CGFloat?
    @State private var autoStep = 0
    /// Resets on system cancellation too, so a cancelled drag still settles and never leaves a stale `dragStart`.
    @GestureState private var dragging = false

    private let frameSize = CGSize(width: 250, height: 330)
    private var detents: [CGFloat] { [72, 190, frameSize.height - 30] }

    var body: some View {
        VStack(spacing: 14) {
            ZStack(alignment: .bottom) {
                FloatingAlbumBackdrop()
                sheet
            }
            .frame(width: frameSize.width, height: frameSize.height)
            .clipShape(RoundedRectangle(cornerRadius: 34, style: .continuous))
            .shadow(color: .black.opacity(0.18), radius: 18, y: 10)
            DemoHint(text: L("Drag the sheet or tap it", "拖动或点击面板"), ctx: ctx)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 1.3) {
            let sequence: [Int] = [1, 2, 1, 0]
            snap(to: detents[sequence[autoStep % sequence.count]])
            autoStep += 1
        }
    }

    private var sheet: some View {
        let low: CGFloat = detents[0]
        let high: CGFloat = detents[2]
        let t: CGFloat = min(max((height - low) / (high - low), 0), 1)
        let margin: CGFloat = 12 * (1 - t)
        let topRadius: CGFloat = 30 - 6 * t
        let bottomRadius: CGFloat = 30 * (1 - t)
        let shape = UnevenRoundedRectangle(
            topLeadingRadius: topRadius,
            bottomLeadingRadius: bottomRadius,
            bottomTrailingRadius: bottomRadius,
            topTrailingRadius: topRadius,
            style: .continuous
        )
        let solid: Double = ctx.bool("glass") ? Double(min(t * 1.6, 1)) : 1
        return FloatingSheetContent(expansion: t, language: ctx.language)
            .frame(width: frameSize.width - margin * 2, height: max(height, 56), alignment: .top)
            .background {
                ZStack {
                    shape.fill(.ultraThinMaterial)
                    shape.fill(Palette.elevated).opacity(solid)
                }
            }
            .clipShape(shape)
            .overlay(shape.stroke(Color.white.opacity(0.25 * (1 - solid)), lineWidth: 1))
            .shadow(color: .black.opacity(0.18), radius: 16, y: 4)
            .padding(.bottom, margin)
            .contentShape(Rectangle())
            .gesture(drag)
            .onTapGesture { cycle() }
            .onChange(of: dragging) { _, active in
                if !active { finish(projected: nil) }
            }
    }

    private var drag: some Gesture {
        // Global space: the sheet's top edge rises with the finger, so local translation would feed back.
        DragGesture(minimumDistance: 6, coordinateSpace: .global)
            .updating($dragging) { _, state, _ in state = true }
            .onChanged { value in
                let start = dragStart ?? height
                if dragStart == nil { dragStart = height }
                let raw: CGFloat = start - value.translation.height
                let low: CGFloat = detents[0]
                let high: CGFloat = detents[2]
                if raw > high {
                    height = high + rubberBand(raw - high, limit: 24)
                } else if raw < low {
                    height = low + rubberBand(raw - low, limit: 24)
                } else {
                    height = raw
                }
            }
            .onEnded { value in
                let start: CGFloat = dragStart ?? height
                finish(projected: start - value.predictedEndTranslation.height)
            }
    }

    /// Normal release (flick-projected height) or cancellation (current height); runs once per drag.
    private func finish(projected: CGFloat?) {
        guard dragStart != nil else { return }
        dragStart = nil
        let target: CGFloat = projected ?? height
        let nearest: CGFloat = detents.min { abs($0 - target) < abs($1 - target) } ?? detents[0]
        snap(to: nearest)
    }

    private func cycle() {
        let index: Int = detents.firstIndex { abs($0 - height) < 1 } ?? 0
        snap(to: detents[(index + 1) % detents.count])
    }

    private func snap(to target: CGFloat) {
        if !ctx.isPreview && abs(target - height) > 1 { Haptics.tap(.light) }
        withAnimation(.spring(response: ctx["response"], dampingFraction: ctx["damping"])) {
            height = target
        }
    }
}

private struct FloatingSheetContent: View {
    let expansion: CGFloat
    let language: AppLanguage

    private func reveal(from start: CGFloat, span: CGFloat = 0.3) -> Double {
        Double(min(max((expansion - start) / span, 0), 1))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Capsule()
                .fill(Color.secondary.opacity(0.45))
                .frame(width: 36, height: 5 * (0.4 + expansion))
                .frame(maxWidth: .infinity)
                .padding(.top, 6)
                .opacity(0.3 + 0.7 * Double(expansion))
            miniRow
            scrubber
                .opacity(reveal(from: 0.1))
            upNext
                .opacity(reveal(from: 0.55))
        }
        .padding(.horizontal, 14)
    }

    private var miniRow: some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(LinearGradient(colors: [Palette.violet, Palette.pink, Palette.amber], startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 40, height: 40)
                .overlay { Image(systemName: "music.note").font(.system(size: 15, weight: .bold)).foregroundStyle(.white) }
            VStack(alignment: .leading, spacing: 1) {
                Text(L("Midnight Drive", "午夜兜风"), language)
                    .font(.subheadline.weight(.bold))
                Text(L("Neon Coast", "霓虹海岸"), language)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .lineLimit(1)
            Spacer(minLength: 4)
            Image(systemName: "pause.fill")
                .font(.system(size: 18, weight: .semibold))
            Image(systemName: "forward.fill")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.secondary)
        }
    }

    private var scrubber: some View {
        VStack(spacing: 6) {
            ZStack(alignment: .leading) {
                Capsule().fill(Color.primary.opacity(0.12))
                Capsule().fill(Color.primary.opacity(0.7)).frame(width: 84)
            }
            .frame(height: 4)
            HStack {
                Text(verbatim: "1:12")
                Spacer()
                Text(verbatim: "-2:31")
            }
            .font(.caption2.monospacedDigit())
            .foregroundStyle(.secondary)
            HStack(spacing: 34) {
                Image(systemName: "backward.fill")
                Image(systemName: "pause.circle.fill").font(.system(size: 34))
                Image(systemName: "forward.fill")
            }
            .font(.system(size: 18, weight: .semibold))
            .frame(maxWidth: .infinity)
        }
    }

    private var upNext: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L("Up Next", "待播清单"), language)
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)
            ForEach(0..<3, id: \.self) { index in
                HStack(spacing: 8) {
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .fill(Palette.spectrum[(index + 2) % Palette.spectrum.count].gradient)
                        .frame(width: 26, height: 26)
                    Capsule().fill(Color.primary.opacity(0.12)).frame(width: CGFloat(110 - index * 18), height: 8)
                }
            }
        }
    }
}

/// Full-bleed album art behind the player, so the glass has something colourful to blur.
private struct FloatingAlbumBackdrop: View {
    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(hex: 0x2B1A4F), Palette.violet, Palette.pink, Palette.amber], startPoint: .top, endPoint: .bottom)
            Circle()
                .fill(Palette.amber.opacity(0.55))
                .frame(width: 140, height: 140)
                .blur(radius: 30)
                .offset(x: 60, y: -80)
            Image(systemName: "music.note")
                .font(.system(size: 96, weight: .bold))
                .foregroundStyle(.white.opacity(0.28))
                .offset(y: -60)
        }
    }
}
