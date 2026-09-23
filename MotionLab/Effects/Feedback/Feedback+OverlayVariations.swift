import SwiftUI

// MARK: - Receding sheet

extension Effect {
    static let feedbackRecedingSheet = Effect(
        id: "feedback.receding-sheet",
        category: .feedback,
        interaction: .gesture,
        name: L("Receding Action Sheet", "后退式确认面板"),
        summary: L(
            "A delete confirmation rises as the page recedes into depth; its buttons cascade in and dragging scrubs the page back.",
            "删除确认面板升起，页面退向纵深；按钮依次落位，拖动面板可把页面拉回。"
        ),
        prompt: L(
            "A photo grid with three selected photos and a trash button. On tap the page recedes: it scales to 92%, rounds its corners from 18 to 30 pt, slides down 10 pt and dims under a 25% scrim, while a 200 pt confirmation sheet rises on a spring (response 0.45 s, damping 0.86). Inside, the 'Delete 3 photos?' title, a red 'Delete' button and 'Cancel' cascade in, each rising 18 pt and fading in, staggered 50 ms. Dragging the sheet down tracks 1:1 and scrubs the page back toward 100%; past 60 pt or a flick dismisses, otherwise it springs back. Confirming fires a firm haptic as the sheet leaves and the three photos shrink away. Deliberate, reversible.",
            "照片网格里选中了三张，右上角有删除按钮。点击后页面退向纵深：缩到 92%，圆角由 18 pt 变 30 pt，下沉 10 pt，并压上 25% 的暗色遮罩；与此同时，一张 200 pt 的确认面板以弹簧（响应 0.45 秒、阻尼 0.86）升起。面板里“删除 3 张照片？”标题、红色“删除”与“取消”按钮依次上浮 18 pt 淡入，间隔 50 毫秒。向下拖动面板 1:1 跟手，页面随之按比例回到 100%；超过 60 pt 或快速下甩即关闭，否则弹回。确认删除时面板退场、给出一记硬朗触感，三张照片缩小消失。郑重，且随时可以反悔。"
        ),
        implementation: L(
            "One presented flag plus a live drag offset feed a single 'openness' value (0…1) that drives the page's scale, corner radius and scrim; the sheet's rows use per-index delayed springs, and a DragGesture with predictedEndTranslation decides dismissal.",
            "一个展示标志加上实时拖动位移，合成单一的“展开度”（0…1），驱动页面的缩放、圆角与遮罩；面板各行使用按序号递增延迟的弹簧，DragGesture 结合 predictedEndTranslation 判断是否关闭。"
        ),
        apis: ["DragGesture", "scaleEffect", "predictedEndTranslation", "spring(response:dampingFraction:)", "animation(_:value:)"],
        tags: ["action sheet", "confirm", "delete", "depth", "确认", "删除", "纵深", "模态"],
        params: [
            .slider("depth", L("Recede scale", "后退缩放"), 0.8...0.98, default: 0.92),
            .slider("response", L("Spring response", "弹簧响应"), 0.25...0.8, default: 0.45, unit: "s"),
            .slider("damping", L("Damping", "阻尼"), 0.5...1.0, default: 0.86),
        ]
    ) { ctx in
        RecedingSheetDemo(ctx: ctx)
    }
}

private struct RecedingSheetDemo: View {
    let ctx: DemoContext
    @State private var presented = false
    @State private var drag: CGFloat = 0
    @State private var deleted = false

    private let sheetHeight: CGFloat = 200
    private let tints: [Color] = [Palette.coral, Palette.sky, Palette.mint, Palette.violet, Palette.amber, Palette.pink, Palette.blue, Palette.green, Palette.indigo]
    private let selected: Set<Int> = [1, 3, 7]

    var body: some View {
        let open: CGFloat = presented ? max(0, 1 - drag / sheetHeight) : 0
        let depth: CGFloat = ctx.cg("depth")
        let scale: CGFloat = 1 - (1 - depth) * open
        let radius: CGFloat = 18 + 12 * open
        VStack(spacing: 10) {
            ZStack(alignment: .bottom) {
                page
                    .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
                    .scaleEffect(scale)
                    .offset(y: 10 * open)
                Color.black
                    .opacity(0.25 * Double(open))
                    .onTapGesture { dismiss() }
                    .allowsHitTesting(presented)
                sheet
                    .offset(y: presented ? max(drag, -12) : sheetHeight + 30)
                    .gesture(sheetDrag)
            }
            .frame(width: 300, height: 320)
            .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
            DemoHint(text: L("Tap the trash, then drag the sheet down", "点击删除按钮，再向下拖动面板"), ctx: ctx)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 2.6, delay: 0.5) {
            if presented { confirm() } else { present() }
        }
    }

    private var page: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(ctx.language == .zh ? (deleted ? "最近项目" : "已选 3 项") : (deleted ? "Recents" : "3 Selected"))
                    .font(.headline)
                    .contentTransition(.opacity)
                Spacer()
                Button(action: present) {
                    Image(systemName: "trash")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(width: 40, height: 40)
                        .background(Palette.red.gradient, in: Circle())
                }
                .buttonStyle(.plain)
                .disabled(deleted)
                .opacity(deleted ? 0.4 : 1)
            }
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 3), spacing: 6) {
                ForEach(0..<tints.count, id: \.self) { index in
                    photo(index)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(width: 300, height: 320)
        .background(Palette.elevated)
    }

    private func photo(_ index: Int) -> some View {
        let isSelected = selected.contains(index)
        let gone = isSelected && deleted
        return RoundedRectangle(cornerRadius: 10, style: .continuous)
            .fill(tints[index].gradient)
            .aspectRatio(1, contentMode: .fit)
            .overlay(alignment: .bottomTrailing) {
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(.white, Palette.blue)
                        .padding(5)
                }
            }
            .scaleEffect(gone ? 0.2 : (isSelected ? 0.92 : 1))
            .opacity(gone ? 0 : 1)
            .animation(.spring(response: 0.4, dampingFraction: 0.7).delay(gone ? 0.15 + Double(index) * 0.03 : 0), value: gone)
    }

    private var sheet: some View {
        let zh = ctx.language == .zh
        return VStack(spacing: 10) {
            Capsule()
                .fill(Color.secondary.opacity(0.5))
                .frame(width: 36, height: 5)
                .padding(.top, 8)
            VStack(spacing: 3) {
                Text(zh ? "删除 3 张照片？" : "Delete 3 photos?")
                    .font(.headline)
                Text(zh ? "它们将从你的所有设备中移除。" : "They'll be removed from all your devices.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .modifier(RecedingCascade(shown: presented, index: 0))
            actionRow(zh ? "删除" : "Delete", destructive: true, index: 1, action: confirm)
            actionRow(zh ? "取消" : "Cancel", destructive: false, index: 2, action: dismiss)
            Spacer(minLength: 0)
        }
        .frame(width: 300, height: sheetHeight + 20, alignment: .top)
        .background(.regularMaterial, in: UnevenRoundedRectangle(topLeadingRadius: 26, bottomLeadingRadius: 0, bottomTrailingRadius: 0, topTrailingRadius: 26, style: .continuous))
        .offset(y: 20)
    }

    private func actionRow(_ title: String, destructive: Bool, index: Int, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.body.weight(destructive ? .semibold : .regular))
                .foregroundStyle(destructive ? Palette.red : Color.primary)
                .frame(maxWidth: .infinity)
                .frame(height: 42)
                .background(Color.primary.opacity(0.07), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 16)
        .modifier(RecedingCascade(shown: presented, index: index))
    }

    private var sheetDrag: some Gesture {
        DragGesture(minimumDistance: 2)
            .onChanged { value in
                let dy: CGFloat = value.translation.height
                drag = dy > 0 ? dy : rubberBand(dy, limit: 30)
            }
            .onEnded { value in
                if value.translation.height > 60 || value.predictedEndTranslation.height > 160 {
                    dismiss()
                } else {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { drag = 0 }
                }
            }
    }

    private func present() {
        guard !presented else { return }
        Haptics.tap()
        withAnimation(.spring(response: ctx["response"], dampingFraction: ctx["damping"])) {
            drag = 0
            deleted = false
            presented = true
        }
    }

    private func confirm() {
        guard presented else { return }
        Haptics.tap(.rigid)
        dismiss()
        withAnimation(.smooth(duration: 0.3)) { deleted = true }
    }

    private func dismiss() {
        withAnimation(.spring(response: ctx["response"], dampingFraction: 0.95)) {
            presented = false
            drag = 0
        }
    }
}

/// Sheet rows rise 18 pt and fade in one after another.
private struct RecedingCascade: ViewModifier {
    let shown: Bool
    let index: Int

    func body(content: Content) -> some View {
        content
            .offset(y: shown ? 0 : 18)
            .opacity(shown ? 1 : 0)
            .animation(.spring(response: 0.4, dampingFraction: 0.75).delay(shown ? 0.1 + Double(index) * 0.05 : 0), value: shown)
    }
}

// MARK: - Anchored tip popover

extension Effect {
    static let feedbackTipPopover = Effect(
        id: "feedback.tip-popover",
        category: .feedback,
        interaction: .tap,
        name: L("Anchored Tip Popover", "锚点提示气泡"),
        summary: L("A feature tip grows out of its arrow's tip, points at a pulsing tool and folds back in.", "功能提示从箭头尖端生长出来，指向正在脉动的工具，再收回原点。"),
        prompt: L(
            "A floating editor toolbar of four 56 pt tools sits at the bottom. A 240 pt tip bubble with a 14 pt arrow grows out of the arrow's point above the third tool — scaling from 10% at that exact anchor to 100% on a bouncy spring (response 0.42 s, damping 0.62) — so it visibly emanates from what it describes; its title and body fade in 100 ms later. While it is open the target tool glows violet and emits a ring that pulses from 100% to 170% every 1.2 s. 'Got it' collapses the bubble back into its anchor in 0.25 s and the ring stops. Guiding, precise, never blocking.",
            "底部悬浮着一条由四个 56 pt 工具组成的编辑工具栏。一枚 240 pt 宽、带 14 pt 箭头的提示气泡从第三个工具上方的箭头尖端“长”出来——以该锚点为中心从 10% 缩放到 100%，采用弹跳弹簧（响应 0.42 秒、阻尼 0.62）——让人清楚看到它源自所描述的对象；标题与正文延后 100 毫秒淡入。气泡打开期间目标工具发出紫罗兰光，并每 1.2 秒放出一圈从 100% 扩到 170% 的脉冲环。点击“知道了”，气泡在 0.25 秒内收回锚点，脉冲环随之停止。引导清晰、定位精准、从不挡路。"
        ),
        implementation: L(
            "scaleEffect(_:anchor:) uses a UnitPoint computed from the arrow's x within the bubble, so the spring grows it from the arrow tip; the target's pulse ring is a phaseAnimator shown only while the tip is open.",
            "scaleEffect(_:anchor:) 的锚点由箭头在气泡内的 x 位置换算成 UnitPoint，弹簧因此从箭头尖端开始放大；目标工具的脉冲环是仅在提示打开时显示的 phaseAnimator。"
        ),
        apis: ["scaleEffect(_:anchor:)", "UnitPoint", "phaseAnimator", "spring(response:dampingFraction:)"],
        tags: ["tip", "popover", "onboarding", "coach mark", "提示", "气泡", "新手引导", "功能介绍"],
        params: [
            .slider("response", L("Spring response", "弹簧响应"), 0.2...0.8, default: 0.42, unit: "s"),
            .slider("damping", L("Damping", "阻尼"), 0.4...1.0, default: 0.62),
            .choice("target", L("Target tool", "目标工具"), [L("2nd", "第 2 个"), L("3rd", "第 3 个"), L("4th", "第 4 个")], default: 1),
        ]
    ) { ctx in
        TipPopoverDemo(ctx: ctx)
    }
}

private struct TipPopoverDemo: View {
    let ctx: DemoContext
    @State private var open = false

    private let tools: [String] = ["pencil.tip", "textformat", "wand.and.stars", "square.and.arrow.up"]
    private let bubbleWidth: CGFloat = 240

    var body: some View {
        let target: Int = min(max(ctx.int("target") + 1, 1), 3)
        // Tool centers relative to the toolbar center (4 × 56 pt tools).
        let arrowShift: CGFloat = CGFloat(target) * 56 + 28 - 112
        let anchorX: CGFloat = (bubbleWidth / 2 + arrowShift) / bubbleWidth
        VStack(spacing: 12) {
            Spacer(minLength: 0)
            bubble(arrowShift: arrowShift)
                .scaleEffect(open ? 1 : 0.1, anchor: UnitPoint(x: anchorX, y: 1))
                .opacity(open ? 1 : 0)
                .allowsHitTesting(open)
            toolbar(target: target)
            DemoHint(text: L("Tap the glowing tool", "点击发光的工具"), ctx: ctx)
        }
        .padding(.bottom, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 2.4, delay: 0.5) { toggle() }
    }

    private func bubble(arrowShift: CGFloat) -> some View {
        let zh = ctx.language == .zh
        return VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "wand.and.stars")
                    .font(.title3)
                    .foregroundStyle(Palette.violet)
                VStack(alignment: .leading, spacing: 4) {
                    Text(zh ? "一键美化" : "Magic Enhance")
                        .font(.subheadline.weight(.semibold))
                    Text(zh ? "自动调整光线与色彩。" : "Fixes light and color in one tap.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Button(zh ? "知道了" : "Got it") { toggle() }
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Palette.accent)
                        .padding(.top, 2)
                }
                Spacer(minLength: 0)
            }
            .opacity(open ? 1 : 0)
            .animation(open ? Animation.easeOut(duration: 0.2).delay(0.1) : Animation.easeIn(duration: 0.08), value: open)
            .padding(14)
            .frame(width: bubbleWidth)
            .background(Palette.elevated, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            TipArrow()
                .fill(Palette.elevated)
                .frame(width: 24, height: 14)
                .offset(x: arrowShift)
        }
        .compositingGroup()
        .shadow(color: .black.opacity(0.16), radius: 16, y: 8)
    }

    private func toolbar(target: Int) -> some View {
        HStack(spacing: 0) {
            ForEach(0..<tools.count, id: \.self) { index in
                let isTarget = index == target
                ZStack {
                    if isTarget && open {
                        Circle()
                            .stroke(Palette.violet, lineWidth: 2)
                            .frame(width: 40, height: 40)
                            .phaseAnimator([false, true]) { content, out in
                                content
                                    .scaleEffect(out ? 1.7 : 1)
                                    .opacity(out ? 0 : 0.8)
                            } animation: { out in
                                out ? Animation.easeOut(duration: 1.2) : Animation.linear(duration: 0.01)
                            }
                    }
                    Image(systemName: tools[index])
                        .font(.system(size: 19, weight: .semibold))
                        .foregroundStyle(isTarget && open ? Palette.violet : Color.primary)
                        .shadow(color: Palette.violet.opacity(isTarget && open ? 0.6 : 0), radius: 8)
                }
                .frame(width: 56, height: 56)
                .contentShape(Rectangle())
                .onTapGesture { if isTarget { toggle() } }
            }
        }
        .background(.regularMaterial, in: Capsule())
        .overlay { Capsule().strokeBorder(Palette.stroke) }
        .shadow(color: .black.opacity(0.1), radius: 12, y: 6)
    }

    private func toggle() {
        if open {
            withAnimation(.easeIn(duration: 0.25)) { open = false }
        } else {
            if !ctx.isPreview { Haptics.tap() }
            withAnimation(.spring(response: ctx["response"], dampingFraction: ctx["damping"])) { open = true }
        }
    }
}

private struct TipArrow: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addQuadCurve(to: CGPoint(x: rect.midX, y: rect.maxY), control: CGPoint(x: rect.midX - 3, y: rect.minY + 4))
        path.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.minY), control: CGPoint(x: rect.midX + 3, y: rect.minY + 4))
        path.closeSubpath()
        return path
    }
}

// MARK: - Gravity drop alert

extension Effect {
    static let feedbackDropAlert = Effect(
        id: "feedback.drop-alert",
        category: .feedback,
        interaction: .tap,
        name: L("Gravity Drop Alert", "重力坠落弹窗"),
        summary: L("An alert falls in under gravity, bounces twice with a squash, and drops away on dismiss.", "弹窗在重力下坠入，挤压着弹跳两下，关闭时向下坠落离场。"),
        prompt: L(
            "Over a 30% dimmed backdrop, a 270 pt alert card — orange Wi-Fi warning glyph, 'Connection lost', a one-line message and Retry / Cancel buttons — falls from 380 pt above in 0.32 s ease-in, like it has weight. On impact it squashes to 104% × 92% for 50 ms, bounces up 22 pt (0.14 s ease-out), lands again, hops 6 pt and settles — every bounce smaller, as with gravity — and a rigid haptic thumps at first contact. Dismissing tips it 10° and lets it fall 420 pt out of the bottom in 0.4 s ease-in while the backdrop clears. Physical, playful, still clearly an alert.",
            "在压暗 30% 的背景上，一张 270 pt 宽的弹窗——橙色 Wi-Fi 警告图标、“连接已断开”、一行说明以及“重试 / 取消”按钮——从上方 380 pt 处以 0.32 秒缓入落下，像是真有重量。落地瞬间它被压成 104% × 92%，持续 50 毫秒，随后弹起 22 pt（0.14 秒缓出）、再次落地、又小跳 6 pt 后停稳——每次弹跳都更小，一如重力；第一次触地时伴随一次硬朗触感。关闭时它倾斜 10°，在 0.4 秒缓入中向下坠落 420 pt 离开画面，背景同时恢复明亮。有物理感、俏皮，但仍然明确是一个警示。"
        ),
        implementation: L(
            "A keyframeAnimator whose initial value is the rest pose runs y-offset and squash tracks (MoveKeyframe to -380 first) on each presentation; dismissal is a plain ease-in on offset and rotation.",
            "keyframeAnimator 以静止姿态为初值，每次出现时运行 y 位移与挤压轨道（先 MoveKeyframe 到 -380）；关闭时对位移与旋转做普通缓入动画。"
        ),
        apis: ["keyframeAnimator(initialValue:trigger:)", "MoveKeyframe", "CubicKeyframe", "rotationEffect(_:anchor:)"],
        tags: ["alert", "gravity", "bounce", "drop", "弹窗", "重力", "弹跳", "坠落"],
        params: [
            .slider("bounce", L("Bounce height", "弹跳高度"), 0...40, default: 22, decimals: 0, unit: "pt"),
            .slider("fall", L("Fall time", "下落时长"), 0.2...0.6, default: 0.32, unit: "s"),
        ]
    ) { ctx in
        DropAlertDemo(ctx: ctx)
    }
}

private struct DropPose {
    var y: CGFloat = 0
    var sx: CGFloat = 1
    var sy: CGFloat = 1
}

private struct DropAlertDemo: View {
    let ctx: DemoContext
    @State private var shown = false
    @State private var leaving = false
    @State private var drops = 0
    @State private var token = 0

    var body: some View {
        let zh = ctx.language == .zh
        ZStack {
            VStack(spacing: 14) {
                Button(action: present) {
                    Label(zh ? "同步" : "Sync now", systemImage: "arrow.triangle.2.circlepath")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 24)
                        .frame(height: 50)
                        .background(Palette.primary, in: Capsule())
                }
                .buttonStyle(.plain)
                DemoHint(text: L("Tap Sync now", "点击同步"), ctx: ctx)
            }
            Color.black
                .opacity(shown && !leaving ? 0.3 : 0)
                .animation(.easeInOut(duration: 0.3), value: shown && !leaving)
                .allowsHitTesting(shown)
                .onTapGesture { dismiss() }
            card(zh: zh)
                .opacity(shown ? 1 : 0)
                .allowsHitTesting(shown && !leaving)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
        .autoplay(ctx.isPreview, every: 2.4, delay: 0.5) {
            if shown { dismiss() } else { present() }
        }
    }

    private func card(zh: Bool) -> some View {
        let bounce: CGFloat = ctx.cg("bounce")
        let fall: Double = ctx["fall"]
        return VStack(spacing: 10) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 30, weight: .semibold))
                .foregroundStyle(Palette.coral)
            Text(zh ? "连接已断开" : "Connection lost")
                .font(.headline)
            Text(zh ? "你的更改会在恢复连接后同步。" : "Your changes will sync when you're back online.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            HStack(spacing: 10) {
                alertButton(zh ? "取消" : "Cancel", primary: false)
                alertButton(zh ? "重试" : "Retry", primary: true)
            }
            .padding(.top, 6)
        }
        .padding(20)
        .frame(width: 270)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).strokeBorder(Palette.stroke))
        .shadow(color: .black.opacity(0.2), radius: 24, y: 12)
        .keyframeAnimator(initialValue: DropPose(), trigger: drops) { content, pose in
            content
                .scaleEffect(x: pose.sx, y: pose.sy, anchor: .bottom)
                .offset(y: pose.y)
        } keyframes: { _ in
            KeyframeTrack(\.y) {
                MoveKeyframe(-380)
                CubicKeyframe(0, duration: fall)
                CubicKeyframe(-bounce, duration: 0.14)
                CubicKeyframe(0, duration: 0.14)
                CubicKeyframe(-bounce * 0.27, duration: 0.08)
                CubicKeyframe(0, duration: 0.08)
            }
            KeyframeTrack(\.sx) {
                MoveKeyframe(0.96)
                LinearKeyframe(0.97, duration: fall)
                CubicKeyframe(1.04, duration: 0.05)
                SpringKeyframe(1, duration: 0.3, spring: .bouncy)
            }
            KeyframeTrack(\.sy) {
                MoveKeyframe(1.04)
                LinearKeyframe(1.03, duration: fall)
                CubicKeyframe(0.92, duration: 0.05)
                SpringKeyframe(1, duration: 0.3, spring: .bouncy)
            }
        }
        .rotationEffect(.degrees(leaving ? 10 : 0), anchor: .bottomLeading)
        .offset(y: leaving ? 420 : 0)
    }

    private func alertButton(_ title: String, primary: Bool) -> some View {
        Button(action: dismiss) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(primary ? AnyShapeStyle(Color.white) : AnyShapeStyle(Color.primary))
                .frame(maxWidth: .infinity)
                .frame(height: 42)
                .background(primary ? AnyShapeStyle(Palette.primary) : AnyShapeStyle(Color.primary.opacity(0.08)), in: Capsule())
        }
        .buttonStyle(.plain)
    }

    private func present() {
        guard !shown else { return }
        token += 1
        let current = token
        leaving = false
        shown = true
        drops += 1
        let fall: Double = ctx["fall"]
        guard !ctx.isPreview else { return }
        Task {
            try? await Task.sleep(for: .seconds(fall))
            guard token == current else { return }
            Haptics.tap(.rigid)
        }
    }

    private func dismiss() {
        guard shown, !leaving else { return }
        token += 1
        let current = token
        withAnimation(.easeIn(duration: 0.4)) { leaving = true }
        Task {
            try? await Task.sleep(for: .seconds(0.42))
            guard token == current else { return }
            shown = false
            leaving = false
        }
    }
}
