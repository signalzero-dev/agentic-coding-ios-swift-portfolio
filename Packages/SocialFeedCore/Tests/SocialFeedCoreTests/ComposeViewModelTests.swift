import Testing
import Foundation
@testable import SocialFeedCore

@MainActor
struct ComposeViewModelTests {

    private func makeViewModel(
        post: MockPostRepository = .init(),
        storage: MockStorageRepository = .init()
    ) -> ComposeViewModel {
        ComposeViewModel(postRepository: post, storageRepository: storage)
    }

    @Test func blankTextIsRejectedWithoutCallingRepositories() async {
        let post = MockPostRepository()
        let storage = MockStorageRepository()
        let viewModel = makeViewModel(post: post, storage: storage)
        viewModel.text = "   \n  "

        await viewModel.submit(imageData: nil)

        #expect(viewModel.submitState.failure == .emptyText)
        #expect(post.created.isEmpty)
        #expect(storage.uploadCount == 0)
        #expect(viewModel.didPost == false)
    }

    @Test func textOnlyPostCreatesWithTrimmedTextAndNoImage() async {
        let post = MockPostRepository()
        let viewModel = makeViewModel(post: post)
        viewModel.text = "  hello world  "

        await viewModel.submit(imageData: nil)

        #expect(post.created.count == 1)
        #expect(post.created.first?.text == "hello world")
        #expect(post.created.first?.imageURL == nil)
        #expect(viewModel.didPost == true)
        #expect(viewModel.submitState.failure == nil)
    }

    @Test func imagePostUploadsThenCreatesWithReturnedURL() async throws {
        let uploaded = try #require(URL(string: "https://cdn.example.com/img.jpg"))
        let post = MockPostRepository()
        let storage = MockStorageRepository()
        storage.result = .success(uploaded)
        let viewModel = makeViewModel(post: post, storage: storage)
        viewModel.text = "with photo"

        await viewModel.submit(imageData: Data([0x1, 0x2]))

        #expect(storage.uploadCount == 1)
        #expect(post.created.first?.imageURL == uploaded)
        #expect(viewModel.didPost == true)
    }

    @Test func uploadFailureSurfacesAndSkipsCreate() async {
        let post = MockPostRepository()
        let storage = MockStorageRepository()
        storage.result = .failure(MockError.boom)
        let viewModel = makeViewModel(post: post, storage: storage)
        viewModel.text = "with photo"

        await viewModel.submit(imageData: Data([0x1]))

        #expect(viewModel.submitState.failure == .uploadFailed)
        #expect(post.created.isEmpty)
        #expect(viewModel.didPost == false)
    }

    @Test func createFailureSurfaces() async {
        let post = MockPostRepository()
        post.error = MockError.boom
        let viewModel = makeViewModel(post: post)
        viewModel.text = "oops"

        await viewModel.submit(imageData: nil)

        #expect(viewModel.submitState.failure == .postFailed)
        #expect(viewModel.didPost == false)
    }

    enum MockError: Error { case boom }
}
