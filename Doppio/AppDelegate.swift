import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let settings = SettingsStore()
    private lazy var session = SessionController(
        preventer: AssertionSleepPreventer(),
        scheduler: TimerExpiryScheduler(),
        displayStaysOn: !settings.allowDisplaySleep
    )
    private var statusItemController: StatusItemController?

    /// The unit tests run inside the app; skip the menu bar UI for them.
    private var isRunningTests: Bool {
        ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        guard !isRunningTests else { return }

        let statusItemController = StatusItemController(
            session: session,
            settings: settings,
            openSettings: { [weak self] in self?.showSettings() }
        )
        self.statusItemController = statusItemController

        session.onChange = { [weak statusItemController] in
            statusItemController?.sessionDidChange()
        }
        settings.onChange = { [weak self] in
            guard let self else { return }
            session.displayStaysOn = !settings.allowDisplaySleep
        }

        // Timers pause while the Mac sleeps, so re-check timed sessions
        // against the real clock on wake and when the clock is changed.
        NSWorkspace.shared.notificationCenter.addObserver(
            self, selector: #selector(refreshSession),
            name: NSWorkspace.didWakeNotification, object: nil
        )
        NotificationCenter.default.addObserver(
            self, selector: #selector(refreshSession),
            name: .NSSystemClockDidChange, object: nil
        )
    }

    func applicationWillTerminate(_ notification: Notification) {
        session.stop()
    }

    @objc private func refreshSession() {
        session.refresh()
    }

    private func showSettings() {
        // Settings window arrives in the next milestone.
    }
}
