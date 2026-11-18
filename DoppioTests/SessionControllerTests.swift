import XCTest
@testable import Doppio

@MainActor
private final class FakePreventer: SleepPreventer {
    /// `nil` when released, otherwise the `displayStaysOn` value in force.
    private(set) var active: Bool?
    private(set) var preventCalls = 0
    var shouldSucceed = true

    func prevent(displayStaysOn: Bool) -> Bool {
        preventCalls += 1
        guard shouldSucceed else { return false }
        active = displayStaysOn
        return true
    }

    func release() { active = nil }
}

@MainActor
private final class FakeScheduler: ExpiryScheduler {
    private(set) var interval: TimeInterval?
    private var action: (@MainActor () -> Void)?

    func schedule(after interval: TimeInterval, _ action: @escaping @MainActor () -> Void) {
        self.interval = interval
        self.action = action
    }

    func cancel() {
        interval = nil
        action = nil
    }

    func fire() {
        let pending = action
        cancel()
        pending?()
    }
}

@MainActor
final class SessionControllerTests: XCTestCase {
    private var preventer: FakePreventer!
    private var scheduler: FakeScheduler!
    private var clock: Date!
    private var session: SessionController!

    override func setUp() async throws {
        preventer = FakePreventer()
        scheduler = FakeScheduler()
        clock = Date(timeIntervalSinceReferenceDate: 1_000_000)
        session = SessionController(preventer: preventer, scheduler: scheduler) { [unowned self] in clock }
    }

    func testStartsOff() {
        XCTAssertFalse(session.isActive)
        XCTAssertNil(preventer.active)
        XCTAssertNil(session.remaining)
    }

    func testIndefiniteSessionHasNoExpiry() {
        session.start(.indefinite)

        XCTAssertEqual(session.state, .on(duration: .indefinite, until: nil))
        XCTAssertEqual(preventer.active, true)
        XCTAssertNil(scheduler.interval)
        XCTAssertNil(session.remaining)
    }

    func testTimedSessionSchedulesExpiry() {
        session.start(.minutes(30))

        XCTAssertEqual(session.remaining, 1800)
        XCTAssertEqual(scheduler.interval, 1800)
        XCTAssertEqual(session.activeDuration, .minutes(30))
    }

    func testTimedSessionEndsWhenTimerFiresAtEndTime() {
        session.start(.minutes(15))
        clock.addTimeInterval(900)
        scheduler.fire()

        XCTAssertFalse(session.isActive)
        XCTAssertNil(preventer.active)
    }

    func testEarlyTimerFireReschedulesInsteadOfEnding() {
        session.start(.minutes(15))
        clock.addTimeInterval(600)
        scheduler.fire()

        XCTAssertTrue(session.isActive)
        XCTAssertEqual(scheduler.interval, 300)
    }

    func testSessionThatExpiredDuringSleepEndsOnWake() {
        session.start(.hours(1))
        clock.addTimeInterval(2 * 3600) // asleep past the end; timer never fired
        session.refresh()

        XCTAssertFalse(session.isActive)
        XCTAssertNil(preventer.active)
    }

    func testSessionStillRunningAfterSleepKeepsWallClockEnd() {
        session.start(.hours(1))
        clock.addTimeInterval(40 * 60)
        session.refresh()

        XCTAssertTrue(session.isActive)
        XCTAssertEqual(session.remaining, 20 * 60)
        XCTAssertEqual(scheduler.interval, 20 * 60)
    }

    func testIndefiniteSessionSurvivesWake() {
        session.start(.indefinite)
        clock.addTimeInterval(24 * 3600)
        session.refresh()

        XCTAssertTrue(session.isActive)
    }

    func testStopReleasesAndCancels() {
        session.start(.hours(2))
        session.stop()

        XCTAssertEqual(session.state, .off)
        XCTAssertNil(preventer.active)
        XCTAssertNil(scheduler.interval)
    }

    func testToggle() {
        session.toggle(defaultDuration: .hours(1))
        XCTAssertEqual(session.activeDuration, .hours(1))

        session.toggle(defaultDuration: .hours(1))
        XCTAssertFalse(session.isActive)
    }

    func testStartingAnotherSessionReplacesTheFirst() {
        session.start(.hours(8))
        session.start(.indefinite)

        XCTAssertEqual(session.state, .on(duration: .indefinite, until: nil))
        XCTAssertNil(scheduler.interval)
    }

    func testChangingDisplayOptionMidSessionSwapsPrevention() {
        session.start(.indefinite)
        session.displayStaysOn = false

        XCTAssertEqual(preventer.active, false)
        XCTAssertEqual(preventer.preventCalls, 2)
        XCTAssertTrue(session.isActive)
    }

    func testChangingDisplayOptionWhileOffDoesNothing() {
        session.displayStaysOn = false

        XCTAssertEqual(preventer.preventCalls, 0)
        session.start(.indefinite)
        XCTAssertEqual(preventer.active, false)
    }

    func testRefusedPreventionLeavesSessionOff() {
        preventer.shouldSucceed = false
        session.start(.hours(1))

        XCTAssertFalse(session.isActive)
        XCTAssertNil(scheduler.interval)
    }

    func testOnChangeFiresOncePerStateChange() {
        var changes = 0
        session.onChange = { changes += 1 }

        session.start(.indefinite)
        session.stop()
        session.stop()

        XCTAssertEqual(changes, 2)
    }
}

final class SessionDurationTests: XCTestCase {
    func testTitles() {
        XCTAssertEqual(SessionDuration.minutes(15).title, "15 minutes")
        XCTAssertEqual(SessionDuration.hours(1).title, "1 hour")
        XCTAssertEqual(SessionDuration.hours(8).title, "8 hours")
        XCTAssertEqual(SessionDuration.indefinite.title, "Indefinitely")
    }

    func testStorageRoundTrip() {
        for duration in SessionDuration.presets + [.indefinite] {
            XCTAssertEqual(SessionDuration(storageValue: duration.storageValue), duration)
        }
    }

    func testUnknownStoredValueFallsBackToIndefinite() {
        XCTAssertEqual(SessionDuration(storageValue: 1234), .indefinite)
    }
}

final class RemainingTimeFormatterTests: XCTestCase {
    func testFormats() {
        XCTAssertEqual(RemainingTimeFormatter.string(for: 30), "less than a minute left")
        XCTAssertEqual(RemainingTimeFormatter.string(for: 60), "1 min left")
        XCTAssertEqual(RemainingTimeFormatter.string(for: 41 * 60 + 10), "42 min left")
        XCTAssertEqual(RemainingTimeFormatter.string(for: 3600), "1 hr left")
        XCTAssertEqual(RemainingTimeFormatter.string(for: 2 * 3600 + 5 * 60), "2 hr 5 min left")
    }
}
