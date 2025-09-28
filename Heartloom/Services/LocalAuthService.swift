import Foundation

public final class LocalAuthService: AuthService {
    private let backend: BackendService
    private let sessionStore = AuthSessionStore()

    public init(backend: BackendService) {
        self.backend = backend
    }

    public func restoreSession() async -> UserAccount? {
        guard let session = sessionStore.load() else { return nil }
        if let list = try? await backend.users(with: [session.userId]), let cachedUser = list.first {
            return cachedUser
        }
        if let user = try? await backend.user(byAuthUID: session.authUID, provider: session.provider) {
            sessionStore.save(userId: user.id, authUID: user.authUID, provider: user.provider)
            return user
        }
        return nil
    }

    public func signInWithApple(idToken: String, nonce: String, displayName: String?, email: String?) async throws -> UserAccount {
        let subject = try subjectIdentifier(from: idToken)
        let user = try await upsertUser(authUID: subject, provider: "apple", displayName: displayName, email: email)
        sessionStore.save(userId: user.id, authUID: user.authUID, provider: user.provider)
        return user
    }

    public func signInWithGoogle(idToken: String, accessToken: String, displayName: String?, email: String?) async throws -> UserAccount {
        let subject = try subjectIdentifier(from: idToken)
        let user = try await upsertUser(authUID: subject, provider: "google", displayName: displayName, email: email)
        sessionStore.save(userId: user.id, authUID: user.authUID, provider: user.provider)
        return user
    }

    public func signOut() async {
        sessionStore.clear()
    }

    private func upsertUser(authUID: String, provider: String, displayName: String?, email: String?) async throws -> UserAccount {
        let existing = try await backend.user(byAuthUID: authUID, provider: provider)
        var normalizedName = displayName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        var normalizedEmail = email?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if normalizedName.isEmpty { normalizedName = normalizedEmail.isEmpty ? "Heartloom User" : normalizedEmail }
        if normalizedEmail.isEmpty { normalizedEmail = "" }

        if var user = existing {
            user.displayName = normalizedName
            if !normalizedEmail.isEmpty { user.email = normalizedEmail }
            return try await backend.saveUser(user)
        } else {
            let user = UserAccount(id: newId(), authUID: authUID, provider: provider, displayName: normalizedName, email: normalizedEmail, photoURL: nil, createdAt: Date())
            return try await backend.saveUser(user)
        }
    }

    private func subjectIdentifier(from jwt: String) throws -> String {
        let segments = jwt.split(separator: ".")
        guard segments.count >= 2 else { throw AppError.invalid }
        let bodySegment = String(segments[1])
        guard let data = Data(base64URLEncoded: bodySegment) else { throw AppError.invalid }
        let payload = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let sub = payload?["sub"] as? String else { throw AppError.invalid }
        return sub
    }
}

private struct StoredSession: Codable {
    let userId: ID
    let authUID: String
    let provider: String
}

private final class AuthSessionStore {
    private let defaults = UserDefaults.standard
    private let key = "heartloom.session"

    func save(userId: ID, authUID: String, provider: String) {
        let session = StoredSession(userId: userId, authUID: authUID, provider: provider)
        if let data = try? JSONEncoder().encode(session) {
            defaults.set(data, forKey: key)
        }
    }

    func load() -> StoredSession? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(StoredSession.self, from: data)
    }

    func clear() {
        defaults.removeObject(forKey: key)
    }
}

private extension Data {
    init?(base64URLEncoded string: String) {
        var base64 = string
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        let paddingLength = 4 - base64.count % 4
        if paddingLength < 4 {
            base64.append(String(repeating: "=", count: paddingLength))
        }
        self.init(base64Encoded: base64)
    }
}
