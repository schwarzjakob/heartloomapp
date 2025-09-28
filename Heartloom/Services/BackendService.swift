import Foundation
import UIKit

@MainActor
public final class AppState: ObservableObject {
    @Published public var currentUser: UserAccount?
    @Published public var currentFamily: Family?
    @Published public var selectedChild: ChildProfile?
}

public protocol AuthService: Sendable {
    func restoreSession() async -> UserAccount?
    func signInWithApple(idToken: String, nonce: String, displayName: String?, email: String?) async throws -> UserAccount
    func signInWithGoogle(idToken: String, accessToken: String, displayName: String?, email: String?) async throws -> UserAccount
    func signOut() async
}

public protocol BackendService: Sendable {
    func user(byAuthUID authUID: String, provider: String) async throws -> UserAccount?
    func saveUser(_ user: UserAccount) async throws -> UserAccount
    func users(with ids: [ID]) async throws -> [UserAccount]

    func createFamily(name: String, ownerId: ID) async throws -> Family
    func joinFamily(inviteCode: String, userId: ID) async throws -> Family
    func families(forUser userId: ID) async throws -> [Family]
    func family(id: ID) async throws -> Family?
    func updateFamily(_ family: Family) async throws -> Family
    func removeMember(familyId: ID, memberId: ID, requesterId: ID) async throws
    func leaveFamily(familyId: ID, memberId: ID) async throws

    func createChild(familyId: ID, name: String, birthdate: Date?) async throws -> ChildProfile
    func children(inFamily familyId: ID) async throws -> [ChildProfile]

    func savePhotos(_ images: [UIImage]) async throws -> [PhotoAsset]
    func createJournalEntry(familyId: ID, childIds: [ID], photoIds: [ID], description: String, tags: [String], uploaderId: ID) async throws -> JournalEntry
    func entries(inFamily familyId: ID) async throws -> [JournalEntry]
    func entries(forChild childId: ID) async throws -> [JournalEntry]
}

public protocol ImageStoring {
    func save(image: UIImage) throws -> PhotoAsset
    func loadImageData(for asset: PhotoAsset) -> Data?
    func imageURL(for asset: PhotoAsset) -> URL
}

public protocol AISuggestionService {
    func generateSuggestion(for images: [UIImage], children: [ChildProfile]) async -> String
}
