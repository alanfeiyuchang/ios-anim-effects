import SwiftUI

struct SearchView: View {
    @Environment(\.appLanguage) private var language
    @State private var query = ""
    @State private var category: EffectCategory?
    @State private var interaction: EffectInteraction?

    private var results: [Effect] {
        EffectLibrary.search(query, category: category, interaction: interaction)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        Chip(title: Strings.all(language), isSelected: category == nil) { category = nil }
                        ForEach(EffectCategory.allCases) { item in
                            Chip(title: item.title(language), symbol: item.symbol, isSelected: category == item) {
                                category = category == item ? nil : item
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(EffectInteraction.allCases) { item in
                            Chip(title: item.title(language), symbol: item.symbol, isSelected: interaction == item) {
                                interaction = interaction == item ? nil : item
                            }
                        }
                    }
                    .padding(.horizontal)
                }

                Text("\(results.count) \(Strings.effects(language))")
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)

                if results.isEmpty {
                    ContentUnavailableView(Strings.noResults(language), systemImage: "sparkle.magnifyingglass")
                        .padding(.top, 40)
                } else {
                    EffectGrid(effects: results)
                        .padding(.horizontal)
                }
            }
            .padding(.vertical)
            .animation(.smooth(duration: 0.3), value: results.map(\.id))
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle(Strings.search(language))
        .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always), prompt: Strings.searchPrompt(language))
    }
}

struct FavoritesView: View {
    @Environment(\.appLanguage) private var language
    @Environment(FavoritesStore.self) private var favorites

    var body: some View {
        ScrollView {
            if favorites.effects.isEmpty {
                ContentUnavailableView(
                    Strings.noFavorites(language),
                    systemImage: "heart",
                    description: Text(Strings.noFavoritesHint, language)
                )
                .padding(.top, 80)
            } else {
                EffectGrid(effects: favorites.effects)
                    .padding()
            }
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle(Strings.favorites(language))
    }
}

struct SettingsView: View {
    @Environment(\.appLanguage) private var language
    @AppStorage("app.language") private var storedLanguage: AppLanguage = .zh
    @AppStorage("app.appearance") private var appearance: Int = 0

    var body: some View {
        Form {
            Section(Strings.language(language)) {
                Picker(Strings.language(language), selection: $storedLanguage) {
                    ForEach(AppLanguage.allCases) { item in
                        Text(item.displayName).tag(item)
                    }
                }
                .pickerStyle(.segmented)
            }
            Section(Strings.appearance(language)) {
                Picker(Strings.appearance(language), selection: $appearance) {
                    Text(Strings.system, language).tag(0)
                    Text(Strings.light, language).tag(1)
                    Text(Strings.dark, language).tag(2)
                }
                .pickerStyle(.segmented)
            }
            Section(Strings.categories(language)) {
                ForEach(EffectCategory.allCases) { category in
                    HStack {
                        Image(systemName: category.symbol)
                            .foregroundStyle(LinearGradient(colors: category.gradient, startPoint: .top, endPoint: .bottom))
                            .frame(width: 26)
                        Text(category.title, language)
                        Spacer()
                        Text("\(EffectLibrary.effects(in: category).count)")
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                }
            }
            Section(Strings.about(language)) {
                Text(Strings.aboutBody, language)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                LabeledContent(Strings.allEffects(language), value: "\(EffectLibrary.all.count)")
            }
        }
        .navigationTitle(Strings.settings(language))
    }
}
