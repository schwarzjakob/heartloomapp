import SwiftUI

struct SignInView: View {
    @EnvironmentObject var authVM: AuthViewModel

    var body: some View {
        VStack(spacing: 24) {
            Text("Heartloom").font(.largeTitle).bold()
            Text("Family photo journals, together.")
                .foregroundColor(.secondary)

            VStack(alignment: .leading, spacing: 12) {
                TextField("Your name", text: $authVM.displayName)
                    .textContentType(.name)
                    .textFieldStyle(.roundedBorder)
                TextField("Email", text: $authVM.email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .textFieldStyle(.roundedBorder)
            }.padding(.horizontal)

            Button(action: { Task { await authVM.signIn() } }) {
                if authVM.isLoading { ProgressView() } else { Text("Continue") }
            }
            .buttonStyle(.borderedProminent)
            .disabled(authVM.displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || authVM.email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

            if let err = authVM.error { Text(err).foregroundColor(.red) }
            Spacer()
        }
        .padding()
    }
}
