import SwiftUI

struct SettingsView: View {
    @Environment(\.appLanguage) private var language
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage(AppLanguage.storageKey) private var storedLanguage: AppLanguage = AppLanguage.systemDefault
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
                            .foregroundStyle(Palette.accent)
                    }
                }
                .disabled(reduceMotion)
            } header: {
                Text(Strings.motion, language)
            } footer: {
                Text(reduceMotion ? Strings.reduceMotionActive : Strings.animatePreviewsFooter, language)
            }
            Section(Strings.about(language)) {
                Text(Strings.aboutBody, language)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                // Browsing lives in the Browse tab; Settings only summarises the catalog.
                LabeledContent(Strings.allEffects(language), value: Strings.effectCount(EffectLibrary.all.count, language))
                LabeledContent(Strings.categories(language), value: Strings.categoryCount(EffectCategory.allCases.count, language))
                LabeledContent(Strings.version(language), value: versionString)
            }
        }
        .navigationTitle(Strings.settings(language))
    }
}
