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
            Group {
                switch authManager.authState {
                case .unknown:
                    SplashView()
                case .authenticated, .unauthenticated:
                    MainTabView()
                        .sheet(isPresented: $appState.showLoginSheet) {
                            LoginView(onLoginSuccess: {
                                appState.onLoginSuccess()
                            })
                            .environmentObject(authManager)
                        }
                }
            }
            .environmentObject(authManager)
            .environmentObject(appState)
            .animation(.easeInOut(duration: 0.3), value: authManager.authState)
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
