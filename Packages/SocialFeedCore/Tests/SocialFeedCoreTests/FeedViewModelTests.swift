import Testing
@testable import SocialFeedCore

@MainActor
struct FeedViewModelTests {

    @Test func startEntersLoadingThenLoadedEmptyOnEmptyEmission() async {
        let repo = MockFeedRepository()
        let viewModel = FeedViewModel(repository: repo)

        viewModel.start()
        #expect(viewModel.state == .loading)

        repo.emit([])
        await waitFor { viewModel.state == .loaded([]) }
        #expect(viewModel.state == .loaded([]))
    }

    @Test func subsequentEmissionsUpdateStateInPlace() async {
        let repo = MockFeedRepository()
        let viewModel = FeedViewModel(repository: repo)
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
        let viewModel = FeedViewModel(repository: repo)

        viewModel.start()
        repo.fail(FeedError.permissionDenied)

        await waitFor { viewModel.state == .error(.permissionDenied) }
        #expect(viewModel.state == .error(.permissionDenied))
    }

    @Test func stopHaltsConsumptionSoLaterEmissionsAreIgnored() async {
        let repo = MockFeedRepository()
        let viewModel = FeedViewModel(repository: repo)

        viewModel.start()
        repo.emit([Post.sample(id: "1")])
        await waitFor { viewModel.state.value?.count == 1 }
        #expect(viewModel.state.value?.count == 1)

        viewModel.stop()
        repo.emit([Post.sample(id: "1"), Post.sample(id: "2")])
        // Give any (incorrectly still-running) consumer a chance to update.
        await waitFor(timeout: .milliseconds(200)) { viewModel.state.value?.count == 2 }
        #expect(viewModel.state.value?.count == 1)
    }
}
