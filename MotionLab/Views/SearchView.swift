import SwiftUI

struct SearchView: View {
    @Environment(\.appLanguage) private var language
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(AppNavigator.self) private var navigator
    @Namespace private var categoryChips
    @Namespace private var interactionChips

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
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                filters
                if navigator.query.isEmpty { suggestions }
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

    private var filters: some View {
        VStack(alignment: .leading, spacing: 8) {
            FilterRowLabel(text: Strings.categoryFilter(language))
            ScrollViewReader { reader in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
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
                // Filters set from elsewhere (e.g. a tag on a detail page) glide into view.
                .onChange(of: navigator.category) { _, category in
                    withAnimation(reduceMotion ? nil : ShellMotion.selection) {
                        reader.scrollTo(category?.rawValue ?? Self.allChipID, anchor: .center)
                    }
                }
            }
            FilterRowLabel(text: Strings.interactionFilter(language))
                .padding(.top, 4)
            ScrollViewReader { reader in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        Chip(title: Strings.all(language), isSelected: navigator.interaction == nil, namespace: interactionChips) {
                            navigator.interaction = nil
                        }
                        .id(Self.allChipID)
                        ForEach(EffectInteraction.allCases) { item in
                            Chip(title: item.title(language), symbol: item.symbol, isSelected: navigator.interaction == item, namespace: interactionChips) {
                                navigator.interaction = navigator.interaction == item ? nil : item
                            }
                            .id(item.rawValue)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 4)
                }
                .onChange(of: navigator.interaction) { _, interaction in
                    withAnimation(reduceMotion ? nil : ShellMotion.selection) {
                        reader.scrollTo(interaction?.rawValue ?? Self.allChipID, anchor: .center)
                    }
                }
            }
        }
    }

    private static let allChipID = "all"

    private var suggestions: some View {
        VStack(alignment: .leading, spacing: 10) {
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
