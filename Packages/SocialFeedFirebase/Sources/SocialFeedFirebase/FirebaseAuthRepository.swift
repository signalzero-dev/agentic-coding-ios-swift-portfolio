@preconcurrency import FirebaseAuth
import Foundation
import SocialFeedCore

/// Firebase-backed `AuthRepository`. Maps Firebase Auth's listener + async APIs
/// and `AuthErrorCode`s onto SocialFeedCore's domain types, so view models never
/// see a Firebase symbol.
public final class FirebaseAuthRepository: AuthRepository, @unchecked Sendable {
    public init() {}

    public func authStateStream() -> AsyncStream<SocialFeedCore.User?> {
        AsyncStream { continuation in
            // The handle is captured by the @Sendable onTermination closure; it is
            // only ever touched on the main thread by Firebase.
            nonisolated(unsafe) let handle = Auth.auth().addStateDidChangeListener { _, firebaseUser in
                continuation.yield(firebaseUser.map(Self.domainUser))
            }
            continuation.onTermination = { _ in
                Auth.auth().removeStateDidChangeListener(handle)
            }
        }
    }

    public func signIn(email: String, password: String) async throws -> SocialFeedCore.User {
        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            return Self.domainUser(result.user)
        } catch {
            throw Self.authError(from: error)
        }
    }

    public func signOut() async throws {
        do {
            try Auth.auth().signOut()
        } catch {
            throw AuthError.unknown
        }
    }

    private static func domainUser(_ user: FirebaseAuth.User) -> SocialFeedCore.User {
        SocialFeedCore.User(
            id: user.uid,
            displayName: user.displayName ?? user.email ?? "User",
            photoURL: user.photoURL
        )
    }

    private static func authError(from error: Error) -> AuthError {
        guard let code = AuthErrorCode(rawValue: (error as NSError).code) else { return .unknown }
        switch code {
        case .wrongPassword, .invalidCredential, .userNotFound, .invalidEmail, .userDisabled:
            return .invalidCredentials
        case .networkError:
            return .network
        default:
            return .unknown
        }
    }
}
