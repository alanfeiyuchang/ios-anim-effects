import SwiftUI

struct BrowseView: View {
    @Environment(\.appLanguage) private var language

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                header
                featured
                categories
            }
            .padding(.bottom, 32)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle(Strings.appTitle(language))
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if let random = EffectLibrary.all.randomElement() {
                    NavigationLink(value: Route.effect(random.id)) {
                        Image(systemName: "dice.fill")
                    }
                    .accessibilityLabel(Strings.random(language))
                }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(Strings.appSubtitle, language)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            HStack(spacing: 14) {
                StatPill(value: "\(EffectLibrary.all.count)", label: Strings.effects(language))
                StatPill(value: "\(EffectCategory.allCases.count)", label: Strings.categories(language))
            }
        }
        .padding(.horizontal)
    }

    private var featured: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(text: Strings.featured(language))
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 16) {
                    ForEach(EffectLibrary.featured) { effect in
                        EffectLink(effect: effect) {
                            FeaturedCard(effect: effect)
                        }
                        .scrollTransition(axis: .horizontal) { content, phase in
                            content
                                .scaleEffect(phase.isIdentity ? 1 : 0.92)
                                .opacity(phase.isIdentity ? 1 : 0.7)
                        }
                    }
                }
                .scrollTargetLayout()
                .padding(.horizontal)
            }
            .scrollTargetBehavior(.viewAligned)
        }
    }

    private var categories: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(text: Strings.categories(language))
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 160), spacing: 14)], spacing: 14) {
                ForEach(EffectCategory.allCases) { category in
                    NavigationLink(value: Route.category(category)) {
                        CategoryTile(category: category)
                    }
                    .buttonStyle(PressableCardStyle())
                }
            }
            .padding(.horizontal)
        }
    }
}

private struct StatPill: View {
    let value: String
    let label: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            Text(value)
                .font(.title3.weight(.bold).monospacedDigit())
                .foregroundStyle(Palette.primary)
            Text(label)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: Capsule())
    }
}

struct SectionTitle: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.title3.weight(.bold))
            .padding(.horizontal)
    }
}

private struct FeaturedCard: View {
    let effect: Effect
    @Environment(\.appLanguage) private var language

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            PreviewStage(effect: effect, cornerRadius: 22)
                .frame(width: 240, height: 240)
            VStack(alignment: .leading, spacing: 3) {
                Text(effect.category.title, language)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(LinearGradient(colors: effect.category.gradient, startPoint: .leading, endPoint: .trailing))
                Text(effect.name, language)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
            }
            .padding(.horizontal, 6)
        }
        .padding(10)
        .frame(width: 260)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 28, style: .continuous))
    }
}

private struct CategoryTile: View {
    let category: EffectCategory
    @Environment(\.appLanguage) private var language

    var body: some View {
        let count = EffectLibrary.effects(in: category).count
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: category.symbol)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(width: 42, height: 42)
                    .background(
                        LinearGradient(colors: category.gradient, startPoint: .topLeading, endPoint: .bottomTrailing),
                        in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                    )
                Spacer()
                Text("\(count)")
                    .font(.subheadline.weight(.bold).monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            Text(category.title, language)
                .font(.headline)
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Text(category.subtitle, language)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.leading)
                .lineLimit(2, reservesSpace: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}

struct CategoryView: View {
    let category: EffectCategory
    @Environment(\.appLanguage) private var language
    @State private var interaction: EffectInteraction?

    private var effects: [Effect] {
        EffectLibrary.effects(in: category).filter { interaction == nil || $0.interaction == interaction }
    }

    private var availableInteractions: [EffectInteraction] {
        let used = Set(EffectLibrary.effects(in: category).map(\.interaction))
        return EffectInteraction.allCases.filter { used.contains($0) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(category.subtitle, language)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        Chip(title: Strings.all(language), isSelected: interaction == nil) { interaction = nil }
                        ForEach(availableInteractions) { item in
                            Chip(title: item.title(language), symbol: item.symbol, isSelected: interaction == item) {
                                interaction = interaction == item ? nil : item
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                EffectGrid(effects: effects)
                    .padding(.horizontal)
                    .animation(.smooth, value: interaction)
            }
            .padding(.vertical)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle(category.title(language))
    }
}
