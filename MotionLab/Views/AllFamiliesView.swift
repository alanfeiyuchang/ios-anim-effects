import SwiftUI

/// One category's block on the All Families page.
private struct FamilySection: Identifiable {
    let category: EffectCategory
    let families: [EffectFamily]

    var id: String { category.rawValue }
}

/// Every family in the catalog, grouped by category under pinned headers, so "all sliders", "all
/// spinners" or "all toggles" can be browsed across the whole catalog. Each family card plays one
/// variation live at a time (see `FamilyPreviewStrip`). A sticky chip row jumps to a category and
/// follows the scroll (its pill always marks the category on screen), and the always-visible search
/// field filters families by name in either language.
///
/// Reached from the "85 families" counter on Browse, the Search suggestions, or `-ML_route families`.
struct AllFamiliesView: View {
    @Environment(\.appLanguage) private var language
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Namespace private var chipNamespace
    @State private var query = ""
    @State private var jumpTarget: EffectCategory?
    @State private var badgeBounce = 0
    /// Sections whose grid is at least partly on screen (ids = category raw values).
    @State private var visibleSections: Set<String> = []
    /// While a chip-initiated jump scrolls, the passing sections do not move the pill.
    @State private var isJumping = false

    var body: some View {
        let sections = Self.sections(matching: query)
        ScrollViewReader { reader in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 16, pinnedViews: [.sectionHeaders]) {
                    header
                    if sections.isEmpty {
                        emptyState
                            .transition(.opacity.combined(with: .scale(scale: 0.96)))
                    }
                    ForEach(sections) { section in
                        Section {
                            grid(section.families)
                                .onScrollVisibilityChange(threshold: 0.01) { visible in
                                    setVisible(section.id, visible)
                                }
                                .onDisappear { setVisible(section.id, false) }
                        } header: {
                            FamilySectionHeader(category: section.category, families: section.families)
                                .id(section.id)
                        }
                    }
                }
                .animation(reduceMotion ? Animation.easeInOut(duration: 0.2) : ShellMotion.reveal, value: sections.map(\.id))
            }
            .shellPageScroll()
            // The jump chips stay pinned under the search field, above the pinned category headers.
            .safeAreaInset(edge: .top, spacing: 0) {
                jumpRow(sections, reader: reader)
                    .background(.bar)
                    .appearEntrance(index: 2, distance: 10, blur: 0)
            }
        }
        .scrollDismissesKeyboard(.immediately)
        .background(Palette.pageBackground)
        .navigationTitle(Strings.allFamilies(language))
        // Always visible: finding "every slider or spinner" is this page's job.
        .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always), prompt: Strings.searchFamilies(language))
        .task {
            // The badge greets you once the push has settled.
            guard !reduceMotion else { return }
            try? await Task.sleep(for: .seconds(0.35))
            guard !Task.isCancelled else { return }
            badgeBounce += 1
        }
    }

    // MARK: Data

    /// Categories in catalog order with their (matching) families; empty categories are dropped.
    private static func sections(matching query: String) -> [FamilySection] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let matches: Set<String>? = trimmed.isEmpty
            ? nil
            : Set(EffectFamilies.search(trimmed, category: nil, interaction: nil).map(\.id))
        let needle = trimmed.lowercased()
        return EffectCategory.allCases.compactMap { category in
            let all = EffectFamilies.families(in: category)
            // A query naming the category itself ("图表", "charts") keeps the whole block.
            let categoryHit = !needle.isEmpty && category.title.all.lowercased().contains(needle)
            let kept = all.filter { matches == nil || categoryHit || matches?.contains($0.id) == true }
            return kept.isEmpty ? nil : FamilySection(category: category, families: kept)
        }
    }

    // MARK: Pieces

    private var header: some View {
        let familyCount = EffectFamilies.all.count
        let effectCount = EffectLibrary.all.count
        return HStack(alignment: .center, spacing: 14) {
            Image(systemName: "square.stack.3d.up.fill")
                .font(.system(size: 23, weight: .semibold))
                .foregroundStyle(Palette.onAccent)
                .symbolEffect(.bounce, value: badgeBounce)
                .frame(width: 52, height: 52)
                .background(Palette.accentFill, in: RoundedRectangle(cornerRadius: 15, style: .continuous))
                .shadow(color: Palette.accentGlow, radius: 8, y: 4)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                Text(verbatim: Strings.familiesAndEffects(families: familyCount, effects: effectCount, language))
                    .font(.footnote.weight(.semibold).monospacedDigit())
                    .foregroundStyle(.primary)
                Text(Strings.allFamiliesSubtitle, language)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .appearEntrance(index: 1, distance: 8)
        }
        .padding(.horizontal)
        .padding(.top, 8)
        .accessibilityElement(children: .combine)
    }

    private func jumpRow(_ sections: [FamilySection], reader: ScrollViewProxy) -> some View {
        ScrollViewReader { chipReader in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(sections) { section in
                        Chip(
                            title: section.category.title(language),
                            symbol: section.category.symbol,
                            count: section.families.count,
                            isSelected: jumpTarget == section.category,
                            namespace: chipNamespace
                        ) {
                            jump(to: section, reader: reader)
                        }
                        .id(Self.chipID(section.id))
                        .accessibilityHint(Text(Strings.jumpToCategory, language))
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
            // The active chip glides into view as the page scrolls through the categories.
            .onChange(of: jumpTarget) { _, target in
                guard let target else { return }
                withAnimation(reduceMotion ? nil : ShellMotion.selection) {
                    chipReader.scrollTo(Self.chipID(target.rawValue), anchor: .center)
                }
            }
        }
    }

    private static func chipID(_ sectionID: String) -> String { "chip.\(sectionID)" }

    private func jump(to section: FamilySection, reader: ScrollViewProxy) {
        jumpTarget = section.category
        isJumping = true
        withAnimation(reduceMotion ? nil : Animation.smooth(duration: 0.5)) {
            reader.scrollTo(section.id, anchor: .top)
        }
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.7))
            isJumping = false
            syncJumpTarget()
        }
    }

    private func setVisible(_ id: String, _ visible: Bool) {
        if visible {
            guard !visibleSections.contains(id) else { return }
            visibleSections.insert(id)
        } else {
            guard visibleSections.remove(id) != nil else { return }
        }
        syncJumpTarget()
    }

    /// The pill follows the first section on screen (the one under the pinned header).
    private func syncJumpTarget() {
        guard !isJumping else { return }
        let active = EffectCategory.allCases.first { visibleSections.contains($0.rawValue) }
        guard let active, active != jumpTarget else { return }
        withAnimation(ShellMotion.selection) { jumpTarget = active }
    }

    private var columns: [GridItem] {
        dynamicTypeSize.isAccessibilitySize
            ? [GridItem(.flexible(), spacing: 14)]
            : [GridItem(.adaptive(minimum: 300), spacing: 14)]
    }

    private func grid(_ families: [EffectFamily]) -> some View {
        LazyVGrid(columns: columns, spacing: 14) {
            ForEach(families) { family in
                FamilyGridItem(family: family)
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 10)
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label {
                Text(Strings.noFamilyResults, language)
            } icon: {
                Image(systemName: "square.stack.3d.up.slash")
                    .symbolEffect(.breathe, isActive: !reduceMotion)
            }
        } description: {
            Text(Strings.noFamilyResultsHint, language)
        }
        .padding(.top, 24)
    }
}

/// One family card on the All Families page, zooming into its family page.
private struct FamilyGridItem: View {
    let family: EffectFamily
    @Environment(\.appLanguage) private var language

    var body: some View {
        let members = EffectFamilies.effects(in: family)
        ZoomRouteLink(route: Route.family(family.id, source: "allFamilies")) {
            FamilyCard(family: family, effects: members)
        }
        .buttonStyle(PressableCardStyle())
        .accessibilityLabel(Text(verbatim: "\(family.name(language)), \(Strings.variationCount(members.count, language))"))
        .accessibilityHint(Text(family.summary, language))
        .scrollReveal(blur: 0)
    }
}

/// Pinned category header: icon, title, "6 families · 17 effects", and a link to the category page.
private struct FamilySectionHeader: View {
    let category: EffectCategory
    let families: [EffectFamily]
    @Environment(\.appLanguage) private var language
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        let effectCount = families.reduce(0) { $0 + EffectFamilies.effects(in: $1).count }
        RouteLink(route: Route.category(category)) {
            HStack(spacing: 10) {
                CategoryIcon(category: category, size: 30)
                VStack(alignment: .leading, spacing: 1) {
                    Text(category.title, language)
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .lineLimit(dynamicTypeSize.isAccessibilitySize ? 3 : 1)
                    Text(verbatim: Strings.familiesAndEffects(families: families.count, effects: effectCount, language))
                        .font(.caption.weight(.semibold).monospacedDigit())
                        .foregroundStyle(Palette.accent)
                        .lineLimit(1)
                }
                Spacer(minLength: 4)
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.tertiary)
                    .accessibilityHidden(true)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.bar)
            .contentShape(Rectangle())
        }
        .buttonStyle(PressableCardStyle())
        .accessibilityAddTraits(.isHeader)
        .accessibilityHint(Text(Strings.openCategory, language))
    }
}
