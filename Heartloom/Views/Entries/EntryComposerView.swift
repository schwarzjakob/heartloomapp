import SwiftUI
import PhotosUI

struct EntryComposerView: View {
    @EnvironmentObject var composerVM: EntryComposerViewModel
    @EnvironmentObject var familyVM: FamilyViewModel
    @EnvironmentObject var appState: AppState

    @State private var showCamera = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                PhotosPicker(selection: $composerVM.selectedPickerItems, matching: .images, preferredItemEncoding: .current, photoLibrary: .shared()) {
                    Label("Select Photos", systemImage: "photo.on.rectangle")
                }
                .onChange(of: composerVM.selectedPickerItems) { _ in Task { await composerVM.loadSelectedImages() } }

                Button(action: { showCamera = true }) {
                    Label("Take Photo", systemImage: "camera")
                }
                .sheet(isPresented: $showCamera) {
                    ImagePickerRepresentable(sourceType: .camera) { image in
                        if let image { composerVM.addCameraImage(image) }
                    }
                }

                if !composerVM.selectedImages.isEmpty {
                    ImageCarouselView(images: composerVM.selectedImages)
                        .frame(height: 220)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                Text("Select Children").font(.headline)
                ChildPillSelectView(children: familyVM.children, selection: $composerVM.selectedChildIds)

                Text("Description").font(.headline)
                TextEditor(text: $composerVM.descriptionText)
                    .frame(minHeight: 120)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.2)))

                Button("Suggest Description") {
                    Task { await composerVM.suggestDescription(children: familyVM.children) }
                }

                Text("Tags (comma-separated)").font(.headline)
                TextField("e.g., birthday, first steps", text: $composerVM.tags)
                    .textFieldStyle(.roundedBorder)

                Button(action: { Task { await composerVM.saveEntry() } }) {
                    if composerVM.isSaving { ProgressView() } else { Text("Save Entry") }
                }
                .buttonStyle(.borderedProminent)
                .disabled(composerVM.selectedImages.isEmpty || composerVM.selectedChildIds.isEmpty)

                if let err = composerVM.error { Text(err).foregroundColor(.red) }
            }
            .padding()
        }
        .onAppear { Task { await familyVM.loadChildren() } }
    }
}
