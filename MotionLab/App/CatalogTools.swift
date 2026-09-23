import SwiftUI

/// Launch-argument tools used by CI to build the documentation site:
/// - `-ML_stage <effect-id>` renders a single effect's demo full-screen (square, autoplaying) for video capture.
/// - `-ML_exportCatalog YES` writes `catalog.json` (all categories, families and effects) to the app's Documents folder.
enum CatalogTools {
    static var stageEffectID: String? {
        guard let id = UserDefaults.standard.string(forKey: "ML_stage"), !id.isEmpty else { return nil }
        return id
    }

    static var shouldExport: Bool { UserDefaults.standard.bool(forKey: "ML_exportCatalog") }

    /// Writes the catalog JSON. Returns the file URL, or nil if encoding failed.
    @discardableResult
    static func exportCatalog() -> URL? {
        let root: [String: Any] = [
            "generated": ISO8601DateFormatter().string(from: Date()),
            "categories": EffectCategory.allCases.map(categoryJSON),
            "families": EffectFamilies.all.map(familyJSON),
            "effects": EffectLibrary.all.map(effectJSON),
        ]
        guard let data = try? JSONSerialization.data(withJSONObject: root, options: [.prettyPrinted, .sortedKeys]),
              let folder = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        else { return nil }
        let url = folder.appendingPathComponent("catalog.json")
        do {
            try data.write(to: url, options: .atomic)
            return url
        } catch {
            return nil
        }
    }

    private static func text(_ value: LocalizedText) -> [String: String] {
        ["en": value.en, "zh": value.zh]
    }

    private static func categoryJSON(_ category: EffectCategory) -> [String: Any] {
        [
            "id": category.rawValue,
            "title": text(category.title),
            "subtitle": text(category.subtitle),
            "symbol": category.symbol,
        ]
    }

    private static func familyJSON(_ family: EffectFamily) -> [String: Any] {
        [
            "id": family.id,
            "category": family.category.rawValue,
            "name": text(family.name),
            "summary": text(family.summary),
            "symbol": family.symbol,
        ]
    }

    private static func effectJSON(_ effect: Effect) -> [String: Any] {
        var json: [String: Any] = [
            "id": effect.id,
            "category": effect.category.rawValue,
            "family": EffectFamilies.family(for: effect)?.id ?? "",
            "interaction": effect.interaction.rawValue,
            "name": text(effect.name),
            "summary": text(effect.summary),
            "prompt": text(effect.prompt),
            "implementation": text(effect.implementation),
            "apis": effect.apis,
            "tags": effect.tags,
            "params": effect.params.map(paramJSON),
        ]
        if let requirement = effect.requirement {
            json["requirement"] = requirement
        }
        return json
    }

    private static func paramJSON(_ spec: ParamSpec) -> [String: Any] {
        var json: [String: Any] = [
            "id": spec.id,
            "name": text(spec.name),
            "unit": spec.unit,
        ]
        switch spec.kind {
        case .slider(let range, _):
            json["kind"] = "slider"
            json["min"] = rounded(range.lowerBound, spec.decimals)
            json["max"] = rounded(range.upperBound, spec.decimals)
            json["default"] = rounded(spec.defaultValue, spec.decimals)
        case .toggle:
            json["kind"] = "toggle"
            json["default"] = spec.defaultValue > 0.5
        case .choice(let options):
            json["kind"] = "choice"
            json["options"] = options.map(text)
            json["default"] = Int(spec.defaultValue.rounded())
        }
        return json
    }

    private static func rounded(_ value: Double, _ decimals: Int) -> Double {
        let factor: Double = pow(10, Double(max(decimals, 0)))
        return (value * factor).rounded() / factor
    }
}

/// A single effect's demo, full-screen and square-centered, autoplaying like a grid preview — used for video capture.
struct StageOnlyView: View {
    let effectID: String
    @Environment(\.appLanguage) private var language

    var body: some View {
        GeometryReader { proxy in
            let side: CGFloat = proxy.size.width
            let canvas: CGFloat = StageMetrics.previewCanvas
            let scale: CGFloat = side / canvas
            ZStack {
                Color.black
                if let effect = EffectLibrary.effect(id: effectID) {
                    effect.makeDemo(DemoContext(params: effect.defaultParams, isPreview: true, language: language))
                        .frame(width: canvas, height: canvas)
                        .background(StageBackground())
                        .clipped()
                        .scaleEffect(scale)
                        .frame(width: side, height: side)
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .ignoresSafeArea()
        .statusBarHidden(true)
    }
}
