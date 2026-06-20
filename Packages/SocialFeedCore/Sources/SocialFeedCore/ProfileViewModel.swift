import Observation

/// Drives the profile screen: the user plus a live stream of their posts.
@MainActor
@Observable
public final class ProfileViewModel {
    public let user: User
    public private(set) var state: LoadState<[Post], FeedError> = .idle

    private let repository: any ProfileRepository
    private var streamTask: Task<Void, Never>?

    public init(user: User, repository: any ProfileRepository) {
        self.user = user
        self.repository = repository
    }

    public func start() {
        guard streamTask == nil else { return }
        state = .loading
        streamTask = Task { [weak self] in
            guard let self else { return }
            do {
                for try await posts in self.repository.userPostsStream(userID: self.user.id) {
                    self.state = .loaded(posts)
                }
            } catch is CancellationError {
                // Expected when stop() cancels the stream.
            } catch let error as FeedError {
                self.state = .error(error)
            } catch {
                self.state = .error(.unknown)
            }
        }
    }

    public func stop() async {
        streamTask?.cancel()
        await streamTask?.value
        streamTask = nil
    }
}
