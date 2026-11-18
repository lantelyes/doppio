import KeyboardShortcuts
import SwiftUI

/// The "Header" layout: app identity on top, one grouped list of controls,
/// and a hint underneath.
struct SettingsView: View {
    @Bindable var settings: SettingsStore

    @State private var launchAtLogin = LaunchAtLogin.isEnabled
    @State private var launchAtLoginError: String?

    private var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
    }

    var body: some View {
        VStack(spacing: 0) {
            header
                .padding(.top, 20)

            Form {
                Section {
                    Toggle("Launch at login", isOn: $launchAtLogin)

                    Toggle(isOn: $settings.allowDisplaySleep) {
                        Text("Allow display to sleep")
                        Text("The Mac stays awake but the screen can turn off.")
                    }

                    Picker("Left-click starts", selection: $settings.defaultDuration) {
                        Text(SessionDuration.indefinite.title).tag(SessionDuration.indefinite)
                        Divider()
                        ForEach(SessionDuration.presets, id: \.self) { duration in
                            Text(duration.title).tag(duration)
                        }
                    }

                    KeyboardShortcuts.Recorder("Toggle shortcut", name: .toggleSession)
                } footer: {
                    if let launchAtLoginError {
                        Text(launchAtLoginError)
                            .foregroundStyle(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            .formStyle(.grouped)
            .scrollDisabled(true)
            .fixedSize(horizontal: false, vertical: true)

            Text("Right-click the menu bar icon for timed sessions.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.bottom, 20)
        }
        .frame(width: 440)
        .onChange(of: launchAtLogin) { _, newValue in
            setLaunchAtLogin(newValue)
        }
    }

    private var header: some View {
        VStack(spacing: 4) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 64, height: 64)
                .accessibilityHidden(true)
            Text("Doppio")
                .font(.headline)
            Text("Version \(version)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func setLaunchAtLogin(_ enabled: Bool) {
        // Also fires when a failed change is reverted below; nothing to do then.
        guard enabled != LaunchAtLogin.isEnabled else { return }
        do {
            try LaunchAtLogin.setEnabled(enabled)
            launchAtLoginError = nil
        } catch {
            launchAtLoginError = "Couldn't change the login item: \(error.localizedDescription)"
            launchAtLogin = LaunchAtLogin.isEnabled
        }
    }
}
