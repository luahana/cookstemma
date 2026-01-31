package com.cookstemma.app.data.repository

import app.cash.turbine.test
import com.cookstemma.app.data.api.ApiService
import com.cookstemma.app.domain.model.*
import io.mockk.*
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.test.*
import org.junit.After
import org.junit.Before
import org.junit.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

@OptIn(ExperimentalCoroutinesApi::class)
class SearchRepositoryTest {

    private lateinit var apiService: ApiService
    private lateinit var repository: SearchRepository
    private val testDispatcher = StandardTestDispatcher()

    @Before
    fun setup() {
        Dispatchers.setMain(testDispatcher)
        apiService = mockk(relaxed = true)
        repository = SearchRepository(apiService)
    }

    @After
    fun tearDown() {
        Dispatchers.resetMain()
    }

    // MARK: - searchRecipes Tests

    @Test
    fun `searchRecipes calls unified search endpoint with recipes type`() = runTest {
        val mockResponse = createMockUnifiedResponse(
            items = listOf(
                createMockRecipeItem("recipe1", "Kimchi Recipe")
            )
        )
        coEvery { apiService.search("kimchi", "recipes", null, 20) } returns mockResponse

        repository.searchRecipes("kimchi").test {
            val result = awaitItem()
            assertTrue(result is Result.Success)
            val data = (result as Result.Success).data
            assertEquals(1, data.content.size)
            assertEquals("recipe1", data.content[0].id)
            assertEquals("Kimchi Recipe", data.content[0].title)
            awaitComplete()
        }

        coVerify { apiService.search("kimchi", "recipes", null, 20) }
    }

    @Test
    fun `searchRecipes filters out non-recipe items`() = runTest {
        val mockResponse = createMockUnifiedResponse(
            items = listOf(
                createMockRecipeItem("recipe1", "Recipe"),
                createMockLogItem("log1", "Log"),
                createMockRecipeItem("recipe2", "Recipe 2")
            )
        )
        coEvery { apiService.search("test", "recipes", null, 20) } returns mockResponse

        repository.searchRecipes("test").test {
            val result = awaitItem()
            assertTrue(result is Result.Success)
            val data = (result as Result.Success).data
            assertEquals(2, data.content.size)
            assertEquals("recipe1", data.content[0].id)
            assertEquals("recipe2", data.content[1].id)
            awaitComplete()
        }
    }

    @Test
    fun `searchRecipes returns error on exception`() = runTest {
        coEvery { apiService.search(any(), any(), any(), any()) } throws RuntimeException("Network error")

        repository.searchRecipes("test").test {
            val result = awaitItem()
            assertTrue(result is Result.Error)
            awaitComplete()
        }
    }

    // MARK: - searchLogs Tests

    @Test
    fun `searchLogs calls unified search endpoint with logs type`() = runTest {
        val mockResponse = createMockUnifiedResponse(
            items = listOf(
                createMockLogItem("log1", "My cooking log")
            )
        )
        coEvery { apiService.search("cooking", "logs", null, 20) } returns mockResponse

        repository.searchLogs("cooking").test {
            val result = awaitItem()
            assertTrue(result is Result.Success)
            val data = (result as Result.Success).data
            assertEquals(1, data.content.size)
            assertEquals("log1", data.content[0].id)
            awaitComplete()
        }

        coVerify { apiService.search("cooking", "logs", null, 20) }
    }

    @Test
    fun `searchLogs filters out non-log items`() = runTest {
        val mockResponse = createMockUnifiedResponse(
            items = listOf(
                createMockLogItem("log1", "Log 1"),
                createMockRecipeItem("recipe1", "Recipe"),
                createMockLogItem("log2", "Log 2")
            )
        )
        coEvery { apiService.search("test", "logs", null, 20) } returns mockResponse

        repository.searchLogs("test").test {
            val result = awaitItem()
            assertTrue(result is Result.Success)
            val data = (result as Result.Success).data
            assertEquals(2, data.content.size)
            assertEquals("log1", data.content[0].id)
            assertEquals("log2", data.content[1].id)
            awaitComplete()
        }
    }

    // MARK: - searchUsers Tests

    @Test
    fun `searchUsers calls unified search endpoint with users type`() = runTest {
        val mockResponse = createMockUnifiedResponse(
            items = listOf(
                createMockUserItem("user1", "john_doe")
            )
        )
        coEvery { apiService.search("john", "users", null, 20) } returns mockResponse

        repository.searchUsers("john").test {
            val result = awaitItem()
            assertTrue(result is Result.Success)
            val data = (result as Result.Success).data
            assertEquals(1, data.content.size)
            assertEquals("user1", data.content[0].id)
            assertEquals("john_doe", data.content[0].username)
            awaitComplete()
        }

        coVerify { apiService.search("john", "users", null, 20) }
    }

    // MARK: - Pagination Tests

    @Test
    fun `searchRecipes passes cursor for pagination`() = runTest {
        val mockResponse = createMockUnifiedResponse(
            items = listOf(createMockRecipeItem("recipe1", "Recipe")),
            nextCursor = "next_page_cursor",
            hasNext = true
        )
        coEvery { apiService.search("test", "recipes", "cursor123", 20) } returns mockResponse

        repository.searchRecipes("test", "cursor123").test {
            val result = awaitItem()
            assertTrue(result is Result.Success)
            val data = (result as Result.Success).data
            assertEquals("next_page_cursor", data.nextCursor)
            assertTrue(data.hasMore)
            awaitComplete()
        }
    }

    // MARK: - Helper Functions

    private fun createMockUnifiedResponse(
        items: List<SearchResultItem>,
        nextCursor: String? = null,
        hasNext: Boolean = false
    ): UnifiedSearchResponse {
        return UnifiedSearchResponse(
            content = items,
            counts = SearchCountsResponse(
                recipes = items.count { it.type == "RECIPE" },
                logs = items.count { it.type == "LOG" },
                hashtags = items.count { it.type == "HASHTAG" }
            ),
            page = 0,
            size = 20,
            totalElements = items.size,
            totalPages = 1,
            hasNext = hasNext,
            nextCursor = nextCursor
        )
    }

    private fun createMockRecipeItem(id: String, title: String): SearchResultItem {
        return SearchResultItem(
            type = "RECIPE",
            relevanceScore = 1.0,
            data = mapOf(
                "publicId" to id,
                "title" to title,
                "foodName" to "Test Food",
                "userName" to "testuser",
                "description" to null,
                "cookingStyle" to null,
                "thumbnail" to null,
                "variantCount" to 0.0,
                "logCount" to 0.0,
                "servings" to null,
                "cookingTimeRange" to null,
                "isPrivate" to false
            )
        )
    }

    private fun createMockLogItem(id: String, content: String): SearchResultItem {
        return SearchResultItem(
            type = "LOG",
            relevanceScore = 0.9,
            data = mapOf(
                "publicId" to id,
                "content" to content,
                "rating" to 5.0,
                "thumbnailUrl" to null,
                "creatorPublicId" to "creator1",
                "userName" to "testuser",
                "foodName" to "Test Food",
                "recipeTitle" to "Test Recipe",
                "hashtags" to listOf("food", "cooking"),
                "isVariant" to false,
                "isPrivate" to false,
                "commentCount" to 0.0,
                "cookingStyle" to null
            )
        )
    }

    private fun createMockUserItem(id: String, username: String): SearchResultItem {
        return SearchResultItem(
            type = "USER",
            relevanceScore = 0.8,
            data = mapOf(
                "publicId" to id,
                "username" to username,
                "displayName" to "John Doe",
                "profileImageUrl" to null,
                "bio" to "Test bio",
                "isFollowing" to false
            )
        )
    }
}
