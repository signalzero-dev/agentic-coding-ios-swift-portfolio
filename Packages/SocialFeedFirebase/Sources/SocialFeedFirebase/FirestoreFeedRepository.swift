@preconcurrency import FirebaseFirestore
@preconcurrency import FirebaseAuth
import Foundation
import SocialFeedCore

/// Firebase-backed `FeedRepository`. Wraps a Firestore snapshot listener on the
/// `posts` collection in an `AsyncThrowingStream`, mapping documents to `Post`.
///
/// Assumed Firestore schema for a `posts/{id}` document:
/// `authorID: String`, `authorName: String`, `text: String`,
/// `createdAt: Timestamp`, `imageURL: String?`, `likeCount: Int`,
/// `likedBy: [String]` (user IDs).
public final class FirestoreFeedRepository: FeedRepository, @unchecked Sendable {
    private let collectionPath: String

    public init(collectionPath: String = "posts") {
        self.collectionPath = collectionPath
    }

    public func feedStream() -> AsyncThrowingStream<[Post], Error> {
        AsyncThrowingStream { continuation in
            let currentUserID = Auth.auth().currentUser?.uid
            nonisolated(unsafe) let registration = Firestore.firestore()
                .collection(collectionPath)
                .order(by: "createdAt", descending: true)
                .addSnapshotListener { snapshot, error in
                    if let error {
                        continuation.finish(throwing: Self.feedError(from: error))
                        return
                    }
                    let documents = snapshot?.documents ?? []
                    let posts = documents.compactMap { Self.post(from: $0, currentUserID: currentUserID) }
                    continuation.yield(posts)
                }
            continuation.onTermination = { _ in registration.remove() }
        }
    }

    private static func post(from doc: QueryDocumentSnapshot, currentUserID: String?) -> Post? {
        let data = doc.data()
        guard let authorID = data["authorID"] as? String,
              let authorName = data["authorName"] as? String,
              let text = data["text"] as? String,
              let createdAt = data["createdAt"] as? Timestamp else {
            return nil
        }
        let likedBy = data["likedBy"] as? [String] ?? []
        return Post(
            id: doc.documentID,
            authorID: authorID,
            authorName: authorName,
            text: text,
            imageURL: (data["imageURL"] as? String).flatMap { URL(string: $0) },
            createdAt: createdAt.dateValue(),
            likeCount: data["likeCount"] as? Int ?? likedBy.count,
            likedByCurrentUser: currentUserID.map(likedBy.contains) ?? false
        )
    }

    private static func feedError(from error: Error) -> FeedError {
        switch FirestoreErrorCode.Code(rawValue: (error as NSError).code) {
        case .permissionDenied: return .permissionDenied
        case .unavailable: return .unavailable
        default: return .unknown
        }
    }
}
