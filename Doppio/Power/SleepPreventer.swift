import Foundation

/// Something that can stop the Mac from sleeping.
///
/// The session logic only talks to this protocol, so another mechanism
/// (for example a lid-closed mode based on `pmset disablesleep`) can be
/// added later without touching the session or the menu bar code.
@MainActor
protocol SleepPreventer: AnyObject {
    /// Starts preventing sleep, replacing any earlier request.
    /// - Parameter displayStaysOn: `true` keeps the screen on as well; `false`
    ///   keeps the Mac awake but lets the screen sleep.
    /// - Returns: `false` if the system refused the request.
    @discardableResult
    func prevent(displayStaysOn: Bool) -> Bool

    /// Stops preventing sleep. Safe to call when nothing is active.
    func release()
}
