import Foundation
import MovieBrowserCore
import NetworkKit

struct RootContainer {
    let movieService: any MovieServiceProtocol

    static func makeProduction() throws -> RootContainer {
        let token = try Secrets.tmdbBearerToken()
        guard let baseURL = URL(string: "https://api.themoviedb.org/3") else {
            throw StartupError.unknown("Invalid TMDB base URL.")
        }
        let client = URLSessionAPIClient(
            baseURL: baseURL,
            defaultHeaders: ["Authorization": "Bearer \(token)"]
        )
        let service = MovieService(client: client)
        return RootContainer(movieService: service)
    }
}

#if DEBUG
extension RootContainer {
    /// Hermetic container for UI tests: in-memory fixtures, no TMDB token, no network.
    /// Activated by launching the app with the `-uiTestStub` argument.
    static func makeUITestStub() -> RootContainer {
        RootContainer(movieService: StubMovieService())
    }
}

/// In-memory `MovieServiceProtocol` backing UI tests. Returns deterministic
/// fixtures decoded from JSON — so the package's real `Decodable` path is
/// exercised — without requiring a TMDB token or any network access.
struct StubMovieService: MovieServiceProtocol {
    func popular(page: Int) async throws -> MoviePage { try Self.decode(Self.popularJSON) }
    func search(query: String, page: Int) async throws -> MoviePage { try Self.decode(Self.searchJSON) }
    func details(id: Int) async throws -> MovieDetails { try Self.decode(Self.detailsJSON) }

    private static func decode<T: Decodable>(_ json: String) throws -> T {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(T.self, from: Data(json.utf8))
    }

    private static let popularJSON = """
    {"page":1,"total_pages":1,"total_results":2,"results":[
      {"id":1,"title":"Stub Popular One","overview":"First stub movie.","poster_path":null},
      {"id":2,"title":"Stub Popular Two","overview":"Second stub movie.","poster_path":null}
    ]}
    """

    private static let searchJSON = """
    {"page":1,"total_pages":1,"total_results":1,"results":[
      {"id":99,"title":"Stub Search Result","overview":"A searched stub movie.","poster_path":null}
    ]}
    """

    private static let detailsJSON = """
    {"id":1,"title":"Stub Detail Title","overview":"Detail overview for the stub movie.",
     "poster_path":"","runtime":100,"tagline":""}
    """
}
#endif
