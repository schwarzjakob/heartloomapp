import SwiftUI
import PhotosUI

struct EntryComposerView: View {
    @EnvironmentObject var composerVM: EntryComposerViewModel
    @EnvironmentObject var familyVM: FamilyViewModel
    @EnvironmentObject var appState: AppState

    @State private var showCamera = false

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                mediaSection
                childPickerSection
                descriptionSection
                tagsSection

                Button(action: { Task { await composerVM.saveEntry() } }) {
                    if composerVM.isSaving {
                        ProgressView().tint(.white)
                    } else {
                        Label("Save entry", systemImage: "sparkles.rectangle.stack")
                    }
                }
                .buttonStyle(GlassButtonStyle())
                .disabled(composerVM.selectedImages.isEmpty || composerVM.selectedChildIds.isEmpty)

                if let err = composerVM.error {
                    Text(err)
                        .font(.footnote)
                        .foregroundColor(.pink)
                }
            }
            .padding(.vertical, 24)
        }
        .scrollIndicators(.hidden)
        .sheet(isPresented: $showCamera) {
            ImagePickerRepresentable(sourceType: .camera) { image in
                if let image { composerVM.addCameraImage(image) }
            }
        }
        .onAppear { Task { await familyVM.loadChildren() } }
    }

    private var mediaSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 18) {
                Text("Photos & moments")
                    .font(.title3.weight(.semibold))
                Text("Import from your library or capture something new. Heartloom applies Liquid Glass styling to every memory you capture.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                HStack(spacing: 12) {
                    PhotosPicker(selection: $composerVM.selectedPickerItems, matching: .images, preferredItemEncoding: .current, photoLibrary: .shared()) {
                        Label("Library", systemImage: "photo.on.rectangle")
                            .glassChip()
                    }
                    .onChange(of: composerVM.selectedPickerItems) { _ in Task { await composerVM.loadSelectedImages() } }

                    Button(action: { showCamera = true }) {
                        Label("Capture", systemImage: "camera")
                            .glassChip()
                    }
                }

                if !composerVM.selectedImages.isEmpty {
                    ImageCarouselView(images: composerVM.selectedImages)
                        .frame(height: 250)
                        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(Color.white.opacity(0.35)))
                }
            }
        }
    }

    private var childPickerSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Who is in this memory?")
                    .font(.title3.weight(.semibold))
                ChildPillSelectView(children: familyVM.children, selection: $composerVM.selectedChildIds)
            }
        }
    }

    private var descriptionSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Story details")
                    .font(.title3.weight(.semibold))
                TextEditor(text: $composerVM.descriptionText)
                    .frame(minHeight: 140)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(.ultraThinMaterial)
                            .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(Color.white.opacity(0.25)))
                    )
                    .foregroundStyle(.primary)

                Button("Suggestions") {
                    Task { await composerVM.suggestDescription(children: familyVM.children) }
                }
                .buttonStyle(GlassButtonStyle(tint: LinearGradient(colors: [Color(red: 0.58, green: 0.7, blue: 1.0), Color(red: 0.83, green: 0.45, blue: 1.0)], startPoint: .topLeading, endPoint: .bottomTrailing)))
            }
        }
    }

    private var tagsSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                Text("Tags")
                    .font(.title3.weight(.semibold))
                TextField("e.g., first steps, birthday", text: $composerVM.tags)
                    .textFieldStyle(.glass)

                if !composerVM.tags.isEmpty {
                    let current = composerVM.tags.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(current, id: \.self) { tag in
                                Text(tag.uppercased())
                                    .font(.caption2.weight(.semibold))
                                    .glassChip(cornerRadius: 12)
                            }
                        }
                    }
                }
            }
        }
    }
}
