import Foundation
import Security

// MARK: - Token Manager

final class TokenManager: TokenManagerProtocol {
    static let shared = TokenManager()

    private let keychainService = "com.cookstemma.app"
    private let accessTokenKey = "accessToken"
    private let refreshTokenKey = "refreshToken"
    private let tokenExpiryKey = "tokenExpiry"

    private var cachedAccessToken: String?
    private var cachedRefreshToken: String?
    private var tokenExpiryDate: Date?

    var accessToken: String? {
        if let cached = cachedAccessToken {
            return cached
        }
        cachedAccessToken = getKeychainValue(key: accessTokenKey)
        return cachedAccessToken
    }

    var refreshToken: String? {
        if let cached = cachedRefreshToken {
            return cached
        }
        cachedRefreshToken = getKeychainValue(key: refreshTokenKey)
        return cachedRefreshToken
    }

    var isAuthenticated: Bool {
        accessToken != nil && !isTokenExpired()
    }

    init() {
        // Load token expiry from UserDefaults
        tokenExpiryDate = UserDefaults.standard.object(forKey: tokenExpiryKey) as? Date
    }

    func saveTokens(accessToken: String, refreshToken: String) {
        // Save to Keychain
        setKeychainValue(value: accessToken, key: accessTokenKey)
        setKeychainValue(value: refreshToken, key: refreshTokenKey)

        // Use default 1 hour expiry (backend doesn't return expiresIn)
        let expiryDate = Date().addingTimeInterval(3600)
        UserDefaults.standard.set(expiryDate, forKey: tokenExpiryKey)

        // Update cache
        cachedAccessToken = accessToken
        cachedRefreshToken = refreshToken
        tokenExpiryDate = expiryDate
    }

    func refreshAccessToken() async throws {
        guard let refreshToken = refreshToken else {
            throw APIError.unauthorized
        }

        // Call the refresh token API
        let response: AuthResponse = try await APIClient.shared.request(
            AuthEndpoint.refreshToken(refreshToken: refreshToken)
        )

        saveTokens(
            accessToken: response.accessToken,
            refreshToken: response.refreshToken
        )
    }

    func clearTokens() {
        deleteKeychainValue(key: accessTokenKey)
        deleteKeychainValue(key: refreshTokenKey)
        UserDefaults.standard.removeObject(forKey: tokenExpiryKey)

        cachedAccessToken = nil
        cachedRefreshToken = nil
        tokenExpiryDate = nil
    }

    private func isTokenExpired() -> Bool {
        guard let expiry = tokenExpiryDate else { return true }
        // Add 60 second buffer
        return Date().addingTimeInterval(60) >= expiry
    }

    // MARK: - Keychain Helpers

    private func setKeychainValue(value: String, key: String) {
        guard let data = value.data(using: .utf8) else { return }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: key
        ]

        // Delete existing item
        SecItemDelete(query as CFDictionary)

        // Add new item
        var newItem = query
        newItem[kSecValueData as String] = data
        SecItemAdd(newItem as CFDictionary, nil)
    }

    private func getKeychainValue(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let value = String(data: data, encoding: .utf8) else {
            return nil
        }

        return value
    }

    private func deleteKeychainValue(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(query as CFDictionary)
    }
}
