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
                    FamilyCompareList(effects: effects)
                        .padding(.horizontal)
                        .transition(.opacity)
                } else {
                    EffectGrid(effects: effects, source: "family")
                        .padding(.horizontal)
                        .transition(.opacity)
                }
            }
            .padding(.vertical)
            .animation(reduceMotion ? Animation.easeInOut(duration: 0.2) : ShellMotion.reveal, value: comparing)
        }
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
                NavigationLink(value: Route.category(family.category)) {
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
        Picker(Strings.familyViewMode(language), selection: $mode) {
            ForEach(FamilyViewMode.allCases) { item in
                Text(item.title, language).tag(item)
            }
        }
        .pickerStyle(.segmented)
        .sensoryFeedback(.selection, trigger: mode)
    }
}

/// Every variation stacked as a large live preview, so the motion styles can be compared directly.
/// Previews play even when "Animate previews" is off (this view exists to watch them move),
/// but never with Reduce Motion.
private struct FamilyCompareList: View {
    let effects: [Effect]
    @Environment(\.appLanguage) private var language
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private static let columns = [GridItem(.adaptive(minimum: 300), spacing: 14)]

    var body: some View {
        let total = effects.count
        VStack(alignment: .leading, spacing: 12) {
            Label {
                Text(Strings.compareHint, language)
            } icon: {
                Image(systemName: "rectangle.grid.1x2")
                    .foregroundStyle(Palette.accent)
            }
            .font(.footnote)
            .foregroundStyle(.secondary)
            LazyVGrid(columns: Self.columns, spacing: 14) {
                ForEach(Array(effects.enumerated()), id: \.element.id) { index, effect in
                    EffectLink(effect: effect, source: "compare") {
                        CompareCard(effect: effect, position: index + 1, total: total)
                    }
                    .scrollReveal(delay: ShellMotion.stagger(index, step: 0.04, cap: 4))
                }
            }
        }
        .environment(\.previewMotionEnabled, !reduceMotion)
    }
}

private struct CompareCard: View {
    let effect: Effect
    let position: Int
    let total: Int
    @Environment(\.appLanguage) private var language
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        let isLarge = dynamicTypeSize.isAccessibilitySize
        let shape = RoundedRectangle(cornerRadius: CornerRadius.card, style: .continuous)
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center, spacing: 8) {
                Text(verbatim: "\(position)")
                    .font(.caption.weight(.bold).monospacedDigit())
                    .foregroundStyle(.white)
                    .frame(minWidth: 24, minHeight: 24)
                    .padding(.horizontal, 2)
                    .background(Palette.primaryStrong, in: Capsule())
                    .accessibilityLabel(Text(verbatim: Strings.variationPosition(position, of: total, language)))
                Text(effect.name, language)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .lineLimit(isLarge ? 3 : 1)
                    .minimumScaleFactor(0.85)
                if let requirement = effect.requirement {
                    RequirementBadge(text: requirement)
                }
                Spacer(minLength: 4)
                Image(systemName: effect.interaction.symbol)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
            }
            PreviewStage(effect: effect, cornerRadius: CornerRadius.thumbnail)
            Text(effect.summary, language)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.leading)
                .lineLimit(isLarge ? 4 : 2, reservesSpace: !isLarge)
                .padding(.horizontal, 2)
        }
        .padding(10)
        .background(Color(uiColor: .systemBackground), in: shape)
        .overlay(shape.strokeBorder(Palette.stroke))
        .shadow(color: .black.opacity(0.06), radius: 12, y: 6)
        .contentShape(shape)
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
        .background(Color(uiColor: .systemBackground), in: shape)
        .overlay(shape.strokeBorder(Palette.stroke))
        .shadow(color: .black.opacity(0.06), radius: 12, y: 6)
        .contentShape(shape)
    }
}

/// Up to `slots` equal square previews; empty slots are dashed placeholders so every tile keeps its height.
struct FamilyPreviewStrip: View {
    let effects: [Effect]
    var slots = 3

    var body: some View {
        let shown = Array(effects.prefix(slots))
        let extra = effects.count - shown.count
        let empty = max(slots - shown.count, 0)
        HStack(spacing: 8) {
            ForEach(Array(shown.enumerated()), id: \.element.id) { index, effect in
                PreviewStage(effect: effect, cornerRadius: 14)
                    .overlay(alignment: .bottomTrailing) {
                        if index == shown.count - 1 && extra > 0 {
                            MoreBadge(count: extra)
                        }
                    }
                    .frame(maxWidth: .infinity)
            }
            ForEach(0..<empty, id: \.self) { _ in
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(Palette.stroke, style: StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
                    .aspectRatio(1, contentMode: .fit)
                    .frame(maxWidth: .infinity)
            }
        }
        .accessibilityHidden(true)
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
            .overlay(RoundedRectangle(cornerRadius: CornerRadius.chip, style: .continuous).strokeBorder(Palette.stroke))
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
                Spacer(minLength: 8)
                NavigationLink(value: Route.family(family.id)) {
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
                                .strokeBorder(Palette.primaryStrong, lineWidth: 2.5)
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
