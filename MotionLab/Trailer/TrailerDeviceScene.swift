import SwiftUI

private typealias M = TrailerMath

// MARK: - Phone geometry

/// An iPhone 16/17 Pro drawn to scale, in points of its own 9:16 authoring size (the 3:4 cut scales it
/// uniformly by `TrailerLayout.phoneScale`).
///
/// Real device: 71.5 × 149.6 mm body, 1206 × 2622 px display (aspect 0.46), display corners ≈ 13 % of
/// its width, Dynamic Island 126 × 37 pt on a 402 pt wide screen, 11 pt from the top.
/// Everything inside the screen is laid out in screen coordinates (0 … 186 × 0 … 404). The embedded app
/// screens (`TrailerAppScreen`) are laid out at the real 402 × 874 pt and scaled by `unit`.
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

    /// Point-to-point factor of the real screen onto this one (402 pt → 186 pt).
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

// MARK: - 30–62 s (source) · The phone: find it, feel it, favourites

/// One continuous shot of an iPhone. First it shows the app's real Browse and Search screens (see
/// `TrailerFind`); the finger opens a result and the detail page zooms out of its card. Then real demos take
/// turns on the detail stage (each swap zooms through depth) while the finger taps them on the beats their
/// own `.autoplay` loops are phase-locked to; the last two are the author's favourites (the day/night
/// switch and the gear checklist), under their own headline.
struct TrailerPhoneScene: View {
    let t: Double
    let origin: Date

    static let appear: Double = 29.45
    static let exitStart: Double = 62.0
    /// The favourites' headline takes over from "真实上手体验" here.
    static let favouritesStart: Double = 53.1
    /// The day/night switch hands over to the gear checklist.
    static let secondFavourite: Double = 58.1

    /// Outgoing demo: sinks back, blurs and fades.
    static func swapOut(_ t: Double, at start: Double) -> Double {
        M.easeIn(M.progress(t, start, 0.45))
    }

    /// Incoming demo: rises out of depth on a spring.
    static func swapIn(_ t: Double, at start: Double) -> Double {
        M.spring(t, at: start, response: 0.55, damping: 0.8)
    }

    /// Demos on the detail stage, with the times their taps land (see `TrailerScript.taps`).
    /// `epochOffset` = first tap − the demo's autoplay delay, so `demoSyncEpoch` fires it on the tap.
    struct Slot {
        let id: String
        let mount: ClosedRange<Double>
        let enter: Double
        let leave: Double
        let epochOffset: Double
        /// The first page zooms out of the search result the finger tapped.
        var zoomsFromResult = false
        /// Speeds the demo's own autoplay loop up (`demoAutoplayIntervalScale`), so a long routine fits its beat.
        var intervalScale: Double = 1
        /// The autoplay loop stops here, so a demo that would start over keeps its finished state on screen.
        var autoplayUntil: Double = .infinity
    }

    static let slots: [Slot] = [
        // showcase.photo-play: delay 0.8, every 3.2 → play at 43.8, pause at 47.0.
        Slot(id: TrailerData.heroID, mount: 42.15...47.95, enter: TrailerFind.detailOpen, leave: 47.45, epochOffset: 43.0, zoomsFromResult: true),
        // showcase.save-burst: delay 0.4, every 1.5 → double-tap save at 48.3, bookmark off at 49.8.
        Slot(id: "showcase.save-burst", mount: 47.0...51.3, enter: 47.6, leave: 50.65, epochOffset: 47.9),
        // showcase.board-card: delay 0.8, every 2.4 → flips at 51.6.
        Slot(id: "showcase.board-card", mount: 50.2...53.35, enter: 50.8, leave: 52.85, epochOffset: 50.8),
        // Favourite 1, inputs.day-night-toggle: delay 0.5, every 1.6 → night at 53.8, day at 55.4, night at 57.0.
        Slot(id: "inputs.day-night-toggle", mount: 52.5...58.45, enter: favouritesStart, leave: 57.9, epochOffset: 53.3),
        // Favourite 2, showcase.gear-checklist (starts with the goggles packed): delay 0.6, every 1.1 × 0.6 = 0.66
        // → packs the other four at 58.6, 59.26, 59.92, 60.58; "all packed" once the last glyph lands (+0.55 s
        // flight, 61.13). The next tick (61.24) would unpack everything, so the loop stops at 61.0 and the
        // packed kit stays until the phone leaves.
        Slot(id: "showcase.gear-checklist", mount: 57.5...62.7, enter: secondFavourite, leave: 70, epochOffset: 58.0, intervalScale: 0.6, autoplayUntil: 61.0),
    ]

    var body: some View {
        let appear: Double = M.spring(t, at: Self.appear, response: 0.75, damping: 0.84)
        let exit: Double = M.easeInOut(M.progress(t, Self.exitStart, 0.6))
        let buzz = CGFloat(TrailerScript.buzz(t) * 2.4)
        let rise = CGFloat(1 - appear) * 150
        let grow = CGFloat(0.94 + 0.06 * appear)
        let shrink = CGFloat(1 - 0.1 * exit)
        let titleSize = TrailerCanvas.pick(28, 34)
        let subtitleSize = TrailerCanvas.pick(17, 21)
        ZStack {
            if t < 43.9 {
                TrailerHeadline(
                    title: TrailerCopy.current.search.title,
                    subtitle: TrailerCopy.optional(TrailerCopy.current.search.subtitle),
                    titleSize: titleSize,
                    subtitleSize: TrailerCanvas.pick(15, 17),
                    reveal: M.progress(t, 29.9, 0.9),
                    exit: M.easeIn(M.progress(t, 43.2, 0.5))
                )
                .position(x: 195, y: TrailerLayout.phoneHeadlineY)
            }
            if t > 43.4 && t < Self.favouritesStart + 0.2 {
                TrailerHeadline(
                    title: TrailerCopy.current.phone.title,
                    subtitle: TrailerCopy.optional(TrailerCopy.current.phone.subtitle),
                    titleSize: titleSize,
                    subtitleSize: subtitleSize,
                    reveal: M.progress(t, 43.7, 0.9),
                    exit: M.easeIn(M.progress(t, Self.favouritesStart - 0.5, 0.5))
                )
                .position(x: 195, y: TrailerLayout.phoneHeadlineY)
            }
            if t > Self.favouritesStart - 0.2 {
                TrailerFavouritesHeadline(t: t, titleSize: titleSize, subtitleSize: subtitleSize)
                    .position(x: 195, y: TrailerLayout.phoneHeadlineY)
            }
            ZStack {
                TrailerPhoneBody {
                    PhoneScreen(t: t)
                }
                .scaleEffect(TrailerLayout.phoneScale)
                .position(TrailerLayout.phoneCenter)
                ForEach(Self.slots.indices, id: \.self) { index in
                    let slot = Self.slots[index]
                    if slot.mount.contains(t) {
                        demo(slot)
                    }
                }
                TrailerPhoneGlass()
                    .scaleEffect(TrailerLayout.phoneScale)
                    .position(TrailerLayout.phoneCenter)
            }
            .frame(width: TrailerCanvas.width, height: TrailerCanvas.height)
            .offset(y: rise)
            .scaleEffect(grow)
            .opacity(M.clamp(appear * 1.5))
            .offset(x: buzz)
            .scaleEffect(shrink)
            // Only blurred on the way out (the embedded app screens are long gone by then).
            .modifier(TrailerExitBlur(radius: CGFloat(exit) * 12))
            .opacity(1 - exit)
        }
        .frame(width: TrailerCanvas.width, height: TrailerCanvas.height)
    }

    private func demo(_ slot: Slot) -> some View {
        let zoom: Double = M.spring(t, at: slot.enter, response: 0.6, damping: 0.86)
        let enter: Double = slot.zoomsFromResult ? zoom : Self.swapIn(t, at: slot.enter)
        let leave: Double = Self.swapOut(t, at: slot.leave)
        // The first page grows out of the tapped result's preview stage, like the app's zoom transition.
        let fromCenter: CGPoint = TrailerFind.canvasPoint(TrailerFind.resultStage(TrailerData.heroResultIndex))
        let fromSide: CGFloat = TrailerFind.canvasLength(TrailerFind.resultStageSide)
        let fromCorner: CGFloat = TrailerFind.canvasLength(CornerRadius.thumbnail)
        let center: CGPoint = slot.zoomsFromResult ? M.mix(fromCenter, TrailerLayout.demoCenter, zoom) : TrailerLayout.demoCenter
        let side: CGFloat = slot.zoomsFromResult ? M.mix(fromSide, TrailerLayout.demoSide, zoom) : TrailerLayout.demoSide
        let corner: CGFloat = slot.zoomsFromResult ? M.mix(fromCorner, TrailerLayout.stageCorner, zoom) : TrailerLayout.stageCorner
        let grow: Double = slot.zoomsFromResult ? 1 : 0.9 + 0.1 * enter
        let scale: Double = grow * (1 - 0.12 * leave)
        let settle: Double = slot.zoomsFromResult ? 0 : (1 - M.clamp(enter)) * 10
        let blur: Double = settle + leave * 10
        let fadeIn: Double = slot.zoomsFromResult ? M.clamp(zoom * 4) : M.clamp(enter * 1.6)
        return TrailerStageTile(
            effectID: slot.id,
            epoch: origin.addingTimeInterval(slot.epochOffset),
            intervalScale: slot.intervalScale,
            autoplay: t < slot.autoplayUntil,
            side: side,
            cornerRadius: corner
        )
        .scaleEffect(CGFloat(scale))
        .blur(radius: CGFloat(blur))
        .opacity(fadeIn * (1 - leave))
        .position(center)
    }
}

/// Blur only while `radius` is noticeable, so the phone (and the UIKit-backed app screens inside it) carry
/// no filter for most of the shot.
private struct TrailerExitBlur: ViewModifier {
    let radius: CGFloat

    @ViewBuilder
    func body(content: Content) -> some View {
        if radius > 0.01 {
            content.blur(radius: radius)
        } else {
            content
        }
    }
}

// MARK: - Device

/// Chassis (graphite titanium band with a rim highlight, black glass border, side buttons, soft
/// shadows) around `screen`, drawn at `TrailerPhone.bodySize`; the screen is laid out at
/// `TrailerPhone.screenSize` and clipped to the display's rounded corners.
struct TrailerPhoneBody<Screen: View>: View {
    let screen: Screen

    init(@ViewBuilder screen: () -> Screen) {
        self.screen = screen()
    }

    private static var titanium: LinearGradient {
        LinearGradient(
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
    }

    private static var rimLight: LinearGradient {
        LinearGradient(
            stops: [
                Gradient.Stop(color: Color.white.opacity(0.6), location: 0),
                Gradient.Stop(color: Color.white.opacity(0.14), location: 0.3),
                Gradient.Stop(color: Color.white.opacity(0.05), location: 0.7),
                Gradient.Stop(color: Color.white.opacity(0.24), location: 1),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    var body: some View {
        let size = TrailerPhone.bodySize
        let outer = RoundedRectangle(cornerRadius: TrailerPhone.bodyCorner, style: .continuous)
        let band: CGFloat = 2.2
        let glass = RoundedRectangle(cornerRadius: TrailerPhone.bodyCorner - band, style: .continuous)
        let display = RoundedRectangle(cornerRadius: TrailerPhone.screenCorner, style: .continuous)
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
            screen
                .frame(width: TrailerPhone.screenSize.width, height: TrailerPhone.screenSize.height)
                .clipShape(display)
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
        let metal = LinearGradient(
            colors: [Color(hex: 0x74747C), Color(hex: 0x2E2E34), Color(hex: 0x5A5A62)],
            startPoint: .top,
            endPoint: .bottom
        )
        let fill: AnyShapeStyle = sapphire ? AnyShapeStyle(Color(hex: 0x16161A)) : AnyShapeStyle(metal)
        return shape
            .fill(fill)
            .overlay(shape.strokeBorder(Color.white.opacity(sapphire ? 0.22 : 0.12), lineWidth: 0.4))
            .frame(width: 3.2, height: length)
    }
}

/// A faint glass reflection over the screen, drawn above the demos.
struct TrailerPhoneGlass: View {
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

/// Status bar (time, signal, Wi-Fi, battery) and the Dynamic Island, in screen coordinates.
struct TrailerPhoneStatusBar: View {
    var body: some View {
        let size = TrailerPhone.screenSize
        let island = TrailerPhone.islandSize
        let y = TrailerPhone.statusY
        ZStack {
            Text(verbatim: TrailerCopy.current.phone.statusTime)
                .font(.system(size: 8, weight: .semibold))
                .foregroundStyle(Color.white)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .frame(width: 40)
                .position(x: 29, y: y)
            HStack(spacing: 2.5) {
                Image(systemName: "cellularbars")
                Image(systemName: "wifi")
                Image(systemName: "battery.100percent")
            }
            .font(.system(size: 6.5, weight: .semibold))
            .foregroundStyle(Color.white)
            .position(x: 155, y: y)
            ZStack {
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
            .position(x: size.width / 2, y: TrailerPhone.islandTop + island.height / 2)
            Capsule()
                .fill(Color.white.opacity(0.55))
                .frame(width: 134 * TrailerPhone.unit, height: 5 * TrailerPhone.unit)
                .position(x: size.width / 2, y: TrailerPhone.homeIndicatorY)
        }
        .frame(width: size.width, height: size.height)
        .allowsHitTesting(false)
    }
}

// MARK: - Screen: the real app, then the app's detail page

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

    static let all: [PhonePage] = TrailerPhoneScene.slots.map { slot in
        PhonePage.page(slot.enter, slot.id)
    }

    /// Width of the hint pill: 120 pt, wider (up to 170) when a hint in `TrailerCopy` needs it.
    static let hintPillWidth: CGFloat = {
        let widest: CGFloat = PhonePage.all.map { TrailerCopy.estimatedWidth($0.hint, size: 8) }.max() ?? 0
        let natural: CGFloat = widest + 7 + 7 + 8 + 16
        return min(max(120, natural), 170)
    }()

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
            return Param(name: spec.name(TrailerCopy.appLanguage), value: spec.formatted(value, TrailerCopy.appLanguage), fraction: fraction)
        }
        return PhonePage(
            start: start,
            name: effect.name(TrailerCopy.appLanguage),
            tag: effect.category.title(TrailerCopy.appLanguage),
            hint: hint(effect.interaction),
            symbol: effect.interaction.symbol,
            params: params
        )
    }

    private static func hint(_ interaction: EffectInteraction) -> String {
        let copy = TrailerCopy.current.phone
        switch interaction {
        case .tap: return copy.hintTap
        case .gesture: return copy.hintGesture
        case .scroll: return copy.hintScroll
        case .loop: return copy.hintLoop
        case .state: return copy.hintState
        }
    }
}

/// The phone's display. Until the finger opens a result it shows the app's real screens
/// (`TrailerAppScreen`, scaled uniformly from 402 × 874 pt); then the detail page: nav title row, the stage
/// well (the demos are drawn over it by the scene), a hint pill and the parameter card. Status bar and
/// Dynamic Island sit on top throughout.
private struct PhoneScreen: View {
    let t: Double

    var body: some View {
        let size = TrailerPhone.screenSize
        let detail: Double = M.easeOut(M.progress(t, TrailerFind.detailOpen + 0.05, 0.4))
        ZStack {
            LinearGradient(
                colors: [Color(hex: 0x17120F), TrailerCanvas.ink, TrailerCanvas.ink],
                startPoint: .top,
                endPoint: .bottom
            )
            if t < TrailerFind.appUnmount {
                TrailerAppScreen(state: TrailerFind.frame(t))
                    .equatable()
                    .frame(width: TrailerFind.deviceSize.width, height: TrailerFind.deviceSize.height)
                    .scaleEffect(TrailerPhone.unit, anchor: .topLeading)
                    .frame(width: size.width, height: size.height, alignment: .topLeading)
                    .opacity(1 - detail)
            }
            if t > TrailerFind.detailOpen {
                detailPage
                    .opacity(detail)
            }
            TrailerPhoneStatusBar()
        }
        .frame(width: size.width, height: size.height)
        .environment(\.colorScheme, .dark)
    }

    private var detailPage: some View {
        let stage = TrailerPhone.stageRect
        let stageShape = RoundedRectangle(cornerRadius: TrailerPhone.stageCorner, style: .continuous)
        return ZStack {
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
        }
        .frame(width: TrailerPhone.screenSize.width, height: TrailerPhone.screenSize.height)
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
                .layoutPriority(1)
            Text(verbatim: page.tag)
                .font(.system(size: 7, weight: .bold))
                .foregroundStyle(Palette.accent)
                .padding(.horizontal, 4)
                .padding(.vertical, 1.5)
                .background(Palette.ember.opacity(0.16), in: Capsule())
        }
        .lineLimit(1)
        .minimumScaleFactor(0.7)
        .frame(width: 136)
        .offset(y: shown.offset)
        .opacity(shown.opacity)
        .position(x: TrailerPhone.screenSize.width / 2, y: TrailerPhone.navY)
    }

    private var hintPill: some View {
        let pulse: Double = min(1, abs(TrailerScript.buzz(t)) * 3)
        return ZStack {
            Capsule()
                .fill(Color.white.opacity(0.06))
                .overlay(Capsule().strokeBorder(Color.white.opacity(0.08), lineWidth: 0.5))
                .frame(width: PhonePage.hintPillWidth, height: 17)
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
                        .minimumScaleFactor(0.6)
                    Image(systemName: "waveform")
                        .font(.system(size: 7, weight: .bold))
                        .foregroundStyle(Palette.accentFill)
                        .scaleEffect(CGFloat(1 + 0.4 * pulse))
                        .opacity(0.4 + 0.6 * pulse)
                }
                .lineLimit(1)
                .frame(maxWidth: PhonePage.hintPillWidth - 10)
                .offset(y: shown.offset * 0.5)
                .opacity(shown.opacity)
            }
        }
        .position(x: TrailerPhone.screenSize.width / 2, y: TrailerPhone.hintY)
    }

    private var paramCard: some View {
        let card = TrailerPhone.cardRect
        let shape = RoundedRectangle(cornerRadius: 14, style: .continuous)
        return ZStack {
            TrailerGlass(shape: shape, shadowOpacity: 0.2)
                .frame(width: card.width, height: card.height)
                .position(x: card.midX, y: card.midY)
            Text(verbatim: TrailerCopy.current.phone.paramsHeader)
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(Color.white.opacity(0.55))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .frame(width: 96, alignment: .leading)
                .position(x: card.minX + 10 + 48, y: TrailerPhone.cardHeaderY)
            Text(verbatim: TrailerCopy.current.phone.reset)
                .font(.system(size: 8, weight: .semibold))
                .foregroundStyle(Palette.accent.opacity(0.8))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .frame(width: 50, alignment: .trailing)
                .position(x: card.maxX - 10 - 25, y: TrailerPhone.cardHeaderY)
            ForEach(PhonePage.all.indices, id: \.self) { index in
                pageParams(index)
            }
        }
    }

    private func pageParams(_ index: Int) -> some View {
        let page = PhonePage.all[index]
        let shown = visibility(index)
        let middleY: CGFloat = (TrailerPhone.rowY[0] + TrailerPhone.rowY[1]) / 2
        return ZStack {
            if page.params.isEmpty {
                Text(verbatim: TrailerCopy.current.phone.noParams)
                    .font(.system(size: 8.5, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.4))
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .frame(width: TrailerPhone.cardRect.width - 20)
                    .position(x: TrailerPhone.cardRect.midX, y: middleY)
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

/// "我最喜欢的" over the favourites, its second line naming the demo on the stage: the title stays while
/// the effect name swaps from the day/night switch to the gear checklist.
private struct TrailerFavouritesHeadline: View {
    let t: Double
    let titleSize: CGFloat
    let subtitleSize: CGFloat

    var body: some View {
        let start = TrailerPhoneScene.favouritesStart
        let swap = TrailerPhoneScene.secondFavourite
        let reveal: Double = M.progress(t, start + 0.1, 0.9)
        let exit: Double = M.easeIn(M.progress(t, TrailerPhoneScene.exitStart - 0.1, 0.5))
        let firstOut: Double = M.easeIn(M.progress(t, swap - 0.3, 0.3))
        VStack(spacing: 8) {
            Text(verbatim: TrailerCopy.current.favorites.title)
                .font(.system(size: titleSize, weight: .heavy))
                .foregroundStyle(Color.white)
                .textRenderer(GlyphBlurRenderer(progress: M.clamp(reveal * 1.2)))
            ZStack {
                Text(verbatim: Self.name(TrailerPhoneScene.slots[3].id))
                    .textRenderer(GlyphBlurRenderer(progress: M.clamp(reveal * 1.35 - 0.35)))
                    .blur(radius: CGFloat(firstOut) * 6)
                    .opacity(1 - firstOut)
                Text(verbatim: Self.name(TrailerPhoneScene.slots[4].id))
                    .textRenderer(GlyphBlurRenderer(progress: M.progress(t, swap, 0.8)))
            }
            .font(.system(size: subtitleSize, weight: .bold))
            .foregroundStyle(TrailerStyle.emberText)
        }
        .lineLimit(1)
        .minimumScaleFactor(0.45)
        .multilineTextAlignment(.center)
        .frame(width: 360)
        .shadow(color: Color.black.opacity(0.4), radius: 12, x: 0, y: 4)
        .trailerDepth(exit, scale: -0.08, lift: -18, blur: 12)
    }

    /// The effect's name in the trailer's language, as the app shows it.
    private static func name(_ id: String) -> String {
        EffectLibrary.effect(id: id)?.name(TrailerCopy.appLanguage) ?? id
    }
}
