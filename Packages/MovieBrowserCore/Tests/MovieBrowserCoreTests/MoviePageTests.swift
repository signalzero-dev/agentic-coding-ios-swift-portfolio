import Foundation
import Testing
@testable import MovieBrowserCore

struct MoviePageTests {
    @Test
    func decodesTMDBPaginatedPopularResponse() throws {
        let json = Data("""
        {
            "page": 1,
            "results": [
                {
                    "id": 550,
                    "title": "Fight Club",
                    "overview": "Insomniac office worker.",
                    "poster_path": "/abc.jpg"
                },
                {
                    "id": 13,
                    "title": "Forrest Gump",
                    "overview": "Life is like a box of chocolates.",
                    "poster_path": "/def.jpg"
                }
            ],
            "total_pages": 500,
            "total_results": 10000
        }
        """.utf8)
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        let page = try decoder.decode(MoviePage.self, from: json)

        #expect(page.page == 1)
        #expect(page.totalPages == 500)
        #expect(page.totalResults == 10000)
        #expect(page.results.count == 2)
        #expect(page.results[0].id == 550)
        #expect(page.results[1].title == "Forrest Gump")
    }
}
