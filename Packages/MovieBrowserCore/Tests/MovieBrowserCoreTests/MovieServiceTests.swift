import Foundation
import Testing
import NetworkKit
@testable import MovieBrowserCore

struct MovieServiceTests {
    @Test
    func popularReturnsDecodedPageOn200() async throws {
        let json = Data("""
        {
            "page": 2,
            "results": [
                {
                    "id": 550,
                    "title": "Fight Club",
                    "overview": "Insomniac.",
                    "poster_path": "/abc.jpg"
                }
            ],
            "total_pages": 500,
            "total_results": 10000
        }
        """.utf8)
        let stubURL = try #require(URL(string: "https://api.themoviedb.org/3/movie/popular"))
        let httpResponse = try #require(HTTPURLResponse(
            url: stubURL,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        ))

        let mockClient = MockAPIClient()
        mockClient.stub(data: json, response: httpResponse)

        let service = MovieService(client: mockClient)

        let page = try await service.popular(page: 2)

        #expect(page.page == 2)
        #expect(page.totalPages == 500)
        #expect(page.results.first?.title == "Fight Club")

        let captured = try #require(mockClient.lastEndpoint)
        #expect(captured.path == "/movie/popular")
        #expect(captured.method == .get)
        #expect(captured.queryItems.contains(URLQueryItem(name: "page", value: "2")))
    }

    @Test
    func popularThrowsNotFoundOn404() async throws {
        let stubURL = try #require(URL(string: "https://api.themoviedb.org/3/movie/popular"))
        let httpResponse = try #require(HTTPURLResponse(
            url: stubURL,
            statusCode: 404,
            httpVersion: nil,
            headerFields: nil
        ))
        let mockClient = MockAPIClient()
        mockClient.stub(data: Data(), response: httpResponse)

        let service = MovieService(client: mockClient)

        do {
            _ = try await service.popular(page: 1)
            Issue.record("Expected MovieServiceError.notFound to be thrown")
        } catch MovieServiceError.notFound {
            // expected
        } catch {
            Issue.record("Expected MovieServiceError.notFound, got: \(error)")
        }
    }

    @Test
    func popularThrowsRateLimitedOn429() async throws {
        let stubURL = try #require(URL(string: "https://api.themoviedb.org/3/movie/popular"))
        let httpResponse = try #require(HTTPURLResponse(
            url: stubURL,
            statusCode: 429,
            httpVersion: nil,
            headerFields: nil
        ))
        let mockClient = MockAPIClient()
        mockClient.stub(data: Data(), response: httpResponse)

        let service = MovieService(client: mockClient)

        do {
            _ = try await service.popular(page: 1)
            Issue.record("Expected MovieServiceError.rateLimited to be thrown")
        } catch MovieServiceError.rateLimited {
            // expected
        } catch {
            Issue.record("Expected MovieServiceError.rateLimited, got: \(error)")
        }
    }

    @Test
    func popularThrowsServerErrorWithStatusCodeOn5xx() async throws {
        let stubURL = try #require(URL(string: "https://api.themoviedb.org/3/movie/popular"))
        let httpResponse = try #require(HTTPURLResponse(
            url: stubURL,
            statusCode: 503,
            httpVersion: nil,
            headerFields: nil
        ))
        let mockClient = MockAPIClient()
        mockClient.stub(data: Data(), response: httpResponse)

        let service = MovieService(client: mockClient)

        do {
            _ = try await service.popular(page: 1)
            Issue.record("Expected MovieServiceError.server(503) to be thrown")
        } catch MovieServiceError.server(let code) {
            #expect(code == 503)
        } catch {
            Issue.record("Expected MovieServiceError.server, got: \(error)")
        }
    }

    @Test
    func popularThrowsDecodingErrorOnMalformedJSON() async throws {
        let badJSON = Data("not valid json".utf8)
        let stubURL = try #require(URL(string: "https://api.themoviedb.org/3/movie/popular"))
        let httpResponse = try #require(HTTPURLResponse(
            url: stubURL,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        ))
        let mockClient = MockAPIClient()
        mockClient.stub(data: badJSON, response: httpResponse)

        let service = MovieService(client: mockClient)

        do {
            _ = try await service.popular(page: 1)
            Issue.record("Expected MovieServiceError.decoding to be thrown")
        } catch MovieServiceError.decoding {
            // expected
        } catch {
            Issue.record("Expected MovieServiceError.decoding, got: \(error)")
        }
    }

    @Test
    func popularThrowsTransportErrorWhenClientFails() async throws {
        let mockClient = MockAPIClient()
        mockClient.stub(error: URLError(.notConnectedToInternet))

        let service = MovieService(client: mockClient)

        do {
            _ = try await service.popular(page: 1)
            Issue.record("Expected MovieServiceError.transport to be thrown")
        } catch MovieServiceError.transport {
            // expected
        } catch {
            Issue.record("Expected MovieServiceError.transport, got: \(error)")
        }
    }

    @Test
    func searchReturnsDecodedPageAndHitsTMDBSearchEndpoint() async throws {
        let json = Data("""
        {
            "page": 1,
            "results": [
                {
                    "id": 550,
                    "title": "Fight Club",
                    "overview": "Insomniac.",
                    "poster_path": "/abc.jpg"
                }
            ],
            "total_pages": 1,
            "total_results": 1
        }
        """.utf8)
        let stubURL = try #require(URL(string: "https://api.themoviedb.org/3/search/movie"))
        let httpResponse = try #require(HTTPURLResponse(
            url: stubURL,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        ))
        let mockClient = MockAPIClient()
        mockClient.stub(data: json, response: httpResponse)

        let service = MovieService(client: mockClient)

        let page = try await service.search(query: "fight", page: 1)

        #expect(page.page == 1)
        #expect(page.results.first?.title == "Fight Club")

        let captured = try #require(mockClient.lastEndpoint)
        #expect(captured.path == "/search/movie")
        #expect(captured.method == .get)
        #expect(captured.queryItems.contains(URLQueryItem(name: "query", value: "fight")))
        #expect(captured.queryItems.contains(URLQueryItem(name: "page", value: "1")))
    }

    @Test
    func detailsReturnsDecodedMovieDetailsAndHitsCorrectPath() async throws {
        let json = Data("""
        {
            "id": 550,
            "title": "Fight Club",
            "overview": "Insomniac.",
            "poster_path": "/abc.jpg",
            "runtime": 139,
            "tagline": "Mischief. Mayhem. Soap."
        }
        """.utf8)
        let stubURL = try #require(URL(string: "https://api.themoviedb.org/3/movie/550"))
        let httpResponse = try #require(HTTPURLResponse(
            url: stubURL,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        ))
        let mockClient = MockAPIClient()
        mockClient.stub(data: json, response: httpResponse)

        let service = MovieService(client: mockClient)

        let details = try await service.details(id: 550)

        #expect(details.id == 550)
        #expect(details.title == "Fight Club")
        #expect(details.runtime == 139)
        #expect(details.tagline == "Mischief. Mayhem. Soap.")

        let captured = try #require(mockClient.lastEndpoint)
        #expect(captured.path == "/movie/550")
        #expect(captured.method == .get)
    }
}
