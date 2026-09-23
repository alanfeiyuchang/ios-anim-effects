import SwiftUI

struct FavoritesView: View {
    @Environment(\.appLanguage) private var language
    @Environment(FavoritesStore.self) private var favorites
    @Environment(AppNavigator.self) private var navigator

    var body: some View {
        let saved = favorites.effects
        ScrollView {
            if saved.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    FavoritesEmptyState {
                        navigator.tab = AppTab.browse
                    }
                    // Give the empty tab something to do: a few featured effects to start from.
                    SectionTitle(text: Strings.startWithThese(language))
                        .appearEntrance(index: 3, distance: 10, blur: 0)
                    EffectGrid(effects: Array(EffectLibrary.featured.prefix(4)), source: "suggested")
                        .padding(.horizontal)
                }
                .padding(.bottom, 24)
                .transition(.opacity)
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    Text(Strings.effectCount(saved.count, language))
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(.secondary)
                        .contentTransition(.numericText(value: Double(saved.count)))
                    EffectGrid(effects: saved)
                }
                .padding()
                .transition(.opacity)
            }
        }
        .shellPageScroll()
        .animation(.smooth(duration: 0.4), value: favorites.ids)
        .background(Palette.pageBackground)
        .navigationTitle(Strings.favorites(language))
    }
}

/// "No favorites yet": a softly glowing heart that breathes and floats among drifting sparkles,
/// with a shimmering call to action. Static with Reduce Motion.
private struct FavoritesEmptyState: View {
    let onBrowse: () -> Void
    @Environment(\.appLanguage) private var language
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 14) {
            FloatingHeartArt(animated: !reduceMotion)
                .frame(width: 160, height: 130)
                .accessibilityHidden(true)
                .appearEntrance(index: 0, distance: 12, scale: 0.85)
            VStack(spacing: 6) {
                Text(Strings.noFavorites, language)
                    .font(.title2.weight(.bold))
                    .multilineTextAlignment(.center)
                Text(Strings.noFavoritesHint, language)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .accessibilityElement(children: .combine)
            .appearEntrance(index: 1, distance: 10)
            ShimmerCapsuleButton(title: Strings.browseEffects(language), systemImage: "arrow.right", action: onBrowse)
                .padding(.top, 4)
                .appearEntrance(index: 2, distance: 10, blur: 0)
        }
        .padding(.horizontal, 32)
        .padding(.top, 32)
        .padding(.bottom, 12)
        .frame(maxWidth: .infinity)
    }
}

/// SF Symbol illustration: a gradient heart with a halo, orbited by small floating accents.
private struct FloatingHeartArt: View {
    let animated: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Palette.pink.opacity(0.24), Palette.ember.opacity(0.1), .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 72
                    )
                )
                .frame(width: 150, height: 150)
                .modifier(FloatingModifier(active: animated, amplitude: 2, duration: 3.2))
            accent("sparkle", size: 18, color: Palette.amber, x: -54, y: -30, duration: 2.1)
            accent("heart.fill", size: 13, color: Palette.ember, x: 56, y: -36, duration: 2.7)
            accent("sparkle", size: 11, color: Palette.sky, x: 50, y: 34, duration: 2.4)
            accent("circle.fill", size: 6, color: Palette.pink, x: -46, y: 36, duration: 1.9)
            Image(systemName: "heart.fill")
                .font(.system(size: 62, weight: .semibold))
                .foregroundStyle(
                    LinearGradient(colors: [Palette.pink, Palette.emberHot], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .symbolEffect(.breathe, isActive: animated)
                .shadow(color: Palette.pink.opacity(0.35), radius: 16, y: 8)
                .modifier(FloatingModifier(active: animated, amplitude: 5, duration: 2.4))
        }
    }

    private func accent(_ symbol: String, size: CGFloat, color: Color, x: CGFloat, y: CGFloat, duration: Double) -> some View {
        Image(systemName: symbol)
            .font(.system(size: size, weight: .bold))
            .foregroundStyle(color)
            .modifier(FloatingModifier(active: animated, amplitude: 4, duration: duration))
            .offset(x: x, y: y)
    }
}
