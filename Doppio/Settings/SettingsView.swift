import KeyboardShortcuts
import SwiftUI

/// The "Sections" layout: three titled groups in the System Settings style.
struct SettingsView: View {
    @Bindable var settings: SettingsStore

    @State private var launchAtLogin = LaunchAtLogin.isEnabled
    @State private var launchAtLoginError: String?

    var body: some View {
        Form {
            Section {
                Toggle("Open at login", isOn: $launchAtLogin)
            } header: {
                Text("Startup")
            } footer: {
                if let launchAtLoginError {
                    Text(launchAtLoginError)
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            Section("Sessions") {
                Picker(selection: $settings.defaultDuration) {
                    Text(SessionDuration.indefinite.title).tag(SessionDuration.indefinite)
                    Divider()
                    ForEach(SessionDuration.presets, id: \.self) { duration in
                        Text(duration.title).tag(duration)
                    }
                } label: {
                    Text("Default duration")
                    Text("Used when you click the cup or press the shortcut. Right-click the cup for other durations.")
                }

                Toggle(isOn: $settings.allowDisplaySleep) {
                    Text("Allow display to sleep")
                    Text("Your Mac stays awake, but the display can turn off.")
                }
            }

            Section("Shortcut") {
                KeyboardShortcuts.Recorder("Turn Doppio on or off", name: .toggleSession)
            }
        }
        .formStyle(.grouped)
        .scrollDisabled(true)
        .fixedSize(horizontal: false, vertical: true)
        .frame(width: 400)
        .onChange(of: launchAtLogin) { _, newValue in
            setLaunchAtLogin(newValue)
        }
    }

    private func setLaunchAtLogin(_ enabled: Bool) {
        // Also fires when a failed change is reverted below; nothing to do then.
        guard enabled != LaunchAtLogin.isEnabled else { return }
        do {
            try LaunchAtLogin.setEnabled(enabled)
            launchAtLoginError = nil
        } catch {
            launchAtLoginError = "Couldn’t change Open at login: \(error.localizedDescription)"
            launchAtLogin = LaunchAtLogin.isEnabled
        }
    }
}
