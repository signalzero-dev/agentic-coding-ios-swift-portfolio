import Foundation
import Testing
import Clocks
@testable import MovieBrowserCore

@MainActor
struct SearchMoviesViewModelTests {
    @Test
    func initialStateIsIdle() {
        let service = MockMovieService()
        let viewModel = SearchMoviesViewModel(service: service)

        guard case .idle = viewModel.state else {
            Issue.record("Expected .idle, got \(String(describing: viewModel.state))")
            return
        }
    }

    @Test
    func rapidQueryChangesCollapseToSingleServiceCallWithFinalValue() async {
        let service = MockMovieService()
        let page = MoviePage(page: 1, results: [], totalPages: 1, totalResults: 0)
        service.stubSearch(.success(page))

        let clock = TestClock()
        let viewModel = SearchMoviesViewModel(service: service, clock: clock)

        viewModel.query = "a"
        viewModel.query = "ap"
        viewModel.query = "app"
        viewModel.query = "appl"
        viewModel.query = "apple"

        // Let queued Tasks start and register their sleeps with the TestClock.
        for _ in 0..<10 { await Task.yield() }

        // Advance past the 300ms debounce window.
        await clock.advance(by: .milliseconds(301))

        // Let the resumed sleep complete and the service call land.
        for _ in 0..<20 { await Task.yield() }

        #expect(service.searchCallCount == 1)
        #expect(service.lastSearchQuery == "apple")
    }

    @Test
    func successfulSearchTransitionsStateToLoaded() async {
        let movies = [Movie(id: 1, title: "Apple", overview: "", posterPath: "/a.jpg")]
        let page = MoviePage(page: 1, results: movies, totalPages: 1, totalResults: 1)
        let service = MockMovieService()
        service.stubSearch(.success(page))

        let clock = TestClock()
        let viewModel = SearchMoviesViewModel(service: service, clock: clock)

        viewModel.query = "apple"
        for _ in 0..<10 { await Task.yield() }
        await clock.advance(by: .milliseconds(301))
        for _ in 0..<20 { await Task.yield() }

        guard case .loaded(let result) = viewModel.state else {
            Issue.record("Expected .loaded, got \(String(describing: viewModel.state))")
            return
        }
        #expect(result.count == 1)
        #expect(result.first?.id == 1)
    }

    @Test
    func failedSearchTransitionsStateToError() async {
        let service = MockMovieService()
        service.stubSearch(.failure(.rateLimited))

        let clock = TestClock()
        let viewModel = SearchMoviesViewModel(service: service, clock: clock)

        viewModel.query = "apple"
        for _ in 0..<10 { await Task.yield() }
        await clock.advance(by: .milliseconds(301))
        for _ in 0..<20 { await Task.yield() }

        guard case .error(let err) = viewModel.state else {
            Issue.record("Expected .error, got \(String(describing: viewModel.state))")
            return
        }
        guard case .rateLimited = err else {
            Issue.record("Expected .rateLimited, got \(String(describing: err))")
            return
        }
    }

    @Test
    func emptyQueryDoesNotTriggerServiceCall() async {
        let service = MockMovieService()
        let page = MoviePage(page: 1, results: [], totalPages: 1, totalResults: 0)
        service.stubSearch(.success(page))

        let clock = TestClock()
        let viewModel = SearchMoviesViewModel(service: service, clock: clock)

        viewModel.query = ""

        for _ in 0..<10 { await Task.yield() }
        await clock.advance(by: .milliseconds(301))
        for _ in 0..<20 { await Task.yield() }

        #expect(service.searchCallCount == 0)
    }
}
