import SwiftUI
import MovieBrowserCore
import Kingfisher

struct MovieDetailView: View {
    @State private var viewModel: MovieDetailViewModel

    init(service: any MovieServiceProtocol, movieID: Int) {
        self._viewModel = State(initialValue: MovieDetailViewModel(service: service, movieID: movieID))
    }

    var body: some View {
        content
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .task {
                if case .idle = viewModel.state {
                    await viewModel.load()
                }
            }
    }

    private var navigationTitle: String {
        if case .loaded(let details) = viewModel.state {
            return details.title
        }
        return ""
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .loaded(let details):
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    KFImage(URL(string: "https://image.tmdb.org/t/p/w500\(details.posterPath)"))
                        .placeholder { Color.gray.opacity(0.15) }
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity)
                        .cornerRadius(12)
                    if !details.tagline.isEmpty {
                        Text(details.tagline)
                            .font(.title3)
                            .italic()
                            .foregroundStyle(.secondary)
                    }
                    Text("\(details.runtime) min")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(details.overview)
                        .font(.body)
                }
                .padding()
            }
            .accessibilityIdentifier("movieDetailScrollView")
        case .error(let error):
            ErrorView(error: error) {
                Task { await viewModel.load() }
            }
        }
    }
}
