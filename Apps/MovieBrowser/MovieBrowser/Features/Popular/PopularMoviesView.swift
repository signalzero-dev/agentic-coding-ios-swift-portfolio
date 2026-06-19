import SwiftUI
import MovieBrowserCore

struct PopularMoviesView: View {
    @State private var viewModel: PopularMoviesViewModel
    private let service: any MovieServiceProtocol

    init(service: any MovieServiceProtocol) {
        self.service = service
        self._viewModel = State(initialValue: PopularMoviesViewModel(service: service))
    }

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Popular")
                .task {
                    if case .idle = viewModel.state {
                        await viewModel.loadPopular()
                    }
                }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .loaded(let movies):
            List {
                ForEach(movies, id: \.id) { movie in
                    NavigationLink {
                        MovieDetailView(service: service, movieID: movie.id)
                    } label: {
                        MovieRow(movie: movie)
                    }
                    .onAppear {
                        if movie.id == movies.last?.id {
                            Task { await viewModel.loadNextPage() }
                        }
                    }
                }
                if viewModel.isLoadingNextPage {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .listRowSeparator(.hidden)
                }
            }
            .listStyle(.plain)
            .accessibilityIdentifier("popularMoviesList")
            .refreshable {
                await viewModel.refresh()
            }
        case .error(let error):
            ErrorView(error: error) {
                Task { await viewModel.loadPopular() }
            }
        }
    }
}
