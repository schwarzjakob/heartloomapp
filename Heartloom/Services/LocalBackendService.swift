import Foundation
import UIKit

actor LocalStore {
    private let fileURL: URL
    private var data: AppData
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(baseURL: URL) {
        self.fileURL = baseURL.appendingPathComponent("backend.json")
        self.encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        self.decoder.dateDecodingStrategy = .iso8601
        self.encoder.dateEncodingStrategy = .iso8601
        if let loaded = try? Data(contentsOf: fileURL), let decoded = try? decoder.decode(AppData.self, from: loaded) {
            self.data = decoded
        } else {
            self.data = AppData()
        }
        migrateFamiliesIfNeeded()
    }

    private func migrateFamiliesIfNeeded() {
        var changed = false
        for idx in data.families.indices {
            if data.families[idx].ownerId.isEmpty {
                if let owner = data.families[idx].memberIds.first {
                    data.families[idx].ownerId = owner
                    changed = true
                }
            }
            if !data.families[idx].ownerId.isEmpty && !data.families[idx].memberIds.contains(data.families[idx].ownerId) {
                data.families[idx].memberIds.insert(data.families[idx].ownerId, at: 0)
                changed = true
            }
        }
        if changed {
            try? persist()
        }
    }

    func persist() throws {
        let d = try encoder.encode(data)
        try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try d.write(to: fileURL, options: .atomic)
    }

    private func upsert<T: Identifiable & Equatable>(_ value: T, into keyPath: WritableKeyPath<AppData, [T]>) {
        var list = data[keyPath: keyPath]
        if let idx = list.firstIndex(where: { $0.id == value.id }) {
            list[idx] = value
        } else {
            list.append(value)
        }
        data[keyPath: keyPath] = list
    }

    private func append<T>(_ values: [T], into keyPath: WritableKeyPath<AppData, [T]>) {
        data[keyPath: keyPath].append(contentsOf: values)
    }

    func findUser(authUID: String, provider: String) -> UserAccount? {
        data.users.first { $0.authUID == authUID && $0.provider == provider }
    }

    func saveUser(_ user: UserAccount) {
        upsert(user, into: \AppData.users)
    }

    func users(with ids: [ID]) -> [UserAccount] {
        data.users.filter { ids.contains($0.id) }
    }

    func getFamilies(for userId: ID) -> [Family] {
        data.families.filter { $0.memberIds.contains(userId) }
    }

    func addFamily(_ family: Family) {
        upsert(family, into: \AppData.families)
    }

    func findFamily(byInvite code: String) -> Family? {
        data.families.first { $0.inviteCode.lowercased() == code.lowercased() }
    }

    func family(id: ID) -> Family? {
        data.families.first { $0.id == id }
    }

    func updateFamily(_ family: Family) {
        upsert(family, into: \AppData.families)
    }

    func addChild(_ child: ChildProfile) {
        upsert(child, into: \AppData.children)
    }

    func children(in familyId: ID) -> [ChildProfile] {
        data.children.filter { $0.familyId == familyId }
    }

    func addPhotos(_ photos: [PhotoAsset]) {
        append(photos, into: \AppData.photos)
    }

    func addEntry(_ entry: JournalEntry) {
        upsert(entry, into: \AppData.entries)
    }

    func entries(inFamily familyId: ID) -> [JournalEntry] {
        data.entries.filter { $0.familyId == familyId }.sorted { $0.createdAt < $1.createdAt }
    }

    func entries(forChild childId: ID) -> [JournalEntry] {
        data.entries.filter { $0.childIds.contains(childId) }.sorted { $0.createdAt < $1.createdAt }
    }
}

public final class LocalBackendService: BackendService {
    private let store: LocalStore
    private let imageStore: ImageStoring

    public init() {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("Heartloom")
        self.store = LocalStore(baseURL: base)
        self.imageStore = ImageStore(baseURL: base.appendingPathComponent("Images"))
    }

    public func user(byAuthUID authUID: String, provider: String) async throws -> UserAccount? {
        await store.findUser(authUID: authUID, provider: provider)
    }

    public func saveUser(_ user: UserAccount) async throws -> UserAccount {
        await store.saveUser(user)
        try await store.persist()
        return user
    }

    public func users(with ids: [ID]) async throws -> [UserAccount] {
        await store.users(with: ids)
    }

    public func createFamily(name: String, ownerId: ID) async throws -> Family {
        let uniqueMembers = Array(Set([ownerId]))
        let family = Family(id: newId(), name: name, ownerId: ownerId, inviteCode: Self.makeInviteCode(), memberIds: uniqueMembers, createdAt: Date())
        await store.addFamily(family)
        try await store.persist()
        return family
    }

    public func joinFamily(inviteCode: String, userId: ID) async throws -> Family {
        guard var family = await store.findFamily(byInvite: inviteCode) else { throw AppError.notFound }
        if !family.memberIds.contains(userId) {
            family.memberIds.append(userId)
            await store.updateFamily(family)
            try await store.persist()
        }
        return family
    }

    public func families(forUser userId: ID) async throws -> [Family] {
        await store.getFamilies(for: userId)
    }

    public func family(id: ID) async throws -> Family? {
        await store.family(id: id)
    }

    public func updateFamily(_ family: Family) async throws -> Family {
        await store.updateFamily(family)
        try await store.persist()
        return family
    }

    public func removeMember(familyId: ID, memberId: ID, requesterId: ID) async throws {
        guard var family = await store.family(id: familyId) else { throw AppError.notFound }
        guard family.ownerId == requesterId else { throw AppError.unauthorized }
        guard memberId != family.ownerId else { throw AppError.invalid }
        if let idx = family.memberIds.firstIndex(of: memberId) {
            family.memberIds.remove(at: idx)
            await store.updateFamily(family)
            try await store.persist()
        }
    }

    public func leaveFamily(familyId: ID, memberId: ID) async throws {
        guard var family = await store.family(id: familyId) else { throw AppError.notFound }
        guard memberId != family.ownerId else { throw AppError.invalid }
        if let idx = family.memberIds.firstIndex(of: memberId) {
            family.memberIds.remove(at: idx)
            await store.updateFamily(family)
            try await store.persist()
        }
    }

    public func createChild(familyId: ID, name: String, birthdate: Date?) async throws -> ChildProfile {
        let child = ChildProfile(id: newId(), familyId: familyId, name: name, birthdate: birthdate, avatarPhotoId: nil, createdAt: Date())
        await store.addChild(child)
        try await store.persist()
        return child
    }

    public func children(inFamily familyId: ID) async throws -> [ChildProfile] {
        await store.children(in: familyId)
    }

    public func savePhotos(_ images: [UIImage]) async throws -> [PhotoAsset] {
        let assets: [PhotoAsset] = try images.map { image in
            try imageStore.save(image: image)
        }
        await store.addPhotos(assets)
        try await store.persist()
        return assets
    }

    public func createJournalEntry(familyId: ID, childIds: [ID], photoIds: [ID], description: String, tags: [String], uploaderId: ID) async throws -> JournalEntry {
        let entry = JournalEntry(id: newId(), familyId: familyId, childIds: childIds, photoIds: photoIds, descriptionText: description, uploaderUserId: uploaderId, tags: tags, createdAt: Date())
        await store.addEntry(entry)
        try await store.persist()
        return entry
    }

    public func entries(inFamily familyId: ID) async throws -> [JournalEntry] {
        await store.entries(inFamily: familyId)
    }

    public func entries(forChild childId: ID) async throws -> [JournalEntry] {
        await store.entries(forChild: childId)
    }

    public static func makeInviteCode() -> String {
        let letters = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
        return String((0..<6).map { _ in letters.randomElement()! })
    }
}
