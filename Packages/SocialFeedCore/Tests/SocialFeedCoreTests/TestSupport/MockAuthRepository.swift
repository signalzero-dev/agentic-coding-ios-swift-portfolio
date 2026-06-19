import SocialFeedCore

/// Test double for `AuthRepository`. The test drives the auth-state stream via
/// `emitAuthState(_:)` and stubs the sign-in outcome via `signInResult`.
final class MockAuthRepository: AuthRepository, @unchecked Sendable {
    private let authStream: AsyncStream<User?>
    private let authContinuation: AsyncStream<User?>.Continuation

    /// Outcome the next `signIn` call should produce.
    var signInResult: Result<User, AuthError> = .failure(.unknown)
    private(set) var signOutCalled = false

    init() {
        (authStream, authContinuation) = AsyncStream.makeStream(of: User?.self)
    }

    func authStateStream() -> AsyncStream<User?> { authStream }

    /// Push an auth-state change to the observer.
    func emitAuthState(_ user: User?) { authContinuation.yield(user) }

    @discardableResult
    func signIn(email: String, password: String) async throws -> User {
        switch signInResult {
        case .success(let user):
            // Mimic Firebase: a successful sign-in fires the auth-state listener.
            authContinuation.yield(user)
            return user
        case .failure(let error):
            throw error
        }
    }

    func signOut() async throws {
        signOutCalled = true
        authContinuation.yield(nil)
    }
}
