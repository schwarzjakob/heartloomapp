import SwiftUI

struct SignInView: View {
    @EnvironmentObject var authVM: AuthViewModel

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
                        TextField("Your name", text: $authVM.displayName)
                            .textContentType(.name)
                            .textFieldStyle(.glass)

                        TextField("Email", text: $authVM.email)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .textFieldStyle(.glass)
                    }

                    Button(action: { Task { await authVM.signIn() } }) {
                        if authVM.isLoading {
                            ProgressView().tint(.white)
                        } else {
                            Text("Enter Heartloom")
                        }
                    }
                    .buttonStyle(GlassButtonStyle())
                    .disabled(authVM.displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || authVM.email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                    if let err = authVM.error {
                        Text(err)
                            .font(.footnote)
                            .foregroundColor(.pink)
                    }
                }
            }
            .shadow(color: Color.black.opacity(0.3), radius: 30, y: 20)

            Spacer()
        }
        .padding(.vertical, 32)
    }
}
