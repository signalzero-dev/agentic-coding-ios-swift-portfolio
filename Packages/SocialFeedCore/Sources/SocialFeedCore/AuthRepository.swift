/// Abstraction over authentication. The concrete implementation
/// (SocialFeedFirebase) wraps Firebase Auth; tests inject a mock. The auth-state
/// stream keeps session observation Combine-free.
///
/// `signInWithApple` is intentionally absent here — it's added in the
/// Sign-in-with-Apple increment alongside the app-layer credential/nonce handling.
public protocol AuthRepository: Sendable {
    /// Emits the current user on subscription and again whenever auth state
    /// changes (sign-in / sign-out / token refresh). `nil` means signed out.
    func authStateStream() -> AsyncStream<User?>

    @discardableResult
    func signIn(email: String, password: String) async throws -> User

    func signOut() async throws
}
