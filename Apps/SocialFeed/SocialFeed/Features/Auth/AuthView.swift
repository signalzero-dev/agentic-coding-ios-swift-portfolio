import SwiftUI
import SocialFeedCore

/// Email/password sign-in. (Sign in with Apple is deferred until a Team is set.)
struct AuthView: View {
    @Bindable var viewModel: AuthViewModel
    @State private var email = ""
    @State private var password = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    SecureField("Password", text: $password)
                        .textContentType(.password)
                }

                Section {
                    Button {
                        Task { await viewModel.signIn(email: email, password: password) }
                    } label: {
                        if viewModel.signInState.isLoading {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("Sign In")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .disabled(email.isEmpty || password.isEmpty || viewModel.signInState.isLoading)
                }

                if let error = viewModel.signInState.failure {
                    Section {
                        Text(message(for: error))
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("SocialFeed")
        }
    }

    private func message(for error: AuthError) -> String {
        switch error {
        case .invalidCredentials: "Incorrect email or password."
        case .network: "Network problem. Check your connection."
        case .unknown: "Something went wrong. Please try again."
        }
    }
}
