import SwiftUI
import UIKit

extension Effect {
    static let textVariableWeight = Effect(
        id: "text.variable-weight",
        category: .text,
        interaction: .gesture,
        name: L("Variable Weight Wave", "可变字重波浪"),
        summary: L("A wave of font weight rolls through a word; drag to pull the boldness under your finger.", "字重如波浪般在单词中流动；拖动手指，粗细随指尖聚拢。"),
        prompt: L(
            "A large display word in the system variable font breathes along its weight axis: a sine wave travels left to right, each letter easing continuously between Thin (100) and Black (900) with a 0.55 rad phase lag per letter and one full cycle every 1.25 s. Because weights interpolate rather than step, the word swells and slims like one elastic body with its width rippling, and heavier glyphs warm from indigo to coral. Dragging across the word takes over: the weight peaks under the finger with a Gaussian falloff about two letters wide, blending in over 250 ms and handing back to the wave over 400 ms on release. A monospaced “wght” readout beneath tracks the average weight; typographic and quietly hypnotic.",
            "一个大号展示单词用系统可变字体沿字重轴“呼吸”：正弦波从左向右穿过字母，每个字在Thin（100）与Black（900）之间连续过渡，相邻字母相位差0.55弧度，1.25秒一个周期。字重是连续插值而非跳档，整个单词像弹性整体般膨胀收细，宽度随之起伏；字越粗，颜色越从靛蓝暖向珊瑚色。在单词上拖动时手指接管：字重在指尖处最高，按约两个字母宽的高斯曲线向两侧衰减，250毫秒内接入，松手后400毫秒交还给波浪。下方等宽“wght”读数显示平均字重，令人着迷。"
        ),
        implementation: L(
            "A TimelineView(.animation) computes a 0…1 weight per letter (sine wave, or a Gaussian around the drag location, cross-faded by time); each letter is its own Text whose Font wraps UIFont.systemFont(ofSize:weight:) with a UIFont.Weight raw value quantised to 64 cached steps, tinted with Color.mix(with:by:).",
            "TimelineView(.animation) 为每个字母计算 0…1 的字重（正弦波，或以拖动位置为中心的高斯分布，二者按时间交叉过渡）；每个字母是独立的 Text，其 Font 由 UIFont.systemFont(ofSize:weight:) 创建，UIFont.Weight 原始值量化为 64 级并缓存，并用 Color.mix(with:by:) 着色。"
        ),
        apis: ["TimelineView(.animation)", "UIFont.Weight(rawValue:)", "Font(CTFont)", "Color.mix(with:by:)", "DragGesture"],
        tags: ["variable font", "font weight", "wave", "typography", "kinetic type", "可变字体", "字重", "波浪", "排版"],
        params: [
            .slider("speed", L("Wave speed", "波浪速度"), 0.2...2, default: 0.8, unit: " Hz"),
            .slider("spread", L("Phase per letter", "字间相位差"), 0.1...1.2, default: 0.55, unit: " rad"),
            .slider("contrast", L("Weight range", "字重范围"), 0.2...1, default: 1),
            .toggle("tint", L("Tint by weight", "按字重着色"), default: true),
        ]
    ) { ctx in
        TextVariableWeightDemo(ctx: ctx)
    }
}

/// CSS-style weights (100…900) and the matching UIFont.Weight raw values of the system font.
private let textWeightStops: [(css: Double, raw: Double)] = [
    (100, -0.8), (200, -0.6), (300, -0.4), (400, 0), (500, 0.23), (600, 0.3), (700, 0.4), (800, 0.56), (900, 0.62),
]

/// Piecewise-linear map from a CSS weight to a UIFont.Weight raw value.
private func textWeightRaw(css: Double) -> CGFloat {
    let value = css.clamped(to: 100...900)
    for i in 1..<textWeightStops.count where value <= textWeightStops[i].css {
        let a = textWeightStops[i - 1]
        let b = textWeightStops[i]
        let t = (value - a.css) / (b.css - a.css)
        return CGFloat(a.raw + (b.raw - a.raw) * t)
    }
    return CGFloat(textWeightStops[textWeightStops.count - 1].raw)
}

/// Fonts quantised to 64 weight steps and built once: the wave would otherwise create
/// six UIFonts every frame.
@MainActor
private enum TextWeightFontCache {
    private static let steps = 63
    private static let lower: CGFloat = -0.8
    private static let span: CGFloat = 1.42
    private static var fonts: [Int: Font] = [:]

    static func font(raw: CGFloat, size: CGFloat) -> Font {
        let unit: CGFloat = ((raw - lower) / span).clamped(to: 0...1)
        let step = Int((unit * CGFloat(steps)).rounded())
        let key = Int(size.rounded()) * 1_000 + step
        if let cached = fonts[key] { return cached }
        let quantised: CGFloat = lower + span * CGFloat(step) / CGFloat(steps)
        let uiFont = UIFont.systemFont(ofSize: size, weight: UIFont.Weight(rawValue: quantised))
        let font = Font(uiFont as CTFont)
        fonts[key] = font
        return font
    }
}

private struct TextVariableWeightDemo: View {
    let ctx: DemoContext
    /// Normalised (0…1) finger position across the word while dragging.
    @State private var touchX: CGFloat?
    /// Last finger position, kept so the hand-back to the wave can blend out of it.
    @State private var lastX: CGFloat = 0.5
    /// When the finger last went down or up; drives the wave ↔ finger cross-fade.
    @State private var touchChanged = Date.distantPast
    /// Resets on system cancellation too, so a stolen touch never freezes the wave under a ghost finger.
    @GestureState private var pressing = false

    private let word = Array("MOTION")
    private let fontSize: CGFloat = 60
    private let touchWidth: CGFloat = 300

    var body: some View {
        VStack(spacing: 14) {
            TimelineView(.animation(minimumInterval: MotionFrameRate.interval(preview: ctx.isPreview))) { timeline in
                let weights = self.weights(at: timeline.date)
                VStack(spacing: 10) {
                    letters(weights)
                    readout(weights)
                }
            }
            .frame(width: touchWidth, height: 130)
            .contentShape(Rectangle())
            .gesture(drag)
            DemoHint(text: L("Drag across the word", "在单词上拖动"), ctx: ctx)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onChange(of: pressing) { _, isPressing in
            if !isPressing { endHold() }
        }
    }

    private func letters(_ weights: [Double]) -> some View {
        HStack(spacing: 0) {
            ForEach(word.indices, id: \.self) { i in
                Text(verbatim: String(word[i]))
                    .font(font(for: weights[i]))
                    .foregroundStyle(color(for: weights[i]))
            }
        }
        .fixedSize()
        .frame(height: 80)
    }

    private func readout(_ weights: [Double]) -> some View {
        let average = weights.reduce(0, +) / Double(max(weights.count, 1))
        let css = Int(cssWeight(average).rounded())
        return HStack(spacing: 6) {
            Text(verbatim: "wght")
                .foregroundStyle(.tertiary)
            Text(verbatim: "\(css)")
                .monospacedDigit()
                .foregroundStyle(.secondary)
                .frame(width: 34, alignment: .leading)
        }
        .font(.system(size: 13, weight: .semibold, design: .monospaced))
    }

    // MARK: Weight model

    private func cssWeight(_ unit: Double) -> Double {
        let contrast = ctx["contrast"]
        return 500 + (unit - 0.5) * 800 * contrast
    }

    private func font(for unit: Double) -> Font {
        TextWeightFontCache.font(raw: textWeightRaw(css: cssWeight(unit)), size: fontSize)
    }

    private func color(for unit: Double) -> Color {
        guard ctx.bool("tint") else { return Color.primary }
        return Palette.indigo.mix(with: Palette.coral, by: unit.clamped(to: 0...1))
    }

    /// Per-letter weight in 0…1: the travelling wave, cross-faded with a Gaussian around the finger.
    private func weights(at date: Date) -> [Double] {
        let t = date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 10_000)
        let since = date.timeIntervalSince(touchChanged)
        let hold: Double = touchX == nil ? max(1 - since / 0.4, 0) : min(since / 0.25, 1)
        let focus = Double(touchX ?? lastX)
        let count = Double(word.count)
        return word.indices.map { i in
            let wave = 0.5 + 0.5 * sin(t * ctx["speed"] * 2 * .pi - Double(i) * ctx["spread"])
            let center = (Double(i) + 0.5) / count
            let distance = (center - focus) * count
            let finger = exp(-(distance * distance) / 2.2)
            return wave + (finger - wave) * hold
        }
    }

    private var drag: some Gesture {
        DragGesture(minimumDistance: 0)
            .updating($pressing) { _, state, _ in state = true }
            .onChanged { value in
                let x = (value.location.x / touchWidth).clamped(to: 0...1)
                if touchX == nil {
                    touchChanged = Date()
                    Haptics.tap(.soft)
                }
                touchX = x
                lastX = x
            }
            .onEnded { _ in endHold() }
    }

    /// Release or system cancellation: hand the letters back to the travelling wave.
    private func endHold() {
        guard touchX != nil else { return }
        touchX = nil
        touchChanged = Date()
    }
}
