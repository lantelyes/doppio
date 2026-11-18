import Foundation
import Observation

/// User preferences, persisted in UserDefaults.
@MainActor
@Observable
final class SettingsStore {
    private enum Key {
        static let defaultDuration = "defaultDuration"
        static let allowDisplaySleep = "allowDisplaySleep"
    }

    @ObservationIgnored private let defaults: UserDefaults

    /// Called after any preference changes.
    @ObservationIgnored var onChange: (() -> Void)?

    /// What a left-click on the menu bar icon starts.
    var defaultDuration: SessionDuration {
        didSet {
            defaults.set(defaultDuration.storageValue, forKey: Key.defaultDuration)
            onChange?()
        }
    }

    /// When on, a session keeps the Mac awake but lets the screen sleep.
    var allowDisplaySleep: Bool {
        didSet {
            defaults.set(allowDisplaySleep, forKey: Key.allowDisplaySleep)
            onChange?()
        }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        defaultDuration = SessionDuration(storageValue: defaults.double(forKey: Key.defaultDuration))
        allowDisplaySleep = defaults.bool(forKey: Key.allowDisplaySleep)
    }
}
