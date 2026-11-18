import Foundation

/// How long a keep-awake session lasts.
enum SessionDuration: Hashable, Sendable {
    case indefinite
    case timed(TimeInterval)

    static func minutes(_ count: Int) -> SessionDuration { .timed(TimeInterval(count * 60)) }
    static func hours(_ count: Int) -> SessionDuration { .timed(TimeInterval(count * 3600)) }

    /// The fixed timed choices offered in the menu and in Settings.
    static let presets: [SessionDuration] = [
        .minutes(15), .minutes(30), .hours(1), .hours(2), .hours(4), .hours(8),
    ]

    var title: String {
        switch self {
        case .indefinite:
            return "Indefinitely"
        case .timed(let seconds):
            let minutes = Int(seconds / 60)
            if minutes < 60 { return "\(minutes) minutes" }
            let hours = minutes / 60
            return hours == 1 ? "1 hour" : "\(hours) hours"
        }
    }

    /// Seconds for a timed session, 0 for an indefinite one. Used for UserDefaults.
    var storageValue: Double {
        switch self {
        case .indefinite: return 0
        case .timed(let seconds): return seconds
        }
    }

    /// Falls back to `.indefinite` for anything that is not one of the presets.
    init(storageValue: Double) {
        let candidate = SessionDuration.timed(storageValue)
        self = SessionDuration.presets.contains(candidate) ? candidate : .indefinite
    }
}
