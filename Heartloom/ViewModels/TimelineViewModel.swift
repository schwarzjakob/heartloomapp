import Foundation
import UIKit

@MainActor
final class TimelineViewModel: ObservableObject {
    @Published var entries: [JournalEntry] = []
    @Published var isLoading: Bool = false
    @Published var error: String?

    private let backend: BackendService
    private let imageStore: ImageStoring
    private let appState: AppState

    init(backend: BackendService, imageStore: ImageStoring, appState: AppState) {
        self.backend = backend
        self.imageStore = imageStore
        self.appState = appState
    }

    func load() async {
        guard let childId = appState.selectedChild?.id else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            entries = try await backend.entries(forChild: childId)
        } catch {
            self.error = error.localizedDescription
        }
    }

    func image(for assetId: ID) -> UIImage? {
        let asset = PhotoAsset(id: assetId, fileName: "\(assetId).jpg", createdAt: Date())
        if let data = imageStore.loadImageData(for: asset) { return UIImage(data: data) }
        return nil
    }
}
