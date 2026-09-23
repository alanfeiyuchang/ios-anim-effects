import SwiftUI

extension Effect {
    static let navigationOverlayMenu = Effect(
        id: "navigation.overlay-menu",
        category: .navigation,
        interaction: .tap,
        name: L("Curtain Overlay Menu", "幕布全屏菜单"),
        summary: L(
            "A curtain drops over the page and oversized menu words rise out of hidden slots, one line after another.",
            "一道幕布落下盖住页面，超大号菜单文字从隐藏的槽位中逐行升起。"
        ),
        prompt: L(
            "A phone frame with a small hamburger in the top-right corner. Tapping it drops a dark curtain from the top edge over ≈0.5 s on an expo-out curve (cubic-bezier 0.16, 1, 0.3, 1), its bottom edge bowing down 30 pt in the middle while it travels and flattening as it lands. Then four 30 pt bold menu words (Work, Studio, Journal, Contact) rise into view from below their own clipped line boxes, ≈60 ms apart, each tilted 6° as it enters and straightening as it settles on a spring; a small index number fades in beside each. The hamburger morphs into an ✕. Closing reverses the choreography: the words sink first, bottom line first, then the curtain retracts. Editorial, agency-portfolio polish.",
            "手机画框的右上角有一枚小小的汉堡按钮。点击后，一道深色幕布从顶部落下，约 0.5 秒，expo 缓出曲线（cubic-bezier 0.16, 1, 0.3, 1）；下落过程中幕布下沿中部向下鼓出 30pt，落定时变平。随后四个 30pt 粗体菜单词（作品、工作室、日志、联系）依次从各自被裁切的行框下方升起，间隔约 60 毫秒，入场时倾斜 6°，以弹簧落定时回正；旁边的小序号随之淡入。汉堡按钮变形为 ✕。关闭时编排反向：文字先沉下（从最后一行开始），然后幕布收起。杂志感、设计工作室作品集级别的质感。"
        ),
        implementation: L(
            "The curtain is an Animatable Shape whose progress sets both its bottom edge and a sine-shaped bow; each menu word sits in a clipped frame and animates its y offset and rotation with animation(_:value:) delays that depend on the open state, so opening and closing run in opposite orders.",
            "幕布是一个可动画的 Shape，其进度同时决定下沿位置与正弦形的鼓出量；每个菜单词放在被裁切的框内，通过 animation(_:value:) 为 y 位移与旋转设置随开合状态变化的延迟，从而让打开与关闭以相反顺序播放。"
        ),
        apis: ["Shape", "animatableData", "clipped()", "animation(_:value:)", "timingCurve"],
        tags: ["menu", "overlay", "curtain", "typography", "菜单", "全屏菜单", "幕布", "排版"],
        params: [
            .slider("stagger", L("Line stagger", "行错峰"), 0.02...0.12, default: 0.06, unit: "s"),
            .slider("duration", L("Curtain duration", "幕布时长"), 0.3...0.9, default: 0.5, unit: "s"),
            .toggle("tilt", L("Tilt words in", "文字倾斜入场"), default: true),
        ]
    ) { ctx in
        OverlayMenuDemo(ctx: ctx)
    }
}

private let overlayWords: [LocalizedText] = [L("Work", "作品"), L("Studio", "工作室"), L("Journal", "日志"), L("Contact", "联系")]

private struct OverlayMenuDemo: View {
    let ctx: DemoContext
    @State private var open = false

    var body: some View {
        VStack(spacing: 14) {
            ZStack(alignment: .topLeading) {
                page
                CurtainShape(progress: open ? 1 : 0)
                    .fill(LinearGradient(colors: [Color(hex: 0x16162A), Color(hex: 0x2A1F4F)], startPoint: .top, endPoint: .bottom))
                    .animation(curtainAnimation, value: open)
                    .allowsHitTesting(false)
                words
                burger
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(16)
            }
            .frame(width: 250, height: 320)
            .clipShape(RoundedRectangle(cornerRadius: 34, style: .continuous))
            .shadow(color: .black.opacity(0.18), radius: 18, y: 10)
            DemoHint(text: L("Tap the menu button", "点击菜单按钮"), ctx: ctx)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 2.0) { toggle() }
    }

    private var curtainAnimation: Animation {
        let duration: Double = ctx["duration"]
        let wordsOut: Double = Double(overlayWords.count) * ctx["stagger"] * 0.5 + 0.2
        return open
            ? .timingCurve(0.16, 1, 0.3, 1, duration: duration)
            : .timingCurve(0.7, 0, 0.84, 0, duration: duration * 0.8).delay(wordsOut)
    }

    private var page: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(verbatim: "atelier°")
                .font(.system(size: 17, weight: .heavy, design: .rounded))
                .padding(.top, 8)
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Palette.sunset)
                .frame(height: 130)
            PlaceholderLines(count: 3)
            Spacer(minLength: 0)
        }
        .padding(18)
        .frame(width: 250, height: 320, alignment: .topLeading)
        .background(Palette.elevated)
    }

    private var words: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(0..<overlayWords.count, id: \.self) { index in
                word(index)
            }
        }
        .padding(.leading, 24)
        .padding(.top, 78)
        .allowsHitTesting(open)
    }

    private func word(_ index: Int) -> some View {
        let count = overlayWords.count
        let stagger: Double = ctx["stagger"]
        let delay: Double = open
            ? ctx["duration"] * 0.45 + Double(index) * stagger
            : Double(count - 1 - index) * stagger * 0.5
        let tilt: Double = ctx.bool("tilt") ? 6 : 0
        let animation: Animation = open
            ? .spring(response: 0.5, dampingFraction: 0.8).delay(delay)
            : .easeIn(duration: 0.18).delay(delay)
        return HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(String(format: "%02d", index + 1))
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundStyle(.white.opacity(0.5))
                .opacity(open ? 1 : 0)
            Text(overlayWords[index], ctx.language)
                .font(.system(size: 30, weight: .bold))
                .foregroundStyle(.white)
                .rotationEffect(.degrees(open ? 0 : tilt), anchor: .bottomLeading)
                .offset(y: open ? 0 : 44)
        }
        .frame(height: 42, alignment: .bottomLeading)
        .clipped()
        .animation(animation, value: open)
        .onTapGesture { toggle() }
    }

    private var burger: some View {
        Button { toggle() } label: {
            ZStack {
                Capsule()
                    .frame(width: 18, height: 2.2)
                    .rotationEffect(.degrees(open ? 45 : 0))
                    .offset(y: open ? 0 : -4)
                Capsule()
                    .frame(width: 18, height: 2.2)
                    .rotationEffect(.degrees(open ? -45 : 0))
                    .offset(y: open ? 0 : 4)
            }
            .foregroundStyle(open ? Color.white : Color.primary)
            .frame(width: 40, height: 40)
            .background(open ? AnyShapeStyle(Color.white.opacity(0.12)) : AnyShapeStyle(Palette.surface), in: Circle())
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: open)
    }

    private func toggle() {
        if !ctx.isPreview { Haptics.tap(open ? .light : .medium) }
        open.toggle()
    }
}

/// A curtain whose bottom edge reaches `progress × height` and bows downward mid-flight.
private struct CurtainShape: Shape {
    var progress: CGFloat

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let p: CGFloat = min(max(progress, 0), 1.05)
        let edge: CGFloat = rect.minY + rect.height * p
        let bow: CGFloat = 30 * sin(min(max(p, 0), 1) * .pi)
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: edge))
        path.addQuadCurve(to: CGPoint(x: rect.minX, y: edge), control: CGPoint(x: rect.midX, y: edge + bow * 2))
        path.closeSubpath()
        return path
    }
}
