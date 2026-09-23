import SwiftUI

struct SearchView: View {
    @Environment(\.appLanguage) private var language
    @Environment(AppNavigator.self) private var navigator

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
                            navigator.clearFilters()
                        }
                        .font(.footnote.weight(.semibold))
                    }
                }
                .padding(.horizontal)

                if results.isEmpty {
                    ContentUnavailableView {
                        Label(Strings.noResults(language), systemImage: "sparkle.magnifyingglass")
                    } description: {
                        Text(Strings.noResultsHint, language)
                    } actions: {
                        if navigator.hasActiveFilters {
                            Button(Strings.clearFilters(language)) { navigator.clearFilters() }
                                .buttonStyle(.bordered)
                        }
                    }
                    .padding(.top, 24)
                } else {
                    EffectGrid(effects: results)
                        .padding(.horizontal)
                }
            }
            .padding(.vertical)
            .animation(.smooth(duration: 0.3), value: results.map(\.id))
        }
        .scrollDismissesKeyboard(.immediately)
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle(Strings.search(language))
        .searchable(text: $navigator.query, placement: .navigationBarDrawer(displayMode: .always), prompt: Strings.searchPrompt(language))
    }

    private var filters: some View {
        VStack(alignment: .leading, spacing: 10) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    Chip(title: Strings.all(language), isSelected: navigator.category == nil) { navigator.category = nil }
                    ForEach(EffectCategory.allCases) { item in
                        Chip(title: item.title(language), symbol: item.symbol, isSelected: navigator.category == item) {
                            navigator.category = navigator.category == item ? nil : item
                        }
                    }
                }
                .padding(.horizontal)
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    Chip(title: Strings.all(language), isSelected: navigator.interaction == nil) { navigator.interaction = nil }
                    ForEach(EffectInteraction.allCases) { item in
                        Chip(title: item.title(language), symbol: item.symbol, isSelected: navigator.interaction == item) {
                            navigator.interaction = navigator.interaction == item ? nil : item
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    private var suggestions: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(Strings.trySearching, language)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)
                .accessibilityAddTraits(.isHeader)
            FlowLayout(spacing: 8) {
                ForEach(Self.keywordSuggestions, id: \.self) { item in
                    SuggestionChip(text: item(language), symbol: "magnifyingglass") { navigator.query = item(language) }
                }
            }
            Text(Strings.popularAPIs, language)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.top, 4)
                .accessibilityAddTraits(.isHeader)
            FlowLayout(spacing: 8) {
                ForEach(Self.apiSuggestions, id: \.self) { api in
                    SuggestionChip(text: api, symbol: "chevron.left.forwardslash.chevron.right", monospaced: true) {
                        navigator.query = api
                    }
                }
            }
        }
        .padding(.horizontal)
        .transition(.opacity)
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
                    .foregroundStyle(Palette.indigo)
                Text(text)
                    .font(monospaced ? .footnote.monospaced() : .footnote.weight(.medium))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
            }
            .padding(.horizontal, 11)
            .padding(.vertical, 7)
            .background(Color(uiColor: .secondarySystemGroupedBackground), in: Capsule())
            .overlay(Capsule().strokeBorder(Palette.stroke))
            .contentShape(Capsule())
        }
        .buttonStyle(PressableCardStyle())
    }
}
