import SwiftUI

struct FamilySetupView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var familyVM: FamilyViewModel

    @State private var newFamilyName: String = ""
    @State private var joinCode: String = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                GlassCard {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Create a family space")
                            .font(.title2.weight(.semibold))
                        Text("Start a private space where trusted members can capture the story together. You can add children later or import existing journals.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        TextField("Family name", text: $newFamilyName)
                            .textFieldStyle(.glass)

                        Button(action: {
                            familyVM.familyName = newFamilyName
                            Task { await familyVM.createFamily() }
                        }) {
                            if familyVM.isLoading {
                                ProgressView().tint(.white)
                            } else {
                                Label("Create family", systemImage: "sparkles")
                            }
                        }
                        .buttonStyle(GlassButtonStyle())
                        .disabled(newFamilyName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }

                GlassCard {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Join with an invite")
                            .font(.title2.weight(.semibold))
                        Text("Enter the invite code a partner or family member shared to join their journal space.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        TextField("Invite code", text: $joinCode)
                            .textInputAutocapitalization(.characters)
                            .textFieldStyle(.glass)

                        Button(action: {
                            familyVM.inviteCode = joinCode
                            Task { await familyVM.joinFamily() }
                        }) {
                            Label("Join family", systemImage: "person.2.badge.gearshape")
                        }
                        .buttonStyle(GlassButtonStyle(tint: LinearGradient(colors: [Color(red: 0.52, green: 0.65, blue: 1.0), Color(red: 0.3, green: 0.83, blue: 0.89)], startPoint: .topLeading, endPoint: .bottomTrailing)))
                        .disabled(joinCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }

                if let err = familyVM.error {
                    Text(err)
                        .font(.footnote)
                        .foregroundColor(.pink)
                        .padding(.horizontal)
                }
            }
            .padding(.vertical, 24)
        }
        .navigationTitle("Your Family")
        .toolbarBackground(.hidden, for: .navigationBar)
        .scrollIndicators(.hidden)
        .onAppear { Task { await familyVM.loadFamilies() } }
    }
}
