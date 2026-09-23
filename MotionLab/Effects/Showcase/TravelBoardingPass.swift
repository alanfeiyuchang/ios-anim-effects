import SwiftUI

extension Effect {
    static let showcaseBoardingPass = Effect(
        id: "showcase.boarding-pass",
        category: .showcase,
        interaction: .gesture,
        name: L("Tear-off Boarding Pass", "撕票登机牌"),
        summary: L(
            "Pull the stub down to tear it along the perforation and watch it tumble away; tap the ticket to flip to its barcode.",
            "向下拉票根，沿齿孔撕下后翻滚坠落；点击票面翻转显示条形码。"
        ),
        prompt: L(
            "A cream boarding pass (270 pt wide) sits on a dark stage: a main panel with HGH → NCE and flight details, then a 74 pt stub, separated by a dashed perforation with half-circle notches cut into both edges. Dragging the stub down makes it follow the finger at 85% of the drag distance. It hinges from its top-left corner by up to ~6° plus a slight sideways drift, and a rigid haptic clicks when the pull passes the 90 pt tear threshold. Released past the threshold, the stub tears free: it falls 420 pt with an ease-in “gravity” curve over 600 ms while spinning ~22°, a success haptic fires, and after 1.3 s a fresh stub springs back in from 90% scale. Released short of the threshold, it snaps back with a bouncy spring. Tapping the main panel flips it 180° in 3D over 0.55 s, and the faces swap exactly at the halfway point to reveal a barcode. It feels physical, crisp and satisfying.",
            "暗色舞台上放着一张奶油白登机牌（宽 270pt）：主票面写着 HGH → NCE 和航班信息，下方是 74pt 高的票根，两者之间是一条虚线齿孔，两侧各切出半圆缺口。向下拖动票根时，它以拖动距离的 85% 跟手移动，以左上角为铰点最多倾斜约 6°，并随手指略微横向漂移；拉过 90pt 撕裂阈值时触发一下清脆的硬朗触感。超过阈值后松手，票根被撕下：以缓入的「重力」曲线在 600 毫秒内下坠 420pt，同时旋转约 22°，触发成功触感；1.3 秒后新的票根从 90% 缩放弹回原位。未达阈值松手，票根会带着弹性回弹。点击主票面，它以 0.55 秒做 180° 立体翻转，正反面恰好在一半时交换，露出条形码。整体有真实的物理感，干脆利落，令人满足。"
        ),
        implementation: L(
            "Two custom Shapes built with Path(roundedRect:cornerRadii:) minus notch ellipses via Path.subtracting; the stub is driven by a DragGesture offset/rotation with a threshold, and the fall and regrow are sequenced with withAnimation and a Task. The flip uses rotation3DEffect, with the face opacity swapped by a delayed zero-length animation.",
            "两个自定义 Shape 由 Path(roundedRect:cornerRadii:) 减去缺口椭圆（Path.subtracting）得到；票根由 DragGesture 驱动偏移与旋转并设撕裂阈值，坠落与复原用 withAnimation 和 Task 串联；翻转使用 rotation3DEffect，正反面透明度通过延迟的瞬时动画在中点切换。"
        ),
        apis: ["DragGesture", "Path.subtracting", "rotation3DEffect", "withAnimation", "Haptics"],
        tags: ["ticket", "boarding pass", "tear", "flip", "gravity", "登机牌", "撕票", "翻转", "重力"],
        params: [
            .slider("threshold", L("Tear threshold", "撕裂阈值"), 50...150, default: 90, decimals: 0, unit: "pt"),
            .slider("spin", L("Fall spin", "坠落旋转"), 0...60, default: 22, decimals: 0, unit: "°"),
            .slider("flip", L("Flip duration", "翻转时长"), 0.3...1.2, default: 0.55, unit: "s"),
        ]
    ) { ctx in
        TravelBoardingDemo(ctx: ctx)
    }
}

// MARK: - Shape

/// A ticket piece with square corners (and half-notches) on the perforated edge.
private struct TravelTicketShape: Shape {
    var perforationOnTop: Bool
    var cornerRadius: CGFloat = 20
    var notchRadius: CGFloat = 11

    func path(in rect: CGRect) -> Path {
        let radii = perforationOnTop
            ? RectangleCornerRadii(topLeading: 0, bottomLeading: cornerRadius, bottomTrailing: cornerRadius, topTrailing: 0)
            : RectangleCornerRadii(topLeading: cornerRadius, bottomLeading: 0, bottomTrailing: 0, topTrailing: cornerRadius)
        let base = Path(roundedRect: rect, cornerRadii: radii, style: .continuous)
        let y = perforationOnTop ? rect.minY : rect.maxY
        let d = notchRadius * 2
        var holes = Path()
        holes.addEllipse(in: CGRect(x: rect.minX - notchRadius, y: y - notchRadius, width: d, height: d))
        holes.addEllipse(in: CGRect(x: rect.maxX - notchRadius, y: y - notchRadius, width: d, height: d))
        return base.subtracting(holes)
    }
}

// MARK: - Demo

private struct TravelBoardingDemo: View {
    let ctx: DemoContext
    @State private var pull: CGSize = .zero
    @State private var armed = false
    @State private var torn = false
    @State private var regrowing = false
    @State private var flipped = false
    @State private var step = 0

    private var zh: Bool { ctx.language == .zh }
    private var threshold: CGFloat { ctx.cg("threshold") }

    var body: some View {
        SignatureStage {
            VStack(spacing: 0) {
                TravelTicketMain(zh: zh, flipped: flipped, flipDuration: ctx["flip"])
                    .onTapGesture(perform: flip)
                    .zIndex(1)
                stub
                    .zIndex(2)
                DemoHint(text: L("Pull the stub down · tap to flip", "下拉票根撕下 · 点击翻面"), ctx: ctx)
                    .padding(.top, 16)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .autoplay(ctx.isPreview, every: 2.6, delay: 0.5) { autoplayStep() }
    }

    private var stubAngle: Double {
        if torn { return ctx["spin"] }
        return Double(min(pull.height, threshold) / max(threshold, 1)) * 6 + Double(pull.width) * 0.04
    }

    private var stub: some View {
        TravelTicketStub(zh: zh, armed: armed)
            .rotationEffect(.degrees(stubAngle), anchor: .topLeading)
            .offset(x: torn ? pull.width * 0.3 + 30 : pull.width * 0.3, y: torn ? 420 : pull.height)
            .scaleEffect(regrowing ? 0.9 : 1, anchor: .top)
            .opacity(regrowing ? 0 : 1)
            .gesture(tearGesture)
    }

    private var tearGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                guard !torn, !regrowing else { return }
                pull = CGSize(width: value.translation.width, height: max(0, value.translation.height) * 0.85)
                let crossed = pull.height > threshold
                if crossed != armed {
                    armed = crossed
                    Haptics.tap(.rigid)
                }
            }
            .onEnded { _ in
                guard !torn, !regrowing else { return }
                if pull.height > threshold {
                    tear()
                } else {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.55)) { pull = .zero }
                }
                armed = false
            }
    }

    private func tear() {
        if !ctx.isPreview { Haptics.success() }
        withAnimation(.easeIn(duration: 0.6)) { torn = true }
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(1.3))
            var reset = Transaction()
            reset.disablesAnimations = true
            withTransaction(reset) {
                regrowing = true
                torn = false
                pull = .zero
                armed = false
            }
            try? await Task.sleep(for: .milliseconds(40))
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) { regrowing = false }
        }
    }

    private func flip() {
        if !ctx.isPreview { Haptics.tap() }
        withAnimation(.easeInOut(duration: ctx["flip"])) { flipped.toggle() }
    }

    private func autoplayStep() {
        switch step % 3 {
        case 0:
            withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
                pull = CGSize(width: 14, height: threshold * 0.75)
            }
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(500))
                tear()
            }
        default:
            // Steps 1 and 2 flip to the barcode and back.
            flip()
        }
        step += 1
    }
}

// MARK: - Main panel

private struct TravelTicketMain: View {
    let zh: Bool
    let flipped: Bool
    let flipDuration: Double

    var body: some View {
        ZStack {
            TravelTicketFront(zh: zh)
                .opacity(flipped ? 0 : 1)
            TravelTicketBack(zh: zh)
                .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
                .opacity(flipped ? 1 : 0)
        }
        // Swap faces exactly at the midpoint of the flip.
        .animation(.linear(duration: 0.001).delay(flipDuration / 2), value: flipped)
        .frame(width: 270, height: 168)
        .background {
            TravelTicketShape(perforationOnTop: false)
                .fill(LinearGradient(colors: [Signature.paper, Color(hex: 0xE6E2D9)], startPoint: .top, endPoint: .bottom))
                .shadow(color: Color.black.opacity(0.4), radius: 16, y: 8)
        }
        .rotation3DEffect(.degrees(flipped ? 180 : 0), axis: (x: 0, y: 1, z: 0), perspective: 0.6)
        .contentShape(Rectangle())
    }
}

private struct TravelTicketFront: View {
    let zh: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(zh ? "登机牌" : "Boarding pass")
                    .signatureEyebrow(light: true)
                Spacer(minLength: 0)
                Text("MU 7123")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(Signature.accentHot)
            }
            HStack(alignment: .center) {
                airport(code: "HGH", city: zh ? "杭州" : "Hangzhou", alignment: .leading)
                Spacer(minLength: 0)
                route
                Spacer(minLength: 0)
                airport(code: "NCE", city: zh ? "尼斯" : "Nice", alignment: .trailing)
            }
            HStack {
                detail(zh ? "登机口" : "Gate", "B12")
                Spacer(minLength: 0)
                detail(zh ? "登机" : "Boards", "09:40")
                Spacer(minLength: 0)
                detail(zh ? "座位" : "Seat", "12A")
            }
        }
        .padding(18)
    }

    private var route: some View {
        HStack(spacing: 4) {
            Circle().fill(Signature.ink.opacity(0.3)).frame(width: 4, height: 4)
            Image(systemName: "airplane")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Signature.accent)
            Circle().fill(Signature.ink.opacity(0.3)).frame(width: 4, height: 4)
        }
    }

    private func airport(code: String, city: String, alignment: HorizontalAlignment) -> some View {
        VStack(alignment: alignment, spacing: 0) {
            Text(code)
                .font(.system(size: 32, weight: .heavy, design: .rounded))
                .foregroundStyle(Signature.ink)
            Text(city)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Signature.ink.opacity(0.5))
        }
    }

    private func detail(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).signatureEyebrow(light: true)
            Text(value)
                .font(Signature.number(15))
                .foregroundStyle(Signature.ink)
        }
    }
}

private struct TravelTicketBack: View {
    let zh: Bool

    private static let widths: [CGFloat] = [1, 3, 1, 2, 4, 1, 1, 3, 2, 1, 2, 3, 1, 4, 2, 1]

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 1.5) {
                ForEach(0..<48, id: \.self) { index in
                    Rectangle()
                        .fill(Signature.ink)
                        .frame(width: Self.widths[index % Self.widths.count])
                }
            }
            .frame(height: 70)
            Text(zh ? "登机口扫码 · 12A" : "Scan at gate · 12A")
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundStyle(Signature.ink.opacity(0.6))
        }
        .padding(18)
    }
}

// MARK: - Stub

private struct TravelTicketStub: View {
    let zh: Bool
    let armed: Bool

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text(zh ? "登机组别" : "Boarding group")
                    .signatureEyebrow(light: true)
                Text(zh ? "A 组 · 12A" : "Group A · 12A")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(Signature.ink)
            }
            Spacer(minLength: 0)
            Image(systemName: armed ? "scissors" : "chevron.down.2")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(armed ? Signature.accentHot : Signature.ink.opacity(0.4))
                .contentTransition(.symbolEffect(.replace))
        }
        .padding(.horizontal, 18)
        .frame(width: 270, height: 74)
        .background {
            TravelTicketShape(perforationOnTop: true)
                .fill(LinearGradient(colors: [Color(hex: 0xE9E5DC), Color(hex: 0xDDD8CD)], startPoint: .top, endPoint: .bottom))
                .shadow(color: Color.black.opacity(0.35), radius: 12, y: 6)
        }
        .overlay(alignment: .top) {
            Line()
                .stroke(Signature.ink.opacity(0.25), style: StrokeStyle(lineWidth: 1.2, dash: [4, 4]))
                .frame(height: 1)
                .padding(.horizontal, 16)
        }
        .contentShape(Rectangle())
    }

    private struct Line: Shape {
        func path(in rect: CGRect) -> Path {
            var path = Path()
            path.move(to: CGPoint(x: rect.minX, y: rect.midY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
            return path
        }
    }
}
