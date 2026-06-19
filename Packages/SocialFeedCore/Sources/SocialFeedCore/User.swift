import Foundation

/// An authenticated user. Pure domain model — no Firebase types.
public struct User: Identifiable, Equatable, Sendable {
    public let id: String
    public let displayName: String
    public let photoURL: URL?

    public init(id: String, displayName: String, photoURL: URL? = nil) {
        self.id = id
        self.displayName = displayName
        self.photoURL = photoURL
    }
}
