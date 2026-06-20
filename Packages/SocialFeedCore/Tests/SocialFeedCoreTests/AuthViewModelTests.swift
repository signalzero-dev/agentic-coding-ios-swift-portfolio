import Testing
@testable import SocialFeedCore

@MainActor
struct AuthViewModelTests {

    @Test func observesAuthStateStreamToDriveSession() async {
        let repo = MockAuthRepository()
        let viewModel = AuthViewModel(repository: repo)

        viewModel.start()
        #expect(viewModel.session == nil)

        let user = User(id: "u1", displayName: "Ada")
        repo.emitAuthState(user)
        await waitFor { viewModel.session == user }
        #expect(viewModel.session == user)

        repo.emitAuthState(nil)
        await waitFor { viewModel.session == nil }
        #expect(viewModel.session == nil)
    }

    @Test func signInSuccessClearsErrorAndSetsSessionViaStream() async {
        let repo = MockAuthRepository()
        let user = User(id: "u1", displayName: "Ada")
        repo.signInResult = .success(user)
        let viewModel = AuthViewModel(repository: repo)
        viewModel.start()

        await viewModel.signIn(email: "a@b.com", password: "pw")

        #expect(viewModel.submitState.failure == nil)
        await waitFor { viewModel.session == user }
        #expect(viewModel.session == user)
    }

    @Test func signInFailureSetsErrorAndLeavesSessionNil() async {
        let repo = MockAuthRepository()
        repo.signInResult = .failure(.invalidCredentials)
        let viewModel = AuthViewModel(repository: repo)
        viewModel.start()

        await viewModel.signIn(email: "a@b.com", password: "bad")

        #expect(viewModel.submitState.failure == .invalidCredentials)
        #expect(viewModel.session == nil)
    }

    @Test func signUpSuccessClearsErrorAndSetsSessionViaStream() async {
        let repo = MockAuthRepository()
        let user = User(id: "u2", displayName: "Grace")
        repo.signUpResult = .success(user)
        let viewModel = AuthViewModel(repository: repo)
        viewModel.start()

        await viewModel.signUp(email: "grace@test.com", password: "pw123456")

        #expect(viewModel.submitState.failure == nil)
        await waitFor { viewModel.session == user }
        #expect(viewModel.session == user)
    }

    @Test func signUpFailureSetsError() async {
        let repo = MockAuthRepository()
        repo.signUpResult = .failure(.emailAlreadyInUse)
        let viewModel = AuthViewModel(repository: repo)
        viewModel.start()

        await viewModel.signUp(email: "taken@test.com", password: "pw123456")

        #expect(viewModel.submitState.failure == .emailAlreadyInUse)
        #expect(viewModel.session == nil)
    }

    @Test func signOutClearsSessionViaStream() async {
        let repo = MockAuthRepository()
        let user = User(id: "u1", displayName: "Ada")
        repo.signInResult = .success(user)
        let viewModel = AuthViewModel(repository: repo)
        viewModel.start()
        await viewModel.signIn(email: "a@b.com", password: "pw")
        await waitFor { viewModel.session == user }

        await viewModel.signOut()

        #expect(repo.signOutCalled)
        await waitFor { viewModel.session == nil }
        #expect(viewModel.session == nil)
    }
}
