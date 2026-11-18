import Foundation

/// Owns the keep-awake session: whether one is running, when it ends, and
/// the sleep prevention that backs it.
@MainActor
final class SessionController {
    enum State: Equatable {
        case off
        /// `until` is `nil` for an indefinite session.
        case on(duration: SessionDuration, until: Date?)
    }

    private(set) var state: State = .off {
        didSet { if state != oldValue { onChange?() } }
    }

    /// Called whenever `state` changes.
    var onChange: (() -> Void)?

    /// Whether the screen stays on during a session. Changing it mid-session
    /// swaps the underlying sleep prevention straight away.
    var displayStaysOn: Bool {
        didSet {
            guard displayStaysOn != oldValue, isActive else { return }
            if !preventer.prevent(displayStaysOn: displayStaysOn) { stop() }
        }
    }

    private let preventer: SleepPreventer
    private let scheduler: ExpiryScheduler
    private let now: () -> Date

    init(
        preventer: SleepPreventer,
        scheduler: ExpiryScheduler,
        displayStaysOn: Bool = true,
        now: @escaping () -> Date = Date.init
    ) {
        self.preventer = preventer
        self.scheduler = scheduler
        self.displayStaysOn = displayStaysOn
        self.now = now
    }

    var isActive: Bool { state != .off }

    /// The running session's duration, or `nil` when off.
    var activeDuration: SessionDuration? {
        if case .on(let duration, _) = state { return duration }
        return nil
    }

    /// Seconds left in a timed session; `nil` when off or indefinite.
    var remaining: TimeInterval? {
        guard case .on(_, let until?) = state else { return nil }
        return max(until.timeIntervalSince(now()), 0)
    }

    /// Starts a session, replacing any session already running.
    func start(_ duration: SessionDuration) {
        guard preventer.prevent(displayStaysOn: displayStaysOn) else {
            stop()
            return
        }
        switch duration {
        case .indefinite:
            scheduler.cancel()
            state = .on(duration: duration, until: nil)
        case .timed(let seconds):
            state = .on(duration: duration, until: now().addingTimeInterval(seconds))
            scheduleExpiry()
        }
    }

    func stop() {
        scheduler.cancel()
        preventer.release()
        state = .off
    }

    func toggle(defaultDuration: SessionDuration) {
        if isActive { stop() } else { start(defaultDuration) }
    }

    /// Re-checks a timed session against the real clock. Call after the Mac
    /// wakes or the clock changes: timers do not advance during system sleep,
    /// so a session can be past its end time without the timer having fired.
    func refresh() {
        guard case .on(_, let until?) = state else { return }
        if now() >= until {
            stop()
        } else {
            scheduleExpiry()
        }
    }

    private func scheduleExpiry() {
        guard case .on(_, let until?) = state else { return }
        scheduler.schedule(after: until.timeIntervalSince(now())) { [weak self] in
            self?.refresh()
        }
    }
}
