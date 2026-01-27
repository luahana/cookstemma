import Foundation
import Combine

// MARK: - Auth State

enum AuthState: Equatable {
    case unknown
    case authenticated(user: MyProfile)
    case unauthenticated
}

// MARK: - Auth Manager Protocol

protocol AuthManagerProtocol: AnyObject {
    var authState: AuthState { get }
    var authStatePublisher: AnyPublisher<AuthState, Never> { get }
    var isAuthenticated: Bool { get }
    var currentUser: MyProfile? { get }

    func loginWithFirebase(token: String) async throws
    func logout() async
    func refreshUserProfile() async throws
}

// MARK: - Auth Manager

@MainActor
final class AuthManager: ObservableObject, AuthManagerProtocol {
    static let shared = AuthManager()

    @Published private(set) var authState: AuthState = .unknown

    var authStatePublisher: AnyPublisher<AuthState, Never> {
        $authState.eraseToAnyPublisher()
    }

    var isAuthenticated: Bool {
        if case .authenticated = authState {
            return true
        }
        return false
    }

    var currentUser: MyProfile? {
        if case .authenticated(let user) = authState {
            return user
        }
        return nil
    }

    private let apiClient: APIClientProtocol
    private let tokenManager: TokenManagerProtocol

    init(
        apiClient: APIClientProtocol = APIClient.shared,
        tokenManager: TokenManagerProtocol = TokenManager.shared
    ) {
        self.apiClient = apiClient
        self.tokenManager = tokenManager

        // Set up API client with token manager
        if let client = apiClient as? APIClient {
            client.setTokenManager(tokenManager)
        }

        // Check initial auth state
        Task {
            await checkAuthState()
        }
    }

    // MARK: - Public Methods

    func loginWithFirebase(token: String) async throws {
        let locale = Locale.current.identifier
        let response: AuthResponse = try await apiClient.request(
            AuthEndpoint.socialLogin(idToken: token, locale: locale)
        )

        tokenManager.saveTokens(
            accessToken: response.accessToken,
            refreshToken: response.refreshToken,
            expiresIn: response.expiresIn
        )

        try await fetchUserProfile()
    }

    func logout() async {
        tokenManager.clearTokens()
        authState = .unauthenticated
    }

    func refreshUserProfile() async throws {
        try await fetchUserProfile()
    }

    // MARK: - Private Methods

    private func checkAuthState() async {
        guard tokenManager.isAuthenticated else {
            authState = .unauthenticated
            return
        }

        do {
            try await fetchUserProfile()
        } catch {
            // Token might be expired or invalid
            tokenManager.clearTokens()
            authState = .unauthenticated
        }
    }

    private func fetchUserProfile() async throws {
        let profile: MyProfile = try await apiClient.request( UserEndpoint.myProfile
        )
        authState = .authenticated(user: profile)
    }
}
