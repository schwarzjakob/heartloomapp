import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var familyVM: FamilyViewModel
    @EnvironmentObject var authVM: AuthViewModel

    @State private var showSignOutConfirm = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                GlassCard {
                    VStack(alignment: .leading, spacing: 18) {
                        Text("Account")
                            .font(.title3.weight(.semibold))
                        if let user = appState.currentUser {
                            settingsRow(title: "Name", value: user.displayName, systemIcon: "person.circle")
                            settingsRow(title: "Email", value: user.email, systemIcon: "envelope")
                        }
                        Button(role: .destructive) {
                            showSignOutConfirm = true
                        } label: {
                            Label("Sign out", systemImage: "arrow.backward.circle")
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .tint(.pink)
                    }
                }

                GlassCard {
                    VStack(alignment: .leading, spacing: 18) {
                        Text("Family space")
                            .font(.title3.weight(.semibold))
                        if let fam = appState.currentFamily {
                            settingsRow(title: "Family", value: fam.name, systemIcon: "house")
                            settingsRow(title: "Invite code", value: fam.inviteCode, systemIcon: "person.3.sequence")
                            NavigationLink(destination: FamilyMembersView()) {
                                Label("Members & roles", systemImage: "person.3.fill")
                            }
                            .buttonStyle(.plain)
                        } else {
                            Text("Create or join a family to unlock the shared timeline experience.")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .padding(.vertical, 24)
            .padding(.horizontal, 24)
        }
        .scrollIndicators(.hidden)
        .confirmationDialog("Sign out of Heartloom?", isPresented: $showSignOutConfirm) {
            Button("Sign out", role: .destructive) {
                Task {
                    await authVM.signOut()
                    familyVM.families = []
                    familyVM.children = []
                    familyVM.members = []
                }
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    private func settingsRow(title: String, value: String, systemIcon: String) -> some View {
        HStack(alignment: .center, spacing: 14) {
            Image(systemName: systemIcon)
                .font(.title3)
                .frame(width: 32, height: 32)
                .foregroundStyle(LinearGradient(colors: [Color(red: 0.54, green: 0.7, blue: 1.0), Color(red: 0.82, green: 0.45, blue: 1.0)], startPoint: .topLeading, endPoint: .bottomTrailing))
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(.ultraThinMaterial)
                )
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.headline)
            }
            Spacer()
        }
    }
}
