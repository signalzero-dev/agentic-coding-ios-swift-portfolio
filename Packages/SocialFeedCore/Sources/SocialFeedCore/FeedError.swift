/// Typed errors surfaced by the feed. The concrete (later) Firebase
/// implementation maps Firestore failures into these cases; view models and
/// views never see a Firebase type.
public enum FeedError: Error, Equatable, Sendable {
    case unavailable
    case permissionDenied
    case unknown
}
