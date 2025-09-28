import Foundation

@MainActor
final class FamilyViewModel: ObservableObject {
    @Published var familyName: String = ""
    @Published var inviteCode: String = ""
    @Published var isLoading: Bool = false
    @Published var error: String?
    @Published var families: [Family] = []
    @Published var children: [ChildProfile] = []
    @Published var members: [UserAccount] = []
    @Published var membersLoading: Bool = false
    @Published var removingMembers: Set<ID> = []
    @Published var leavingFamily: Bool = false

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
            if let first = families.first {
                if appState.currentFamily == nil || !families.contains(where: { $0.id == appState.currentFamily?.id }) {
                    appState.currentFamily = first
                }
            } else {
                appState.currentFamily = nil
            }
            await refreshMembers()
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
            await refreshMembers()
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
            await refreshMembers()
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

    func refreshMembers() async {
        guard let family = appState.currentFamily else {
            members = []
            return
        }
        membersLoading = true
        defer { membersLoading = false }
        do {
            let users = try await backend.users(with: family.memberIds)
            var ordered: [UserAccount] = []
            for id in family.memberIds {
                if let user = users.first(where: { $0.id == id }) {
                    ordered.append(user)
                }
            }
            let extras = users.filter { user in !family.memberIds.contains(user.id) }
            members = ordered + extras
        } catch {
            self.error = error.localizedDescription
        }
    }

    func removeMember(_ member: UserAccount) async {
        guard let family = appState.currentFamily, let requester = appState.currentUser else { return }
        removingMembers.insert(member.id)
        defer { removingMembers.remove(member.id) }
        do {
            try await backend.removeMember(familyId: family.id, memberId: member.id, requesterId: requester.id)
            try await reloadCurrentFamily()
        } catch {
            if let appError = error as? AppError, case .invalid = appError {
                self.error = "Owners cannot be removed."
            } else {
                self.error = error.localizedDescription
            }
        }
    }

    func leaveCurrentFamily() async {
        guard let family = appState.currentFamily, let user = appState.currentUser else { return }
        leavingFamily = true
        defer { leavingFamily = false }
        do {
            try await backend.leaveFamily(familyId: family.id, memberId: user.id)
            appState.currentFamily = nil
            appState.selectedChild = nil
            await loadFamilies()
            await refreshMembers()
        } catch {
            if let appError = error as? AppError, case .invalid = appError {
                self.error = "Transfer ownership before leaving this family."
            } else {
                self.error = error.localizedDescription
            }
        }
    }

    private func reloadCurrentFamily() async throws {
        guard let family = appState.currentFamily else { return }
        if let updated = try await backend.family(id: family.id) {
            appState.currentFamily = updated
            await refreshMembers()
        }
    }
}
