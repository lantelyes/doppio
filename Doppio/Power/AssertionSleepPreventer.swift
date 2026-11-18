import Foundation
import IOKit.pwr_mgt

/// Prevents idle sleep with an IOKit power assertion, the same mechanism
/// `caffeinate` uses. It does not block manual sleep or closing the lid.
@MainActor
final class AssertionSleepPreventer: SleepPreventer {
    private static let noAssertion = IOPMAssertionID(kIOPMNullAssertionID)
    private var assertionID = AssertionSleepPreventer.noAssertion

    @discardableResult
    func prevent(displayStaysOn: Bool) -> Bool {
        release()

        let type = displayStaysOn
            ? kIOPMAssertionTypePreventUserIdleDisplaySleep
            : kIOPMAssertionTypePreventUserIdleSystemSleep
        var newID = AssertionSleepPreventer.noAssertion
        let result = IOPMAssertionCreateWithName(
            type as CFString,
            IOPMAssertionLevel(kIOPMAssertionLevelOn),
            "Doppio is keeping the Mac awake" as CFString,
            &newID
        )
        guard result == kIOReturnSuccess else { return false }
        assertionID = newID
        return true
    }

    func release() {
        guard assertionID != AssertionSleepPreventer.noAssertion else { return }
        IOPMAssertionRelease(assertionID)
        assertionID = AssertionSleepPreventer.noAssertion
    }
}
