import SwiftUI

private typealias M = TrailerMath

// MARK: - Phone geometry

/// An iPhone 16/17 Pro drawn to scale, in points of its own 9:16 authoring size (the 3:4 cut scales it
/// uniformly by `TrailerLayout.phoneScale`).
///
/// Real device: 71.5 × 149.6 mm body, 1206 × 2622 px display (aspect 0.46), display corners ≈ 13 % of
/// its width, Dynamic Island 126 × 37 pt on a 402 pt wide screen, 11 pt from the top.
/// Everything inside the screen is laid out in screen coordinates (0 … 186 × 0 … 404) and mirrors the
/// app's detail page: status bar + island, nav title row, the square demo stage, a hint, the parameters.
enum TrailerPhone {
    static let screenSize = CGSize(width: 186, height: 404)
    /// Titanium band (2.2 pt) + black glass border.
    static let bezel: CGFloat = 6
    static let bodySize = CGSize(width: screenSize.width + bezel * 2, height: screenSize.height + bezel * 2)
    static let screenCorner: CGFloat = screenSize.width * 0.13
    /// Concentric with the screen corner.
    static let bodyCorner: CGFloat = screenCorner + bezel
    /// Body height in the 3:4 cut (the 9:16 cut uses `bodySize.height`, 416 pt).
    static let classicBodyHeight: CGFloat = 336

    /// Pixel-to-point factor of the real screen onto this one (402 pt → 186 pt).
    static let unit: CGFloat = screenSize.width / 402
    static let islandSize = CGSize(width: 126 * unit, height: 37 * unit)
    static let islandTop: CGFloat = 11 * unit

    static let statusY: CGFloat = 14
    static let navY: CGFloat = 44
    static let stageRect = CGRect(x: 9, y: 62, width: 168, height: 168)
    static let stageCorner: CGFloat = 18
    static let hintY: CGFloat = 246
    static let cardRect = CGRect(x: 9, y: 262, width: 168, height: 112)
    static let cardHeaderY: CGFloat = 278
    /// Parameter rows: label, slider track, value.
    static let rowY: [CGFloat] = [306, 342]
    static let trackX: CGFloat = 60
    static let trackWidth: CGFloat = 78
    static let homeIndicatorY: CGFloat = 398
}

// MARK: - 21–44 s · Feel it on the phone, then tune it

/// The app's detail page on an iPhone. The opened search result (`TrailerHeroLayer`) lands on its stage
/// card and plays first; then real demos take turns (each swap zooms through depth), a scripted finger
/// taps them on the beats their own `.autoplay` loops are phase-locked to, and finally a spring lab takes
/// the stage while the finger scrubs the page's parameter sliders.
struct TrailerPhoneScene: View {
    let t: Double
    let origin: Date

    /// Outgoing demo: sinks back, blurs and fades.
    static func swapOut(_ t: Double, at start: Double) -> Double {
        M.easeIn(M.progress(t, start, 0.45))
    }

    /// Incoming demo: rises out of depth on a spring.
    static func swapIn(_ t: Double, at start: Double) -> Double {
        M.spring(t, at: start, response: 0.55, damping: 0.8)
    }

    /// Demos after the hero, with the times their taps land (see `TrailerScript.taps`).
    /// `epochOffset` = first tap − the demo's autoplay delay, so `demoSyncEpoch` fires it on the tap.
    private struct Slot {
        let id: String
        let mount: ClosedRange<Double>
        let enter: Double
        let leave: Double
        let epochOffset: Double
    }

    private static let slots: [Slot] = [
        // showcase.board-card: delay 0.8, every 2.4 → flips at 26.3 and 28.7.
        Slot(id: "showcase.board-card", mount: 24.9...29.8, enter: 25.45, leave: 29.1, epochOffset: 25.5),
        // buttons.depth-press: delay 0.6, toggles every 0.8 → presses at 30.0 and 31.6.
        Slot(id: "buttons.depth-press", mount: 28.6...33.4, enter: 29.3, leave: 32.75, epochOffset: 29.4),
        // inputs.squash-toggle: delay 0.4, every 1.3 → taps at 33.5 and 34.8.
        Slot(id: "inputs.squash-toggle", mount: 32.2...36.4, enter: 32.9, leave: 35.55, epochOffset: 33.1),
    ]

    var body: some View {
        let appear = M.spring(t, at: 20.85, response: 0.7, damping: 0.85)
        let exit = M.easeInOut(M.progress(t, 43.85, 0.6))
        let buzz = CGFloat(TrailerScript.buzz(t) * 2.4)
        let center = TrailerLayout.demoCenter
        // The phone grows around its stage, so the hero tile landing there never drifts.
        let anchor = UnitPoint(x: center.x / TrailerCanvas.width, y: center.y / TrailerCanvas.height)
        let titleSize = TrailerCanvas.pick(28, 34)
        let subtitleSize = TrailerCanvas.pick(17, 21)
        ZStack {
            TrailerHeadline(
                title: "在手机上直接玩",
                subtitle: "每一下都有触感",
                titleSize: titleSize,
                subtitleSize: subtitleSize,
                reveal: M.progress(t, 21.3, 0.9),
                exit: M.easeIn(M.progress(t, 35.45, 0.5))
            )
            .position(x: 195, y: TrailerLayout.phoneHeadlineY)
            if t > 35.8 {
                TrailerHeadline(
                    title: "参数实时可调",
                    subtitle: "弹簧 · 阻尼 · 响应，随手试",
                    titleSize: titleSize,
                    subtitleSize: subtitleSize,
                    reveal: M.progress(t, 36.0, 0.9),
                    exit: M.easeIn(M.progress(t, 43.7, 0.5))
                )
                .position(x: 195, y: TrailerLayout.phoneHeadlineY)
            }
            ZStack {
                PhoneDevice(t: t)
                    .scaleEffect(TrailerLayout.phoneScale)
                    .position(TrailerLayout.phoneCenter)
                ForEach(Self.slots.indices, id: \.self) { index in
                    let slot = Self.slots[index]
                    if slot.mount.contains(t) {
                        demo(slot)
                    }
                }
                if t > 35.2 {
                    let labIn = Self.swapIn(t, at: 35.75)
                    TrailerSpringLab(t: t, side: TrailerLayout.demoSide)
                        .scaleEffect(CGFloat(0.9 + 0.1 * labIn))
                        .blur(radius: CGFloat(1 - M.clamp(labIn)) * 10)
                        .opacity(M.clamp(labIn * 1.6))
                        .position(center)
                }
                PhoneGlass()
                    .scaleEffect(TrailerLayout.phoneScale)
                    .position(TrailerLayout.phoneCenter)
            }
            .frame(width: TrailerCanvas.width, height: TrailerCanvas.height)
            .scaleEffect(CGFloat(0.9 + 0.1 * appear), anchor: anchor)
            .opacity(M.clamp(appear * 1.5))
            .offset(x: buzz)
            .scaleEffect(CGFloat(1 - 0.1 * exit))
            .blur(radius: CGFloat(exit) * 12)
            .opacity(1 - exit)
        }
        .frame(width: TrailerCanvas.width, height: TrailerCanvas.height)
    }

    private func demo(_ slot: Slot) -> some View {
        let enter = Self.swapIn(t, at: slot.enter)
        let leave = Self.swapOut(t, at: slot.leave)
        let scale: Double = (0.9 + 0.1 * enter) * (1 - 0.12 * leave)
        let blur: Double = (1 - M.clamp(enter)) * 10 + leave * 10
        return TrailerStageTile(
            effectID: slot.id,
            epoch: origin.addingTimeInterval(slot.epochOffset),
            side: TrailerLayout.demoSide,
            cornerRadius: TrailerLayout.stageCorner
        )
        .scaleEffect(CGFloat(scale))
        .blur(radius: CGFloat(blur))
        .opacity(M.clamp(enter * 1.6) * (1 - leave))
        .position(TrailerLayout.demoCenter)
    }
}

// MARK: - Device

/// Chassis (graphite titanium band with a rim highlight, black glass border, side buttons, soft
/// shadows) around the screen, drawn at `TrailerPhone.bodySize`.
private struct PhoneDevice: View {
    let t: Double

    private static let titanium = LinearGradient(
        stops: [
            Gradient.Stop(color: Color(hex: 0x6A6A72), location: 0),
            Gradient.Stop(color: Color(hex: 0x2C2C32), location: 0.07),
            Gradient.Stop(color: Color(hex: 0x1B1B1F), location: 0.5),
            Gradient.Stop(color: Color(hex: 0x2C2C32), location: 0.93),
            Gradient.Stop(color: Color(hex: 0x55555D), location: 1),
        ],
        startPoint: .leading,
        endPoint: .trailing
    )

    private static let rimLight = LinearGradient(
        stops: [
            Gradient.Stop(color: Color.white.opacity(0.6), location: 0),
            Gradient.Stop(color: Color.white.opacity(0.14), location: 0.3),
            Gradient.Stop(color: Color.white.opacity(0.05), location: 0.7),
            Gradient.Stop(color: Color.white.opacity(0.24), location: 1),
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    var body: some View {
        let size = TrailerPhone.bodySize
        let outer = RoundedRectangle(cornerRadius: TrailerPhone.bodyCorner, style: .continuous)
        let band: CGFloat = 2.2
        let glass = RoundedRectangle(cornerRadius: TrailerPhone.bodyCorner - band, style: .continuous)
        let screen = RoundedRectangle(cornerRadius: TrailerPhone.screenCorner, style: .continuous)
        ZStack {
            // Contact shadow under the phone.
            Ellipse()
                .fill(Color.black.opacity(0.55))
                .frame(width: size.width * 0.78, height: 16)
                .blur(radius: 12)
                .position(x: size.width / 2, y: size.height + 4)
            sideButtons
            ZStack {
                outer.fill(Self.titanium)
                outer.strokeBorder(Self.rimLight, lineWidth: 0.8)
                glass
                    .fill(Color.black)
                    .padding(band)
                glass
                    .strokeBorder(Color.white.opacity(0.07), lineWidth: 0.5)
                    .padding(band)
            }
            .compositingGroup()
            .shadow(color: Color.black.opacity(0.65), radius: 28, x: 0, y: 22)
            .shadow(color: Palette.ember.opacity(0.14), radius: 44, x: 0, y: 0)
            PhoneScreen(t: t)
                .frame(width: TrailerPhone.screenSize.width, height: TrailerPhone.screenSize.height)
                .clipShape(screen)
        }
        .frame(width: size.width, height: size.height)
    }

    /// Action button + volume on the left, side button + Camera Control on the right (iPhone 16/17 Pro
    /// positions, in body points). They sit half inside the band, so 1.6 pt shows.
    private var sideButtons: some View {
        let width = TrailerPhone.bodySize.width
        let left: [(y: CGFloat, length: CGFloat)] = [(83, 16), (118, 28), (152, 28)]
        let right: [(y: CGFloat, length: CGFloat)] = [(134, 44), (250, 26)]
        return ZStack {
            ForEach(left.indices, id: \.self) { index in
                button(length: left[index].length)
                    .position(x: 0.4, y: left[index].y)
            }
            ForEach(right.indices, id: \.self) { index in
                button(length: right[index].length, sapphire: index == 1)
                    .position(x: width - 0.4, y: right[index].y)
            }
        }
        .frame(width: width, height: TrailerPhone.bodySize.height)
    }

    private func button(length: CGFloat, sapphire: Bool = false) -> some View {
        let shape = RoundedRectangle(cornerRadius: 1.4, style: .continuous)
        return shape
            .fill(sapphire ? AnyShapeStyle(Color(hex: 0x16161A)) : AnyShapeStyle(LinearGradient(
                colors: [Color(hex: 0x74747C), Color(hex: 0x2E2E34), Color(hex: 0x5A5A62)],
                startPoint: .top,
                endPoint: .bottom
            )))
            .overlay(shape.strokeBorder(Color.white.opacity(sapphire ? 0.22 : 0.12), lineWidth: 0.4))
            .frame(width: 3.2, height: length)
    }
}

/// A faint glass reflection over the screen, drawn above the demos.
private struct PhoneGlass: View {
    var body: some View {
        let screen = RoundedRectangle(cornerRadius: TrailerPhone.screenCorner, style: .continuous)
        screen
            .fill(
                LinearGradient(
                    stops: [
                        Gradient.Stop(color: Color.white.opacity(0.07), location: 0),
                        Gradient.Stop(color: Color.white.opacity(0.015), location: 0.34),
                        Gradient.Stop(color: Color.white.opacity(0), location: 0.35),
                        Gradient.Stop(color: Color.white.opacity(0), location: 0.8),
                        Gradient.Stop(color: Color.white.opacity(0.03), location: 1),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: TrailerPhone.screenSize.width, height: TrailerPhone.screenSize.height)
            .frame(width: TrailerPhone.bodySize.width, height: TrailerPhone.bodySize.height)
            .allowsHitTesting(false)
    }
}

// MARK: - Screen: the app's detail page

/// One demo's page: its real name, category, how to play it and its first parameters.
private struct PhonePage {
    struct Param {
        let name: String
        let value: String
        /// Knob position on the slider, nil for toggles and choices (value only).
        let fraction: Double?
    }

    let start: Double
    let name: String
    let tag: String
    let hint: String
    let symbol: String
    let params: [Param]
    var isLab = false

    static let all: [PhonePage] = [
        page(0, TrailerData.heroID),
        page(25.45, "showcase.board-card"),
        page(29.3, "buttons.depth-press"),
        page(32.9, "inputs.squash-toggle"),
        PhonePage(start: 35.75, name: "弹簧参数", tag: "实时预览", hint: "拖动滑块，实时预览", symbol: "slider.horizontal.3", params: [], isLab: true),
    ]

    private static func page(_ start: Double, _ id: String) -> PhonePage {
        guard let effect = EffectLibrary.effect(id: id) else {
            return PhonePage(start: start, name: id, tag: "", hint: "", symbol: "hand.tap", params: [])
        }
        let values = effect.defaultParams
        let params: [Param] = effect.params.prefix(2).map { spec in
            let value = values[spec.id]
            var fraction: Double? = nil
            if case .slider(let range, _) = spec.kind, range.upperBound > range.lowerBound {
                fraction = M.clamp((value - range.lowerBound) / (range.upperBound - range.lowerBound))
            }
            return Param(name: spec.name.zh, value: spec.formatted(value, .zh), fraction: fraction)
        }
        return PhonePage(
            start: start,
            name: effect.name.zh,
            tag: effect.category.title.zh,
            hint: hint(effect.interaction),
            symbol: effect.interaction.symbol,
            params: params
        )
    }

    private static func hint(_ interaction: EffectInteraction) -> String {
        switch interaction {
        case .tap: return "点一下试试"
        case .gesture: return "按住拖动试试"
        case .scroll: return "上下滑动试试"
        case .loop: return "自动循环播放"
        case .state: return "点一下切换状态"
        }
    }
}

/// Status bar and Dynamic Island, nav title row, the stage well (the demos are drawn over it by the
/// scene), a hint pill and the parameter card, all in `TrailerPhone.screenSize` coordinates.
private struct PhoneScreen: View {
    let t: Double

    var body: some View {
        let size = TrailerPhone.screenSize
        let stage = TrailerPhone.stageRect
        let stageShape = RoundedRectangle(cornerRadius: TrailerPhone.stageCorner, style: .continuous)
        ZStack {
            LinearGradient(
                colors: [Color(hex: 0x17120F), TrailerCanvas.ink, TrailerCanvas.ink],
                startPoint: .top,
                endPoint: .bottom
            )
            statusBar
            island
            navChrome
            ForEach(PhonePage.all.indices, id: \.self) { index in
                navRow(index)
            }
            stageShape
                .fill(Color(hex: 0x141417))
                .overlay(StageRim(cornerRadius: TrailerPhone.stageCorner))
                .frame(width: stage.width, height: stage.height)
                .position(x: stage.midX, y: stage.midY)
            hintPill
            paramCard
            Capsule()
                .fill(Color.white.opacity(0.55))
                .frame(width: 134 * TrailerPhone.unit, height: 5 * TrailerPhone.unit)
                .position(x: size.width / 2, y: TrailerPhone.homeIndicatorY)
        }
        .frame(width: size.width, height: size.height)
        .environment(\.colorScheme, .dark)
    }

    /// 0 → 1 → 0 visibility of page `index`, and its slide.
    private func visibility(_ index: Int) -> (opacity: Double, offset: CGFloat) {
        let pages = PhonePage.all
        let entry = pages[index]
        let next: Double = index + 1 < pages.count ? pages[index + 1].start : 999
        let enter: Double = index == 0 ? 1 : M.easeOut(M.progress(t, entry.start, 0.35))
        let leave: Double = M.easeIn(M.progress(t, next - 0.2, 0.3))
        let offset = CGFloat((1 - enter) * 6 - leave * 6)
        return (enter * (1 - leave), offset)
    }

    private var statusBar: some View {
        let y = TrailerPhone.statusY
        return ZStack {
            Text(verbatim: "9:41")
                .font(.system(size: 8, weight: .semibold))
                .foregroundStyle(Color.white)
                .position(x: 29, y: y)
            HStack(spacing: 2.5) {
                Image(systemName: "cellularbars")
                Image(systemName: "wifi")
                Image(systemName: "battery.100percent")
            }
            .font(.system(size: 6.5, weight: .semibold))
            .foregroundStyle(Color.white)
            .position(x: 155, y: y)
        }
    }

    private var island: some View {
        let island = TrailerPhone.islandSize
        return ZStack {
            Capsule()
                .fill(Color.black)
                .overlay(Capsule().strokeBorder(Color.white.opacity(0.05), lineWidth: 0.4))
            // Front camera behind the glass.
            Circle()
                .fill(RadialGradient(colors: [Color(hex: 0x2A2F45), Color(hex: 0x0A0A10)], center: .topLeading, startRadius: 0, endRadius: 3.2))
                .frame(width: 5.4, height: 5.4)
                .offset(x: island.width / 2 - island.height / 2)
        }
        .frame(width: island.width, height: island.height)
        .position(x: TrailerPhone.screenSize.width / 2, y: TrailerPhone.islandTop + island.height / 2)
    }

    /// Back chevron and favourite heart, constant across pages.
    private var navChrome: some View {
        ZStack {
            Image(systemName: "chevron.left")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(Palette.accent)
                .position(x: 15, y: TrailerPhone.navY)
            Image(systemName: "heart")
                .font(.system(size: 9.5, weight: .semibold))
                .foregroundStyle(Color.white.opacity(0.7))
                .position(x: 171, y: TrailerPhone.navY)
        }
    }

    private func navRow(_ index: Int) -> some View {
        let page = PhonePage.all[index]
        let shown = visibility(index)
        return HStack(spacing: 4) {
            Text(verbatim: page.name)
                .font(.system(size: 10.5, weight: .heavy))
                .foregroundStyle(Color.white)
            Text(verbatim: page.tag)
                .font(.system(size: 7, weight: .bold))
                .foregroundStyle(Palette.accent)
                .padding(.horizontal, 4)
                .padding(.vertical, 1.5)
                .background(Palette.ember.opacity(0.16), in: Capsule())
        }
        .lineLimit(1)
        .frame(width: 130)
        .offset(y: shown.offset)
        .opacity(shown.opacity)
        .position(x: TrailerPhone.screenSize.width / 2, y: TrailerPhone.navY)
    }

    private var hintPill: some View {
        let pulse = min(1, abs(TrailerScript.buzz(t)) * 3)
        return ZStack {
            Capsule()
                .fill(Color.white.opacity(0.06))
                .overlay(Capsule().strokeBorder(Color.white.opacity(0.08), lineWidth: 0.5))
                .frame(width: 120, height: 17)
            ForEach(PhonePage.all.indices, id: \.self) { index in
                let page = PhonePage.all[index]
                let shown = visibility(index)
                HStack(spacing: 4) {
                    Image(systemName: page.symbol)
                        .font(.system(size: 7, weight: .bold))
                        .foregroundStyle(Palette.accentFill)
                    Text(verbatim: page.hint)
                        .font(.system(size: 8, weight: .semibold))
                        .foregroundStyle(Color.white.opacity(0.72))
                    Image(systemName: "waveform")
                        .font(.system(size: 7, weight: .bold))
                        .foregroundStyle(Palette.accentFill)
                        .scaleEffect(CGFloat(1 + 0.4 * pulse))
                        .opacity(0.4 + 0.6 * pulse)
                }
                .lineLimit(1)
                .offset(y: shown.offset * 0.5)
                .opacity(shown.opacity)
            }
        }
        .position(x: TrailerPhone.screenSize.width / 2, y: TrailerPhone.hintY)
    }

    private var paramCard: some View {
        let card = TrailerPhone.cardRect
        let tune = M.progress(t, 36.15, 0.5)
        let shape = RoundedRectangle(cornerRadius: 14, style: .continuous)
        return ZStack {
            TrailerGlass(shape: shape, glow: 0.55 * tune, shadowOpacity: 0.2)
                .frame(width: card.width, height: card.height)
                .position(x: card.midX, y: card.midY)
            Text(verbatim: "参数")
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(Color.white.opacity(0.55))
                .frame(width: 60, alignment: .leading)
                .position(x: card.minX + 10 + 30, y: TrailerPhone.cardHeaderY)
            Text(verbatim: "重置")
                .font(.system(size: 8, weight: .semibold))
                .foregroundStyle(Palette.accent.opacity(0.8))
                .position(x: card.maxX - 18, y: TrailerPhone.cardHeaderY)
            ForEach(PhonePage.all.indices, id: \.self) { index in
                pageParams(index)
            }
        }
    }

    private func pageParams(_ index: Int) -> some View {
        let page = PhonePage.all[index]
        let shown = visibility(index)
        return ZStack {
            if page.isLab {
                PhoneParamRow(title: "阻尼", value: String(format: "%.2f", TrailerTune.damping(t)), fraction: TrailerTune.normalized(row: 0, t: t), y: TrailerPhone.rowY[0], active: TrailerTune.isDragging(row: 0, t: t))
                PhoneParamRow(title: "响应", value: String(format: "%.2f", TrailerTune.response(t)), fraction: TrailerTune.normalized(row: 1, t: t), y: TrailerPhone.rowY[1], active: TrailerTune.isDragging(row: 1, t: t))
            } else if page.params.isEmpty {
                Text(verbatim: "无可调参数")
                    .font(.system(size: 8.5, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.4))
                    .position(x: TrailerPhone.cardRect.midX, y: (TrailerPhone.rowY[0] + TrailerPhone.rowY[1]) / 2)
            } else {
                ForEach(page.params.indices, id: \.self) { row in
                    let param = page.params[row]
                    PhoneParamRow(title: param.name, value: param.value, fraction: param.fraction, y: TrailerPhone.rowY[min(row, 1)], active: false)
                        .opacity(0.8)
                }
            }
        }
        .opacity(shown.opacity)
    }
}

/// One parameter row of the detail page: label, slider (ember fill + white knob) and value.
private struct PhoneParamRow: View {
    let title: String
    let value: String
    let fraction: Double?
    let y: CGFloat
    let active: Bool

    var body: some View {
        let trackX = TrailerPhone.trackX
        let track = TrailerPhone.trackWidth
        let right = TrailerPhone.cardRect.maxX
        ZStack {
            Text(verbatim: title)
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(Color.white.opacity(0.85))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .frame(width: 38, alignment: .leading)
                .position(x: 19 + 19, y: y)
            if let fraction {
                let filled: CGFloat = max(track * CGFloat(fraction), 3)
                Capsule()
                    .fill(Color.white.opacity(0.12))
                    .frame(width: track, height: 3)
                    .position(x: trackX + track / 2, y: y)
                Capsule()
                    .fill(Palette.accentFill)
                    .frame(width: filled, height: 3)
                    .position(x: trackX + filled / 2, y: y)
                Circle()
                    .fill(Color.white)
                    .frame(width: 12, height: 12)
                    .shadow(color: Color.black.opacity(0.35), radius: 3, x: 0, y: 1.5)
                    .scaleEffect(active ? 1.2 : 1)
                    .position(x: trackX + track * CGFloat(fraction), y: y)
            }
            Text(verbatim: value)
                .font(.system(size: 9, weight: .heavy, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(TrailerStyle.emberText)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .frame(width: fraction == nil ? 96 : 30, alignment: .trailing)
                .position(x: right - 8 - (fraction == nil ? 48 : 15), y: y)
        }
    }
}

// MARK: - Tune: spring lab + the page's sliders

/// The scripted slider values and the finger that scrubs them.
enum TrailerTune {
    struct Press {
        let row: Int
        let start: Double
        let end: Double
    }

    struct Tick {
        let time: Double
        let point: CGPoint
    }

    static let presses: [Press] = [
        Press(row: 0, start: 36.9, end: 38.3),
        Press(row: 0, start: 38.9, end: 40.35),
        Press(row: 0, start: 40.85, end: 42.0),
        Press(row: 1, start: 42.3, end: 43.25),
    ]

    static let dampingRange: ClosedRange<Double> = 0.1...1.0
    static let responseRange: ClosedRange<Double> = 0.2...1.0
    /// Slider tracks in canvas space: the phone page's parameter rows (`TrailerPhone.rowY`).
    static let trackMinX: CGFloat = TrailerLayout.screenPoint(TrailerPhone.trackX, 0).x
    static let trackWidth: CGFloat = TrailerPhone.trackWidth * TrailerLayout.phoneScale
    static let rowY: [CGFloat] = TrailerPhone.rowY.map { TrailerLayout.screenPoint(0, $0).y }

    static func damping(_ t: Double) -> Double {
        var value = 0.7
        value = M.mix(value, 0.2, M.easeInOut(M.progress(t, 37.05, 1.1)))
        value = M.mix(value, 1.0, M.easeInOut(M.progress(t, 39.05, 1.15)))
        value = M.mix(value, 0.5, M.easeInOut(M.progress(t, 41.0, 0.85)))
        return value
    }

    static func response(_ t: Double) -> Double {
        M.mix(0.55, 0.3, M.easeInOut(M.progress(t, 42.4, 0.75)))
    }

    static func normalized(row: Int, t: Double) -> Double {
        let range = row == 0 ? dampingRange : responseRange
        let value = row == 0 ? damping(t) : response(t)
        return M.clamp((value - range.lowerBound) / (range.upperBound - range.lowerBound))
    }

    static func isDragging(row: Int, t: Double) -> Bool {
        presses.contains { $0.row == row && t >= $0.start && t <= $0.end }
    }

    static func knobPoint(row: Int, t: Double) -> CGPoint {
        CGPoint(x: trackMinX + trackWidth * CGFloat(normalized(row: row, t: t)), y: rowY[min(max(row, 0), 1)])
    }

    static func pressed(_ t: Double) -> Double {
        for press in presses where t >= press.start - 0.06 && t <= press.end + 0.08 {
            let down = M.progress(t, press.start - 0.06, 0.06)
            let up = 1 - M.progress(t, press.end, 0.08)
            return min(down, up)
        }
        return 0
    }

    static func fingerPoint(_ t: Double) -> CGPoint {
        let first = knobPoint(row: 0, t: 36.9)
        if t < 36.85 {
            let p = M.easeInOut(M.progress(t, 36.4, 0.45))
            return M.mix(CGPoint(x: first.x + 70, y: first.y + 50), first, p)
        }
        let hover = CGFloat(1 - pressed(t)) * 6
        if t < 42.05 {
            let knob = knobPoint(row: 0, t: t)
            return CGPoint(x: knob.x, y: knob.y + hover)
        }
        if t < 42.3 {
            let p = M.easeInOut(M.progress(t, 42.05, 0.22))
            return M.mix(knobPoint(row: 0, t: t), knobPoint(row: 1, t: t), p)
        }
        let knob = knobPoint(row: 1, t: t)
        if t < 43.3 { return CGPoint(x: knob.x, y: knob.y + hover) }
        let p = M.easeIn(M.progress(t, 43.3, 0.3))
        return M.mix(knob, CGPoint(x: knob.x + 60, y: knob.y + 40), p)
    }

    /// Detent ticks: every 10 % of travel while a knob is dragged gets a tiny ring (selection haptic).
    static let ticks: [Tick] = {
        var list: [Tick] = []
        for press in TrailerTune.presses {
            var step = Int((TrailerTune.normalized(row: press.row, t: press.start) * 10).rounded(.down))
            var time = press.start
            while time <= press.end {
                let current = Int((TrailerTune.normalized(row: press.row, t: time) * 10).rounded(.down))
                if current != step {
                    step = current
                    list.append(Tick(time: time, point: TrailerTune.knobPoint(row: press.row, t: time)))
                }
                time += 1.0 / 60.0
            }
        }
        return list
    }()
}

/// Self-contained demo for the tune beat, filling the phone's stage: an ember block ping-pongs on a
/// spring driven by the live damping/response values, with its step-response curve drawn underneath.
/// Laid out in fractions of `side`, so it keeps its proportions at every size.
private struct TrailerSpringLab: View {
    let t: Double
    let side: CGFloat

    private static let cycle: Double = 1.3
    private static let start: Double = 35.8

    var body: some View {
        let damping = TrailerTune.damping(t)
        let response = TrailerTune.response(t)
        let shape = RoundedRectangle(cornerRadius: TrailerLayout.stageCorner, style: .continuous)
        ZStack(alignment: .topLeading) {
            StageBackground()
            curve(damping: damping, response: response)
            lane(damping: damping, response: response)
        }
        .frame(width: side, height: side)
        .clipShape(shape)
        .overlay(StageRim(cornerRadius: TrailerLayout.stageCorner))
    }

    private func phase(_ time: Double) -> (elapsed: Double, forward: Bool) {
        let local = max(time - Self.start, 0)
        let index = (local / Self.cycle).rounded(.down)
        return (local - index * Self.cycle, Int(index) % 2 == 0)
    }

    private func blockX(at time: Double, damping: Double, response: Double) -> CGFloat {
        let (elapsed, forward) = phase(time)
        let value = M.spring(elapsed, response: response, damping: damping)
        let left: CGFloat = side * 0.15
        let right: CGFloat = side * 0.85
        return forward ? M.mix(left, right, value) : M.mix(right, left, value)
    }

    private func lane(damping: Double, response: Double) -> some View {
        let block: CGFloat = side * 0.13
        let laneY: CGFloat = side * 0.17
        return ZStack(alignment: .topLeading) {
            Capsule()
                .fill(Color.white.opacity(0.06))
                .frame(width: side * 0.84, height: 3)
                .offset(x: side * 0.08, y: laneY - 1.5)
            ForEach(0..<4, id: \.self) { ghost in
                let x = blockX(at: t - Double(ghost) * 0.035, damping: damping, response: response)
                RoundedRectangle(cornerRadius: block * 0.3, style: .continuous)
                    .fill(Palette.accentFill)
                    .frame(width: block, height: block)
                    .shadow(color: ghost == 0 ? Palette.accentGlow : Color.clear, radius: 10, x: 0, y: 3)
                    .opacity(ghost == 0 ? 1 : 0.22 / Double(ghost))
                    .offset(x: x - block / 2, y: laneY - block / 2)
            }
        }
    }

    private func curve(damping: Double, response: Double) -> some View {
        let left: CGFloat = side * 0.08
        let width: CGFloat = side * 0.84
        let base: CGFloat = side * 0.86
        let amplitude: CGFloat = side * 0.46
        let target: CGFloat = base - amplitude
        let elapsed = phase(t).elapsed
        let headX: CGFloat = left + width * CGFloat(min(elapsed / Self.cycle, 1))
        let headY: CGFloat = base - amplitude * CGFloat(M.spring(elapsed, response: response, damping: damping))
        let labelSize: CGFloat = max(side * 0.052, 6.5)
        return ZStack(alignment: .topLeading) {
            Path { path in
                path.move(to: CGPoint(x: left, y: target))
                path.addLine(to: CGPoint(x: left + width, y: target))
            }
            .stroke(Color.white.opacity(0.22), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
            Path { path in
                path.move(to: CGPoint(x: left, y: base))
                path.addLine(to: CGPoint(x: left + width, y: base))
            }
            .stroke(Color.white.opacity(0.1), lineWidth: 1)
            Path { path in
                let samples = 90
                for sample in 0...samples {
                    let fraction: Double = Double(sample) / Double(samples)
                    let value: Double = M.spring(Self.cycle * fraction, response: response, damping: damping)
                    let point = CGPoint(x: left + width * CGFloat(fraction), y: base - amplitude * CGFloat(value))
                    if sample == 0 { path.move(to: point) } else { path.addLine(to: point) }
                }
            }
            .stroke(Palette.accentFill, style: StrokeStyle(lineWidth: 2.2, lineCap: .round, lineJoin: .round))
            .shadow(color: Palette.accentGlow, radius: 6, x: 0, y: 0)
            Circle()
                .fill(Color.white)
                .frame(width: 7, height: 7)
                .shadow(color: Palette.ember, radius: 6, x: 0, y: 0)
                .offset(x: headX - 3.5, y: headY - 3.5)
            Text(verbatim: "目标")
                .font(.system(size: labelSize, weight: .bold))
                .foregroundStyle(Color.white.opacity(0.45))
                .offset(x: left + width - labelSize * 2.2, y: target - labelSize * 1.6)
        }
    }
}
