import AppKit

/// The menu bar icon: left-click toggles the session, right-click (or
/// control-click) opens the menu.
@MainActor
final class StatusItemController: NSObject, NSMenuDelegate {
    private let statusItem: NSStatusItem
    private let session: SessionController
    private let settings: SettingsStore
    private let openSettings: () -> Void

    // Items of the currently open menu, kept so they can update live.
    private var statusLineItem: NSMenuItem?
    private var toggleItem: NSMenuItem?
    private var durationItems: [(item: NSMenuItem, duration: SessionDuration)] = []
    private var countdownTimer: Timer?

    init(session: SessionController, settings: SettingsStore, openSettings: @escaping () -> Void) {
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        self.session = session
        self.settings = settings
        self.openSettings = openSettings
        super.init()

        if let button = statusItem.button {
            button.target = self
            button.action = #selector(statusItemClicked(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
            button.setAccessibilityTitle("Doppio")
        }
        sessionDidChange()
    }

    /// Call whenever the session state changes.
    func sessionDidChange() {
        let active = session.isActive
        if let button = statusItem.button {
            button.image = Self.icon(active: active)
            button.toolTip = active
                ? "Doppio is keeping your Mac awake. Click to turn it off."
                : "Doppio is off. Click to keep your Mac awake, or right-click to set a timer."
            button.setAccessibilityValue(active ? "On" : "Off")
        }
        refreshMenuItems()
    }

    private static func icon(active: Bool) -> NSImage? {
        let image = NSImage(named: active ? "MenuBarOn" : "MenuBarOff")
            ?? NSImage(
                systemSymbolName: active ? "cup.and.saucer.fill" : "cup.and.saucer",
                accessibilityDescription: nil
            )
        image?.isTemplate = true
        return image
    }

    // MARK: Clicks

    @objc private func statusItemClicked(_ sender: Any?) {
        let event = NSApp.currentEvent
        let wantsMenu = event?.type == .rightMouseUp || event?.modifierFlags.contains(.control) == true
        if wantsMenu {
            showMenu()
        } else {
            session.toggle(defaultDuration: settings.defaultDuration)
        }
    }

    private func showMenu() {
        // Attaching the menu only for this click keeps left-click free for toggling.
        statusItem.menu = buildMenu()
        statusItem.button?.performClick(nil)
        statusItem.menu = nil
    }

    // MARK: Menu

    private func buildMenu() -> NSMenu {
        let menu = NSMenu()
        menu.delegate = self
        menu.autoenablesItems = false

        let statusLine = NSMenuItem(title: "", action: nil, keyEquivalent: "")
        statusLine.isEnabled = false
        menu.addItem(statusLine)
        statusLineItem = statusLine

        let toggle = NSMenuItem(title: "", action: #selector(toggleSession), keyEquivalent: "")
        toggle.target = self
        menu.addItem(toggle)
        toggleItem = toggle

        menu.addItem(.separator())
        menu.addItem(.sectionHeader(title: "Keep Awake"))

        durationItems = (SessionDuration.presets + [.indefinite]).enumerated().map { index, duration in
            let item = NSMenuItem(title: duration.title, action: #selector(startSession(_:)), keyEquivalent: "")
            item.target = self
            item.tag = index
            menu.addItem(item)
            return (item, duration)
        }

        menu.addItem(.separator())

        let settingsItem = NSMenuItem(title: "Settings…", action: #selector(showSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)

        let quitItem = NSMenuItem(title: "Quit Doppio", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        menu.addItem(quitItem)

        refreshMenuItems()
        return menu
    }

    private func refreshMenuItems() {
        statusLineItem?.title = statusLineText
        toggleItem?.title = session.isActive ? "Turn Off" : "Turn On"
        let activeDuration = session.activeDuration
        for (item, duration) in durationItems {
            item.state = duration == activeDuration ? .on : .off
        }
    }

    private var statusLineText: String {
        guard session.isActive else { return "Off" }
        guard let remaining = session.remaining else { return "Awake" }
        return "Awake · \(RemainingTimeFormatter.string(for: remaining))"
    }

    func menuWillOpen(_ menu: NSMenu) {
        // Keep the countdown line current while the menu stays open.
        let timer = Timer(timeInterval: 1, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.refreshMenuItems() }
        }
        RunLoop.main.add(timer, forMode: .common)
        countdownTimer = timer
    }

    func menuDidClose(_ menu: NSMenu) {
        countdownTimer?.invalidate()
        countdownTimer = nil
        statusLineItem = nil
        toggleItem = nil
        durationItems = []
    }

    // MARK: Actions

    @objc private func toggleSession() {
        session.toggle(defaultDuration: settings.defaultDuration)
    }

    @objc private func startSession(_ sender: NSMenuItem) {
        let durations = SessionDuration.presets + [.indefinite]
        guard durations.indices.contains(sender.tag) else { return }
        session.start(durations[sender.tag])
    }

    @objc private func showSettings() {
        openSettings()
    }
}
