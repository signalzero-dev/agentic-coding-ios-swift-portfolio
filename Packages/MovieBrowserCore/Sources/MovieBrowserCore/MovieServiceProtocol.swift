import Foundation

public protocol MovieServiceProtocol: Sendable {
    func popular(page: Int) async throws -> MoviePage
    func search(query: String, page: Int) async throws -> MoviePage
    func details(id: Int) async throws -> MovieDetails
}
