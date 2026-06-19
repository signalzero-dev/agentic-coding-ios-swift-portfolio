import Foundation
import Testing
@testable import MovieBrowserCore

@MainActor
struct PopularMoviesViewModelTests {
    @Test
    func initialStateIsIdle() {
        let service = MockMovieService()
        let viewModel = PopularMoviesViewModel(service: service)

        guard case .idle = viewModel.state else {
            Issue.record("Expected .idle, got \(String(describing: viewModel.state))")
            return
        }
    }

    @Test
    func loadPopularTransitionsFromIdleToLoadingToLoaded() async {
        let movies = [
            Movie(id: 1, title: "Movie A", overview: "", posterPath: "/a.jpg"),
            Movie(id: 2, title: "Movie B", overview: "", posterPath: "/b.jpg")
        ]
        let page = MoviePage(page: 1, results: movies, totalPages: 1, totalResults: 2)
        let service = MockMovieService()
        service.stubPopular(.success(page))
        service.enablePopularGate()

        let viewModel = PopularMoviesViewModel(service: service)

        // Kick off the load — it'll suspend inside the gated mock.
        let task = Task { await viewModel.loadPopular() }

        // Yield enough times for the Task to start and suspend at the gate.
        for _ in 0..<10 { await Task.yield() }

        guard case .loading = viewModel.state else {
            Issue.record("Expected .loading mid-flight, got \(String(describing: viewModel.state))")
            service.releasePopular()
            _ = await task.value
            return
        }

        service.releasePopular()
        await task.value

        guard case .loaded(let loadedMovies) = viewModel.state else {
            Issue.record("Expected .loaded after completion, got \(String(describing: viewModel.state))")
            return
        }
        #expect(loadedMovies.count == 2)
        #expect(loadedMovies.first?.id == 1)
    }

    @Test
    func loadPopularTransitionsToErrorOnServiceFailure() async {
        let service = MockMovieService()
        service.stubPopular(.failure(.notFound))

        let viewModel = PopularMoviesViewModel(service: service)

        await viewModel.loadPopular()

        guard case .error(let err) = viewModel.state else {
            Issue.record("Expected .error, got \(String(describing: viewModel.state))")
            return
        }
        guard case .notFound = err else {
            Issue.record("Expected .notFound, got \(String(describing: err))")
            return
        }
    }

    @Test
    func loadNextPageAppendsResultsAndTogglesIsLoadingNextPage() async {
        let page1Movies = [Movie(id: 1, title: "A", overview: "", posterPath: "/a.jpg")]
        let page1 = MoviePage(page: 1, results: page1Movies, totalPages: 5, totalResults: 50)
        let page2Movies = [Movie(id: 2, title: "B", overview: "", posterPath: "/b.jpg")]
        let page2 = MoviePage(page: 2, results: page2Movies, totalPages: 5, totalResults: 50)

        let service = MockMovieService()
        service.stubPopular(.success(page1))

        let viewModel = PopularMoviesViewModel(service: service)
        await viewModel.loadPopular()

        // Switch stub to page 2 and gate the next call so we can inspect mid-flight state.
        service.stubPopular(.success(page2))
        service.enablePopularGate()

        let task = Task { await viewModel.loadNextPage() }
        for _ in 0..<10 { await Task.yield() }

        // Mid-flight: state stays .loaded(page1), isLoadingNextPage flips true.
        guard case .loaded(let mid) = viewModel.state else {
            Issue.record("Expected .loaded mid-flight, got \(String(describing: viewModel.state))")
            service.releasePopular()
            _ = await task.value
            return
        }
        #expect(mid.map(\.id) == [1])
        #expect(viewModel.isLoadingNextPage == true)

        service.releasePopular()
        await task.value

        // After completion: state appended, flag reset, page=2 was requested.
        guard case .loaded(let final) = viewModel.state else {
            Issue.record("Expected .loaded after completion, got \(String(describing: viewModel.state))")
            return
        }
        #expect(final.map(\.id) == [1, 2])
        #expect(viewModel.isLoadingNextPage == false)
        #expect(service.popularPagesRequested == [1, 2])
    }

    @Test
    func refreshIsNoOpWhenStateIsIdle() async {
        let service = MockMovieService()
        let page = MoviePage(
            page: 1,
            results: [Movie(id: 1, title: "X", overview: "", posterPath: "/x.jpg")],
            totalPages: 1,
            totalResults: 1
        )
        service.stubPopular(.success(page))

        let viewModel = PopularMoviesViewModel(service: service)
        // State is .idle.

        await viewModel.refresh()

        guard case .idle = viewModel.state else {
            Issue.record("Expected refresh from .idle to stay .idle, got \(String(describing: viewModel.state))")
            return
        }
        #expect(service.popularPagesRequested == [])
    }

    @Test
    func refreshIsNoOpWhenStateIsError() async {
        let service = MockMovieService()
        service.stubPopular(.failure(.notFound))
        let viewModel = PopularMoviesViewModel(service: service)
        await viewModel.loadPopular()
        // State is now .error(.notFound). popularPagesRequested == [1].

        let happyPage = MoviePage(
            page: 1,
            results: [Movie(id: 1, title: "X", overview: "", posterPath: "/x.jpg")],
            totalPages: 1,
            totalResults: 1
        )
        service.stubPopular(.success(happyPage))

        await viewModel.refresh()

        // Refresh must not move .error → .loaded directly.
        guard case .error = viewModel.state else {
            Issue.record("Expected refresh from .error to stay .error, got \(String(describing: viewModel.state))")
            return
        }
        // Service was not re-called by refresh.
        #expect(service.popularPagesRequested == [1])
    }

    @Test
    func refreshKeepsCurrentLoadedDataVisibleInFlightAndReplacesOnCompletion() async {
        let movie1 = Movie(id: 1, title: "Old", overview: "", posterPath: "/a.jpg")
        let movie2 = Movie(id: 2, title: "Fresh", overview: "", posterPath: "/b.jpg")
        let firstPage = MoviePage(page: 1, results: [movie1], totalPages: 5, totalResults: 50)
        let refreshedPage = MoviePage(page: 1, results: [movie2], totalPages: 5, totalResults: 50)

        let service = MockMovieService()
        service.stubPopular(.success(firstPage))
        let viewModel = PopularMoviesViewModel(service: service)
        await viewModel.loadPopular()

        // Switch stub to the refreshed page, then gate the next call so we can inspect mid-flight.
        service.stubPopular(.success(refreshedPage))
        service.enablePopularGate()

        let task = Task { await viewModel.refresh() }
        for _ in 0..<10 { await Task.yield() }

        // Mid-flight: state must still be .loaded([movie1]). Never .loading.
        guard case .loaded(let mid) = viewModel.state else {
            Issue.record("Expected .loaded(old) mid-flight, got \(String(describing: viewModel.state))")
            service.releasePopular()
            _ = await task.value
            return
        }
        #expect(mid.map(\.id) == [1])

        service.releasePopular()
        await task.value

        // After completion: replaced with new data, page count back to 1.
        guard case .loaded(let final) = viewModel.state else {
            Issue.record("Expected .loaded(new) after refresh, got \(String(describing: viewModel.state))")
            return
        }
        #expect(final.map(\.id) == [2])
        #expect(service.popularPagesRequested == [1, 1])
    }

    @Test
    func loadNextPageDedupesAgainstAlreadyLoadedMovies() async {
        let movie1 = Movie(id: 1, title: "A", overview: "", posterPath: "/a.jpg")
        let movie2 = Movie(id: 2, title: "B", overview: "", posterPath: "/b.jpg")
        let movie3 = Movie(id: 3, title: "C", overview: "", posterPath: "/c.jpg")
        let page1 = MoviePage(page: 1, results: [movie1, movie2], totalPages: 5, totalResults: 50)
        // movie2 reappears in page 2 — TMDB pagination instability.
        let page2 = MoviePage(page: 2, results: [movie2, movie3], totalPages: 5, totalResults: 50)

        let service = MockMovieService()
        service.stubPopular(.success(page1))
        let viewModel = PopularMoviesViewModel(service: service)
        await viewModel.loadPopular()

        service.stubPopular(.success(page2))
        await viewModel.loadNextPage()

        guard case .loaded(let movies) = viewModel.state else {
            Issue.record("Expected .loaded, got \(String(describing: viewModel.state))")
            return
        }
        #expect(movies.map(\.id) == [1, 2, 3])
    }

    @Test
    func loadNextPageIsNoOpWhenHasReachedEnd() async {
        let onlyMovie = [Movie(id: 1, title: "Solo", overview: "", posterPath: "/a.jpg")]
        let page1 = MoviePage(page: 1, results: onlyMovie, totalPages: 1, totalResults: 1)

        let service = MockMovieService()
        service.stubPopular(.success(page1))

        let viewModel = PopularMoviesViewModel(service: service)
        await viewModel.loadPopular()

        #expect(viewModel.hasReachedEnd == true)

        await viewModel.loadNextPage()

        #expect(service.popularPagesRequested == [1])
    }
}
