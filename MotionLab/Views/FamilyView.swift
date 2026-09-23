import SwiftUI
import UIKit

// MARK: - Modes

/// How a category page lists its effects. Remembered across launches (`app.categoryMode`).
enum CategoryBrowseMode: String, CaseIterable, Identifiable {
    case families
    case all

    var id: String { rawValue }

    var title: LocalizedText {
        switch self {
        case .families: return Strings.byFamily
        case .all: return Strings.allEffects
        }
    }
}

/// How a family page lists its variations. Remembered across launches (`app.familyMode`).
enum FamilyViewMode: String, CaseIterable, Identifiable {
    case grid
    case compare

    var id: String { rawValue }

    var title: LocalizedText {
        switch self {
        case .grid: return Strings.gridMode
        case .compare: return Strings.compareMode
        }
    }
}

// MARK: - Family view

/// A family's variations: header, then a grid of cards or a "Compare" list of large live previews.
struct FamilyView: View {
    let family: EffectFamily
    @Environment(\.appLanguage) private var language
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage("app.familyMode") private var mode: FamilyViewMode = .grid
    @State private var badgeBounce = 0
    /// Each variation's stage flies between its grid card and its compare card.
    @Namespace private var stages

    var body: some View {
        let effects = EffectFamilies.effects(in: family)
        let comparing = mode == .compare && effects.count > 1
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header(count: effects.count)
                if effects.count > 1 {
                    modePicker
                        .padding(.horizontal)
                        .appearEntrance(index: 2, distance: 10, blur: 0)
                }
                if comparing {
                    FamilyCompareList(effects: effects, stageNamespace: reduceMotion ? nil : stages)
                        .padding(.horizontal)
                        .transition(.opacity)
                } else {
                    EffectGrid(effects: effects, source: "family", stageNamespace: reduceMotion ? nil : stages)
                        .padding(.horizontal)
                        .transition(.opacity)
                }
            }
            .padding(.vertical)
            .animation(reduceMotion ? Animation.easeInOut(duration: 0.2) : ShellMotion.reveal, value: comparing)
        }
        .shellPageScroll()
        .background(Palette.pageBackground)
        .navigationTitle(family.name(language))
        .task {
            // The badge greets you once the push has settled.
            guard !reduceMotion else { return }
            try? await Task.sleep(for: .seconds(0.35))
            guard !Task.isCancelled else { return }
            badgeBounce += 1
        }
    }

    private func header(count: Int) -> some View {
        HStack(alignment: .center, spacing: 14) {
            FamilyBadge(family: family, size: 52, bounce: badgeBounce)
            VStack(alignment: .leading, spacing: 4) {
                RouteLink(route: Route.category(family.category)) {
                    HStack(spacing: 4) {
                        Text(family.category.title, language)
                        Image(systemName: "chevron.right")
                            .font(.caption2.weight(.bold))
                            .accessibilityHidden(true)
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Palette.accent)
                    .lineLimit(1)
                    .contentShape(Rectangle())
                }
                .buttonStyle(PressableCardStyle())
                .accessibilityHint(Text(Strings.openCategory, language))
                Text(verbatim: Strings.variationCount(count, language))
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.primary)
                Text(family.summary, language)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .appearEntrance(index: 1, distance: 8)
        }
        .padding(.horizontal)
    }

    private var modePicker: some View {
        ShellSegmentedControl(
            label: Strings.familyViewMode(language),
            segments: FamilyViewMode.allCases.map { item in
                ShellSegmentedControl<FamilyViewMode>.Segment(value: item, title: item.title(language))
            },
            selection: $mode
        )
    }
}

/// Every variation as a live preview, side by side (two columns on iPhone), on one shared clock:
/// autoplay loops fire on a common grid (`demoSyncEpoch`), so variations with the same rhythm play
/// in lockstep, and "Replay All" restarts every demo in the same frame.
/// Previews play even when "Animate previews" is off (this view exists to watch them move),
/// but never with Reduce Motion.
private struct FamilyCompareList: View {
    let effects: [Effect]
    /// Shared with the grid so each stage flies between layouts (nil with Reduce Motion).
    let stageNamespace: Namespace.ID?
    @Environment(\.appLanguage) private var language
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.horizontalSizeClass) private var sizeClass
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    /// Shared start of every autoplay loop; reset by Replay All.
    @State private var epoch = Date()
    @State private var replays = 0

    /// Two columns on iPhone (compact width), adaptive on iPad, one column at accessibility sizes.
    private var columns: [GridItem] {
        if dynamicTypeSize.isAccessibilitySize { return [GridItem(.flexible(), spacing: 12)] }
        if sizeClass == .regular { return [GridItem(.adaptive(minimum: 250), spacing: 14)] }
        return [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]
    }

    var body: some View {
        let total = effects.count
        let compact = sizeClass != .regular && !dynamicTypeSize.isAccessibilitySize
        let replays = self.replays
        let pulses = !reduceMotion
        let stageNamespace = self.stageNamespace
        VStack(alignment: .leading, spacing: 12) {
            header
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(Array(effects.enumerated()), id: \.element.id) { index, effect in
                    EffectLink(effect: effect, source: "compare") {
                        CompareCard(effect: effect, position: index + 1, total: total, compact: compact, replays: replays,
                                    stageNamespace: stageNamespace)
                    }
                    .modifier(ReplayPulse(trigger: replays, delay: ShellMotion.stagger(index, step: 0.04, cap: 8), enabled: pulses))
                    .scrollReveal(delay: ShellMotion.stagger(index, step: 0.04, cap: 4), blur: 0)
                }
            }
        }
        .environment(\.previewMotionEnabled, !reduceMotion)
        .environment(\.demoSyncEpoch, epoch)
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 10) {
            Label {
                Text(Strings.compareHint, language)
            } icon: {
                Image(systemName: "square.grid.2x2")
                    .foregroundStyle(Palette.accent)
            }
            .font(.footnote)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 4)
            ReplayAllButton(replays: replays, action: replayAll)
        }
    }

    private func replayAll() {
        Haptics.tap(.light)
        // One new epoch + one new identity for every stage: all demos restart in the same frame.
        epoch = Date()
        replays += 1
        UIAccessibility.post(notification: .announcement, argument: Strings.replayAll(language))
    }
}

/// Capsule "Replay All" button; the arrow makes one full turn per replay.
private struct ReplayAllButton: View {
    let replays: Int
    let action: () -> Void
    @Environment(\.appLanguage) private var language
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button(action: action) {
            Label {
                Text(Strings.replayAll, language)
            } icon: {
                Image(systemName: "arrow.counterclockwise")
                    .rotationEffect(.degrees(reduceMotion ? 0 : Double(replays) * -360))
                    .animation(.spring(response: 0.6, dampingFraction: 0.72), value: replays)
            }
            .font(.footnote.weight(.semibold))
            .lineLimit(1)
            .foregroundStyle(Palette.onAccent)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(Palette.accentFill, in: Capsule())
            .shadow(color: Palette.accentGlow, radius: 6, y: 3)
            .contentShape(Capsule())
        }
        .buttonStyle(PressableCardStyle())
        .fixedSize()
        .accessibilityHint(Text(Strings.replayAllHint, language))
    }
}

/// A quick dip-and-spring of each compare card on Replay All, cascading 40 ms per card.
private struct ReplayPulse: ViewModifier {
    let trigger: Int
    let delay: Double
    let enabled: Bool

    @ViewBuilder
    func body(content: Content) -> some View {
        if enabled {
            let delay = self.delay
            content.phaseAnimator([false, true], trigger: trigger) { view, dipped in
                view.scaleEffect(dipped ? 0.95 : 1)
            } animation: { dipped in
                dipped ? Animation.easeOut(duration: 0.14).delay(delay) : ShellMotion.pressUp
            }
        } else {
            content
        }
    }
}

private struct CompareCard: View {
    let effect: Effect
    let position: Int
    let total: Int
    /// Two-column iPhone layout: number + name only.
    let compact: Bool
    /// Replay All count; a new value rebuilds the stage so the demo restarts.
    let replays: Int
    let stageNamespace: Namespace.ID?
    @Environment(\.appLanguage) private var language
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: compact ? CornerRadius.section : CornerRadius.card, style: .continuous)
        VStack(alignment: .leading, spacing: compact ? 8 : 10) {
            title
            PreviewStage(effect: effect, cornerRadius: compact ? 14 : CornerRadius.thumbnail)
                .id(replays)
                .modifier(StageGeometryLink(effectID: effect.id, namespace: stageNamespace))
            if !compact {
                Text(effect.summary, language)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(dynamicTypeSize.isAccessibilitySize ? 4 : 2, reservesSpace: !dynamicTypeSize.isAccessibilitySize)
                    .padding(.horizontal, 2)
            }
        }
        .padding(compact ? 8 : 10)
        .glossCard(cornerRadius: compact ? CornerRadius.section : CornerRadius.card, tint: effect.category.gradient.first)
        .contentShape(shape)
    }

    private var title: some View {
        let isLarge = dynamicTypeSize.isAccessibilitySize
        return HStack(alignment: .center, spacing: compact ? 6 : 8) {
            Text(verbatim: "\(position)")
                .font(.caption2.weight(.bold).monospacedDigit())
                .foregroundStyle(Palette.onAccent)
                .frame(minWidth: compact ? 20 : 24, minHeight: compact ? 20 : 24)
                .padding(.horizontal, 2)
                .background(Palette.accentFill, in: Capsule())
                .accessibilityLabel(Text(verbatim: Strings.variationPosition(position, of: total, language)))
            Text(effect.name, language)
                .font(compact ? Font.caption.weight(.semibold) : Font.headline)
                .foregroundStyle(.primary)
                .lineLimit(isLarge ? 3 : (compact ? 2 : 1), reservesSpace: compact && !isLarge)
                .minimumScaleFactor(0.85)
                .multilineTextAlignment(.leading)
            if !compact, let requirement = effect.requirement {
                RequirementBadge(text: requirement)
            }
            Spacer(minLength: 0)
            if !compact {
                Image(systemName: effect.interaction.symbol)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
            }
        }
    }
}

// MARK: - Family pieces

/// Gradient rounded-square badge with the family's SF Symbol (category colors).
/// Bounces when `bounce` changes, and on touch-down inside a `PressableCardStyle` button.
struct FamilyBadge: View {
    let family: EffectFamily
    var size: CGFloat = 40
    var bounce: Int = 0
    @Environment(\.isCardPressed) private var isPressed
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pressBounces = 0

    var body: some View {
        let colors = family.category.gradient
        Image(systemName: family.symbol)
            .font(.system(size: size * 0.44, weight: .semibold))
            .foregroundStyle(.white)
            .symbolEffect(.bounce, value: bounce + pressBounces)
            .frame(width: size, height: size)
            .background(
                LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing),
                in: RoundedRectangle(cornerRadius: size * 0.29, style: .continuous)
            )
            .shadow(color: (colors.last ?? .clear).opacity(0.28), radius: size * 0.14, y: size * 0.07)
            .accessibilityHidden(true)
            .onChange(of: isPressed) { _, pressed in
                if pressed && !reduceMotion { pressBounces += 1 }
            }
    }
}

/// Category-page tile for one family: badge, name, variation count, summary and a 3-up strip of
/// live previews (the first three variations; "+N" on the last when there are more).
struct FamilyCard: View {
    let family: EffectFamily
    let effects: [Effect]
    @Environment(\.appLanguage) private var language
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        let isLarge = dynamicTypeSize.isAccessibilitySize
        let shape = RoundedRectangle(cornerRadius: CornerRadius.card, style: .continuous)
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 12) {
                FamilyBadge(family: family)
                VStack(alignment: .leading, spacing: 2) {
                    Text(family.name, language)
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .lineLimit(isLarge ? 3 : 1)
                        .minimumScaleFactor(0.85)
                    Text(verbatim: Strings.variationCount(effects.count, language))
                        .font(.caption.weight(.semibold).monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 4)
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.tertiary)
                    .accessibilityHidden(true)
            }
            Text(family.summary, language)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.leading)
                .lineLimit(isLarge ? 6 : 2, reservesSpace: !isLarge)
            FamilyPreviewStrip(effects: effects)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glossCard(cornerRadius: CornerRadius.card, tint: family.category.gradient.first)
        .contentShape(shape)
    }
}

/// Up to `slots` equal square previews; empty slots are dashed placeholders so every tile keeps its height.
///
/// Only one slot plays live at a time: a "spotlight" (with a softly glowing ring that glides between
/// slots) moves to the next variation every few seconds, while the others show still frames. A category
/// page therefore runs one live demo per visible family card instead of three, and none at all while
/// the strip is scrolled away.
///
/// No tile ever flashes blank on a hand-off: every slot keeps its still frame as a permanent base
/// layer; the lit slot mounts its live demo above it, invisible, and fades it in only once the demo
/// has had time to draw and start moving; the slot the spotlight leaves fades its live layer out over
/// that same still instead of swapping views.
struct FamilyPreviewStrip: View {
    let effects: [Effect]
    var slots = 3
    @Environment(\.previewMotionEnabled) private var motionEnabled
    @State private var spotlight = 0
    @State private var isVisible = false
    @Namespace private var ring

    private static let dwell: Double = 3.2

    var body: some View {
        let shown = Array(effects.prefix(slots))
        let extra = effects.count - shown.count
        let empty = max(slots - shown.count, 0)
        let live = motionEnabled
        let lit = shown.isEmpty ? 0 : spotlight % shown.count
        HStack(spacing: 8) {
            ForEach(Array(shown.enumerated()), id: \.element.id) { index, effect in
                StripSlot(effect: effect, isLit: live && index == lit)
                    .overlay {
                        if live && index == lit && shown.count > 1 {
                            SpotlightRing(namespace: ring)
                        }
                    }
                    .overlay(alignment: .bottomTrailing) {
                        if index == shown.count - 1 && extra > 0 {
                            MoreBadge(count: extra)
                        }
                    }
                    .frame(maxWidth: .infinity)
            }
            ForEach(0..<empty, id: \.self) { _ in
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(Palette.edge, style: StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
                    .aspectRatio(1, contentMode: .fit)
                    .frame(maxWidth: .infinity)
            }
        }
        .accessibilityHidden(true)
        .onScrollVisibilityChange(threshold: 0.2) { visible in
            if isVisible != visible { isVisible = visible }
        }
        .task(id: live && isVisible && shown.count > 1) {
            guard live && isVisible && shown.count > 1 else { return }
            let count = shown.count
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(Self.dwell))
                guard !Task.isCancelled else { return }
                withAnimation(.smooth(duration: 0.55)) { spotlight = (spotlight + 1) % count }
            }
        }
    }
}

/// One tile of a preview strip: the still frame, always, with the live demo layered over it while lit.
/// Demos that cannot be rasterised have no still; their single (live) stage just toggles autoplay.
private struct StripSlot: View {
    let effect: Effect
    let isLit: Bool

    var body: some View {
        let layered = PreviewSnapshotCache.canSnapshot(effect)
        ZStack {
            PreviewStage(effect: effect, cornerRadius: 14)
                .environment(\.previewMotionEnabled, layered ? false : isLit)
            if layered && isLit {
                PreviewStage(effect: effect, cornerRadius: 14)
                    .modifier(LiveLayerFadeIn())
                    .environment(\.previewMotionEnabled, true)
                    .transition(.asymmetric(
                        insertion: .identity,
                        removal: .opacity.animation(.easeInOut(duration: 0.4))
                    ))
            }
        }
    }
}

/// Keeps a freshly mounted live demo invisible (the still below shows) until it has drawn its first
/// frames and its autoplay has begun, then fades it in, so a tile never shows a demo's empty
/// initial state.
private struct LiveLayerFadeIn: ViewModifier {
    @State private var shown = false

    func body(content: Content) -> some View {
        content
            .opacity(shown ? 1 : 0)
            .task {
                try? await Task.sleep(for: .seconds(0.7))
                guard !Task.isCancelled else { return }
                withAnimation(.easeInOut(duration: 0.4)) { shown = true }
            }
    }
}

/// Thin ember ring with a soft glow on the live slot of a preview strip; glides to the next slot.
private struct SpotlightRing: View {
    let namespace: Namespace.ID

    var body: some View {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .strokeBorder(Palette.accentFill, lineWidth: 1.5)
            .shadow(color: Palette.accentGlow, radius: 5)
            .matchedGeometryEffect(id: "spotlight", in: namespace)
            .allowsHitTesting(false)
    }
}

/// "+4" pill on the last preview of a strip.
private struct MoreBadge: View {
    let count: Int

    var body: some View {
        Text(verbatim: "+\(count)")
            .font(.caption2.weight(.bold).monospacedDigit())
            .foregroundStyle(.white)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(Color.black.opacity(0.55), in: Capsule())
            .padding(6)
    }
}

/// Compact search result for a family: badge, name, "<category> · N variations".
struct FamilyResultChip: View {
    let family: EffectFamily
    @Environment(\.appLanguage) private var language

    var body: some View {
        let count = EffectFamilies.effects(in: family).count
        NavigationLink(value: Route.family(family.id)) {
            HStack(spacing: 10) {
                FamilyBadge(family: family, size: 32)
                VStack(alignment: .leading, spacing: 1) {
                    Text(family.name, language)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                    Text(verbatim: "\(family.category.title(language)) · \(Strings.variationCount(count, language))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .lineLimit(1)
                Image(systemName: "chevron.right")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.tertiary)
                    .accessibilityHidden(true)
            }
            .padding(.leading, 6)
            .padding(.trailing, 12)
            .padding(.vertical, 6)
            .background(Palette.chipOnPage, in: RoundedRectangle(cornerRadius: CornerRadius.chip, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: CornerRadius.chip, style: .continuous).strokeBorder(Palette.edge))
            .contentShape(RoundedRectangle(cornerRadius: CornerRadius.chip, style: .continuous))
        }
        .buttonStyle(PressableCardStyle())
        .accessibilityLabel(Text(verbatim: "\(family.name(language)), \(Strings.variationCount(count, language))"))
        .accessibilityHint(Text(Strings.openFamily, language))
    }
}

// MARK: - Variation strip (detail page)

/// "Variations" row on the detail page: every sibling in the family as a tiny still preview with its
/// name. The current one wears a ring that glides to the next selection; tapping swaps the page.
struct VariationStrip: View {
    let family: EffectFamily
    let variations: [Effect]
    let currentID: String
    let onSelect: (Effect) -> Void
    /// Steps to the previous (-1) or next (+1) variation; shows chevron buttons when set.
    var onStep: ((Int) -> Void)? = nil
    @Environment(\.appLanguage) private var language
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Namespace private var ring

    var body: some View {
        let position = (variations.firstIndex(where: { $0.id == currentID }) ?? 0) + 1
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(Strings.variations, language)
                    .font(.subheadline.weight(.semibold))
                    .accessibilityAddTraits(.isHeader)
                Text(verbatim: "\(position)/\(variations.count)")
                    .font(.caption.weight(.semibold).monospacedDigit())
                    .foregroundStyle(.secondary)
                    .contentTransition(.numericText(value: Double(position)))
                    .accessibilityLabel(Text(verbatim: Strings.variationPosition(position, of: variations.count, language)))
                if let onStep {
                    StepChevron(symbol: "chevron.left", label: Strings.previousVariation) { onStep(-1) }
                    StepChevron(symbol: "chevron.right", label: Strings.nextVariation) { onStep(1) }
                }
                Spacer(minLength: 8)
                RouteLink(route: Route.family(family.id)) {
                    HStack(spacing: 3) {
                        Text(family.name, language)
                        Image(systemName: "chevron.right")
                            .font(.caption2.weight(.bold))
                            .accessibilityHidden(true)
                    }
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Palette.accent)
                    .lineLimit(1)
                    .contentShape(Rectangle())
                }
                .buttonStyle(PressableCardStyle())
                .accessibilityHint(Text(Strings.openFamily, language))
            }
            ScrollViewReader { reader in
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(alignment: .top, spacing: 10) {
                        ForEach(variations) { item in
                            VariationThumb(effect: item, isCurrent: item.id == currentID, ring: ring) {
                                onSelect(item)
                            }
                            .id(item.id)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 2)
                }
                // Bleeds to the screen edges like the Browse carousels.
                .padding(.horizontal, -16)
                .onAppear {
                    reader.scrollTo(currentID, anchor: .center)
                }
                .onChange(of: currentID) { _, id in
                    withAnimation(reduceMotion ? nil : ShellMotion.selection) {
                        reader.scrollTo(id, anchor: .center)
                    }
                }
            }
        }
        // Tiny thumbnails stay still (the stage below is the live demo), which also keeps this row cheap.
        .environment(\.previewMotionEnabled, false)
    }
}

/// Small round chevron next to the "2/5" counter; bounces in its direction on each tap.
private struct StepChevron: View {
    let symbol: String
    let label: LocalizedText
    let action: () -> Void
    @Environment(\.appLanguage) private var language
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var taps = 0

    var body: some View {
        Button {
            if !reduceMotion { taps += 1 }
            action()
        } label: {
            Image(systemName: symbol)
                .font(.caption2.weight(.bold))
                .foregroundStyle(Palette.accent)
                .symbolEffect(.bounce, value: taps)
                .frame(width: 24, height: 24)
                .background(Palette.chipOnPage, in: Circle())
                .overlay(Circle().strokeBorder(Palette.edge))
                .padding(4)
                .contentShape(Circle())
        }
        .buttonStyle(PressableCardStyle())
        .accessibilityLabel(Text(label, language))
    }
}

private struct VariationThumb: View {
    let effect: Effect
    let isCurrent: Bool
    let ring: Namespace.ID
    let action: () -> Void
    @Environment(\.appLanguage) private var language
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        let isLarge = dynamicTypeSize.isAccessibilitySize
        Button(action: action) {
            VStack(alignment: .leading, spacing: 6) {
                PreviewStage(effect: effect, cornerRadius: 14)
                    .frame(width: 76, height: 76)
                    .padding(3)
                    .background {
                        if isCurrent {
                            RoundedRectangle(cornerRadius: 17, style: .continuous)
                                .strokeBorder(Palette.accentFill, lineWidth: 2.5)
                                .shadow(color: Palette.accentGlow, radius: 5)
                                .matchedGeometryEffect(id: "variation.ring", in: ring)
                        }
                    }
                Text(effect.name, language)
                    .font(isCurrent ? Font.caption2.weight(.semibold) : Font.caption2)
                    .foregroundStyle(isCurrent ? Color.primary : Color.secondary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(isLarge ? 3 : 2, reservesSpace: true)
                    .frame(width: 82, alignment: .leading)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(PressableCardStyle())
        .accessibilityLabel(Text(effect.name, language))
        .accessibilityHint(Text(Strings.showVariation, language))
        .accessibilityAddTraits(isCurrent ? .isSelected : [])
    }
}

// MARK: - Variation swap transition

/// Stage swap on the detail page when switching variations: the new demo slides in from the side
/// it comes from; the old one sinks and blurs away in place. A plain fade with Reduce Motion.
struct VariationSwapTransition: Transition {
    /// +1 when moving to a later variation, -1 to an earlier one.
    var direction: CGFloat
    var reduceMotion: Bool

    func body(content: Content, phase: TransitionPhase) -> some View {
        let hidden = !phase.isIdentity
        let moves = hidden && !reduceMotion
        var entering = false
        if case .willAppear = phase { entering = true }
        let shift: CGFloat = moves && entering ? 56 * direction : 0
        return content
            .opacity(hidden ? 0 : 1)
            .offset(x: shift)
            .scaleEffect(moves ? (entering ? 0.97 : 0.92) : 1)
            .blur(radius: moves ? 6 : 0)
    }
}
