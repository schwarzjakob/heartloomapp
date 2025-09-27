import Foundation

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var displayName: String = ""
    @Published var email: String = ""
    @Published var isLoading: Bool = false
    @Published var error: String?

    private let backend: BackendService
    private let appState: AppState

    init(backend: BackendService, appState: AppState) {
        self.backend = backend
        self.appState = appState
    }

    func signIn() async {
        isLoading = true
        defer { isLoading = false }
        error = nil
        do {
            let user = try await backend.signIn(displayName: displayName, email: email)
            appState.currentUser = user
        } catch {
            self.error = error.localizedDescription
        }
    }
}
