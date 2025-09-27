import Foundation

public typealias ID = String

public struct UserAccount: Codable, Identifiable, Equatable {
    public let id: ID
    public var displayName: String
    public var email: String
    public var createdAt: Date
}

public struct Family: Codable, Identifiable, Equatable {
    public let id: ID
    public var name: String
    public var inviteCode: String
    public var memberIds: [ID]
    public var createdAt: Date
}

public struct ChildProfile: Codable, Identifiable, Equatable {
    public let id: ID
    public let familyId: ID
    public var name: String
    public var birthdate: Date?
    public var avatarPhotoId: ID?
    public var createdAt: Date
}

public struct PhotoAsset: Codable, Identifiable, Equatable {
    public let id: ID
    public var fileName: String
    public var createdAt: Date
}

public struct JournalEntry: Codable, Identifiable, Equatable {
    public let id: ID
    public let familyId: ID
    public var childIds: [ID]
    public var photoIds: [ID]
    public var descriptionText: String
    public var uploaderUserId: ID
    public var tags: [String]
    public var createdAt: Date

    public var date: Date { createdAt }
}

public struct AppData: Codable {
    public var users: [UserAccount] = []
    public var families: [Family] = []
    public var children: [ChildProfile] = []
    public var photos: [PhotoAsset] = []
    public var entries: [JournalEntry] = []
}

public enum AppError: Error, LocalizedError {
    case notFound
    case invalid
    case unauthorized
    case io(String)

    public var errorDescription: String? {
        switch self {
        case .notFound: return "Not found"
        case .invalid: return "Invalid data"
        case .unauthorized: return "Unauthorized"
        case .io(let m): return m
        }
    }
}

public func newId() -> ID { UUID().uuidString }
