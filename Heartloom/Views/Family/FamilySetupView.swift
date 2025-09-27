import SwiftUI

struct FamilySetupView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var familyVM: FamilyViewModel

    @State private var newFamilyName: String = ""
    @State private var joinCode: String = ""

    var body: some View {
        Form {
            Section(header: Text("Create Family")) {
                TextField("Family name", text: $newFamilyName)
                Button("Create") {
                    familyVM.familyName = newFamilyName
                    Task { await familyVM.createFamily() }
                }.disabled(newFamilyName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }

            Section(header: Text("Join Family")) {
                TextField("Invite code", text: $joinCode)
                    .textInputAutocapitalization(.characters)
                Button("Join") {
                    familyVM.inviteCode = joinCode
                    Task { await familyVM.joinFamily() }
                }.disabled(joinCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }

            if let err = familyVM.error { Text(err).foregroundColor(.red) }
        }
        .navigationTitle("Your Family")
        .onAppear { Task { await familyVM.loadFamilies() } }
    }
}
