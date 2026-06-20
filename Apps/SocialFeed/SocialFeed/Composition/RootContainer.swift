import SocialFeedCore
import SocialFeedFirebase

/// Composition root: constructs the concrete Firebase repositories and the view
/// models. The view layer depends only on SocialFeedCore protocols/types; Firebase
/// lives entirely behind `SocialFeedFirebase`.
struct RootContainer: Sendable {
    let authRepository: any AuthRepository
    let feedRepository: any FeedRepository
    let likeRepository: any LikeRepository

    static func makeProduction() -> RootContainer {
        RootContainer(
            authRepository: FirebaseAuthRepository(),
            feedRepository: FirestoreFeedRepository(),
            likeRepository: FirestoreLikeRepository()
        )
    }

    @MainActor
    func makeAuthViewModel() -> AuthViewModel {
        AuthViewModel(repository: authRepository)
    }

    @MainActor
    func makeFeedViewModel() -> FeedViewModel {
        FeedViewModel(feedRepository: feedRepository, likeRepository: likeRepository)
    }
}
