import SwiftUI
import Combine

@MainActor
final class AppState: ObservableObject {
    @Published var selectedTab: Tab = .home
    @Published var showCreateLogSheet: Bool = false
    @Published var deepLinkDestination: DeepLinkDestination?
    @Published var unreadNotificationCount: Int = 0
    @Published var showLoginSheet: Bool = false

    /// Trigger to scroll home feed to top and refresh (incremented on each trigger)
    @Published var homeScrollToTopTrigger: Int = 0
    /// Trigger to scroll recipes list to top and refresh (incremented on each trigger)
    @Published var recipesScrollToTopTrigger: Int = 0
    /// Trigger to scroll search view to top and refresh (incremented on each trigger)
    @Published var searchScrollToTopTrigger: Int = 0
    /// Trigger to scroll profile view to top and refresh (incremented on each trigger)
    @Published var profileScrollToTopTrigger: Int = 0

    func triggerHomeScrollToTop() {
        homeScrollToTopTrigger += 1
    }

    func triggerRecipesScrollToTop() {
        recipesScrollToTopTrigger += 1
    }

    func triggerSearchScrollToTop() {
        searchScrollToTopTrigger += 1
    }

    func triggerProfileScrollToTop() {
        profileScrollToTopTrigger += 1
    }

    /// Call this to require authentication before performing an action
    func requireAuth(then action: @escaping () -> Void) {
        if AuthManager.shared.isAuthenticated {
            action()
        } else {
            pendingAuthAction = action
            showLoginSheet = true
        }
    }

    /// Action to perform after successful login
    var pendingAuthAction: (() -> Void)?

    func onLoginSuccess() {
        showLoginSheet = false
        pendingAuthAction?()
        pendingAuthAction = nil
    }

    enum Tab: Int, CaseIterable {
        case home = 0
        case recipes = 1
        case create = 2
        case saved = 3
        case profile = 4

        var title: String {
            switch self {
            case .home: return "Home"
            case .recipes: return "Recipes"
            case .create: return "Create"
            case .saved: return "Saved"
            case .profile: return "Profile"
            }
        }

        var iconName: String {
            switch self {
            case .home: return "house.fill"
            case .recipes: return "book.fill"
            case .create: return "plus.circle.fill"
            case .saved: return "bookmark.fill"
            case .profile: return "person.fill"
            }
        }
    }

    enum DeepLinkDestination: Equatable {
        case recipe(id: String)
        case log(id: String, commentId: String? = nil)
        case user(id: String)
        case hashtag(name: String)
    }

    func handleDeepLink(_ url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
              components.scheme == "cookstemma" else { return }

        let pathComponents = components.path.split(separator: "/").map(String.init)

        switch components.host {
        case "recipes":
            if let id = pathComponents.first {
                deepLinkDestination = .recipe(id: id)
            }
        case "logs":
            if let id = pathComponents.first {
                let commentId = components.queryItems?.first(where: { $0.name == "comment" })?.value
                deepLinkDestination = .log(id: id, commentId: commentId)
            }
        case "users":
            if let id = pathComponents.first {
                deepLinkDestination = .user(id: id)
            }
        case "hashtags":
            if let name = pathComponents.first {
                deepLinkDestination = .hashtag(name: name)
            }
        default:
            break
        }
    }
}
