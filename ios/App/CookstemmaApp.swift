import SwiftUI

@main
struct CookstemmaApp: App {
    @StateObject private var authManager = AuthManager.shared
    @StateObject private var appState = AppState()

    init() {
        FirebaseService.shared.configure()
    }

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(authManager)
                .environmentObject(appState)
                .sheet(isPresented: $appState.showLoginSheet) {
                    LoginView(onLoginSuccess: {
                        appState.onLoginSuccess()
                    })
                    .environmentObject(authManager)
                }
                .onAppear {
                    setupAppearance()
                }
                .onOpenURL { url in
                    _ = FirebaseService.handleOpenURL(url)
                }
        }
    }

    private func setupAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}
