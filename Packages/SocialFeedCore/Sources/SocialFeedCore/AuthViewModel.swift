import Observation

/// Owns authentication state for the app. `session` is the source of truth for
/// "is the user signed in" and is driven by `authStateStream()` (so it survives
/// relaunches once the concrete repository restores persisted auth). `signInState`
/// tracks the in-flight sign-in action for the sign-in screen.
@MainActor
@Observable
public final class AuthViewModel {
    public private(set) var session: User?
    public private(set) var signInState: LoadState<Void, AuthError> = .idle

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

    /// Stops observing auth state.
    public func stop() {
        observationTask?.cancel()
        observationTask = nil
    }

    public func signIn(email: String, password: String) async {
        signInState = .loading
        do {
            try await repository.signIn(email: email, password: password)
            signInState = .loaded(())
        } catch let error as AuthError {
            signInState = .error(error)
        } catch {
            signInState = .error(.unknown)
        }
    }

    public func signOut() async {
        try? await repository.signOut()
    }
}
