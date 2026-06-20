import SwiftUI
import SocialFeedCore

/// Email/password sign-in or sign-up. (Sign in with Apple is deferred until a Team is set.)
struct AuthView: View {
    @Bindable var viewModel: AuthViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var mode: Mode = .signIn

    enum Mode: String, CaseIterable {
        case signIn = "Sign In"
        case signUp = "Sign Up"
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Mode", selection: $mode) {
                        ForEach(Mode.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)
                }

                Section {
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    SecureField("Password", text: $password)
                        .textContentType(mode == .signUp ? .newPassword : .password)
                }

                Section {
                    Button(action: submit) {
                        if viewModel.submitState.isLoading {
                            ProgressView().frame(maxWidth: .infinity)
                        } else {
                            Text(mode.rawValue).frame(maxWidth: .infinity)
                        }
                    }
                    .disabled(email.isEmpty || password.isEmpty || viewModel.submitState.isLoading)
                }

                if let error = viewModel.submitState.failure {
                    Section {
                        Text(message(for: error)).foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("SocialFeed")
        }
    }

    private func submit() {
        Task {
            switch mode {
            case .signIn: await viewModel.signIn(email: email, password: password)
            case .signUp: await viewModel.signUp(email: email, password: password)
            }
        }
    }

    private func message(for error: AuthError) -> String {
        switch error {
        case .invalidCredentials: "Incorrect email or password."
        case .emailAlreadyInUse: "That email is already registered. Try signing in."
        case .weakPassword: "Password must be at least 6 characters."
        case .network: "Network problem. Check your connection."
        case .unknown: "Something went wrong. Please try again."
        }
    }
}
