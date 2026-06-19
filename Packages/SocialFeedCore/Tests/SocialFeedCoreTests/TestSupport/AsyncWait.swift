import Foundation

/// Awaits until `condition` holds or `timeout` elapses, yielding between checks.
/// Used to let a view model's stream-consuming `Task` deliver a value before the
/// test asserts. Bounded by wall-clock time so a never-true condition fails the
/// test (via the follow-up `#expect`) rather than hanging.
@MainActor
func waitFor(
    timeout: Duration = .seconds(2),
    _ condition: @MainActor () -> Bool
) async {
    let clock = ContinuousClock()
    let deadline = clock.now.advanced(by: timeout)
    while !condition() && clock.now < deadline {
        await Task.yield()
    }
}
