import SwiftUI
import UIKit

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
        ZStack {
            LiquidGlassBackground()
            Group {
                if appState.currentUser == nil {
                    SignInView()
                        .transition(.opacity.combined(with: .scale))
                } else if appState.currentFamily == nil {
                    FamilySetupView()
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                } else {
                    MainTabsView()
                        .transition(.opacity)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .animation(.easeInOut(duration: 0.35), value: appState.currentUser?.id)
            .animation(.easeInOut(duration: 0.35), value: appState.currentFamily?.id)
        }
        .task(id: appState.currentFamily?.id) {
            await familyVM.loadChildren()
            await timelineVM.load()
        }
    }
}

struct MainTabsView: View {
    init() {
        let tabBar = UITabBar.appearance()
        tabBar.unselectedItemTintColor = UIColor.white.withAlphaComponent(0.6)
        tabBar.backgroundImage = UIImage()
        tabBar.isTranslucent = true
    }

    var body: some View {
        TabView {
            NavigationStack {
                ChildTimelineView()
                    .navigationTitle("Timeline")
            }
            .tabItem { Label("Timeline", systemImage: "sparkle") }

            NavigationStack {
                EntryComposerView()
                    .navigationTitle("New Entry")
            }
            .tabItem { Label("Add", systemImage: "plus.rectangle.on.rectangle") }

            NavigationStack {
                ChildrenListView()
                    .navigationTitle("Children")
            }
            .tabItem { Label("Children", systemImage: "person.2.fill") }

            NavigationStack {
                SettingsView()
                    .navigationTitle("Settings")
            }
            .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
        .tint(Color(red: 0.72, green: 0.82, blue: 1.0))
    }
}
