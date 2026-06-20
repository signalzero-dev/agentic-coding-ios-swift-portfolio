/// Typed authentication errors. The concrete (later) Firebase implementation maps
/// `AuthErrorCode` values into these; view models never see a Firebase type.
public enum AuthError: Error, Equatable, Sendable {
    case invalidCredentials
    case emailAlreadyInUse
    case weakPassword
    case network
    case unknown
}
