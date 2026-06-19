import Foundation
import Testing
@testable import MovieBrowserCore

struct MovieTests {
    @Test
    func decodesTMDBPopularListItem() throws {
        let json = Data("""
        {
            "id": 550,
            "title": "Fight Club",
            "overview": "A ticking-time-bomb insomniac and a slippery soap salesman channel primal male aggression.",
            "poster_path": "/abc.jpg"
        }
        """.utf8)
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        let movie = try decoder.decode(Movie.self, from: json)

        #expect(movie.id == 550)
        #expect(movie.title == "Fight Club")
        #expect(movie.overview == "A ticking-time-bomb insomniac and a slippery soap salesman channel primal male aggression.")
        #expect(movie.posterPath == "/abc.jpg")
    }

    @Test
    func decodesMovieWithNullPosterPath() throws {
        let json = Data("""
        {
            "id": 999,
            "title": "Obscure Film",
            "overview": "Unknown.",
            "poster_path": null
        }
        """.utf8)
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        let movie = try decoder.decode(Movie.self, from: json)

        #expect(movie.id == 999)
        #expect(movie.posterPath == nil)
    }
}
