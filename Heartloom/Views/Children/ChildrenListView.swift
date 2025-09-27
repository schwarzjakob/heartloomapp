import SwiftUI

struct ChildrenListView: View {
    @EnvironmentObject var familyVM: FamilyViewModel
    @EnvironmentObject var appState: AppState

    @State private var childName: String = ""
    @State private var birthdate: Date? = nil
    @State private var showingAdd = false

    var body: some View {
        VStack {
            if familyVM.children.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "person.crop.circle.badge.plus").font(.system(size: 40))
                    Text("No children yet").font(.headline)
                    Text("Add your child to start journaling.").foregroundColor(.secondary)
                }.padding()
            } else {
                List(familyVM.children) { child in
                    Button(action: { appState.selectedChild = child }) {
                        HStack {
                            Image(systemName: appState.selectedChild?.id == child.id ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(.accentColor)
                            Text(child.name)
                            Spacer()
                            if let bd = child.birthdate {
                                Text(DateFormatter.localizedString(from: bd, dateStyle: .medium, timeStyle: .none))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }

            Button(action: { showingAdd = true }) {
                Label("Add Child", systemImage: "plus")
            }.buttonStyle(.borderedProminent)
            .padding()
        }
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
    @State private var hasDate: Bool = false

    var body: some View {
        Form {
            TextField("Name", text: $childName)
            Toggle("Add birthdate", isOn: Binding(get: { birthdate != nil }, set: { val in birthdate = val ? Date() : nil }))
            if let _ = birthdate {
                DatePicker("Birthdate", selection: Binding(get: { birthdate ?? Date() }, set: { birthdate = $0 }), displayedComponents: .date)
            }
            Button("Save") {
                Task { await familyVM.createChild(name: childName, birthdate: birthdate); dismiss() }
            }.disabled(childName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .navigationTitle("New Child")
        .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel", action: { dismiss() }) } }
    }
}
