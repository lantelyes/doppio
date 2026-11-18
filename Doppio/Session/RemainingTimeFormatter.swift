import Foundation

enum RemainingTimeFormatter {
    /// "2 hr 5 min left", "42 min left", "less than a minute left".
    /// Minutes round up, so 41 min 10 s reads as "42 min left".
    static func string(for remaining: TimeInterval) -> String {
        if remaining < 60 { return "less than a minute left" }
        let totalMinutes = Int((remaining / 60).rounded(.up))
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        if hours == 0 { return "\(minutes) min left" }
        if minutes == 0 { return "\(hours) hr left" }
        return "\(hours) hr \(minutes) min left"
    }
}
