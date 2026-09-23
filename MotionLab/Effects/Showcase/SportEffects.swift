import SwiftUI

/// Ski / outdoor dashboard entries of the "Signature Interactions" category.
/// Each effect lives in its own `Sport+<Name>.swift` file; shared sport-only helpers are below.
enum ShowcaseSportEffects {
    static let all: [Effect] = [
        .showcaseSlideToStart,
        .showcaseSpeedLine,
        .showcaseFreshSnow,
        .showcaseBoardCard,
        .showcaseBestLine,
        .showcasePhotoPlay,
        .showcaseSpotsGrid,
        .showcaseGoCountdown,
        .showcaseSummitBadge,
        .showcaseAltitudeRuler,
        .showcaseLiftStatus,
        .showcaseHeartZone,
        .showcaseRunSummary,
        .showcaseWeatherWidget,
        .showcaseGearChecklist,
    ]
}

// MARK: - Shared sport helpers

/// Press feedback used by tappable showcase cards: sink + dim on touch-down, springy release.
struct SportPressStyle: ButtonStyle {
    var scale: CGFloat = 0.96
    var dim: Double = 0.08

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1)
            .brightness(configuration.isPressed ? -dim : 0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

/// Eyebrow row: optional orange glyph, uppercase title, optional trailing caption.
struct SportEyebrowRow: View {
    let title: String
    var symbol: String? = nil
    var trailing: String? = nil

    var body: some View {
        HStack(spacing: 6) {
            if let symbol {
                Image(systemName: symbol)
                    .foregroundStyle(Signature.accent)
            }
            Text(title)
            Spacer(minLength: 0)
            if let trailing {
                Text(trailing)
            }
        }
        .signatureEyebrow()
    }
}

/// A small "live" dot with a ring that keeps pulsing outward.
struct SportLiveDot: View {
    var color: Color = Signature.accent
    var size: CGFloat = 8
    var period: Double = 1.4

    var body: some View {
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            let p = CGFloat(t.truncatingRemainder(dividingBy: period) / period)
            ZStack {
                Circle()
                    .stroke(color.opacity(Double(1 - p)), lineWidth: 1.5)
                    .frame(width: size, height: size)
                    .scaleEffect(1 + p * 1.8)
                Circle()
                    .fill(color)
                    .frame(width: size, height: size)
                    .shadow(color: color.opacity(0.8), radius: 4)
            }
        }
        .frame(width: size * 3, height: size * 3)
    }
}

/// Deterministic pseudo-random value in 0..<1 for procedural drawing.
func sportHash(_ x: Double) -> Double {
    let n = sin(x * 12.9898 + 78.233) * 43758.5453
    return n - n.rounded(.down)
}
