import SwiftUI

struct ChildrenListView: View {
    @EnvironmentObject var familyVM: FamilyViewModel
    @EnvironmentObject var appState: AppState

    @State private var childName: String = ""
    @State private var birthdate: Date? = nil
    @State private var showingAdd = false

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                if familyVM.children.isEmpty {
                    GlassCard {
                        VStack(spacing: 12) {
                            Image(systemName: "person.crop.circle.badge.plus")
                                .font(.system(size: 40))
                                .foregroundStyle(LinearGradient(colors: [.white.opacity(0.9), Color(red: 0.6, green: 0.85, blue: 1.0)], startPoint: .top, endPoint: .bottom))
                            Text("No children yet")
                                .font(.headline)
                            Text("Add your first child to begin weaving together their journey.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                    }
                } else {
                    ForEach(familyVM.children) { child in
                        Button(action: {
                            appState.selectedChild = child
                        }) {
                            GlassCard(cornerRadius: 24, padding: 18) {
                                HStack(spacing: 16) {
                                    Circle()
                                        .fill(LinearGradient(colors: [Color(red: 0.4, green: 0.7, blue: 1.0), Color(red: 0.78, green: 0.42, blue: 0.95)], startPoint: .topLeading, endPoint: .bottomTrailing))
                                        .opacity(0.5)
                                        .frame(width: 46, height: 46)
                                        .overlay(
                                            Image(systemName: appState.selectedChild?.id == child.id ? "checkmark.circle.fill" : "person.crop.circle")
                                                .font(.system(size: 26, weight: .medium))
                                                .foregroundStyle(.white)
                                        )

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(child.name)
                                            .font(.headline)
                                        if let bd = child.birthdate {
                                            Text(DateFormatter.localizedString(from: bd, dateStyle: .medium, timeStyle: .none))
                                                .font(.footnote)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.forward")
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }

                Button(action: { showingAdd = true }) {
                    Label("Add a child", systemImage: "plus.circle")
                        .labelStyle(.titleAndIcon)
                }
                .buttonStyle(GlassButtonStyle(tint: LinearGradient(colors: [Color(red: 0.32, green: 0.86, blue: 0.94), Color(red: 0.72, green: 0.55, blue: 1.0)], startPoint: .topLeading, endPoint: .bottomTrailing)))
            }
            .padding(.vertical, 22)
            .padding(.horizontal, 24)
        }
        .scrollIndicators(.hidden)
        .sheet(isPresented: $showingAdd) {
            NavigationStack { AddChildSheet(childName: $childName, birthdate: $birthdate) }
        }
        .task { await familyVM.loadChildren() }
    }
}

private struct AddChildSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var familyVM: FamilyViewModel
    @Binding var childName: String
    @Binding var birthdate: Date?
    @FocusState private var isNameFocused: Bool

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                GlassCard {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("New child")
                            .font(.title2.weight(.semibold))
                        TextField("Name", text: $childName)
                            .textFieldStyle(.glass)
                            .focused($isNameFocused)

                        Toggle("Add birthdate", isOn: Binding(get: { birthdate != nil }, set: { val in birthdate = val ? Date() : nil }))
                            .toggleStyle(SwitchToggleStyle(tint: Color(red: 0.52, green: 0.75, blue: 1.0)))

                        if let _ = birthdate {
                            DatePicker("Birthdate", selection: Binding(get: { birthdate ?? Date() }, set: { birthdate = $0 }), displayedComponents: .date)
                                .datePickerStyle(.graphical)
                                .background(
                                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                                        .fill(.ultraThinMaterial)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        }

                        Button("Save") {
                            Task { await familyVM.createChild(name: childName, birthdate: birthdate); dismiss() }
                        }
                        .buttonStyle(GlassButtonStyle())
                        .disabled(childName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
            }
            .padding(24)
        }
        .background(LiquidGlassBackground().ignoresSafeArea())
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle("New Child")
        .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Close", action: { dismiss() }) } }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { isNameFocused = false }
            }
        }
    }
}
