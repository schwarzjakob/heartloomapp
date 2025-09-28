import Foundation

public typealias ID = String

public struct UserAccount: Codable, Identifiable, Equatable {
    public let id: ID
    public let authUID: String
    public let provider: String
    public var displayName: String
    public var email: String
    public var photoURL: String?
    public var createdAt: Date

    public init(id: ID, authUID: String, provider: String, displayName: String, email: String, photoURL: String?, createdAt: Date) {
        self.id = id
        self.authUID = authUID
        self.provider = provider
        self.displayName = displayName
        self.email = email
        self.photoURL = photoURL
        self.createdAt = createdAt
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(ID.self, forKey: .id)
        self.authUID = try container.decodeIfPresent(String.self, forKey: .authUID) ?? id
        self.provider = try container.decodeIfPresent(String.self, forKey: .provider) ?? "local"
        self.displayName = try container.decode(String.self, forKey: .displayName)
        self.email = try container.decode(String.self, forKey: .email)
        self.photoURL = try container.decodeIfPresent(String.self, forKey: .photoURL)
        self.createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
    }
}

public struct Family: Codable, Identifiable, Equatable {
    public let id: ID
    public var name: String
    public var ownerId: ID
    public var inviteCode: String
    public var memberIds: [ID]
    public var createdAt: Date

    public init(id: ID, name: String, ownerId: ID, inviteCode: String, memberIds: [ID], createdAt: Date) {
        self.id = id
        self.name = name
        self.ownerId = ownerId
        self.inviteCode = inviteCode
        self.memberIds = memberIds
        self.createdAt = createdAt
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(ID.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)
        self.inviteCode = try container.decode(String.self, forKey: .inviteCode)
        self.memberIds = try container.decodeIfPresent([ID].self, forKey: .memberIds) ?? []
        self.createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        if let owner = try container.decodeIfPresent(ID.self, forKey: .ownerId) {
            self.ownerId = owner
        } else if let firstMember = memberIds.first {
            self.ownerId = firstMember
        } else {
            self.ownerId = ""
        }
    }
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
