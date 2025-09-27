import SwiftUI

@MainActor
final class AppContainer: ObservableObject {
    let backend: BackendService
    let appState: AppState
    let imageStore: ImageStoring
    let ai: AISuggestionService

    init(useVisionAI: Bool = true) {
        let backend = LocalBackendService()
        self.backend = backend
        self.appState = AppState()
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("Heartloom/Images")
        self.imageStore = ImageStore(baseURL: base)
        self.ai = useVisionAI ? VisionAISuggestionService() : FallbackAISuggestionService()
    }
}

struct RootContentView: View {
    @EnvironmentObject var container: AppContainer
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var familyVM: FamilyViewModel
    @EnvironmentObject var timelineVM: TimelineViewModel

    var body: some View {
        Group {
            if appState.currentUser == nil {
                SignInView()
            } else if appState.currentFamily == nil {
                FamilySetupView()
            } else {
                MainTabsView()
            }
        }
        .task(id: appState.currentFamily?.id) {
            await familyVM.loadChildren()
            await timelineVM.load()
        }
    }
}

struct MainTabsView: View {
    var body: some View {
        TabView {
            NavigationStack { ChildTimelineView().navigationTitle("Timeline") }
                .tabItem { Label("Timeline", systemImage: "clock") }
            NavigationStack { EntryComposerView().navigationTitle("New Entry") }
                .tabItem { Label("Add", systemImage: "plus.app") }
            NavigationStack { ChildrenListView().navigationTitle("Children") }
                .tabItem { Label("Children", systemImage: "person.2") }
            NavigationStack { SettingsView().navigationTitle("Settings") }
                .tabItem { Label("Settings", systemImage: "gear") }
        }
    }
}
