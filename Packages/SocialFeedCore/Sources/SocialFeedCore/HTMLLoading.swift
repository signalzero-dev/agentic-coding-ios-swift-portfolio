import Foundation

/// Fetches the raw HTML at a URL. The concrete implementation (app/composition
/// layer) uses URLSession (via NetworkKit) to load an arbitrary absolute URL;
/// keeping it behind a protocol lets `LinkPreviewService` be unit-tested with
/// fixture HTML and no network.
public protocol HTMLLoading: Sendable {
    func loadHTML(from url: URL) async throws -> Data
}
