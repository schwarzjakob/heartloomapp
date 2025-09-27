import SwiftUI

struct SignInView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @FocusState private var focusedField: Field?

    private enum Field { case name, email }

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
                            .focused($focusedField, equals: .name)
                            .submitLabel(.next)

                        TextField("Email", text: $authVM.email)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .textFieldStyle(.glass)
                            .focused($focusedField, equals: .email)
                            .submitLabel(.done)
                            .onSubmit { Task { await authVM.signIn() } }
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
            .padding(.horizontal, 24)
            
            Spacer()
        }
        .padding(.vertical, 32)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { focusedField = nil }
            }
        }
    }
}
