import SwiftUI

struct FamilyMembersView: View {
    @EnvironmentObject var familyVM: FamilyViewModel
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var memberPendingRemoval: UserAccount?
    @State private var showLeaveConfirmation = false

    private var currentUser: UserAccount? { appState.currentUser }
    private var currentFamily: Family? { appState.currentFamily }
    private var isOwner: Bool { currentUser?.id == currentFamily?.ownerId }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                if let family = currentFamily {
                    GlassCard {
                        VStack(alignment: .leading, spacing: 10) {
                            Text(family.name)
                                .font(.title3.weight(.semibold))
                            Text("Manage who can contribute to this family journal. Owners can remove members; members can leave anytime.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                if familyVM.membersLoading {
                    ProgressView().tint(.white)
                }

                if !familyVM.membersLoading && familyVM.members.isEmpty {
                    GlassCard {
                        Text("No members yet. Share the invite code to add family." )
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }

                ForEach(familyVM.members) { member in
                    GlassCard(cornerRadius: 24, padding: 18) {
                        HStack(spacing: 14) {
                            Circle()
                                .fill(LinearGradient(colors: [Color(red: 0.55, green: 0.73, blue: 1.0), Color(red: 0.88, green: 0.47, blue: 1.0)], startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(width: 48, height: 48)
                                .overlay(Text(initials(for: member)).font(.headline.weight(.bold)).foregroundColor(.white))

                            VStack(alignment: .leading, spacing: 4) {
                                Text(member.displayName)
                                    .font(.headline)
                                if !member.email.isEmpty {
                                    Text(member.email)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                roleBadge(for: member)
                            }
                            Spacer()
                            actionButton(for: member)
                        }
                    }
                }

                if let err = familyVM.error {
                    Text(err)
                        .font(.footnote)
                        .foregroundColor(.pink)
                        .padding(.top, 8)
                }
            }
            .padding(.vertical, 24)
            .padding(.horizontal, 24)
        }
        .scrollIndicators(.hidden)
        .navigationTitle("Members & Roles")
        .task { await familyVM.refreshMembers() }
        .onChange(of: appState.currentFamily?.id) { newValue in
            if newValue == nil {
                dismiss()
            }
        }
        .confirmationDialog("Remove member?", isPresented: Binding(get: { memberPendingRemoval != nil }, set: { if !$0 { memberPendingRemoval = nil } }), presenting: memberPendingRemoval) { member in
            Button("Remove \(member.displayName)", role: .destructive) {
                Task { await familyVM.removeMember(member); memberPendingRemoval = nil }
            }
            Button("Cancel", role: .cancel) { memberPendingRemoval = nil }
        } message: { member in
            Text("They will lose access to this family journal.")
        }
        .confirmationDialog("Leave this family?", isPresented: $showLeaveConfirmation) {
            Button("Leave Family", role: .destructive) {
                Task { await familyVM.leaveCurrentFamily() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("You will no longer see shared entries or children.")
        }
    }

    @ViewBuilder
    private func actionButton(for member: UserAccount) -> some View {
        if let family = currentFamily, let current = currentUser {
            if isOwner && member.id != family.ownerId {
                if familyVM.removingMembers.contains(member.id) {
                    ProgressView().tint(.white)
                } else {
                    Button(role: .destructive) {
                        memberPendingRemoval = member
                    } label: {
                        Image(systemName: "trash")
                    }
                }
            } else if member.id == current.id && member.id != family.ownerId {
                if familyVM.leavingFamily {
                    ProgressView().tint(.white)
                } else {
                    Button("Leave") {
                        showLeaveConfirmation = true
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.pink)
                }
            }
        } else {
            EmptyView()
        }
    }

    @ViewBuilder
    private func roleBadge(for member: UserAccount) -> some View {
        if let ownerId = currentFamily?.ownerId {
            let text = member.id == ownerId ? "OWNER" : "MEMBER"
            let color: Color = member.id == ownerId ? .green : .secondary
            Text(text)
                .font(.caption2.weight(.semibold))
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    Capsule().fill(color.opacity(0.18))
                )
        }
    }

    private func initials(for user: UserAccount) -> String {
        let components = user.displayName.split(separator: " ")
        if let first = components.first?.first {
            if components.count > 1, let second = components.last?.first {
                return String([first, second])
            }
            return String(first)
        }
        if let emailFirst = user.email.first { return String(emailFirst) }
        return "?"
    }
}
