package com.cookstemma.app.data.repository

import app.cash.turbine.test
import com.cookstemma.app.data.api.ApiService
import com.cookstemma.app.data.api.AuthResponse
import com.cookstemma.app.data.api.MyProfileResponse
import com.cookstemma.app.data.api.RefreshTokenRequest
import com.cookstemma.app.data.api.UserInfoDto
import com.cookstemma.app.data.auth.TokenManager
import com.cookstemma.app.domain.model.Result
import io.mockk.*
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.resetMain
import kotlinx.coroutines.test.runTest
import kotlinx.coroutines.test.setMain
import okhttp3.ResponseBody.Companion.toResponseBody
import org.junit.After
import org.junit.Before
import org.junit.Test
import retrofit2.HttpException
import retrofit2.Response
import kotlin.test.assertEquals
import kotlin.test.assertTrue

@OptIn(ExperimentalCoroutinesApi::class)
class AuthRepositoryTest {

    private lateinit var apiService: ApiService
    private lateinit var tokenManager: TokenManager
    private lateinit var repository: AuthRepository
    private val testDispatcher = StandardTestDispatcher()

    @Before
    fun setup() {
        Dispatchers.setMain(testDispatcher)
        apiService = mockk(relaxed = true)
        tokenManager = mockk(relaxed = true)
        repository = AuthRepository(apiService, tokenManager)
    }

    @After
    fun tearDown() {
        Dispatchers.resetMain()
        clearAllMocks()
    }

    // MARK: - checkAuthState Tests

    @Test
    fun `checkAuthState returns Authenticated when token is valid`() = runTest {
        // Given
        every { tokenManager.hasValidToken() } returns true
        coEvery { apiService.getMyProfile() } returns createMockProfileResponse()

        // When/Then
        repository.checkAuthState().test {
            val result = awaitItem()
            assertTrue(result is Result.Success)
            val state = (result as Result.Success).data
            assertTrue(state is AuthState.Authenticated)
            awaitComplete()
        }
    }

    @Test
    fun `checkAuthState refreshes token when access token expired but refresh token exists`() = runTest {
        // Given
        every { tokenManager.hasValidToken() } returns false
        every { tokenManager.getRefreshToken() } returns "refresh_token"
        coEvery { apiService.refreshToken(RefreshTokenRequest("refresh_token")) } returns
            AuthResponse(
                accessToken = "new_access_token",
                refreshToken = "new_refresh_token",
                expiresIn = 3600
            )
        coEvery { apiService.getMyProfile() } returns createMockProfileResponse()

        // When/Then
        repository.checkAuthState().test {
            val result = awaitItem()
            assertTrue(result is Result.Success)
            val state = (result as Result.Success).data
            assertTrue(state is AuthState.Authenticated)
            awaitComplete()
        }

        verify { tokenManager.saveTokens("new_access_token", "new_refresh_token", 3600) }
    }

    @Test
    fun `checkAuthState returns Unauthenticated when no tokens exist`() = runTest {
        // Given
        every { tokenManager.hasValidToken() } returns false
        every { tokenManager.getRefreshToken() } returns null

        // When/Then
        repository.checkAuthState().test {
            val result = awaitItem()
            assertTrue(result is Result.Success)
            val state = (result as Result.Success).data
            assertEquals(AuthState.Unauthenticated, state)
            awaitComplete()
        }
    }

    @Test
    fun `checkAuthState returns Unauthenticated when refresh token fails`() = runTest {
        // Given
        every { tokenManager.hasValidToken() } returns false
        every { tokenManager.getRefreshToken() } returns "refresh_token"
        coEvery { apiService.refreshToken(any()) } throws RuntimeException("Refresh failed")

        // When/Then
        repository.checkAuthState().test {
            val result = awaitItem()
            assertTrue(result is Result.Success)
            val state = (result as Result.Success).data
            assertEquals(AuthState.Unauthenticated, state)
            awaitComplete()
        }
    }

    @Test
    fun `checkAuthState clears tokens on 401 error`() = runTest {
        // Given
        every { tokenManager.hasValidToken() } returns true
        coEvery { apiService.getMyProfile() } throws HttpException(
            Response.error<MyProfileResponse>(401, "".toResponseBody())
        )

        // When/Then
        repository.checkAuthState().test {
            val result = awaitItem()
            assertTrue(result is Result.Success)
            val state = (result as Result.Success).data
            assertEquals(AuthState.Unauthenticated, state)
            awaitComplete()
        }

        verify { tokenManager.clearTokens() }
    }

    @Test
    fun `checkAuthState does not clear tokens on network error`() = runTest {
        // Given
        every { tokenManager.hasValidToken() } returns true
        coEvery { apiService.getMyProfile() } throws java.io.IOException("Network error")

        // When/Then
        repository.checkAuthState().test {
            val result = awaitItem()
            assertTrue(result is Result.Error)
            awaitComplete()
        }

        verify(exactly = 0) { tokenManager.clearTokens() }
    }

    @Test
    fun `checkAuthState returns Unauthenticated state on non-401 HTTP error`() = runTest {
        // Given
        every { tokenManager.hasValidToken() } returns true
        coEvery { apiService.getMyProfile() } throws HttpException(
            Response.error<MyProfileResponse>(500, "".toResponseBody())
        )

        // When/Then
        repository.checkAuthState().test {
            val result = awaitItem()
            assertTrue(result is Result.Success)
            val state = (result as Result.Success).data
            assertEquals(AuthState.Unauthenticated, state)
            awaitComplete()
        }

        // Should not clear tokens on 500 error
        verify(exactly = 0) { tokenManager.clearTokens() }
    }

    // MARK: - Helper Functions

    private fun createMockProfileResponse(): MyProfileResponse {
        return MyProfileResponse(
            user = UserInfoDto(
                id = "user123",
                username = "testuser",
                role = "USER",
                profileImageUrl = null,
                gender = null,
                locale = "en",
                defaultCookingStyle = null,
                measurementPreference = null,
                followerCount = 0,
                followingCount = 0,
                recipeCount = 5,
                logCount = 10,
                level = 1,
                levelName = "Beginner",
                totalXp = 100,
                xpForCurrentLevel = 0,
                xpForNextLevel = 200,
                levelProgress = 0.5,
                bio = null,
                youtubeUrl = null,
                instagramHandle = null
            ),
            recipeCount = 5,
            logCount = 10,
            savedCount = 3
        )
    }
}
