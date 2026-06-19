import Foundation
import Testing
@testable import MovieBrowserCore

@MainActor
struct MovieDetailViewModelTests {
    @Test
    func initialStateIsIdle() {
        let service = MockMovieService()
        let viewModel = MovieDetailViewModel(service: service, movieID: 550)

        guard case .idle = viewModel.state else {
            Issue.record("Expected .idle, got \(String(describing: viewModel.state))")
            return
        }
    }

    @Test
    func loadTransitionsFromIdleToLoadingToLoaded() async {
        let details = MovieDetails(
            id: 550,
            title: "Fight Club",
            overview: "Insomniac.",
            posterPath: "/abc.jpg",
            runtime: 139,
            tagline: "Mischief. Mayhem. Soap."
        )
        let service = MockMovieService()
        service.stubDetails(.success(details))
        service.enableDetailsGate()

        let viewModel = MovieDetailViewModel(service: service, movieID: 550)

        let task = Task { await viewModel.load() }
        for _ in 0..<10 { await Task.yield() }

        guard case .loading = viewModel.state else {
            Issue.record("Expected .loading mid-flight, got \(String(describing: viewModel.state))")
            service.releaseDetails()
            _ = await task.value
            return
        }

        service.releaseDetails()
        await task.value

        guard case .loaded(let loaded) = viewModel.state else {
            Issue.record("Expected .loaded after completion, got \(String(describing: viewModel.state))")
            return
        }
        #expect(loaded.id == 550)
        #expect(loaded.title == "Fight Club")
    }

    @Test
    func loadTransitionsToErrorOnServiceFailure() async {
        let service = MockMovieService()
        service.stubDetails(.failure(.notFound))

        let viewModel = MovieDetailViewModel(service: service, movieID: 550)

        await viewModel.load()

        guard case .error(let err) = viewModel.state else {
            Issue.record("Expected .error, got \(String(describing: viewModel.state))")
            return
        }
        guard case .notFound = err else {
            Issue.record("Expected .notFound, got \(String(describing: err))")
            return
        }
    }
}
