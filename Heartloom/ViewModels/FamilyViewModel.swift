import Foundation

@MainActor
final class FamilyViewModel: ObservableObject {
    @Published var familyName: String = ""
    @Published var inviteCode: String = ""
    @Published var isLoading: Bool = false
    @Published var error: String?
    @Published var families: [Family] = []
    @Published var children: [ChildProfile] = []

    let backend: BackendService
    private let appState: AppState

    init(backend: BackendService, appState: AppState) {
        self.backend = backend
        self.appState = appState
    }

    func loadFamilies() async {
        guard let uid = appState.currentUser?.id else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            families = try await backend.families(forUser: uid)
            if appState.currentFamily == nil { appState.currentFamily = families.first }
        } catch {
            self.error = error.localizedDescription
        }
    }

    func createFamily() async {
        guard let uid = appState.currentUser?.id else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            let fam = try await backend.createFamily(name: familyName, ownerId: uid)
            appState.currentFamily = fam
            await loadFamilies()
            await loadChildren()
        } catch {
            self.error = error.localizedDescription
        }
    }

    func joinFamily() async {
        guard let uid = appState.currentUser?.id else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            let fam = try await backend.joinFamily(inviteCode: inviteCode, userId: uid)
            appState.currentFamily = fam
            await loadFamilies()
            await loadChildren()
        } catch {
            self.error = error.localizedDescription
        }
    }

    func loadChildren() async {
        guard let fid = appState.currentFamily?.id else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            children = try await backend.children(inFamily: fid)
            if appState.selectedChild == nil { appState.selectedChild = children.first }
        } catch {
            self.error = error.localizedDescription
        }
    }

    func createChild(name: String, birthdate: Date?) async {
        guard let fid = appState.currentFamily?.id else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            let child = try await backend.createChild(familyId: fid, name: name, birthdate: birthdate)
            children.append(child)
            if appState.selectedChild == nil { appState.selectedChild = child }
        } catch {
            self.error = error.localizedDescription
        }
    }
}
