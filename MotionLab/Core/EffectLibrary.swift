import SwiftUI

/// The full catalog. Each category module exposes `enum XxxEffects { static let all: [Effect] }`.
enum EffectLibrary {
    static let all: [Effect] = {
        let groups: [[Effect]] = [
            ShowcaseEffects.all,
            ButtonEffects.all,
            InputEffects.all,
            LoadingEffects.all,
            FeedbackEffects.all,
            MorphEffects.all,
            NavigationEffects.all,
            CardEffects.all,
            ScrollEffects.all,
            TextEffects.all,
            IconEffects.all,
            GestureEffects.all,
            ChartEffects.all,
            BackgroundEffects.all,
            ShaderEffects.all,
        ]
        return groups.flatMap { $0 }
    }()

    static let byID: [String: Effect] = {
        var dict: [String: Effect] = [:]
        for effect in all {
            assert(dict[effect.id] == nil, "Duplicate effect id \(effect.id)")
            dict[effect.id] = effect
        }
        return dict
    }()

    static func effect(id: String) -> Effect? { byID[id] }

    static func effects(in category: EffectCategory) -> [Effect] {
        all.filter { $0.category == category }
    }

    /// A small hand-picked set for the Browse header; falls back gracefully if ids change.
    static var featured: [Effect] {
        let ids = [
            "showcase.slide-to-start", "showcase.fog-wipe", "showcase.speed-line",
            "morph.button-to-card", "loading.load-button", "shader.ripple", "cards.tilt-3d",
            "backgrounds.mesh-gradient", "text.numeric-counter", "buttons.magnetic", "navigation.tab-indicator",
        ]
        let picked = ids.compactMap { byID[$0] }
        return picked.count >= 4 ? picked : Array(all.prefix(8))
    }

    static func search(_ query: String, category: EffectCategory?, interaction: EffectInteraction?) -> [Effect] {
        let terms = query
            .lowercased()
            .split(whereSeparator: { $0 == " " || $0 == "　" })
            .map(String.init)
        return all.filter { effect in
            if let category, effect.category != category { return false }
            if let interaction, effect.interaction != interaction { return false }
            guard !terms.isEmpty else { return true }
            let haystack = effect.searchText
            return terms.allSatisfy { haystack.contains($0) }
        }
    }
}
