import SwiftUI

private typealias M = TrailerMath

// MARK: - Catalog data

/// Real catalog numbers and real search results shown in the trailer.
enum TrailerData {
    static let query = "卡片"
    /// The result that is opened and played on the phone (it is the first phone demo).
    static let heroID = "cards.flip"

    static var effectCount: Int { EffectLibrary.all.count }
    static var categoryCount: Int { EffectCategory.allCases.count }
    static var familyCount: Int { EffectFamilies.all.count }

    /// Every match for the query, and the matches inside the "卡片" category chip.
    static let allMatches: [Effect] = EffectLibrary.search(query, category: nil, interaction: nil)
    static let cardMatches: [Effect] = EffectLibrary.search(query, category: .cards, interaction: nil)

    /// First six tile-friendly results before and after the chip is selected. The hero is kept in the
    /// filtered grid (top centre) so the zoom into the phone always starts from it.
    static let gridA: [Effect] = pick(allMatches, ensuring: nil)
    static let gridB: [Effect] = pick(cardMatches, ensuring: heroID)

    static var heroSlot: Int { gridB.firstIndex { $0.id == heroID } ?? 1 }

    private static func pick(_ list: [Effect], ensuring id: String?) -> [Effect] {
        var picked = list.filter { PreviewSnapshotCache.canSnapshot($0) }
        if picked.count < 6 {
            let extra = EffectLibrary.effects(in: .cards).filter { effect in
                PreviewSnapshotCache.canSnapshot(effect) && !picked.contains { $0.id == effect.id }
            }
            picked.append(contentsOf: extra)
        }
        if let id, let hero = EffectLibrary.effect(id: id) {
            picked.removeAll { $0.id == id }
            picked.insert(hero, at: min(1, picked.count))
        }
        return Array(picked.prefix(6))
    }

    /// Touches every lazily built catalog table so the heavy first access happens during the slate.
    static func warmUp() {
        _ = gridA.count + gridB.count + familyCount + heroSlot
        _ = TrailerScript.taps.count
    }
}

// MARK: - Live demo

/// A real effect demo on its 340 pt authoring canvas, autoplaying like a grid preview.
/// Equatable on the id and clock, so the trailer's per-frame re-render never rebuilds it.
/// `epoch` phase-locks its `.autoplay` loop (see `demoSyncEpoch`) so taps land on the script's beats.
struct TrailerLiveDemo: View, Equatable {
    let effectID: String
    var epoch: Date? = nil

    static func == (lhs: TrailerLiveDemo, rhs: TrailerLiveDemo) -> Bool {
        lhs.effectID == rhs.effectID && lhs.epoch == rhs.epoch
    }

    var body: some View {
        let side = StageMetrics.previewCanvas
        if let effect = EffectLibrary.effect(id: effectID) {
            EffectDemoView(effect: effect, context: DemoContext(params: effect.defaultParams, isPreview: true, language: .zh))
                .frame(width: side, height: side)
                .environment(\.demoAutoplayEnabled, true)
                .environment(\.demoSyncEpoch, epoch)
                .environment(\.appLanguage, .zh)
        }
    }
}

/// A live demo scaled into a square stage of `side` points, on the app's own stage background.
struct TrailerStageTile: View {
    let effectID: String
    var epoch: Date? = nil
    let side: CGFloat
    var cornerRadius: CGFloat = 16
    var backgroundOpacity: Double = 1

    var body: some View {
        let canvas = StageMetrics.previewCanvas
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        ZStack {
            StageBackground()
                .opacity(backgroundOpacity)
            TrailerLiveDemo(effectID: effectID, epoch: epoch)
                .equatable()
                .scaleEffect(side / canvas)
                .frame(width: side, height: side)
        }
        .frame(width: side, height: side)
        .clipShape(shape)
        .overlay(StageRim(cornerRadius: cornerRadius))
    }
}

// MARK: - 10–21 s · Search

struct TrailerSearchScene: View {
    let t: Double

    var body: some View {
        let headlineExit = M.easeIn(M.progress(t, 20.55, 0.55))
        ZStack {
            TrailerHeadline(
                title: "一搜即达",
                subtitle: "\(TrailerData.effectCount) 个动效秒速定位",
                accentOnTitle: true,
                titleSize: 36,
                reveal: M.progress(t, 11.25, 0.9),
                exit: headlineExit
            )
            .position(x: 195, y: 54)
            if t < 21.4 {
                SearchGrid(t: t)
                SearchChips(t: t)
                    .position(x: 195, y: TrailerLayout.chipY)
            }
            SearchField(t: t)
        }
        .frame(width: TrailerCanvas.width, height: TrailerCanvas.height)
    }
}

/// The words of the previous scene collapse into this glass field; it glides up and types the query.
private struct SearchField: View {
    let t: Double

    private static let typedAt: [Double] = [12.0, 12.35]

    var body: some View {
        let emerge = M.spring(t, at: 10.05, response: 0.55, damping: 0.72)
        let glide = M.spring(t, at: 10.95, response: 0.6, damping: 0.8)
        let exit = M.easeIn(M.progress(t, 20.6, 0.5))
        let width = max(CGFloat(44 + 286 * emerge), 44)
        let y = M.mix(CGFloat(250), TrailerLayout.fieldY, glide)
        let focus = M.progress(t, 11.6, 0.4)
        let typedCount = Self.typedAt.filter { t >= $0 }.count
        let bump = Self.typedAt.reduce(0.0) { sum, time in sum + 0.03 * TrailerMath.buzz(t - time) }
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(focus > 0.5 ? AnyShapeStyle(Palette.accentFill) : AnyShapeStyle(Color.white.opacity(0.6)))
            ZStack(alignment: .leading) {
                Text(verbatim: "搜索动效、控件、手势…")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.35))
                    .opacity(typedCount == 0 ? 1 : 0)
                HStack(spacing: 1) {
                    ForEach(0..<typedCount, id: \.self) { index in
                        typedCharacter(index)
                    }
                    caret
                }
            }
            Spacer(minLength: 0)
            resultCount
        }
        .padding(.horizontal, 16)
        .frame(width: width, height: 46)
        .clipped()
        .background(TrailerGlass(shape: Capsule(), frosted: true, glow: 0.25 + 0.6 * focus))
        .shadow(color: Palette.accentGlow.opacity(focus), radius: 16, x: 0, y: 6)
        .scaleEffect(CGFloat(1 + bump))
        .opacity(M.clamp(emerge * 3))
        .trailerDepth(exit, scale: 0.1, lift: -20, blur: 10)
        .position(x: 195, y: y)
    }

    private func typedCharacter(_ index: Int) -> some View {
        let characters = Array(TrailerData.query)
        let pop = M.spring(t, at: Self.typedAt[index], response: 0.35, damping: 0.55)
        return Text(verbatim: String(characters[index]))
            .font(.system(size: 18, weight: .bold))
            .foregroundStyle(Color.white)
            .scaleEffect(CGFloat(0.3 + 0.7 * pop), anchor: .bottom)
            .opacity(M.clamp(pop * 3))
    }

    private var caret: some View {
        let typing = t > 11.8 && t < 12.6
        let blink = typing || sin(t * 2 * Double.pi * 1.4) > -0.2
        return RoundedRectangle(cornerRadius: 1)
            .fill(Palette.accentFill)
            .frame(width: 2, height: 20)
            .opacity(t > 11.6 && blink ? 1 : 0)
    }

    private var resultCount: some View {
        let value = t < 12.8 ? 0 : (t < 16.1 ? TrailerData.allMatches.count : TrailerData.cardMatches.count)
        return HStack(spacing: 2) {
            Text(verbatim: "\(value)")
                .font(.system(size: 14, weight: .heavy, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(TrailerStyle.emberText)
                .contentTransition(.numericText(value: Double(value)))
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: value)
            Text(verbatim: "个结果")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color.white.opacity(0.55))
        }
        .fixedSize()
        .opacity(M.progress(t, 12.7, 0.3))
    }
}

/// Filter chips; the ember pill slides from "全部" to "卡片" when the finger taps it.
private struct SearchChips: View {
    let t: Double

    private static let titles = ["全部", "卡片", "质感交互", "按钮"]

    var body: some View {
        let slide = M.spring(t, at: 15.9, response: 0.45, damping: 0.72)
        let exit = M.easeIn(M.progress(t, 20.55, 0.5))
        let first = TrailerLayout.chipCenter(0)
        let second = TrailerLayout.chipCenter(1)
        let pillX = M.mix(first.x, second.x, slide)
        let pillWidth = M.mix(TrailerLayout.chipWidths[0], TrailerLayout.chipWidths[1], slide)
        ZStack {
            ForEach(Self.titles.indices, id: \.self) { index in
                chipBackground(index)
            }
            Capsule()
                .fill(Palette.accentFill)
                .frame(width: pillWidth, height: 30)
                .shadow(color: Palette.accentGlow, radius: 8, x: 0, y: 3)
                .position(x: pillX, y: 15)
                .opacity(M.progress(t, 12.7, 0.3))
            ForEach(Self.titles.indices, id: \.self) { index in
                chipLabel(index, pillX: pillX)
            }
        }
        .frame(width: TrailerCanvas.width, height: 30)
        .trailerDepth(exit, scale: 0.05, lift: -10, blur: 8)
    }

    private func appear(_ index: Int) -> Double {
        M.spring(t, at: 12.55 + Double(index) * 0.06, response: 0.5, damping: 0.7)
    }

    private func chipBackground(_ index: Int) -> some View {
        let center = TrailerLayout.chipCenter(index)
        let pop = appear(index)
        return Capsule()
            .fill(Palette.chipOnPage)
            .overlay(Capsule().strokeBorder(Color.white.opacity(0.1), lineWidth: 0.75))
            .frame(width: TrailerLayout.chipWidths[index], height: 30)
            .scaleEffect(CGFloat(0.6 + 0.4 * pop))
            .opacity(M.clamp(pop * 2))
            .position(x: center.x, y: 15 + CGFloat(1 - M.clamp(pop)) * 10)
    }

    private func chipLabel(_ index: Int, pillX: CGFloat) -> some View {
        let center = TrailerLayout.chipCenter(index)
        let pop = appear(index)
        let onPill = M.clamp(1 - Double(abs(pillX - center.x)) / 40)
        return ZStack {
            Text(verbatim: Self.titles[index])
                .foregroundStyle(Color.white.opacity(0.88))
                .opacity(1 - onPill)
            Text(verbatim: Self.titles[index])
                .foregroundStyle(Palette.onAccent)
                .opacity(onPill)
        }
        .font(.system(size: 14, weight: .bold))
        .scaleEffect(CGFloat(0.6 + 0.4 * pop))
        .opacity(M.clamp(pop * 2))
        .position(x: center.x, y: 15 + CGFloat(1 - M.clamp(pop)) * 10)
    }
}

// MARK: - Result grid

/// Where a result tile is at time `t`: cascades out of the search field, reflows when the chip filters
/// the list, and falls back into depth when the hero result is opened.
struct TrailerTileState {
    var center: CGPoint
    var scale: CGFloat
    var opacity: Double
    var blur: CGFloat
    var rotation: Double

    static func at(_ t: Double, id: String) -> TrailerTileState? {
        let indexA = TrailerData.gridA.firstIndex { $0.id == id }
        let indexB = TrailerData.gridB.firstIndex { $0.id == id }
        let fieldCenter = CGPoint(x: 195, y: TrailerLayout.fieldY)
        var state = TrailerTileState(center: fieldCenter, scale: 1, opacity: 0, blur: 0, rotation: 0)

        if let indexA {
            let enter = M.spring(t, at: 12.85 + Double(indexA) * 0.075, response: 0.6, damping: 0.74)
            let clamped = M.clamp(enter)
            state.center = M.mix(fieldCenter, TrailerLayout.slotCenter(indexA), enter)
            state.scale = CGFloat(0.35 + 0.65 * enter)
            state.opacity = M.clamp(enter * 2.5)
            state.blur = CGFloat(1 - clamped) * 8
            state.rotation = (1 - clamped) * (indexA % 2 == 0 ? -10 : 10)
            if let indexB {
                let move = M.spring(t, at: 16.15 + Double(indexB) * 0.04, response: 0.55, damping: 0.78)
                state.center = M.mix(TrailerLayout.slotCenter(indexA), TrailerLayout.slotCenter(indexB), move)
                if t < 16.15 { state.center = M.mix(fieldCenter, TrailerLayout.slotCenter(indexA), enter) }
            } else {
                let leave = M.easeIn(M.progress(t, 16.05 + Double(indexA) * 0.03, 0.35))
                state.scale *= CGFloat(1 - 0.4 * leave)
                state.opacity *= 1 - leave
                state.blur += CGFloat(leave) * 8
                if leave >= 1 { return nil }
            }
        } else if let indexB {
            let enter = M.spring(t, at: 16.35 + Double(indexB) * 0.07, response: 0.6, damping: 0.74)
            let clamped = M.clamp(enter)
            let slot = TrailerLayout.slotCenter(indexB)
            state.center = CGPoint(x: slot.x, y: slot.y + CGFloat(1 - enter) * 40)
            state.scale = CGFloat(0.6 + 0.4 * enter)
            state.opacity = M.clamp(enter * 2.5)
            state.blur = CGFloat(1 - clamped) * 8
        } else {
            return nil
        }

        // Opening the hero: every other tile falls back and away from it.
        if id != TrailerData.heroID, let indexB {
            let hero = TrailerLayout.slotCenter(TrailerData.heroSlot)
            let slot = TrailerLayout.slotCenter(indexB)
            let distance = Double(hypot(slot.x - hero.x, slot.y - hero.y))
            let fall = M.easeInOut(M.progress(t, 20.55 + distance / 114 * 0.05, 0.6))
            let dx = slot.x - hero.x
            let dy = slot.y - hero.y
            let length = max(CGFloat(distance), 1)
            state.center.x += dx / length * 36 * CGFloat(fall)
            state.center.y += dy / length * 36 * CGFloat(fall)
            state.scale *= CGFloat(1 - 0.2 * fall)
            state.opacity *= 1 - fall
            state.blur += CGFloat(fall) * 10
        }
        return state
    }
}

private struct SearchGrid: View {
    let t: Double

    /// Every tile that may be on screen now (the hero is drawn by `TrailerHeroLayer`).
    private var tiles: [Effect] {
        guard t > 11.4 else { return [] }
        var list: [Effect] = []
        if t < 16.6 { list.append(contentsOf: TrailerData.gridA) }
        if t > 15.4 {
            for effect in TrailerData.gridB where !list.contains(where: { $0.id == effect.id }) {
                list.append(effect)
            }
        }
        return list.filter { $0.id != TrailerData.heroID }
    }

    var body: some View {
        ZStack {
            ForEach(tiles, id: \.id) { effect in
                if let state = TrailerTileState.at(t, id: effect.id) {
                    TrailerResultTile(effect: effect, epoch: nil, side: TrailerLayout.tileSide, labelOpacity: 1)
                        .scaleEffect(state.scale)
                        .rotationEffect(.degrees(state.rotation))
                        .blur(radius: state.blur)
                        .opacity(state.opacity)
                        .position(state.center)
                }
            }
        }
        .frame(width: TrailerCanvas.width, height: TrailerCanvas.height)
    }
}

/// A search result: live stage with the effect's name on a soft scrim.
struct TrailerResultTile: View {
    let effect: Effect
    let epoch: Date?
    let side: CGFloat
    var cornerRadius: CGFloat = 16
    var labelOpacity: Double = 1
    var backgroundOpacity: Double = 1

    var body: some View {
        TrailerStageTile(effectID: effect.id, epoch: epoch, side: side, cornerRadius: cornerRadius, backgroundOpacity: backgroundOpacity)
            .overlay(alignment: .bottomLeading) {
                ZStack(alignment: .bottomLeading) {
                    LinearGradient(colors: [Color.black.opacity(0), Color.black.opacity(0.6)], startPoint: .top, endPoint: .bottom)
                        .frame(height: 34)
                    Text(verbatim: effect.name.zh)
                        .font(.system(size: 10.5, weight: .bold))
                        .foregroundStyle(Color.white)
                        .lineLimit(1)
                        .padding(.horizontal, 8)
                        .padding(.bottom, 6)
                }
                .clipShape(UnevenRoundedRectangle(bottomLeadingRadius: cornerRadius, bottomTrailingRadius: cornerRadius, style: .continuous))
                .opacity(labelOpacity)
            }
            .shadow(color: Color.black.opacity(0.45), radius: 12, x: 0, y: 8)
    }
}

// MARK: - Hero (search result → phone stage)

/// The opened result. It is one continuous view from its grid slot to the phone's stage card, so the
/// live demo inside keeps its state across the zoom, and it is the first demo played on the phone.
struct TrailerHeroLayer: View {
    let t: Double
    let origin: Date

    /// cards.flip autoplay: delay 0.6 s, every 2.2 s → the first flip lands on the 22.6 s tap.
    static let epochOffset: Double = 22.0
    static let zoomStart: Double = 20.75

    var body: some View {
        if let effect = EffectLibrary.effect(id: TrailerData.heroID), let state = TrailerTileState.at(t, id: effect.id) {
            let zoom = M.spring(t, at: Self.zoomStart, response: 0.75, damping: 0.84)
            let side = M.mix(TrailerLayout.tileSide, TrailerLayout.demoSide, zoom)
            let center = M.mix(state.center, TrailerLayout.demoCenter, zoom)
            let exit = TrailerPhoneScene.swapOut(t, at: 25.3)
            TrailerResultTile(
                effect: effect,
                epoch: origin.addingTimeInterval(Self.epochOffset),
                side: side,
                cornerRadius: M.mix(16, 24, zoom),
                labelOpacity: 1 - M.clamp(zoom * 2),
                backgroundOpacity: 1
            )
            .scaleEffect(state.scale * CGFloat(1 - 0.12 * exit))
            .rotationEffect(.degrees(state.rotation))
            .blur(radius: state.blur + CGFloat(exit) * 10)
            .opacity(state.opacity * (1 - exit))
            .offset(x: CGFloat(TrailerScript.buzz(t) * 2.4 * M.clamp(zoom)))
            .position(center)
        }
    }
}
