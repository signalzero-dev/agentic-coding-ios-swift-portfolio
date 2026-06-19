import Foundation
import NetworkKit

public final class MovieService: MovieServiceProtocol {
    private let client: any APIClientProtocol
    private let decoder: JSONDecoder

    public init(client: any APIClientProtocol) {
        self.client = client
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        self.decoder = decoder
    }

    public func popular(page: Int) async throws -> MoviePage {
        try await perform(Endpoint(
            path: "/movie/popular",
            method: .get,
            queryItems: [URLQueryItem(name: "page", value: String(page))]
        ))
    }

    public func search(query: String, page: Int) async throws -> MoviePage {
        try await perform(Endpoint(
            path: "/search/movie",
            method: .get,
            queryItems: [
                URLQueryItem(name: "query", value: query),
                URLQueryItem(name: "page", value: String(page))
            ]
        ))
    }

    public func details(id: Int) async throws -> MovieDetails {
        try await perform(Endpoint(
            path: "/movie/\(id)",
            method: .get
        ))
    }

    private func perform<T: Decodable & Sendable>(_ endpoint: Endpoint) async throws -> T {
        let data: Data
        let response: HTTPURLResponse
        do {
            (data, response) = try await client.send(endpoint)
        } catch {
            throw MovieServiceError.transport(error)
        }
        if response.statusCode == 404 {
            throw MovieServiceError.notFound
        }
        if response.statusCode == 429 {
            throw MovieServiceError.rateLimited
        }
        if (500...599).contains(response.statusCode) {
            throw MovieServiceError.server(response.statusCode)
        }
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw MovieServiceError.decoding(error)
        }
    }
}
