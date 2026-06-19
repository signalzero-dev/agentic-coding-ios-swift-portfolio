/// Canonical view-model state for an asynchronous load, generic over both the
/// loaded value and the failure type.
///
/// Generalises MovieBrowserCore's `LoadState` (which hard-codes its error type)
/// so each SocialFeed view model can pair it with its own typed error.
///
/// Transition discipline (same as MovieBrowserCore): there is no `.empty` case —
/// zero results are `.loaded([])`; real-time refreshes stay in-place
/// `.loaded → .loaded` so data never disappears mid-update.
public enum LoadState<Value: Sendable, Failure: Error & Sendable>: Sendable {
    case idle
    case loading
    case loaded(Value)
    case error(Failure)

    /// The loaded value, or `nil` in any non-loaded state.
    public var value: Value? {
        if case let .loaded(value) = self { return value }
        return nil
    }

    /// The failure, or `nil` if not in the error state. Useful for views and for
    /// asserting on states whose `Value` isn't `Equatable` (e.g. `Void`).
    public var failure: Failure? {
        if case let .error(failure) = self { return failure }
        return nil
    }
}

extension LoadState: Equatable where Value: Equatable, Failure: Equatable {}
