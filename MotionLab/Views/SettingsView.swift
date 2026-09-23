import SwiftUI

struct SettingsView: View {
    @Environment(\.appLanguage) private var language
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage("app.language") private var storedLanguage: AppLanguage = .zh
    @AppStorage("app.appearance") private var appearance: Int = 0
    @AppStorage("app.animatePreviews") private var animatePreviews = true

    private var versionString: String {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = info?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }

    var body: some View {
        Form {
            Section(Strings.language(language)) {
                Picker(Strings.language(language), selection: $storedLanguage) {
                    ForEach(AppLanguage.allCases) { item in
                        Text(item.displayName).tag(item)
                    }
                }
                .pickerStyle(.segmented)
            }
            Section(Strings.appearance(language)) {
                Picker(Strings.appearance(language), selection: $appearance) {
                    Text(Strings.system, language).tag(0)
                    Text(Strings.light, language).tag(1)
                    Text(Strings.dark, language).tag(2)
                }
                .pickerStyle(.segmented)
            }
            Section {
                // Reduce Motion always wins: show the toggle as off and explain why.
                Toggle(isOn: reduceMotion ? .constant(false) : $animatePreviews) {
                    Label {
                        Text(Strings.animatePreviews, language)
                    } icon: {
                        Image(systemName: "play.rectangle.on.rectangle.fill")
                            .foregroundStyle(Palette.indigo)
                    }
                }
                .disabled(reduceMotion)
            } header: {
                Text(Strings.motion, language)
            } footer: {
                Text(reduceMotion ? Strings.reduceMotionActive : Strings.animatePreviewsFooter, language)
            }
            Section(Strings.library(language)) {
                ForEach(EffectCategory.allCases) { category in
                    NavigationLink(value: Route.category(category)) {
                        HStack(spacing: 12) {
                            CategoryIcon(category: category, size: 28)
                            Text(category.title, language)
                            Spacer()
                            Text("\(EffectLibrary.effects(in: category).count)")
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                        }
                    }
                }
            }
            Section(Strings.about(language)) {
                Text(Strings.aboutBody, language)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                LabeledContent(Strings.allEffects(language), value: "\(EffectLibrary.all.count)")
                LabeledContent(Strings.categories(language), value: "\(EffectCategory.allCases.count)")
                LabeledContent(Strings.version(language), value: versionString)
            }
        }
        .navigationTitle(Strings.settings(language))
    }
}
