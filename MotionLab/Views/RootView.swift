import SwiftUI

enum Route: Hashable {
    case category(EffectCategory)
    case effect(String)
}

private struct ZoomNamespaceKey: EnvironmentKey {
    static let defaultValue: Namespace.ID? = nil
}

extension EnvironmentValues {
    /// Namespace used for the iOS 18 zoom navigation transition from cards into detail.
    var zoomNamespace: Namespace.ID? {
        get { self[ZoomNamespaceKey.self] }
        set { self[ZoomNamespaceKey.self] = newValue }
    }
}

struct RootView: View {
    @Environment(\.appLanguage) private var language

    var body: some View {
        TabView {
            Tab(Strings.browse(language), systemImage: "square.grid.2x2.fill") {
                RoutedStack { BrowseView() }
            }
            Tab(Strings.search(language), systemImage: "magnifyingglass") {
                RoutedStack { SearchView() }
            }
            Tab(Strings.favorites(language), systemImage: "heart.fill") {
                RoutedStack { FavoritesView() }
            }
            Tab(Strings.settings(language), systemImage: "gearshape.fill") {
                NavigationStack { SettingsView() }
            }
        }
    }
}

/// A NavigationStack that knows how to show categories and effects with a zoom transition.
struct RoutedStack<Content: View>: View {
    @Namespace private var namespace
    @ViewBuilder var content: () -> Content

    var body: some View {
        NavigationStack {
            content()
                .navigationDestination(for: Route.self) { route in
                    switch route {
                    case .category(let category):
                        CategoryView(category: category)
                    case .effect(let id):
                        if let effect = EffectLibrary.effect(id: id) {
                            EffectDetailView(effect: effect)
                                .navigationTransition(.zoom(sourceID: id, in: namespace))
                        }
                    }
                }
        }
        .environment(\.zoomNamespace, namespace)
    }
}

/// A navigation link to an effect's detail page, acting as the zoom transition's source.
struct EffectLink<Label: View>: View {
    let effect: Effect
    @ViewBuilder var label: () -> Label
    @Environment(\.zoomNamespace) private var namespace

    var body: some View {
        NavigationLink(value: Route.effect(effect.id)) {
            if let namespace {
                label().matchedTransitionSource(id: effect.id, in: namespace)
            } else {
                label()
            }
        }
        .buttonStyle(PressableCardStyle())
    }
}

/// Subtle press-down scale used on every card in the app.
struct PressableCardStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}
