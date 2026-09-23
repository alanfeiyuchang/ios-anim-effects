import SwiftUI
import UIKit

struct EffectDetailView: View {
    let effect: Effect

    @Environment(\.appLanguage) private var language
    @Environment(FavoritesStore.self) private var favorites
    @State private var params: ParamValues
    @State private var resetToken = 0
    @State private var copied = false

    init(effect: Effect) {
        self.effect = effect
        _params = State(initialValue: effect.defaultParams)
    }

    var body: some View {
        ScrollViewReader { reader in
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header
                    stage
                    if !effect.params.isEmpty { parameters }
                    promptCard.id("prompt")
                    implementationCard
                    if !effect.tags.isEmpty { tagsCard }
                }
                .padding()
                .padding(.bottom, 24)
            }
            .onAppear {
                if let anchor = LaunchOptions.detailAnchor {
                    reader.scrollTo(anchor, anchor: .top)
                }
            }
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle(effect.name(language))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                ShareLink(item: effect.fullPrompt(language, params: params)) {
                    Image(systemName: "square.and.arrow.up")
                }
                Button {
                    favorites.toggle(effect.id)
                    Haptics.tap(.medium)
                } label: {
                    Image(systemName: favorites.contains(effect.id) ? "heart.fill" : "heart")
                        .foregroundStyle(favorites.contains(effect.id) ? Palette.pink : Color.accentColor)
                        .contentTransition(.symbolEffect(.replace))
                }
            }
        }
    }

    // MARK: Sections

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Label(effect.category.title(language), systemImage: effect.category.symbol)
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .foregroundStyle(.white)
                    .background(LinearGradient(colors: effect.category.gradient, startPoint: .leading, endPoint: .trailing), in: Capsule())
                Label(effect.interaction.title(language), systemImage: effect.interaction.symbol)
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color(uiColor: .secondarySystemGroupedBackground), in: Capsule())
                    .foregroundStyle(.secondary)
                if let requirement = effect.requirement {
                    Text("\(Strings.requires(language)) \(requirement)")
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Palette.violet.opacity(0.15), in: Capsule())
                        .foregroundStyle(Palette.violet)
                }
            }
            Text(effect.name, language)
                .font(.largeTitle.weight(.bold))
            Text(effect.summary, language)
                .font(.body)
                .foregroundStyle(.secondary)
        }
    }

    private var stage: some View {
        effect.makeDemo(DemoContext(params: params, isPreview: false, language: language))
            .id(resetToken)
            .frame(maxWidth: .infinity)
            .frame(height: StageMetrics.detailHeight)
            .background(StageBackground())
            .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 30, style: .continuous).strokeBorder(Palette.stroke))
            .overlay(alignment: .topTrailing) {
                Button {
                    resetToken += 1
                    Haptics.tap()
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.footnote.weight(.bold))
                        .frame(width: 32, height: 32)
                        .background(.ultraThinMaterial, in: Circle())
                }
                .buttonStyle(.plain)
                .padding(12)
                .accessibilityLabel(Strings.reset(language))
            }
    }

    private var parameters: some View {
        DetailSection(title: Strings.parameters(language), symbol: "slider.horizontal.3") {
            VStack(spacing: 16) {
                ForEach(effect.params) { spec in
                    ParamControl(spec: spec, value: Binding(
                        get: { params[spec.id] },
                        set: { params[spec.id] = $0 }
                    ))
                }
                Button(Strings.resetParams(language)) {
                    withAnimation(.snappy) { params = effect.defaultParams }
                }
                .font(.footnote.weight(.semibold))
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
    }

    private var promptCard: some View {
        DetailSection(title: Strings.prompt(language), symbol: "text.quote") {
            VStack(alignment: .leading, spacing: 12) {
                Text(Strings.promptHint, language)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(effect.fullPrompt(language, params: params))
                    .font(.callout)
                    .lineSpacing(3)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
                    .background(Palette.indigo.opacity(0.07), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(alignment: .leading) {
                        Capsule().fill(Palette.primary).frame(width: 3).padding(.vertical, 10)
                    }
                Button {
                    UIPasteboard.general.string = effect.fullPrompt(language, params: params)
                    Haptics.success()
                    withAnimation(.snappy) { copied = true }
                    Task {
                        try? await Task.sleep(for: .seconds(1.6))
                        withAnimation(.snappy) { copied = false }
                    }
                } label: {
                    Label(copied ? Strings.copied(language) : Strings.copy(language),
                          systemImage: copied ? "checkmark" : "doc.on.doc")
                        .contentTransition(.symbolEffect(.replace))
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .foregroundStyle(.white)
                        .background(copied ? AnyShapeStyle(Palette.green) : AnyShapeStyle(Palette.primary),
                                    in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(PressableCardStyle())
            }
        }
    }

    private var implementationCard: some View {
        DetailSection(title: Strings.implementation(language), symbol: "chevron.left.forwardslash.chevron.right") {
            VStack(alignment: .leading, spacing: 12) {
                Text(effect.implementation, language)
                    .font(.callout)
                    .lineSpacing(3)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(Strings.apis, language)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                FlowLayout(spacing: 6) {
                    ForEach(effect.apis, id: \.self) { api in
                        TagLabel(text: api, monospaced: true)
                    }
                }
            }
        }
    }

    private var tagsCard: some View {
        DetailSection(title: Strings.tags(language), symbol: "tag") {
            FlowLayout(spacing: 6) {
                ForEach(effect.tags, id: \.self) { tag in
                    TagLabel(text: "#\(tag)")
                }
            }
        }
    }
}

private struct DetailSection<Content: View>: View {
    let title: String
    let symbol: String
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: symbol)
                .font(.headline)
            content()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}

struct ParamControl: View {
    let spec: ParamSpec
    @Binding var value: Double
    @Environment(\.appLanguage) private var language

    var body: some View {
        switch spec.kind {
        case .slider(let range, let step):
            VStack(spacing: 6) {
                HStack {
                    Text(spec.name, language).font(.subheadline)
                    Spacer()
                    Text(spec.formatted(value, language))
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(.secondary)
                        .contentTransition(.numericText(value: value))
                }
                if let step {
                    Slider(value: $value, in: range, step: step)
                } else {
                    Slider(value: $value, in: range)
                }
            }
        case .toggle:
            Toggle(isOn: Binding(get: { value > 0.5 }, set: { value = $0 ? 1 : 0 })) {
                Text(spec.name, language).font(.subheadline)
            }
        case .choice(let options):
            VStack(alignment: .leading, spacing: 8) {
                Text(spec.name, language).font(.subheadline)
                Picker(spec.name(language), selection: Binding(get: { Int(value.rounded()) }, set: { value = Double($0) })) {
                    ForEach(options.indices, id: \.self) { index in
                        Text(options[index], language).tag(index)
                    }
                }
                .pickerStyle(.segmented)
            }
        }
    }
}
