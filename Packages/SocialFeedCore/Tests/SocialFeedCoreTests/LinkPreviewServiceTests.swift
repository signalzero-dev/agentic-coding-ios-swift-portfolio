import Testing
import Foundation
@testable import SocialFeedCore

struct LinkPreviewServiceTests {

    @Test func parsesOpenGraphTagsIntoPreview() async throws {
        let url = try #require(URL(string: "https://example.com/article"))
        let html = """
        <html><head>
        <meta property="og:title" content="The Title">
        <meta property="og:description" content="A description.">
        <meta property="og:image" content="https://example.com/img.png">
        </head><body></body></html>
        """
        let service = LinkPreviewService(loader: MockHTMLLoader(html: html))

        let preview = try await service.preview(for: url)

        #expect(preview.url == url)
        #expect(preview.title == "The Title")
        #expect(preview.description == "A description.")
        #expect(preview.imageURL == URL(string: "https://example.com/img.png"))
    }

    @Test func leavesMissingTagsNil() async throws {
        let url = try #require(URL(string: "https://example.com"))
        let html = #"<head><meta property="og:title" content="Only Title"></head>"#
        let service = LinkPreviewService(loader: MockHTMLLoader(html: html))

        let preview = try await service.preview(for: url)

        #expect(preview.title == "Only Title")
        #expect(preview.description == nil)
        #expect(preview.imageURL == nil)
    }

    @Test func parsesRegardlessOfAttributeOrderAndQuoteStyle() async throws {
        let url = try #require(URL(string: "https://example.com"))
        // content before property; single quotes.
        let html = "<meta content='Reversed' property='og:title'>"
        let service = LinkPreviewService(loader: MockHTMLLoader(html: html))

        let preview = try await service.preview(for: url)

        #expect(preview.title == "Reversed")
    }

    @Test func throwsNoMetadataWhenNoOpenGraphTags() async throws {
        let url = try #require(URL(string: "https://example.com"))
        let html = "<html><head><title>Plain</title></head><body>hi</body></html>"
        let service = LinkPreviewService(loader: MockHTMLLoader(html: html))

        await #expect(throws: LinkPreviewError.noMetadata) {
            try await service.preview(for: url)
        }
    }

    @Test func throwsFetchFailedWhenLoaderThrows() async throws {
        let url = try #require(URL(string: "https://example.com"))
        let service = LinkPreviewService(loader: MockHTMLLoader(error: .offline))

        await #expect(throws: LinkPreviewError.fetchFailed) {
            try await service.preview(for: url)
        }
    }
}
