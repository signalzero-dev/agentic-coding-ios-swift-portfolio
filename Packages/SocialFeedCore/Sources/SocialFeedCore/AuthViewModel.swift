import Observation

/// Owns authentication state for the app. `session` is the source of truth for
/// "is the user signed in" and is driven by `authStateStream()` (so it survives
/// relaunches once the concrete repository restores persisted auth). `submitState`
/// tracks the in-flight sign-in / sign-up action for the auth screen.
@MainActor
@Observable
public final class AuthViewModel {
    public private(set) var session: User?
    /// The in-flight sign-in / sign-up action.
    public private(set) var submitState: LoadState<Void, AuthError> = .idle

    private let repository: any AuthRepository
    private var observationTask: Task<Void, Never>?

    public init(repository: any AuthRepository) {
        self.repository = repository
    }

    /// Begins observing auth state. Idempotent.
    public func start() {
        guard observationTask == nil else { return }
        observationTask = Task { [weak self] in
            guard let self else { return }
            for await user in self.repository.authStateStream() {
                self.session = user
            }
        }
    }

    /// Stops observing auth state, awaiting the cancelled task so that no further
    /// session updates can land after this returns.
    public func stop() async {
        observationTask?.cancel()
        await observationTask?.value
        observationTask = nil
    }

    public func signIn(email: String, password: String) async {
        await submit { try await self.repository.signIn(email: email, password: password) }
    }

    public func signUp(email: String, password: String) async {
        await submit { try await self.repository.signUp(email: email, password: password) }
    }

    private func submit(_ action: () async throws -> Void) async {
        submitState = .loading
        do {
            try await action()
            submitState = .loaded(())
        } catch let error as AuthError {
            submitState = .error(error)
        } catch {
            submitState = .error(.unknown)
        }
    }

    public func signOut() async {
        try? await repository.signOut()
    }
}
