@preconcurrency import FirebaseFirestore
@preconcurrency import FirebaseAuth
import Foundation
import SocialFeedCore

/// Firebase-backed `ProfileRepository`. Streams one author's posts via a filtered
/// Firestore snapshot listener.
///
/// Note: the `authorID ==` + `createdAt` ordering needs a composite index, which
/// Firestore will prompt you to create (with a one-click link) on first run.
public final class FirestoreProfileRepository: ProfileRepository, @unchecked Sendable {
    private let collectionPath: String

    public init(collectionPath: String = "posts") {
        self.collectionPath = collectionPath
    }

    public func userPostsStream(userID: String) -> AsyncThrowingStream<[Post], Error> {
        AsyncThrowingStream { continuation in
            let currentUserID = Auth.auth().currentUser?.uid
            nonisolated(unsafe) let registration = Firestore.firestore()
                .collection(collectionPath)
                .whereField("authorID", isEqualTo: userID)
                .order(by: "createdAt", descending: true)
                .addSnapshotListener { snapshot, error in
                    if let error {
                        continuation.finish(throwing: FirestorePostMapping.feedError(from: error))
                        return
                    }
                    let documents = snapshot?.documents ?? []
                    let posts = documents.compactMap {
                        FirestorePostMapping.post(from: $0, currentUserID: currentUserID)
                    }
                    continuation.yield(posts)
                }
            continuation.onTermination = { _ in registration.remove() }
        }
    }
}
