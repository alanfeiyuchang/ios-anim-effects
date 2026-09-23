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
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(AppNavigator.self) private var navigator
    @AppStorage("app.animatePreviews") private var animatePreviews = true

    var body: some View {
        @Bindable var navigator = navigator
        TabView(selection: $navigator.tab) {
            Tab(Strings.browse(language), systemImage: "square.grid.2x2.fill", value: AppTab.browse) {
                RoutedStack(initialPath: LaunchOptions.initialPath) { BrowseView() }
            }
            Tab(Strings.search(language), systemImage: "magnifyingglass", value: AppTab.search) {
                RoutedStack(popsToRootOnSearch: true) { SearchView() }
            }
            Tab(Strings.favorites(language), systemImage: "heart.fill", value: AppTab.favorites) {
                RoutedStack { FavoritesView() }
            }
            Tab(Strings.settings(language), systemImage: "gearshape.fill", value: AppTab.settings) {
                RoutedStack { SettingsView() }
            }
        }
        .environment(\.previewMotionEnabled, animatePreviews && !reduceMotion)
    }
}

/// Launch arguments used for automated screenshots, e.g.
/// `-ML_route effect:shader.ripple`, `-ML_route category:buttons`, `-ML_tab 3`, `-ML_anchor prompt`.
/// (`-app.language en` / `-app.appearance 2` also work because @AppStorage reads the argument domain.)
enum LaunchOptions {
    static var initialTab: Int { UserDefaults.standard.integer(forKey: "ML_tab") }

    static var initialPath: [Route] {
        guard let raw = UserDefaults.standard.string(forKey: "ML_route") else { return [] }
        if raw.hasPrefix("effect:") {
            let id = String(raw.dropFirst("effect:".count))
            return EffectLibrary.effect(id: id) == nil ? [] : [.effect(id)]
        }
        if raw.hasPrefix("category:"), let category = EffectCategory(rawValue: String(raw.dropFirst("category:".count))) {
            return [.category(category)]
        }
        return []
    }

    static var detailAnchor: String? { UserDefaults.standard.string(forKey: "ML_anchor") }
}

/// A NavigationStack that knows how to show categories and effects with a zoom transition.
struct RoutedStack<Content: View>: View {
    @Namespace private var namespace
    @State private var path: [Route]
    @Environment(AppNavigator.self) private var navigator
    private let popsToRootOnSearch: Bool
    private let content: () -> Content

    init(initialPath: [Route] = [], popsToRootOnSearch: Bool = false, @ViewBuilder content: @escaping () -> Content) {
        _path = State(initialValue: initialPath)
        self.popsToRootOnSearch = popsToRootOnSearch
        self.content = content
    }

    var body: some View {
        NavigationStack(path: $path) {
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
        .onChange(of: navigator.searchRevision) {
            if popsToRootOnSearch { path = [] }
        }
    }
}

/// A navigation link to an effect's detail page, acting as the zoom transition's source.
struct EffectLink<Label: View>: View {
    let effect: Effect
    @ViewBuilder var label: () -> Label
    @Environment(\.zoomNamespace) private var namespace
    @Environment(\.appLanguage) private var language
    @Environment(FavoritesStore.self) private var favorites

    var body: some View {
        NavigationLink(value: Route.effect(effect.id)) {
            if let namespace {
                label().matchedTransitionSource(id: effect.id, in: namespace)
            } else {
                label()
            }
        }
        .buttonStyle(PressableCardStyle())
        .effectContextMenu(effect)
        // A link is already one VoiceOver stop; give it "<name>, <category>" and the summary as the hint.
        .accessibilityLabel(Text(verbatim: "\(effect.name(language)), \(effect.category.title(language))"))
        .accessibilityValue(Text(verbatim: favorites.contains(effect.id) ? Strings.favorited(language) : ""))
        .accessibilityHint(Text(effect.summary, language))
    }
}

/// Subtle press-down scale used on every card in the app.
/// With Reduce Motion on, the press is shown as a dim instead of a scale.
struct PressableCardStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        PressableCardBody(label: configuration.label, isPressed: configuration.isPressed)
    }
}

private struct PressableCardBody: View {
    let label: ButtonStyleConfiguration.Label
    let isPressed: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        label
            .scaleEffect(isPressed && !reduceMotion ? 0.96 : 1)
            .opacity(isPressed && reduceMotion ? 0.7 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
    }
}
