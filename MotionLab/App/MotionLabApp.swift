import SwiftUI

@main
struct MotionLabApp: App {
    @AppStorage("app.language") private var language: AppLanguage = .zh
    @AppStorage("app.appearance") private var appearance: Int = 0
    @State private var favorites = FavoritesStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(\.appLanguage, language)
                .environment(favorites)
                .preferredColorScheme(colorScheme)
                .tint(Palette.indigo)
        }
    }

    private var colorScheme: ColorScheme? {
        switch appearance {
        case 1: return .light
        case 2: return .dark
        default: return nil
        }
    }
}

@Observable
final class FavoritesStore {
    private static let key = "app.favorites"

    private(set) var ids: [String]

    init() {
        ids = UserDefaults.standard.stringArray(forKey: Self.key) ?? []
    }

    func contains(_ id: String) -> Bool { ids.contains(id) }

    func toggle(_ id: String) {
        if let index = ids.firstIndex(of: id) {
            ids.remove(at: index)
        } else {
            ids.insert(id, at: 0)
        }
        UserDefaults.standard.set(ids, forKey: Self.key)
    }

    var effects: [Effect] { ids.compactMap { EffectLibrary.effect(id: $0) } }
}
