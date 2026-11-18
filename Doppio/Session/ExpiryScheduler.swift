import Foundation

/// Runs one pending action after a delay. Abstracted so tests can fire it by hand.
@MainActor
protocol ExpiryScheduler: AnyObject {
    /// Schedules `action`, replacing anything scheduled earlier.
    func schedule(after interval: TimeInterval, _ action: @escaping @MainActor () -> Void)
    func cancel()
}

@MainActor
final class TimerExpiryScheduler: ExpiryScheduler {
    private var timer: Timer?

    func schedule(after interval: TimeInterval, _ action: @escaping @MainActor () -> Void) {
        cancel()
        let timer = Timer(timeInterval: max(interval, 0), repeats: false) { _ in
            MainActor.assumeIsolated { action() }
        }
        timer.tolerance = 1
        // `.common` so the timer still fires while a menu is open.
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    func cancel() {
        timer?.invalidate()
        timer = nil
    }
}
