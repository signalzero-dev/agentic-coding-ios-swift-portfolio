import Foundation

/// Canonical state for asynchronous view-model loads.
/// Zero results are `.loaded([])` — there is no `.empty` case.
/// See `README.md` for the full transition rule.
public enum LoadState<Value: Sendable>: Sendable {
    case idle
    case loading
    case loaded(Value)
    case error(MovieServiceError)
}
