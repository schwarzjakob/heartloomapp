import Foundation

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var isLoading: Bool = false
    @Published var error: String?

    private let auth: AuthService
    private let appState: AppState

    init(auth: AuthService, appState: AppState) {
        self.auth = auth
        self.appState = appState
    }

    func restore() async {
        guard appState.currentUser == nil else { return }
        let user = await auth.restoreSession()
        if let user {
            appState.currentUser = user
        }
    }

    func signInWithApple(idToken: String, nonce: String, name: String?, email: String?) async {
        await authenticate {
            try await auth.signInWithApple(idToken: idToken, nonce: nonce, displayName: name, email: email)
        }
    }

    func signInWithGoogle(idToken: String, accessToken: String, name: String?, email: String?) async {
        await authenticate {
            try await auth.signInWithGoogle(idToken: idToken, accessToken: accessToken, displayName: name, email: email)
        }
    }

    func signOut() async {
        await auth.signOut()
        appState.currentUser = nil
        appState.currentFamily = nil
        appState.selectedChild = nil
        error = nil
    }

    private func authenticate(_ block: () async throws -> UserAccount) async {
        isLoading = true
        error = nil
        do {
            let user = try await block()
            appState.currentUser = user
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }
}
