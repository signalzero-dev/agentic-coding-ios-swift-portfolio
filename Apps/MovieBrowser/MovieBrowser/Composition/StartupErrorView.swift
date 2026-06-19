import SwiftUI

struct StartupErrorView: View {
    let error: StartupError

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.octagon.fill")
                .font(.largeTitle)
                .foregroundStyle(.red)
            Text("Setup error")
                .font(.title2)
                .bold()
            Text(error.errorDescription ?? "Unknown error")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
        }
        .padding()
    }
}
