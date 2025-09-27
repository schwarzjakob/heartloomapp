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
    }

    func save() throws {
        let d = try encoder.encode(data)
        try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try d.write(to: fileURL, options: .atomic)
    }

    func upsert<T: Identifiable & Equatable>(_ value: T, into keyPath: WritableKeyPath<AppData, [T]>) {
        var list = data[keyPath: keyPath]
        if let idx = list.firstIndex(where: { $0.id == value.id }) {
            list[idx] = value
        } else {
            list.append(value)
        }
        data[keyPath: keyPath] = list
    }

    func append<T>(_ values: [T], into keyPath: WritableKeyPath<AppData, [T]>) {
        data[keyPath: keyPath].append(contentsOf: values)
    }

    // Accessors
    func findUser(byEmail email: String) -> UserAccount? {
        data.users.first { $0.email.caseInsensitiveCompare(email) == .orderedSame }
    }

    func addUser(_ user: UserAccount) {
        upsert(user, into: \AppData.users)
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

    public func signIn(displayName: String, email: String) async throws -> UserAccount {
        if let existing = await store.findUser(byEmail: email) {
            return existing
        }
        let user = UserAccount(id: newId(), displayName: displayName, email: email, createdAt: Date())
        await store.addUser(user)
        try await store.save()
        return user
    }

    public func user(byEmail email: String) async throws -> UserAccount? {
        await store.findUser(byEmail: email)
    }

    public func createFamily(name: String, ownerId: ID) async throws -> Family {
        let family = Family(id: newId(), name: name, inviteCode: Self.makeInviteCode(), memberIds: [ownerId], createdAt: Date())
        await store.addFamily(family)
        try await store.save()
        return family
    }

    public func joinFamily(inviteCode: String, userId: ID) async throws -> Family {
        guard var family = await store.findFamily(byInvite: inviteCode) else { throw AppError.notFound }
        if !family.memberIds.contains(userId) {
            family.memberIds.append(userId)
            await store.updateFamily(family)
            try await store.save()
        }
        return family
    }

    public func families(forUser userId: ID) async throws -> [Family] {
        await store.getFamilies(for: userId)
    }

    public func createChild(familyId: ID, name: String, birthdate: Date?) async throws -> ChildProfile {
        let child = ChildProfile(id: newId(), familyId: familyId, name: name, birthdate: birthdate, avatarPhotoId: nil, createdAt: Date())
        await store.addChild(child)
        try await store.save()
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
        try await store.save()
        return assets
    }

    public func createJournalEntry(familyId: ID, childIds: [ID], photoIds: [ID], description: String, tags: [String], uploaderId: ID) async throws -> JournalEntry {
        let e = JournalEntry(id: newId(), familyId: familyId, childIds: childIds, photoIds: photoIds, descriptionText: description, uploaderUserId: uploaderId, tags: tags, createdAt: Date())
        await store.addEntry(e)
        try await store.save()
        return e
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

