import SwiftUI
import MovieBrowserCore

struct ErrorView: View {
    let error: MovieServiceError
    let retry: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.largeTitle)
                .foregroundStyle(.orange)
            Text(message)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Button("Retry", action: retry)
                .buttonStyle(.borderedProminent)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var message: String {
        switch error {
        case .notFound:
            return "Couldn't find that resource."
        case .rateLimited:
            return "Too many requests. Please wait a moment."
        case .server(let code):
            return "TMDB server error (\(code))."
        case .decoding:
            return "Couldn't decode the response."
        case .transport:
            return "Network problem. Check your connection."
        }
    }
}
