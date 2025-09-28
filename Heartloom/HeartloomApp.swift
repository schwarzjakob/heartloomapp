import SwiftUI
import GoogleSignIn

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        return GIDSignIn.sharedInstance.handle(url)
    }
}

@main
struct HeartloomApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var container: AppContainer
    @StateObject private var authVM: AuthViewModel
    @StateObject private var familyVM: FamilyViewModel
    @StateObject private var composerVM: EntryComposerViewModel
    @StateObject private var timelineVM: TimelineViewModel

    init() {
        let c = AppContainer()
        _container = StateObject(wrappedValue: c)
        _authVM = StateObject(wrappedValue: AuthViewModel(auth: c.auth, appState: c.appState))
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
                .preferredColorScheme(.dark)
        }
    }
}
