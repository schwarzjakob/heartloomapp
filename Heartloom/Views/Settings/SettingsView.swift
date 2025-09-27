import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var familyVM: FamilyViewModel

    var body: some View {
        Form {
            Section(header: Text("Account")) {
                if let user = appState.currentUser {
                    LabeledContent("Name", value: user.displayName)
                    LabeledContent("Email", value: user.email)
                }
            }
            Section(header: Text("Family")) {
                if let fam = appState.currentFamily {
                    LabeledContent("Family", value: fam.name)
                    LabeledContent("Invite code", value: fam.inviteCode)
                }
            }
        }
    }
}
