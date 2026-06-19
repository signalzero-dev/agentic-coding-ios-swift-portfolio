import Foundation
import Testing
@testable import NetworkKit

struct EndpointTests {
    @Test
    func buildsGETURLRequestWithQueryItems() throws {
        let endpoint = Endpoint(
            path: "/movie/popular",
            method: .get,
            queryItems: [
                URLQueryItem(name: "language", value: "en-US"),
                URLQueryItem(name: "page", value: "1")
            ]
        )
        let base = try #require(URL(string: "https://api.themoviedb.org/3"))

        let request = try endpoint.urlRequest(relativeTo: base)

        #expect(request.url?.absoluteString == "https://api.themoviedb.org/3/movie/popular?language=en-US&page=1")
        #expect(request.httpMethod == "GET")
    }

    @Test
    func appliesHeadersToURLRequest() throws {
        let endpoint = Endpoint(
            path: "/movie/popular",
            method: .get,
            headers: [
                "Authorization": "Bearer token",
                "Accept": "application/json"
            ]
        )
        let base = try #require(URL(string: "https://api.themoviedb.org/3"))

        let request = try endpoint.urlRequest(relativeTo: base)

        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer token")
        #expect(request.value(forHTTPHeaderField: "Accept") == "application/json")
    }

    @Test
    func attachesBodyToPOSTURLRequest() throws {
        let payload = Data("{\"title\":\"hello\"}".utf8)
        let endpoint = Endpoint(
            path: "/posts",
            method: .post,
            body: payload
        )
        let base = try #require(URL(string: "https://api.themoviedb.org/3"))

        let request = try endpoint.urlRequest(relativeTo: base)

        #expect(request.httpMethod == "POST")
        #expect(request.httpBody == payload)
    }
}
