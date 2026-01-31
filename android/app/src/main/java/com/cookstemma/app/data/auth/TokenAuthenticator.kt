package com.cookstemma.app.data.auth

import com.cookstemma.app.data.api.ApiService
import com.cookstemma.app.data.api.RefreshTokenRequest
import kotlinx.coroutines.runBlocking
import okhttp3.Authenticator
import okhttp3.Request
import okhttp3.Response
import okhttp3.Route
import javax.inject.Inject
import javax.inject.Provider
import javax.inject.Singleton

/**
 * OkHttp Authenticator that handles 401 responses by automatically
 * refreshing the access token and retrying the original request.
 *
 * Uses Provider<ApiService> to avoid circular dependency since ApiService
 * depends on OkHttpClient which depends on this Authenticator.
 */
@Singleton
class TokenAuthenticator @Inject constructor(
    private val tokenManager: TokenManager,
    private val apiService: Provider<ApiService>
) : Authenticator {

    companion object {
        private const val HEADER_RETRY_WITH_REFRESH = "X-Retry-With-Refresh"
    }

    override fun authenticate(route: Route?, response: Response): Request? {
        // Don't retry if we already retried with a refreshed token
        if (response.request.header(HEADER_RETRY_WITH_REFRESH) != null) {
            return null
        }

        // Don't try to refresh for auth endpoints (login, refresh itself)
        if (response.request.url.encodedPath.contains("/auth/")) {
            return null
        }

        synchronized(this) {
            // Check if another thread already refreshed the token
            val currentToken = tokenManager.getAccessToken()
            val requestToken = response.request.header("Authorization")
                ?.removePrefix("Bearer ")

            // If current token is different from request token, another thread refreshed it
            if (currentToken != null && currentToken != requestToken) {
                // Retry with the new token
                return response.request.newBuilder()
                    .header("Authorization", "Bearer $currentToken")
                    .header(HEADER_RETRY_WITH_REFRESH, "true")
                    .build()
            }

            // Try to refresh the token
            val refreshToken = tokenManager.getRefreshToken() ?: return null

            return runBlocking {
                try {
                    val authResponse = apiService.get().refreshToken(
                        RefreshTokenRequest(refreshToken)
                    )

                    tokenManager.saveTokens(
                        accessToken = authResponse.accessToken,
                        refreshToken = authResponse.refreshToken,
                        expiresIn = authResponse.expiresIn
                    )

                    // Retry original request with new token
                    response.request.newBuilder()
                        .header("Authorization", "Bearer ${authResponse.accessToken}")
                        .header(HEADER_RETRY_WITH_REFRESH, "true")
                        .build()
                } catch (e: Exception) {
                    // Refresh failed - clear tokens and let the request fail
                    tokenManager.clearTokens()
                    null
                }
            }
        }
    }
}
