import SwiftUI

@main
struct HeartloomApp: App {
    @StateObject private var container: AppContainer
    @StateObject private var authVM: AuthViewModel
    @StateObject private var familyVM: FamilyViewModel
    @StateObject private var composerVM: EntryComposerViewModel
    @StateObject private var timelineVM: TimelineViewModel

    init() {
        let c = AppContainer()
        _container = StateObject(wrappedValue: c)
        _authVM = StateObject(wrappedValue: AuthViewModel(backend: c.backend, appState: c.appState))
        _familyVM = StateObject(wrappedValue: FamilyViewModel(backend: c.backend, appState: c.appState))
        _composerVM = StateObject(wrappedValue: EntryComposerViewModel(backend: c.backend, appState: c.appState, ai: c.ai))
        _timelineVM = StateObject(wrappedValue: TimelineViewModel(backend: c.backend, imageStore: c.imageStore, appState: c.appState))
    }

    var body: some Scene {
        WindowGroup {
            RootContentView()
                .environmentObject(container)
                .environmentObject(container.appState)
                .environmentObject(authVM)
                .environmentObject(familyVM)
                .environmentObject(composerVM)
                .environmentObject(timelineVM)
        }
    }
}
