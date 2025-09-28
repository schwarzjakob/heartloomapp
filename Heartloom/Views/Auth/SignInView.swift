import AuthenticationServices
import SwiftUI

struct SignInView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @State private var signInError: String?

    var body: some View {
        VStack(spacing: 28) {
            Spacer(minLength: 40)

            GlassCard {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Welcome to Heartloom")
                            .font(.largeTitle.weight(.bold))
                            .foregroundStyle(LinearGradient(colors: [.white, Color(red: 0.7, green: 0.86, blue: 1.0)], startPoint: .leading, endPoint: .trailing))
                        Text("Craft a living journal that every family member can contribute to.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    VStack(spacing: 16) {
                        // appleButton
                        googleButton
                    }

                    if authVM.isLoading {
                        ProgressView().tint(.white)
                    }

                    if let err = signInError ?? authVM.error {
                        Text(err)
                            .font(.footnote)
                            .foregroundColor(.pink)
                    }
                }
            }
            .padding(.horizontal, 24)

            Spacer()
        }
        .padding(.vertical, 32)
    }

    // private var appleButton: some View {
    //     ZStack {
    //         SignInWithAppleButton(.signIn) { _ in } onCompletion: { _ in }
    //             .signInWithAppleButtonStyle(.black)
    //             .frame(height: 52)
    //             .cornerRadius(16)
    //             .allowsHitTesting(false)

    //         Button {
    //             Task { await handleAppleSignIn() }
    //         } label: {
    //             HStack {
    //                 Image(systemName: "applelogo")
    //                 Text("Continue with Apple")
    //                     .fontWeight(.semibold)
    //             }
    //             .frame(maxWidth: .infinity)
    //             .frame(height: 52)
    //         }
    //         .buttonStyle(.plain)
    //         .background(
    //             RoundedRectangle(cornerRadius: 16, style: .continuous)
    //                 .fill(LinearGradient(colors: [Color.white.opacity(0.2), Color.white.opacity(0.05)], startPoint: .topLeading, endPoint: .bottomTrailing))
    //         )
    //         .overlay(
    //             RoundedRectangle(cornerRadius: 16, style: .continuous)
    //                 .stroke(Color.white.opacity(0.27), lineWidth: 1)
    //         )
    //         .foregroundColor(.white)
    //         .disabled(authVM.isLoading)
    //     }
    // }

    private var googleButton: some View {
        Button {
            Task { await handleGoogleSignIn() }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "g.circle")
                    .font(.title2)
                Text("Continue with Google")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(LinearGradient(colors: [Color.white.opacity(0.16), Color.white.opacity(0.04)], startPoint: .topLeading, endPoint: .bottomTrailing))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.white.opacity(0.22), lineWidth: 1)
            )
            .foregroundColor(.white)
        }
        .disabled(authVM.isLoading)
    }

    // private func handleAppleSignIn() async {
    //     signInError = nil
    //     do {
    //         let payload = try await AuthProvider.shared.signInWithApple()
    //         await authVM.signInWithApple(idToken: payload.idToken, nonce: payload.nonce, name: payload.displayName, email: payload.email)
    //     } catch {
    //         if let authError = error as? ASAuthorizationError {
    //             switch authError.code {
    //             case .canceled:
    //                 signInError = nil
    //             case .failed, .unknown:
    //                 signInError = "Sign in with Apple is not fully configured for this build. Enable the capability and try again."
    //             default:
    //                 signInError = authError.localizedDescription
    //             }
    //         } else {
    //             signInError = error.localizedDescription
    //         }
    //     }
    // }

    private func handleGoogleSignIn() async {
        signInError = nil
        do {
            let payload = try await AuthProvider.shared.signInWithGoogle()
            await authVM.signInWithGoogle(idToken: payload.idToken, accessToken: payload.accessToken, name: payload.displayName, email: payload.email)
        } catch {
            if let appError = error as? AppError, case .invalid = appError {
                signInError = "Update Info.plist with a valid Google client ID before testing Google Sign-In."
            } else {
                signInError = error.localizedDescription
            }
        }
    }
}
