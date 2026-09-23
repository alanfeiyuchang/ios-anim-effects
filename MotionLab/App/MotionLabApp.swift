import SwiftUI

@main
struct MotionLabApp: App {
    @AppStorage(AppLanguage.storageKey) private var language: AppLanguage = AppLanguage.systemDefault
    @AppStorage("app.appearance") private var appearance: Int = 0
    @State private var favorites = FavoritesStore()
    @State private var recents = RecentsStore()
    @State private var navigator = AppNavigator()

    init() {
        // First launch: follow the device language (zh* → 中文, otherwise English) and remember it.
        AppLanguage.registerInitialChoice()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(\.appLanguage, language)
                .environment(\.locale, language.locale)
                .environment(favorites)
                .environment(recents)
                .environment(navigator)
                .preferredColorScheme(colorScheme)
                .tint(Palette.accent)
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

    var count: Int { ids.count }

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
