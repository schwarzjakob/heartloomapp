import AuthenticationServices
import CryptoKit
import Foundation
import GoogleSignIn
import UIKit

public struct AppleSignInPayload {
    public let idToken: String
    public let nonce: String
    public let displayName: String?
    public let email: String?
}

public struct GoogleSignInPayload {
    public let idToken: String
    public let accessToken: String
    public let displayName: String?
    public let email: String?
}

@MainActor
final class AuthProvider: NSObject {
    static let shared = AuthProvider()

    private var appleContinuation: CheckedContinuation<AppleSignInPayload, Error>?
    private var currentNonce: String?
    private var googleConfigured = false

    private override init() {
        super.init()
        if let clientID = Bundle.main.object(forInfoDictionaryKey: "GIDClientID") as? String,
           !clientID.isEmpty,
           clientID.contains("googleusercontent.com"),
           clientID.contains("YOUR_GOOGLE_CLIENT_ID") == false {
            GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
            googleConfigured = true
        }
    }

    func signInWithApple() async throws -> AppleSignInPayload {
        let nonce = randomNonce()
        currentNonce = nonce
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)

        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self

        return try await withCheckedThrowingContinuation { continuation in
            appleContinuation = continuation
            controller.performRequests()
        }
    }

    func signInWithGoogle() async throws -> GoogleSignInPayload {
        guard googleConfigured else { throw AppError.invalid }
        guard let root = topViewController() else { throw AppError.invalid }
        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: root)
        guard let idToken = result.user.idToken?.tokenString else { throw AppError.invalid }
        let accessToken = result.user.accessToken.tokenString
        let profile = result.user.profile
        return GoogleSignInPayload(idToken: idToken,
                                   accessToken: accessToken,
                                   displayName: profile?.name,
                                   email: profile?.email)
    }

    private func randomNonce(length: Int = 32) -> String {
        let charset = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remaining = length

        while remaining > 0 {
            var randoms = [UInt8](repeating: 0, count: 16)
            let status = SecRandomCopyBytes(kSecRandomDefault, randoms.count, &randoms)
            if status != errSecSuccess { fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(status)") }

            randoms.forEach { random in
                if remaining == 0 { return }
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remaining -= 1
                }
            }
        }

        return result
    }

    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashed = SHA256.hash(data: inputData)
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }

    private func topViewController(_ base: UIViewController? = UIApplication.shared.connectedScenes
        .compactMap { $0 as? UIWindowScene }
        .flatMap { $0.windows }
        .first(where: { $0.isKeyWindow })?.rootViewController) -> UIViewController? {
        if let nav = base as? UINavigationController {
            return topViewController(nav.visibleViewController)
        }
        if let tab = base as? UITabBarController, let selected = tab.selectedViewController {
            return topViewController(selected)
        }
        if let presented = base?.presentedViewController {
            return topViewController(presented)
        }
        return base
    }
}

extension AuthProvider: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let continuation = appleContinuation else { return }
        appleContinuation = nil
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let tokenData = credential.identityToken,
              let tokenString = String(data: tokenData, encoding: .utf8),
              let nonce = currentNonce else {
            continuation.resume(throwing: AppError.invalid)
            return
        }
        currentNonce = nil
        let name = [credential.fullName?.givenName, credential.fullName?.familyName]
            .compactMap { $0 }
            .joined(separator: " ")
        continuation.resume(returning: AppleSignInPayload(idToken: tokenString,
                                                          nonce: nonce,
                                                          displayName: name.isEmpty ? nil : name,
                                                          email: credential.email))
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        appleContinuation?.resume(throwing: error)
        appleContinuation = nil
        currentNonce = nil
    }
}

extension AuthProvider: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first(where: { $0.isKeyWindow }) ?? UIWindow()
    }
}
