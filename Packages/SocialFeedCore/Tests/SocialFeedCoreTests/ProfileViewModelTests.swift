import Testing
@testable import SocialFeedCore

@MainActor
struct ProfileViewModelTests {

    @Test func startStreamsTheUsersPosts() async {
        let user = User(id: "u1", displayName: "Ada")
        let repo = MockProfileRepository()
        let viewModel = ProfileViewModel(user: user, repository: repo)

        viewModel.start()
        #expect(viewModel.state == .loading)

        let posts = [Post.sample(id: "p1"), Post.sample(id: "p2")]
        repo.emit(posts)
        await waitFor { viewModel.state == .loaded(posts) }

        #expect(viewModel.state == .loaded(posts))
        #expect(repo.requestedUserID == "u1")
    }

    @Test func streamFailureTransitionsToError() async {
        let repo = MockProfileRepository()
        let viewModel = ProfileViewModel(user: User(id: "u1", displayName: "Ada"), repository: repo)

        viewModel.start()
        repo.fail(FeedError.unavailable)
        await waitFor { viewModel.state == .error(.unavailable) }

        #expect(viewModel.state == .error(.unavailable))
    }
}
