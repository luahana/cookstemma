import Foundation
import FirebaseCore
import FirebaseAuth
import GoogleSignIn

// MARK: - Firebase Service Protocol

protocol FirebaseServiceProtocol {
    func configure()
    func signInWithGoogle() async throws -> String
    func signInWithApple() async throws -> String
    func signOut()
}

// MARK: - Firebase Service

final class FirebaseService: FirebaseServiceProtocol {
    static let shared = FirebaseService()

    private init() {}

    // MARK: - Configuration

    func configure() {
        guard FirebaseApp.app() == nil else { return }
        FirebaseApp.configure()
    }

    // MARK: - Google Sign In

    /// Signs in with Google and returns Firebase ID token
    func signInWithGoogle() async throws -> String {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            throw FirebaseServiceError.notConfigured
        }

        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config

        guard let windowScene = await UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = await windowScene.windows.first?.rootViewController else {
            throw FirebaseServiceError.noRootViewController
        }

        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)

        guard let idToken = result.user.idToken?.tokenString else {
            throw FirebaseServiceError.missingIdToken
        }

        let credential = GoogleAuthProvider.credential(
            withIDToken: idToken,
            accessToken: result.user.accessToken.tokenString
        )

        let authResult = try await Auth.auth().signIn(with: credential)
        let firebaseToken = try await authResult.user.getIDToken()

        return firebaseToken
    }

    // MARK: - Apple Sign In

    /// Signs in with Apple and returns Firebase ID token
    func signInWithApple() async throws -> String {
        // TODO: Implement Apple Sign In
        throw FirebaseServiceError.notImplemented
    }

    // MARK: - Sign Out

    func signOut() {
        GIDSignIn.sharedInstance.signOut()
        try? Auth.auth().signOut()
    }

    // MARK: - URL Handling

    static func handleOpenURL(_ url: URL) -> Bool {
        return GIDSignIn.sharedInstance.handle(url)
    }
}

// MARK: - Errors

enum FirebaseServiceError: LocalizedError {
    case notConfigured
    case noRootViewController
    case missingIdToken
    case missingFirebaseToken
    case notImplemented

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Firebase is not configured"
        case .noRootViewController:
            return "Could not find root view controller"
        case .missingIdToken:
            return "Could not get Google ID token"
        case .missingFirebaseToken:
            return "Could not get Firebase token"
        case .notImplemented:
            return "This feature is not yet implemented"
        }
    }
}
