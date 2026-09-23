import SwiftUI

extension Effect {
    static let scrollRotaryWheel = Effect(
        id: "scroll.rotary-wheel",
        category: .scroll,
        interaction: .scroll,
        name: L("Rotary Scroll Wheel", "旋钮转盘"),
        summary: L("Vertical scrolling turns a round dial of twelve icons; the one at 12 o'clock is selected.", "上下滚动会转动一圈十二个图标组成的转盘，位于 12 点方向的就是选中项。"),
        prompt: L(
            "A 250 pt circular dial carries twelve 40 pt icon badges evenly around a 100 pt radius, over a faint tick ring. Scrolling vertically anywhere on the dial rotates it, one 30° notch per 56 pt, and snaps to whole notches, so an icon always rests at 12 o'clock under a small triangular marker; the dial turns endlessly in either direction, straight past 11 back to 0. The badge in that slot grows to 1.3× on a quick spring and gains a gradient ring and glow, while the others orbit upright without spinning at 85% opacity. The centre title cross-fades to the selection and every notch ticks a selection haptic, like an iPod click wheel or a camera mode dial.",
            "一个 250 pt 的圆形转盘上，十二个 40 pt 图标徽章均匀分布在半径 100 pt 的圆周上，底下是一圈淡淡的刻度环。在转盘上任意位置上下滚动就能转动它：每 56 pt 转过一个 30° 档位，并吸附到整档，总有一个图标停在 12 点方向的小三角下；转盘可朝任一方向无限转动，从 11 直接转回 0。落在该位置的徽章以快速弹簧放大到 1.3 倍，带上渐变光环与辉光，其余徽章只公转不自转，保持 85% 不透明度。中心标题随选中项淡入淡出，每过一档轻轻一震，像 iPod 点按式转盘或相机模式拨盘。"
        ),
        implementation: L(
            "An invisible vertical ScrollView (clear content with a contentShape, three turns long) sits on top of the dial, snaps to 56 pt steps and silently re-centres on the middle turn when idle; onScrollGeometryChange converts the offset into a continuous rotation that positions each badge with cos/sin, so icons orbit but never spin.",
            "一个不可见的纵向 ScrollView（透明内容加 contentShape，长度为三圈）覆盖在转盘上方，按 56 pt 吸附，停止时无动画地回到中间一圈；onScrollGeometryChange 将偏移换算为连续的旋转角度，用 cos/sin 摆放每个徽章，因此图标只公转、不自转。"
        ),
        apis: ["onScrollGeometryChange", "ScrollTargetBehavior", "ScrollPosition", "contentShape", "sensoryFeedback"],
        tags: ["dial", "wheel", "rotary", "click wheel", "转盘", "旋钮", "滚轮", "拨盘"],
        params: [
            .slider("pitch", L("Scroll per notch", "每档滚动距离"), 30...100, default: 56, step: 2, decimals: 0, unit: "pt"),
            .slider("focus", L("Selected scale", "选中放大"), 1...1.6, default: 1.3),
        ]
    ) { ctx in
        ScrollRotaryDemo(ctx: ctx)
    }
}

private let scrollRotaryCount = 12
/// The scroll surface holds three turns of the dial; it is re-centred on the middle turn whenever
/// scrolling stops, so the dial can keep turning past 11 → 0 in either direction.
private let scrollRotaryCopies = 3

private struct ScrollRotaryDemo: View {
    let ctx: DemoContext
    @State private var position = ScrollPosition(edge: .top)
    @State private var offset: CGFloat = 0
    @State private var step = 0
    /// True while autoplay (or the detail intro) turns the dial, so scripted notches stay silent.
    @State private var scripted = false

    private let dial: CGFloat = 250

    private var pitch: CGFloat { max(ctx.cg("pitch"), 1) }
    private var turns: CGFloat { offset / pitch }
    private var selected: Int {
        let raw = Int(turns.rounded())
        return ((raw % scrollRotaryCount) + scrollRotaryCount) % scrollRotaryCount
    }

    var body: some View {
        VStack(spacing: 14) {
            ZStack {
                ScrollRotaryDial(turns: turns, selected: selected, focus: ctx.cg("focus"), language: ctx.language)
                scroller
            }
            .frame(width: dial, height: dial)
            DemoHint(text: L("Scroll up and down on the dial", "在转盘上上下滚动"), ctx: ctx)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .sensoryFeedback(.selection, trigger: selected) { _, _ in !ctx.isPreview && !scripted }
        .autoplay(ctx.isPreview, every: 1.3) { autoTurn() }
    }

    /// Transparent scroll surface: its offset is the dial's rotation.
    private var scroller: some View {
        let pitch = self.pitch
        return ScrollView {
            Color.clear
                .frame(height: dial + pitch * CGFloat(scrollRotaryCount * scrollRotaryCopies - 1))
                .contentShape(Rectangle())
        }
        .scrollIndicators(.hidden)
        .scrollTargetBehavior(ScrollStrideSnap(pitch: pitch, axis: .vertical))
        .scrollPosition($position)
        .onScrollGeometryChange(for: CGFloat.self, of: { geometry in
            geometry.contentOffset.y + geometry.contentInsets.top
        }, action: { _, newValue in
            offset = newValue
        })
        .onScrollPhaseChange { _, newPhase in
            if newPhase == .interacting { scripted = false }
            if newPhase == .idle { recenter() }
        }
        .onAppear { position.scrollTo(y: CGFloat(scrollRotaryCount) * pitch) }
        .clipShape(Circle())
    }

    /// Jumps a whole turn (12 notches, 360°) back into the middle copy without animation: invisible,
    /// because every badge, the tick ring and the selection repeat every turn.
    private func recenter() {
        let notch = Int((offset / pitch).rounded())
        let shift: Int
        if notch < scrollRotaryCount {
            shift = scrollRotaryCount
        } else if notch >= scrollRotaryCount * 2 {
            shift = -scrollRotaryCount
        } else {
            return
        }
        var instant = Transaction()
        instant.disablesAnimations = true
        withTransaction(instant) {
            position.scrollTo(y: CGFloat(notch + shift) * pitch)
        }
    }

    private func autoTurn() {
        let targets = [3, 5, 2, 8, 11, 6, 0]
        let target = targets[step % targets.count]
        step += 1
        scripted = true
        withAnimation(.spring(response: 0.8, dampingFraction: 0.82)) {
            position.scrollTo(y: CGFloat(scrollRotaryCount + target) * pitch)
        }
    }
}

private struct ScrollRotaryDial: View {
    let turns: CGFloat
    let selected: Int
    let focus: CGFloat
    let language: AppLanguage

    private let radius: CGFloat = 100

    var body: some View {
        ZStack {
            Circle()
                .fill(Palette.elevated)
                .shadow(color: .black.opacity(0.12), radius: 18, y: 10)
            Circle()
                .stroke(Color.primary.opacity(0.12), style: StrokeStyle(lineWidth: 6, dash: [1.5, 7.2]))
                .frame(width: 164, height: 164)
                .rotationEffect(.degrees(-Double(turns) * 30))
            Image(systemName: "triangle.fill")
                .font(.system(size: 10, weight: .bold))
                .rotationEffect(.degrees(180))
                .foregroundStyle(Palette.primary)
                .offset(y: -radius - 30)
            ForEach(0..<scrollRotaryCount, id: \.self) { i in
                badge(i)
            }
            Text(ScrollKit.title(selected), language)
                .font(.headline)
                .contentTransition(.opacity)
                .animation(.easeInOut(duration: 0.2), value: selected)
                .allowsHitTesting(false)
        }
    }

    private func badge(_ i: Int) -> some View {
        // Angle from 12 o'clock, clockwise; the dial turns counter-clockwise as the offset grows.
        let degrees = (Double(i) - Double(turns)) * 30
        let radians = degrees * .pi / 180
        let x = radius * CGFloat(sin(radians))
        let y = -radius * CGFloat(cos(radians))
        let isSelected = i == selected
        return ScrollKitIcon(index: i, size: 40)
            .clipShape(Circle())
            .overlay {
                Circle()
                    .strokeBorder(Palette.primary, lineWidth: 2.5)
                    .padding(-4)
                    .opacity(isSelected ? 1 : 0)
            }
            .shadow(color: isSelected ? Palette.violet.opacity(0.5) : .clear, radius: 10)
            .scaleEffect(isSelected ? focus : 1)
            .opacity(isSelected ? 1 : 0.85)
            // Animate only the selection pop; the orbit position follows the scroll directly.
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
            .offset(x: x, y: y)
            .allowsHitTesting(false)
    }
}
