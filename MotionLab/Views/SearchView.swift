import SwiftUI

struct SearchView: View {
    @Environment(\.appLanguage) private var language
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(AppNavigator.self) private var navigator
    @Namespace private var categoryChips

    /// Keywords that match many effects in both languages (the search haystack is bilingual).
    private static let keywordSuggestions: [LocalizedText] = [
        L("spring", "弹簧"), L("blur", "模糊"), L("glow", "辉光"), L("gradient", "渐变"),
        L("morph", "形变"), L("3D", "3D"), L("haptic", "触感"), L("particle", "粒子"),
        L("parallax", "视差"), L("glass", "玻璃"),
    ]

    private static let apiSuggestions = [
        "matchedGeometryEffect", "keyframeAnimator", "phaseAnimator", "TimelineView", "Canvas", "symbolEffect",
    ]

    var body: some View {
        @Bindable var navigator = navigator
        let results = EffectLibrary.search(navigator.query, category: navigator.category, interaction: navigator.interaction)
        let familyResults = EffectFamilies.search(navigator.query, category: navigator.category, interaction: navigator.interaction)
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                filters
                if navigator.query.isEmpty { suggestions }
                if !familyResults.isEmpty {
                    familySection(familyResults)
                        .transition(.opacity.combined(with: .offset(y: -8)))
                }
                HStack {
                    Text(Strings.effectCount(results.count, language))
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(.secondary)
                        .contentTransition(.numericText(value: Double(results.count)))
                    Spacer()
                    if navigator.hasActiveFilters {
                        Button(Strings.clearFilters(language)) {
                            Haptics.tap()
                            withAnimation(ShellMotion.selection) { navigator.clearFilters() }
                        }
                        .font(.footnote.weight(.semibold))
                        .transition(.opacity.combined(with: .scale(scale: 0.9, anchor: .trailing)))
                    }
                }
                .padding(.horizontal)

                if results.isEmpty {
                    emptyState
                        .transition(.opacity.combined(with: .scale(scale: 0.96)))
                } else {
                    EffectGrid(effects: results)
                        .padding(.horizontal)
                }
            }
            .padding(.vertical)
            .animation(.smooth(duration: 0.32), value: results.map(\.id))
            .animation(.smooth(duration: 0.32), value: familyResults.map(\.id))
            .animation(.smooth(duration: 0.25), value: navigator.query.isEmpty)
        }
        .scrollDismissesKeyboard(.immediately)
        .background(Palette.pageBackground)
        .navigationTitle(Strings.search(language))
        .searchable(text: $navigator.query, placement: .navigationBarDrawer(displayMode: .always), prompt: Strings.searchPrompt(language))
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label {
                Text(Strings.noResults, language)
            } icon: {
                Image(systemName: "sparkle.magnifyingglass")
                    .symbolEffect(.breathe, isActive: !reduceMotion)
            }
        } description: {
            Text(Strings.noResultsHint, language)
        } actions: {
            if navigator.hasActiveFilters {
                Button(Strings.clearFilters(language)) {
                    Haptics.tap()
                    withAnimation(ShellMotion.selection) { navigator.clearFilters() }
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(.top, 24)
    }

    /// One row: the interaction menu first, then the category chips, so results start high on the screen.
    private var filters: some View {
        ScrollViewReader { reader in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    InteractionMenuChip(selection: navigator.interaction) { item in
                        navigator.interaction = item
                    }
                    .id(Self.interactionChipID)
                    Capsule()
                        .fill(Palette.stroke)
                        .frame(width: 1, height: 22)
                        .accessibilityHidden(true)
                    Chip(title: Strings.all(language), isSelected: navigator.category == nil, namespace: categoryChips) {
                        navigator.category = nil
                    }
                    .id(Self.allChipID)
                    ForEach(EffectCategory.allCases) { item in
                        Chip(title: item.title(language), symbol: item.symbol, isSelected: navigator.category == item, namespace: categoryChips) {
                            navigator.category = navigator.category == item ? nil : item
                        }
                        .id(item.rawValue)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 4)
            }
            // Filters set from elsewhere (e.g. a tag or interaction chip on a detail page) glide into view.
            .onChange(of: navigator.category) { _, category in
                withAnimation(reduceMotion ? nil : ShellMotion.selection) {
                    reader.scrollTo(category?.rawValue ?? Self.allChipID, anchor: .center)
                }
            }
            .onChange(of: navigator.interaction) { _, interaction in
                guard interaction != nil else { return }
                withAnimation(reduceMotion ? nil : ShellMotion.selection) {
                    reader.scrollTo(Self.interactionChipID, anchor: .leading)
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text(verbatim: "\(Strings.interactionFilter(language)), \(Strings.categoryFilter(language))"))
    }

    private static let interactionChipID = "interaction"
    private static let allChipID = "all"

    /// Families whose name matches the query, as a horizontal row of chips above the effect grid.
    private func familySection(_ families: [EffectFamily]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            FilterRowLabel(text: "\(Strings.familyResults(language)) · \(families.count)")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Array(families.enumerated()), id: \.element.id) { index, family in
                        FamilyResultChip(family: family)
                            .appearEntrance(index: index, delay: 0.02, distance: 8, scale: 0.94, blur: 3)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 4)
            }
        }
    }

    private var suggestions: some View {
        VStack(alignment: .leading, spacing: 10) {
            AllFamiliesEntry()
                .padding(.bottom, 4)
                .appearEntrance(index: 0, distance: 10, scale: 0.96, blur: 3)
            Text(Strings.trySearching, language)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)
                .accessibilityAddTraits(.isHeader)
            FlowLayout(spacing: 8) {
                ForEach(Array(Self.keywordSuggestions.enumerated()), id: \.element) { index, item in
                    SuggestionChip(text: item(language), symbol: "magnifyingglass") { navigator.query = item(language) }
                        .appearEntrance(index: index, delay: 0.05, distance: 10, scale: 0.9, blur: 3)
                }
            }
            Text(Strings.popularAPIs, language)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.top, 4)
                .accessibilityAddTraits(.isHeader)
            FlowLayout(spacing: 8) {
                ForEach(Array(Self.apiSuggestions.enumerated()), id: \.element) { index, api in
                    SuggestionChip(text: api, symbol: "chevron.left.forwardslash.chevron.right", monospaced: true) {
                        navigator.query = api
                    }
                    .appearEntrance(index: index, delay: 0.25, distance: 10, scale: 0.9, blur: 3)
                }
            }
        }
        .padding(.horizontal)
        .transition(.opacity.combined(with: .offset(y: -8)))
    }
}

/// Menu chip for the interaction filter: "Interaction ▾", or the chosen interaction as a filled pill.
private struct InteractionMenuChip: View {
    let selection: EffectInteraction?
    let onSelect: (EffectInteraction?) -> Void
    @Environment(\.appLanguage) private var language

    private var binding: Binding<EffectInteraction?> {
        Binding {
            selection
        } set: { value in
            withAnimation(ShellMotion.selection) { onSelect(value) }
        }
    }

    var body: some View {
        Menu {
            Picker(Strings.interactionFilter(language), selection: binding) {
                Label(Strings.anyInteraction(language), systemImage: "circle.dashed")
                    .tag(EffectInteraction?.none)
                ForEach(EffectInteraction.allCases) { item in
                    Label(item.title(language), systemImage: item.symbol)
                        .tag(Optional(item))
                }
            }
        } label: {
            label
        }
        .sensoryFeedback(.selection, trigger: selection)
        .accessibilityLabel(Text(verbatim: Strings.interactionFilter(language)))
        .accessibilityValue(Text(verbatim: selection?.title(language) ?? Strings.anyInteraction(language)))
    }

    private var label: some View {
        let selected = selection != nil
        return HStack(spacing: 5) {
            Image(systemName: selection?.symbol ?? "line.3.horizontal.decrease")
                .font(.caption.weight(.semibold))
                .contentTransition(.symbolEffect(.replace))
            Text(verbatim: selection?.title(language) ?? Strings.interactionFilter(language))
                .font(.subheadline.weight(.medium))
                .lineLimit(1)
            Image(systemName: "chevron.down")
                .font(.caption2.weight(.bold))
                .opacity(0.7)
        }
        .fixedSize()
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .foregroundStyle(selected ? Color.white : Color.primary)
        .background {
            ZStack {
                Capsule()
                    .fill(Palette.chipOnPage)
                    .overlay(Capsule().strokeBorder(Palette.stroke))
                    .opacity(selected ? 0 : 1)
                Capsule()
                    .fill(Palette.primaryStrong)
                    .shadow(color: Palette.indigo.opacity(0.28), radius: 6, y: 3)
                    .opacity(selected ? 1 : 0)
            }
        }
        .contentShape(Capsule())
        .animation(ShellMotion.selection, value: selected)
    }
}

/// "Browse all families · 85" card at the top of the empty-query suggestions.
private struct AllFamiliesEntry: View {
    @Environment(\.appLanguage) private var language

    var body: some View {
        let count = EffectFamilies.all.count
        NavigationLink(value: Route.families) {
            HStack(spacing: 12) {
                Image(systemName: "square.stack.3d.up.fill")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 38, height: 38)
                    .background(Palette.primaryStrong, in: RoundedRectangle(cornerRadius: 11, style: .continuous))
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 1) {
                    Text(Strings.browseAllFamilies, language)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                    Text(verbatim: Strings.familiesAndEffects(families: count, effects: EffectLibrary.all.count, language))
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                .lineLimit(1)
                Spacer(minLength: 4)
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.tertiary)
                    .accessibilityHidden(true)
            }
            .padding(10)
            .background(Palette.cardBackground, in: RoundedRectangle(cornerRadius: CornerRadius.chip, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: CornerRadius.chip, style: .continuous).strokeBorder(Palette.stroke))
            .contentShape(RoundedRectangle(cornerRadius: CornerRadius.chip, style: .continuous))
        }
        .buttonStyle(PressableCardStyle())
        .accessibilityHint(Text(Strings.showAllFamilies, language))
    }
}

/// Small caption naming a horizontal chip row ("Category", "Interaction").
private struct FilterRowLabel: View {
    let text: String

    var body: some View {
        Text(verbatim: text)
            .font(.footnote.weight(.semibold))
            .foregroundStyle(.secondary)
            .padding(.horizontal)
            .accessibilityAddTraits(.isHeader)
    }
}

/// Tappable keyword that fills the search field.
private struct SuggestionChip: View {
    let text: String
    let symbol: String
    var monospaced = false
    let action: () -> Void

    var body: some View {
        Button {
            Haptics.selection()
            action()
        } label: {
            HStack(spacing: 5) {
                Image(systemName: symbol)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(Palette.accent)
                Text(text)
                    .font(monospaced ? .footnote.monospaced() : .footnote.weight(.medium))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
            }
            .padding(.horizontal, 11)
            .padding(.vertical, 7)
            .background(Palette.chipOnPage, in: Capsule())
            .overlay(Capsule().strokeBorder(Palette.stroke))
            .contentShape(Capsule())
        }
        .buttonStyle(PressableCardStyle())
    }
}
