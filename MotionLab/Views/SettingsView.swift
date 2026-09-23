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

    /// Language changes cross-fade the whole window (every label, the tab bar, the prompts).
    private var languageSelection: Binding<AppLanguage> {
        Binding {
            storedLanguage
        } set: { newValue in
            guard newValue != storedLanguage else { return }
            WindowCrossfade.perform { storedLanguage = newValue }
        }
    }

    /// Appearance changes cross-fade too, so light ↔ dark melts instead of snapping.
    private var appearanceSelection: Binding<Int> {
        Binding {
            appearance
        } set: { newValue in
            guard newValue != appearance else { return }
            WindowCrossfade.perform(duration: 0.45) { appearance = newValue }
        }
    }

    var body: some View {
        Form {
            Section(Strings.language(language)) {
                Picker(Strings.language(language), selection: languageSelection) {
                    ForEach(AppLanguage.allCases) { item in
                        Text(item.displayName).tag(item)
                    }
                }
                .pickerStyle(.segmented)
                .sensoryFeedback(.selection, trigger: storedLanguage)
            }
            Section(Strings.appearance(language)) {
                Picker(Strings.appearance(language), selection: appearanceSelection) {
                    Text(Strings.system, language).tag(0)
                    Text(Strings.light, language).tag(1)
                    Text(Strings.dark, language).tag(2)
                }
                .pickerStyle(.segmented)
                .sensoryFeedback(.selection, trigger: appearance)
            }
            Section {
                // Reduce Motion always wins: show the toggle as off and explain why.
                Toggle(isOn: reduceMotion ? .constant(false) : $animatePreviews) {
                    Label {
                        Text(Strings.animatePreviews, language)
                    } icon: {
                        Image(systemName: "play.rectangle.on.rectangle.fill")
                            .foregroundStyle(Palette.accent)
                            .symbolEffect(.bounce, value: animatePreviews)
                    }
                }
                .disabled(reduceMotion)
                .sensoryFeedback(.impact(weight: .light), trigger: animatePreviews)
            } header: {
                Text(Strings.motion, language)
            } footer: {
                Text(reduceMotion ? Strings.reduceMotionActive : Strings.animatePreviewsFooter, language)
                    .contentTransition(.opacity)
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
