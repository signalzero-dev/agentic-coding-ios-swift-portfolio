import Foundation
import SocialFeedCore

/// Test double for `HTMLLoading` — returns canned HTML or a canned error.
struct MockHTMLLoader: HTMLLoading {
    let result: Result<Data, MockError>

    init(html: String) { result = .success(Data(html.utf8)) }
    init(error: MockError) { result = .failure(error) }

    func loadHTML(from url: URL) async throws -> Data {
        try result.get()
    }

    enum MockError: Error { case offline }
}
