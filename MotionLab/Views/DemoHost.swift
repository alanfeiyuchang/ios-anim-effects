import SwiftUI
import UIKit

/// Demos that own a `NavigationStack` (e.g. the native zoom transition demo).
///
/// SwiftUI does not support a NavigationStack nested inside another one: the inner stack merges into
/// the app's stack, so its pushes land on the app's path and the app's own routes can resolve to the
/// yellow "missing destination" placeholder. These demos are therefore hosted in their own
/// `UIHostingController` (a separate SwiftUI hierarchy with an independent stack), and they are
/// never rasterised with `ImageRenderer` (which cannot draw a navigation controller).
enum DemoIsolation {
    static let hostedIDs: Set<String> = []  // Add an effect id here if its demo ever owns a NavigationStack.

    static func needsHost(_ effect: Effect) -> Bool { hostedIDs.contains(effect.id) }
}

/// An effect's demo, built inline, or inside its own hosting controller when the demo owns a
/// NavigationStack (see `DemoIsolation`). Environment values demos read are forwarded explicitly,
/// since SwiftUI's environment does not cross a hosting-controller boundary (traits such as the
/// color scheme, Dynamic Type and Reduce Motion do).
struct EffectDemoView: View {
    let effect: Effect
    let context: DemoContext
    @Environment(\.appLanguage) private var language
    @Environment(\.demoAutoplayEnabled) private var autoplay
    @Environment(\.demoIntroPlay) private var introPlay
    @Environment(\.demoSyncEpoch) private var syncEpoch

    var body: some View {
        if DemoIsolation.needsHost(effect) {
            IsolatedDemoHost(content: hostedContent)
        } else {
            effect.makeDemo(context)
        }
    }

    private var hostedContent: AnyView {
        AnyView(
            effect.makeDemo(context)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .environment(\.appLanguage, language)
                .environment(\.locale, language.locale)
                .environment(\.demoAutoplayEnabled, autoplay)
                .environment(\.demoIntroPlay, introPlay)
                .environment(\.demoSyncEpoch, syncEpoch)
        )
    }
}

/// Hosts SwiftUI content in a child `UIHostingController` with a clear background and no safe area.
private struct IsolatedDemoHost: UIViewControllerRepresentable {
    let content: AnyView

    func makeUIViewController(context: Context) -> UIHostingController<AnyView> {
        let host = UIHostingController(rootView: content)
        host.view.backgroundColor = .clear
        host.safeAreaRegions = []
        return host
    }

    func updateUIViewController(_ host: UIHostingController<AnyView>, context: Context) {
        host.rootView = content
    }
}
