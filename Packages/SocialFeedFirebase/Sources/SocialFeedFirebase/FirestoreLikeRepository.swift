@preconcurrency import FirebaseFirestore
@preconcurrency import FirebaseAuth
import Foundation
import SocialFeedCore

/// Firebase-backed `LikeRepository`. Adds/removes the current user's ID in the
/// post's `likedBy` array and adjusts `likeCount` atomically. The feed's snapshot
/// listener then emits the authoritative state, superseding the optimistic UI.
public final class FirestoreLikeRepository: LikeRepository, @unchecked Sendable {
    private let collectionPath: String

    public init(collectionPath: String = "posts") {
        self.collectionPath = collectionPath
    }

    public func setLike(postID: String, liked: Bool) async throws {
        guard let uid = Auth.auth().currentUser?.uid else {
            throw FirebaseRepositoryError.notAuthenticated
        }
        let ref = Firestore.firestore().collection(collectionPath).document(postID)
        let update: [String: Any] = liked
            ? ["likedBy": FieldValue.arrayUnion([uid]), "likeCount": FieldValue.increment(Int64(1))]
            : ["likedBy": FieldValue.arrayRemove([uid]), "likeCount": FieldValue.increment(Int64(-1))]
        try await ref.updateData(update)
    }
}

enum FirebaseRepositoryError: Error {
    case notAuthenticated
}
