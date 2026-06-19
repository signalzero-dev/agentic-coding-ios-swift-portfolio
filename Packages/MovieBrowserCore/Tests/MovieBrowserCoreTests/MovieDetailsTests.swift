import Foundation
import Testing
@testable import MovieBrowserCore

struct MovieDetailsTests {
    @Test
    func decodesTMDBMovieDetails() throws {
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
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        let details = try decoder.decode(MovieDetails.self, from: json)

        #expect(details.id == 550)
        #expect(details.title == "Fight Club")
        #expect(details.overview == "Insomniac.")
        #expect(details.posterPath == "/abc.jpg")
        #expect(details.runtime == 139)
        #expect(details.tagline == "Mischief. Mayhem. Soap.")
    }
}
