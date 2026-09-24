import SwiftUI
import UIKit

/// Launch-argument tools used by CI to build the documentation site:
/// - `-ML_stage <effect-id>` renders a single effect's demo full-screen (square, autoplaying) for video capture.
/// - `-ML_exportCatalog YES` writes `catalog.json` (all categories, families and effects) to the app's Documents folder.
/// - `-ML_auditStills YES` renders every snapshot-able effect's still thumbnail (light + dark) through the grid's
///   own pipeline and writes `still-audit.json` to Documents: the "ink" coverage of each still, plus the Data & Charts
///   stills below `-ML_auditStillsMinInk` (default 0.08) as `flagged`. An empty chart (a demo that zeroes its data in
///   `onAppear`, which `ImageRenderer` runs) shows only axes and labels and falls far below a settled chart.
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

// MARK: - Still audit

extension CatalogTools {
    static var shouldAuditStills: Bool { UserDefaults.standard.bool(forKey: "ML_auditStills") }

    /// Minimum ink coverage for a Data & Charts still.
    static var stillInkThreshold: Double {
        let value = UserDefaults.standard.double(forKey: "ML_auditStillsMinInk")
        return value > 0 ? value : 0.08
    }

    /// Renders every snapshot-able still (English, light and dark, 1 px/pt) and writes `still-audit.json`.
    /// Yields between renders so the app stays responsive. Returns the file URL, or nil if writing failed.
    @MainActor
    @discardableResult
    static func auditStills() async -> URL? {
        let threshold = stillInkThreshold
        let schemes: [ColorScheme] = [.light, .dark]
        var rows: [[String: Any]] = []
        var flagged: [String] = []
        for effect in EffectLibrary.all where PreviewSnapshotCache.canSnapshot(effect) {
            for scheme in schemes {
                await Task.yield()
                let image = PreviewStill.render(effect: effect, language: .en, colorScheme: scheme, pixelsPerPoint: 1)
                let ink: Double = image.map(inkCoverage) ?? 0
                let schemeName = scheme == .dark ? "dark" : "light"
                let isLow = effect.category == .charts && ink < threshold
                rows.append([
                    "id": effect.id,
                    "category": effect.category.rawValue,
                    "scheme": schemeName,
                    "rendered": image != nil,
                    "ink": rounded(ink, 4),
                    "flagged": isLow,
                ])
                if isLow {
                    flagged.append("\(effect.id) (\(schemeName), ink \(rounded(ink, 3)))")
                }
            }
        }
        for line in flagged {
            print("still-audit: empty-looking chart still: \(line)")
        }
        let root: [String: Any] = [
            "generated": ISO8601DateFormatter().string(from: Date()),
            "threshold": threshold,
            "flagged": flagged,
            "stills": rows,
        ]
        guard let data = try? JSONSerialization.data(withJSONObject: root, options: [.prettyPrinted, .sortedKeys]),
              let folder = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        else { return nil }
        let url = folder.appendingPathComponent("still-audit.json")
        do {
            try data.write(to: url, options: .atomic)
            return url
        } catch {
            return nil
        }
    }

    /// Fraction of the drawn (non-transparent) pixels that differ clearly from the still's dominant colour.
    /// For a chart card the dominant colour is the card fill, so bars, arcs, cells and filled areas count as
    /// ink, while an empty chart (axes, gridlines, a "0" label) stays at a few percent.
    private static func inkCoverage(_ image: UIImage) -> Double {
        guard let cgImage = image.cgImage else { return 0 }
        let side = 85
        let bytesPerRow = side * 4
        var pixels = [UInt8](repeating: 0, count: side * bytesPerRow)
        let drawn: Bool = pixels.withUnsafeMutableBytes { buffer -> Bool in
            guard let context = CGContext(
                data: buffer.baseAddress,
                width: side,
                height: side,
                bitsPerComponent: 8,
                bytesPerRow: bytesPerRow,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            ) else { return false }
            context.interpolationQuality = .medium
            context.draw(cgImage, in: CGRect(x: 0, y: 0, width: side, height: side))
            return true
        }
        guard drawn else { return 0 }

        // Dominant colour among drawn pixels, quantised to 4 bits per channel.
        var histogram: [Int: Int] = [:]
        var drawnCount = 0
        for index in stride(from: 0, to: pixels.count, by: 4) where pixels[index + 3] > 32 {
            let red = Int(pixels[index]) >> 4
            let green = Int(pixels[index + 1]) >> 4
            let blue = Int(pixels[index + 2]) >> 4
            histogram[(red << 8) | (green << 4) | blue, default: 0] += 1
            drawnCount += 1
        }
        guard drawnCount > 0, let dominant = histogram.max(by: { $0.value < $1.value })?.key else { return 0 }
        let dominantRed = ((dominant >> 8) & 0xF) * 16 + 8
        let dominantGreen = ((dominant >> 4) & 0xF) * 16 + 8
        let dominantBlue = (dominant & 0xF) * 16 + 8

        var inkCount = 0
        for index in stride(from: 0, to: pixels.count, by: 4) where pixels[index + 3] > 32 {
            let distance = abs(Int(pixels[index]) - dominantRed)
                + abs(Int(pixels[index + 1]) - dominantGreen)
                + abs(Int(pixels[index + 2]) - dominantBlue)
            if distance > 60 { inkCount += 1 }
        }
        return Double(inkCount) / Double(drawnCount)
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
