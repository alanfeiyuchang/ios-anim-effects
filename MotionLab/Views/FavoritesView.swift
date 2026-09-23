import SwiftUI

struct FavoritesView: View {
    @Environment(\.appLanguage) private var language
    @Environment(FavoritesStore.self) private var favorites
    @Environment(AppNavigator.self) private var navigator

    var body: some View {
        let saved = favorites.effects
        ScrollView {
            if saved.isEmpty {
                ContentUnavailableView {
                    Label {
                        Text(Strings.noFavorites, language)
                    } icon: {
                        Image(systemName: "heart.fill")
                            .foregroundStyle(LinearGradient(colors: [Palette.pink, Palette.violet], startPoint: .topLeading, endPoint: .bottomTrailing))
                    }
                } description: {
                    Text(Strings.noFavoritesHint, language)
                } actions: {
                    Button {
                        navigator.tab = AppTab.browse
                    } label: {
                        Text(Strings.browseEffects, language)
                            .font(.subheadline.weight(.semibold))
                            .padding(.horizontal, 6)
                    }
                    .buttonStyle(.borderedProminent)
                    .buttonBorderShape(.capsule)
                }
                .padding(.top, 80)
                .transition(.opacity)
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    Text(Strings.effectCount(saved.count, language))
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(.secondary)
                    EffectGrid(effects: saved)
                }
                .padding()
            }
        }
        .animation(.smooth, value: favorites.ids)
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle(Strings.favorites(language))
    }
}
