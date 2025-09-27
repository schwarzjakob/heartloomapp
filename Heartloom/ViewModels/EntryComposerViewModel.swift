import Foundation
import SwiftUI
import PhotosUI

@MainActor
final class EntryComposerViewModel: ObservableObject {
    @Published var selectedPickerItems: [PhotosPickerItem] = []
    @Published var selectedImages: [UIImage] = []
    @Published var selectedChildIds: Set<ID> = []
    @Published var descriptionText: String = ""
    @Published var tags: String = "" // comma-separated input
    @Published var isSaving: Bool = false
    @Published var error: String?

    private let backend: BackendService
    private let appState: AppState
    private let ai: AISuggestionService

    init(backend: BackendService, appState: AppState, ai: AISuggestionService) {
        self.backend = backend
        self.appState = appState
        self.ai = ai
    }

    func loadSelectedImages() async {
        var images: [UIImage] = []
        for item in selectedPickerItems {
            if let data = try? await item.loadTransferable(type: Data.self), let img = UIImage(data: data) {
                images.append(img)
            }
        }
        self.selectedImages = images
    }

    func addCameraImage(_ image: UIImage) {
        selectedImages.append(image)
    }

    func suggestDescription(children: [ChildProfile]) async {
        let s = await ai.generateSuggestion(for: selectedImages, children: children.filter { selectedChildIds.contains($0.id) })
        if descriptionText.isEmpty { descriptionText = s } else { descriptionText += "\n\n" + s }
    }

    func saveEntry() async {
        guard !selectedImages.isEmpty else { return }
        guard let fid = appState.currentFamily?.id, let uid = appState.currentUser?.id else { return }
        let childIds = Array(selectedChildIds)
        isSaving = true
        defer { isSaving = false }
        do {
            let assets = try await backend.savePhotos(selectedImages)
            let photoIds = assets.map { $0.id }
            let tagList = tags.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
            _ = try await backend.createJournalEntry(familyId: fid, childIds: childIds, photoIds: photoIds, description: descriptionText, tags: tagList, uploaderId: uid)
            // reset
            selectedPickerItems.removeAll()
            selectedImages.removeAll()
            selectedChildIds.removeAll()
            descriptionText = ""
            tags = ""
        } catch {
            self.error = error.localizedDescription
        }
    }
}
