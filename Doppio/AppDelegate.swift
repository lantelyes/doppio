import AppKit
import KeyboardShortcuts

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let settings = SettingsStore()
    private lazy var session = SessionController(
        preventer: AssertionSleepPreventer(),
        scheduler: TimerExpiryScheduler(),
        displayStaysOn: !settings.allowDisplaySleep
    )
    private lazy var settingsWindowController = SettingsWindowController(settings: settings)
    private var statusItemController: StatusItemController?

    /// The unit tests run inside the app; skip the menu bar UI for them.
    private var isRunningTests: Bool {
        ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        guard !isRunningTests else { return }

        NSApp.mainMenu = makeMainMenu()

        let statusItemController = StatusItemController(
            session: session,
            settings: settings,
            openSettings: { [weak self] in self?.settingsWindowController.show() }
        )
        self.statusItemController = statusItemController

        session.onChange = { [weak statusItemController] in
            statusItemController?.sessionDidChange()
        }
        settings.onChange = { [weak self] in
            guard let self else { return }
            session.displayStaysOn = !settings.allowDisplaySleep
        }

        KeyboardShortcuts.onKeyUp(for: .toggleSession) { [weak self] in
            guard let self else { return }
            session.toggle(defaultDuration: settings.defaultDuration)
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

    /// Never shown (the app has no menu bar of its own), but it is what makes
    /// ⌘W, ⌘Q and text editing shortcuts work while the settings window is open.
    private func makeMainMenu() -> NSMenu {
        let mainMenu = NSMenu()

        let appMenu = NSMenu()
        appMenu.addItem(withTitle: "Quit Doppio", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        let appItem = NSMenuItem()
        appItem.submenu = appMenu
        mainMenu.addItem(appItem)

        let windowMenu = NSMenu(title: "Window")
        windowMenu.addItem(withTitle: "Close", action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w")
        let windowItem = NSMenuItem()
        windowItem.submenu = windowMenu
        mainMenu.addItem(windowItem)

        return mainMenu
    }
}
