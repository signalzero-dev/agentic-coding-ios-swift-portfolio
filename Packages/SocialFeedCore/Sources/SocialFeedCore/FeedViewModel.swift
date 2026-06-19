import Foundation
import Observation

/// Drives the real-time feed screen. Consumes `FeedRepository.feedStream()` and
/// publishes a `LoadState`. Real-time updates stay in-place (`.loaded → .loaded`)
/// so the list never unmounts mid-update.
@MainActor
@Observable
public final class FeedViewModel {
    public private(set) var state: LoadState<[Post], FeedError> = .idle

    private let repository: any FeedRepository
    private var streamTask: Task<Void, Never>?

    public init(repository: any FeedRepository) {
        self.repository = repository
    }

    /// Begins consuming the feed stream. Idempotent — a second call while already
    /// streaming is a no-op.
    public func start() {
        guard streamTask == nil else { return }
        state = .loading
        streamTask = Task { [weak self] in
            guard let self else { return }
            do {
                for try await posts in self.repository.feedStream() {
                    self.state = .loaded(posts)
                }
            } catch is CancellationError {
                // Expected when stop() cancels the stream; leave state as-is.
            } catch let error as FeedError {
                self.state = .error(error)
            } catch {
                self.state = .error(.unknown)
            }
        }
    }

    /// Stops consuming the feed stream.
    public func stop() {
        streamTask?.cancel()
        streamTask = nil
    }
}
