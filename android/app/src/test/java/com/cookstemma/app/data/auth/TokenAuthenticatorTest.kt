package com.cookstemma.app.data.auth

import com.cookstemma.app.data.api.ApiService
import com.cookstemma.app.data.api.AuthResponse
import com.cookstemma.app.data.api.RefreshTokenRequest
import io.mockk.*
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.resetMain
import kotlinx.coroutines.test.setMain
import okhttp3.Protocol
import okhttp3.Request
import okhttp3.Response
import okhttp3.ResponseBody.Companion.toResponseBody
import org.junit.After
import org.junit.Before
import org.junit.Test
import javax.inject.Provider
import kotlin.test.assertEquals
import kotlin.test.assertNotNull
import kotlin.test.assertNull

@OptIn(ExperimentalCoroutinesApi::class)
class TokenAuthenticatorTest {

    private lateinit var tokenManager: TokenManager
    private lateinit var apiService: ApiService
    private lateinit var apiServiceProvider: Provider<ApiService>
    private lateinit var authenticator: TokenAuthenticator
    private val testDispatcher = StandardTestDispatcher()

    @Before
    fun setup() {
        Dispatchers.setMain(testDispatcher)
        tokenManager = mockk(relaxed = true)
        apiService = mockk(relaxed = true)
        apiServiceProvider = mockk()
        every { apiServiceProvider.get() } returns apiService
        authenticator = TokenAuthenticator(tokenManager, apiServiceProvider)
    }

    @After
    fun tearDown() {
        Dispatchers.resetMain()
        clearAllMocks()
    }

    // MARK: - Token Refresh Tests

    @Test
    fun `authenticate refreshes token and retries request on 401`() {
        // Given
        val oldToken = "old_access_token"
        val newToken = "new_access_token"
        val refreshToken = "refresh_token"
        val response = create401Response(oldToken)

        every { tokenManager.getRefreshToken() } returns refreshToken
        every { tokenManager.getAccessToken() } returns oldToken
        coEvery { apiService.refreshToken(RefreshTokenRequest(refreshToken)) } returns
            AuthResponse(
                accessToken = newToken,
                refreshToken = "new_refresh_token",
                expiresIn = 3600
            )

        // When
        val newRequest = authenticator.authenticate(null, response)

        // Then
        assertNotNull(newRequest)
        assertEquals("Bearer $newToken", newRequest.header("Authorization"))
        assertEquals("true", newRequest.header("X-Retry-With-Refresh"))
        verify { tokenManager.saveTokens(newToken, "new_refresh_token", 3600) }
    }

    @Test
    fun `authenticate returns null when no refresh token available`() {
        // Given
        val response = create401Response("old_token")
        every { tokenManager.getRefreshToken() } returns null
        every { tokenManager.getAccessToken() } returns "old_token"

        // When
        val newRequest = authenticator.authenticate(null, response)

        // Then
        assertNull(newRequest)
        verify(exactly = 0) { tokenManager.saveTokens(any(), any(), any()) }
    }

    @Test
    fun `authenticate clears tokens when refresh fails`() {
        // Given
        val response = create401Response("old_token")
        every { tokenManager.getRefreshToken() } returns "refresh_token"
        every { tokenManager.getAccessToken() } returns "old_token"
        coEvery { apiService.refreshToken(any()) } throws RuntimeException("Refresh failed")

        // When
        val newRequest = authenticator.authenticate(null, response)

        // Then
        assertNull(newRequest)
        verify { tokenManager.clearTokens() }
    }

    @Test
    fun `authenticate does not retry if already retried with refresh`() {
        // Given
        val response = create401ResponseWithRetryHeader()

        // When
        val newRequest = authenticator.authenticate(null, response)

        // Then
        assertNull(newRequest)
        verify(exactly = 0) { tokenManager.getRefreshToken() }
    }

    @Test
    fun `authenticate skips auth endpoints`() {
        // Given
        val response = create401ResponseForAuthEndpoint()

        // When
        val newRequest = authenticator.authenticate(null, response)

        // Then
        assertNull(newRequest)
        verify(exactly = 0) { tokenManager.getRefreshToken() }
    }

    @Test
    fun `authenticate uses existing token if another thread already refreshed`() {
        // Given
        val oldToken = "old_access_token"
        val newToken = "new_access_token"
        val response = create401Response(oldToken)

        // Token was refreshed by another thread
        every { tokenManager.getAccessToken() } returns newToken
        every { tokenManager.getRefreshToken() } returns "refresh_token"

        // When
        val newRequest = authenticator.authenticate(null, response)

        // Then
        assertNotNull(newRequest)
        assertEquals("Bearer $newToken", newRequest.header("Authorization"))
        // Should not call refreshToken since token was already updated
        coVerify(exactly = 0) { apiService.refreshToken(any()) }
    }

    // MARK: - Helper Functions

    private fun create401Response(token: String): Response {
        val request = Request.Builder()
            .url("https://api.example.com/api/v1/users/me")
            .header("Authorization", "Bearer $token")
            .build()

        return Response.Builder()
            .request(request)
            .protocol(Protocol.HTTP_1_1)
            .code(401)
            .message("Unauthorized")
            .body("".toResponseBody())
            .build()
    }

    private fun create401ResponseWithRetryHeader(): Response {
        val request = Request.Builder()
            .url("https://api.example.com/api/v1/users/me")
            .header("Authorization", "Bearer token")
            .header("X-Retry-With-Refresh", "true")
            .build()

        return Response.Builder()
            .request(request)
            .protocol(Protocol.HTTP_1_1)
            .code(401)
            .message("Unauthorized")
            .body("".toResponseBody())
            .build()
    }

    private fun create401ResponseForAuthEndpoint(): Response {
        val request = Request.Builder()
            .url("https://api.example.com/api/v1/auth/refresh")
            .header("Authorization", "Bearer token")
            .build()

        return Response.Builder()
            .request(request)
            .protocol(Protocol.HTTP_1_1)
            .code(401)
            .message("Unauthorized")
            .body("".toResponseBody())
            .build()
    }
}
