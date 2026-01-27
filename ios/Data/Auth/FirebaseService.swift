import Foundation
import FirebaseCore
import FirebaseAuth
import GoogleSignIn
import AuthenticationServices
import CryptoKit

// MARK: - Firebase Service Protocol

protocol FirebaseServiceProtocol {
    func configure()
    func signInWithGoogle() async throws -> String
    func signInWithApple() async throws -> String
    func signOut()
}

// MARK: - Firebase Service

final class FirebaseService: NSObject, FirebaseServiceProtocol {
    static let shared = FirebaseService()

    private var currentNonce: String?
    private var appleSignInContinuation: CheckedContinuation<ASAuthorization, Error>?

    private override init() {
        super.init()
    }

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
        let nonce = randomNonceString()
        currentNonce = nonce

        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)

        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self

        let authorization = try await withCheckedThrowingContinuation { continuation in
            self.appleSignInContinuation = continuation
            authorizationController.performRequests()
        }

        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let appleIDToken = appleIDCredential.identityToken,
              let idTokenString = String(data: appleIDToken, encoding: .utf8),
              let nonce = currentNonce else {
            throw FirebaseServiceError.missingIdToken
        }

        let credential = OAuthProvider.appleCredential(
            withIDToken: idTokenString,
            rawNonce: nonce,
            fullName: appleIDCredential.fullName
        )

        let authResult = try await Auth.auth().signIn(with: credential)
        let firebaseToken = try await authResult.user.getIDToken()

        return firebaseToken
    }

    // MARK: - Nonce Helpers

    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
        }
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        return String(randomBytes.map { charset[Int($0) % charset.count] })
    }

    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        return hashedData.compactMap { String(format: "%02x", $0) }.joined()
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
    case appleSignInFailed(String)

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Firebase is not configured"
        case .noRootViewController:
            return "Could not find root view controller"
        case .missingIdToken:
            return "Could not get ID token"
        case .missingFirebaseToken:
            return "Could not get Firebase token"
        case .notImplemented:
            return "This feature is not yet implemented"
        case .appleSignInFailed(let message):
            return "Apple Sign-In failed: \(message)"
        }
    }
}

// MARK: - ASAuthorizationControllerDelegate

extension FirebaseService: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        appleSignInContinuation?.resume(returning: authorization)
        appleSignInContinuation = nil
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        appleSignInContinuation?.resume(throwing: error)
        appleSignInContinuation = nil
    }
}
