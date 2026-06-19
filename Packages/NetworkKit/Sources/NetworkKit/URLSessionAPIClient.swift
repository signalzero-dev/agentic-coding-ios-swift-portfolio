import Foundation

public final class URLSessionAPIClient: APIClientProtocol {
    private let baseURL: URL
    private let session: URLSession
    private let defaultHeaders: [String: String]

    public init(
        baseURL: URL,
        session: URLSession = .shared,
        defaultHeaders: [String: String] = [:]
    ) {
        self.baseURL = baseURL
        self.session = session
        self.defaultHeaders = defaultHeaders
    }

    public func send(_ endpoint: Endpoint) async throws -> (Data, HTTPURLResponse) {
        var request = try endpoint.urlRequest(relativeTo: baseURL)
        for (field, value) in defaultHeaders where request.value(forHTTPHeaderField: field) == nil {
            request.setValue(value, forHTTPHeaderField: field)
        }
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        return (data, http)
    }
}
