import Testing
@testable import SocialFeedCore

@MainActor
struct FeedViewModelTests {

    @Test func startEntersLoadingThenLoadedEmptyOnEmptyEmission() async {
        let repo = MockFeedRepository()
        let viewModel = FeedViewModel(feedRepository: repo, likeRepository: MockLikeRepository())

        viewModel.start()
        #expect(viewModel.state == .loading)

        repo.emit([])
        await waitFor { viewModel.state == .loaded([]) }
        #expect(viewModel.state == .loaded([]))
    }

    @Test func subsequentEmissionsUpdateStateInPlace() async {
        let repo = MockFeedRepository()
        let viewModel = FeedViewModel(feedRepository: repo, likeRepository: MockLikeRepository())
        let first = [Post.sample(id: "1")]
        let second = [Post.sample(id: "1"), Post.sample(id: "2")]

        viewModel.start()

        repo.emit(first)
        await waitFor { viewModel.state == .loaded(first) }
        #expect(viewModel.state == .loaded(first))

        repo.emit(second)
        await waitFor { viewModel.state == .loaded(second) }
        #expect(viewModel.state == .loaded(second))
    }

    @Test func streamFailureTransitionsStateToError() async {
        let repo = MockFeedRepository()
        let viewModel = FeedViewModel(feedRepository: repo, likeRepository: MockLikeRepository())

        viewModel.start()
        repo.fail(FeedError.permissionDenied)

        await waitFor { viewModel.state == .error(.permissionDenied) }
        #expect(viewModel.state == .error(.permissionDenied))
    }

    @Test func stopHaltsConsumptionSoLaterEmissionsAreIgnored() async {
        let repo = MockFeedRepository()
        let viewModel = FeedViewModel(feedRepository: repo, likeRepository: MockLikeRepository())

        viewModel.start()
        repo.emit([Post.sample(id: "1")])
        await waitFor { viewModel.state.value?.count == 1 }
        #expect(viewModel.state.value?.count == 1)

        await viewModel.stop() // returns only once consumption has fully stopped
        repo.emit([Post.sample(id: "1"), Post.sample(id: "2")])
        #expect(viewModel.state.value?.count == 1)
    }

    // MARK: - Optimistic likes

    @Test func toggleLikeOptimisticallyFlipsPostImmediately() async {
        let feed = MockFeedRepository()
        let viewModel = FeedViewModel(feedRepository: feed, likeRepository: MockLikeRepository())
        let post = Post.sample(id: "1") // likedByCurrentUser: false, likeCount: 0
        viewModel.start()
        feed.emit([post])
        await waitFor { viewModel.state == .loaded([post]) }

        await viewModel.toggleLike(post)

        let updated = viewModel.state.value?.first
        #expect(updated?.likedByCurrentUser == true)
        #expect(updated?.likeCount == 1)
    }

    @Test func toggleLikeCallsRepositoryWithNewLikeState() async {
        let feed = MockFeedRepository()
        let like = MockLikeRepository()
        let viewModel = FeedViewModel(feedRepository: feed, likeRepository: like)
        let post = Post.sample(id: "42")
        viewModel.start()
        feed.emit([post])
        await waitFor { viewModel.state == .loaded([post]) }

        await viewModel.toggleLike(post)

        #expect(like.calls.count == 1)
        #expect(like.calls.first?.postID == "42")
        #expect(like.calls.first?.liked == true)
    }

    @Test func toggleLikeRollsBackWhenRepositoryFails() async {
        let feed = MockFeedRepository()
        let like = MockLikeRepository()
        like.error = FeedError.unknown
        let viewModel = FeedViewModel(feedRepository: feed, likeRepository: like)
        let post = Post.sample(id: "1") // liked: false, count: 0
        viewModel.start()
        feed.emit([post])
        await waitFor { viewModel.state == .loaded([post]) }

        await viewModel.toggleLike(post)

        // Optimistic change reverted after the failure.
        let reverted = viewModel.state.value?.first
        #expect(reverted?.likedByCurrentUser == false)
        #expect(reverted?.likeCount == 0)
    }
}
