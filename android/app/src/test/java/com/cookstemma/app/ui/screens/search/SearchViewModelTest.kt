package com.cookstemma.app.ui.screens.search

import app.cash.turbine.test
import com.cookstemma.app.data.api.ApiService
import com.cookstemma.app.data.api.HomeResponse
import com.cookstemma.app.data.local.SearchHistoryDataStore
import com.cookstemma.app.data.repository.HashtagResult
import com.cookstemma.app.data.repository.SearchRepository
import com.cookstemma.app.data.repository.SearchResults
import com.cookstemma.app.domain.model.*
import io.mockk.*
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.flowOf
import kotlinx.coroutines.test.*
import org.junit.After
import org.junit.Before
import org.junit.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue

@OptIn(ExperimentalCoroutinesApi::class)
class SearchViewModelTest {

    private lateinit var searchRepository: SearchRepository
    private lateinit var searchHistoryDataStore: SearchHistoryDataStore
    private lateinit var apiService: ApiService
    private lateinit var viewModel: SearchViewModel
    private val testDispatcher = StandardTestDispatcher()
    private val mockHistoryFlow = MutableStateFlow<List<String>>(emptyList())

    @Before
    fun setup() {
        Dispatchers.setMain(testDispatcher)
        searchRepository = mockk()
        searchHistoryDataStore = mockk()
        apiService = mockk()

        // Default mocks for init
        coEvery { searchRepository.getTrendingHashtags() } returns flowOf(Result.Success(emptyList()))
        every { searchHistoryDataStore.searchHistory } returns mockHistoryFlow
        coEvery { apiService.getHome() } returns HomeResponse(
            recentRecipes = emptyList(),
            recentActivity = emptyList(),
            trendingTrees = emptyList()
        )
    }

    @After
    fun tearDown() {
        Dispatchers.resetMain()
    }

    // MARK: - Initial State Tests

    @Test
    fun `initial state has correct defaults`() = runTest {
        viewModel = SearchViewModel(searchRepository, searchHistoryDataStore, apiService)

        viewModel.uiState.test {
            val state = awaitItem()
            assertTrue(state.query.isEmpty())
            assertEquals(SearchTab.ALL, state.selectedTab)
            assertNull(state.results)
            assertFalse(state.isLoading)
        }
    }

    @Test
    fun `init loads trending hashtags`() = runTest {
        val hashtags = listOf(
            HashtagResult(id = "1", name = "trending", postCount = 100),
            HashtagResult(id = "2", name = "popular", postCount = 50)
        )
        coEvery { searchRepository.getTrendingHashtags() } returns flowOf(Result.Success(hashtags))

        viewModel = SearchViewModel(searchRepository, searchHistoryDataStore, apiService)
        testDispatcher.scheduler.advanceUntilIdle()

        viewModel.uiState.test {
            val state = awaitItem()
            assertEquals(2, state.trendingHashtags.size)
        }
    }

    // MARK: - Query Tests

    @Test
    fun `setQuery updates query state`() = runTest {
        viewModel = SearchViewModel(searchRepository, searchHistoryDataStore, apiService)

        viewModel.setQuery("kimchi")

        viewModel.uiState.test {
            val state = awaitItem()
            assertEquals("kimchi", state.query)
        }
    }

    @Test
    fun `setQuery with empty query clears results`() = runTest {
        viewModel = SearchViewModel(searchRepository, searchHistoryDataStore, apiService)

        viewModel.setQuery("kimchi")
        viewModel.setQuery("")

        viewModel.uiState.test {
            val state = awaitItem()
            assertNull(state.results)
            assertTrue(state.recipes.isEmpty())
        }
    }

    // MARK: - Tab Selection Tests

    @Test
    fun `selectTab updates selected tab`() = runTest {
        viewModel = SearchViewModel(searchRepository, searchHistoryDataStore, apiService)

        viewModel.selectTab(SearchTab.RECIPES)

        viewModel.uiState.test {
            val state = awaitItem()
            assertEquals(SearchTab.RECIPES, state.selectedTab)
        }
    }

    @Test
    fun `selectTab triggers search when query exists`() = runTest {
        val recipes = listOf(createMockRecipeSummary())
        coEvery { searchRepository.searchRecipes("test", any()) } returns flowOf(
            Result.Success(PaginatedResponse(recipes, null, false))
        )

        viewModel = SearchViewModel(searchRepository, searchHistoryDataStore, apiService)
        viewModel.setQuery("test")
        viewModel.selectTab(SearchTab.RECIPES)
        testDispatcher.scheduler.advanceUntilIdle()

        coVerify { searchRepository.searchRecipes("test", any()) }
    }

    // MARK: - Search Tests

    @Test
    fun `search ALL tab returns combined results`() = runTest {
        val mockResults = createMockSearchResults()
        coEvery { searchRepository.search("test", any(), any()) } returns flowOf(Result.Success(mockResults))

        viewModel = SearchViewModel(searchRepository, searchHistoryDataStore, apiService)
        viewModel.setQuery("test")
        viewModel.submitSearch()
        testDispatcher.scheduler.advanceUntilIdle()

        viewModel.uiState.test {
            val state = awaitItem()
            assertEquals(mockResults, state.results)
            assertFalse(state.isLoading)
        }
    }

    @Test
    fun `search RECIPES tab returns recipes only`() = runTest {
        val recipes = listOf(createMockRecipeSummary())
        coEvery { searchRepository.searchRecipes("test", any()) } returns flowOf(
            Result.Success(PaginatedResponse(recipes, "cursor-1", true))
        )

        viewModel = SearchViewModel(searchRepository, searchHistoryDataStore, apiService)
        viewModel.selectTab(SearchTab.RECIPES)
        viewModel.setQuery("test")
        viewModel.submitSearch()
        testDispatcher.scheduler.advanceUntilIdle()

        viewModel.uiState.test {
            val state = awaitItem()
            assertEquals(1, state.recipes.size)
            assertTrue(state.hasMore)
            assertEquals("cursor-1", state.cursor)
        }
    }

    @Test
    fun `search LOGS tab returns logs only`() = runTest {
        val logs = listOf(createMockFeedItem())
        coEvery { searchRepository.searchLogs("test", any()) } returns flowOf(
            Result.Success(PaginatedResponse(logs, null, false))
        )

        viewModel = SearchViewModel(searchRepository, searchHistoryDataStore, apiService)
        viewModel.selectTab(SearchTab.LOGS)
        viewModel.setQuery("test")
        viewModel.submitSearch()
        testDispatcher.scheduler.advanceUntilIdle()

        viewModel.uiState.test {
            val state = awaitItem()
            assertEquals(1, state.logs.size)
        }
    }

    @Test
    fun `search USERS tab returns users only`() = runTest {
        val users = listOf(createMockUserSummary())
        coEvery { searchRepository.searchUsers("test", any()) } returns flowOf(
            Result.Success(PaginatedResponse(users, null, false))
        )

        viewModel = SearchViewModel(searchRepository, searchHistoryDataStore, apiService)
        viewModel.selectTab(SearchTab.USERS)
        viewModel.setQuery("test")
        viewModel.submitSearch()
        testDispatcher.scheduler.advanceUntilIdle()

        viewModel.uiState.test {
            val state = awaitItem()
            assertEquals(1, state.users.size)
        }
    }

    // MARK: - Load More Tests

    @Test
    fun `loadMore appends results`() = runTest {
        val initialRecipes = listOf(createMockRecipeSummary("recipe-1"))
        val moreRecipes = listOf(createMockRecipeSummary("recipe-2"))

        coEvery { searchRepository.searchRecipes("test", null) } returns flowOf(
            Result.Success(PaginatedResponse(initialRecipes, "cursor-1", true))
        )
        coEvery { searchRepository.searchRecipes("test", "cursor-1") } returns flowOf(
            Result.Success(PaginatedResponse(moreRecipes, null, false))
        )

        viewModel = SearchViewModel(searchRepository, searchHistoryDataStore, apiService)
        viewModel.selectTab(SearchTab.RECIPES)
        viewModel.setQuery("test")
        viewModel.submitSearch()
        testDispatcher.scheduler.advanceUntilIdle()

        viewModel.loadMore()
        testDispatcher.scheduler.advanceUntilIdle()

        viewModel.uiState.test {
            val state = awaitItem()
            assertEquals(2, state.recipes.size)
            assertFalse(state.hasMore)
        }
    }

    @Test
    fun `loadMore does nothing without cursor`() = runTest {
        val recipes = listOf(createMockRecipeSummary())
        coEvery { searchRepository.searchRecipes("test", null) } returns flowOf(
            Result.Success(PaginatedResponse(recipes, null, false))
        )

        viewModel = SearchViewModel(searchRepository, searchHistoryDataStore, apiService)
        viewModel.selectTab(SearchTab.RECIPES)
        viewModel.setQuery("test")
        viewModel.submitSearch()
        testDispatcher.scheduler.advanceUntilIdle()

        viewModel.loadMore()
        testDispatcher.scheduler.advanceUntilIdle()

        // Should not call API again for loadMore since there's no cursor
        coVerify(exactly = 1) { searchRepository.searchRecipes("test", any()) }
    }

    // MARK: - Recent Searches Tests

    @Test
    fun `submitSearch adds to recent searches`() = runTest {
        coEvery { searchRepository.search("new search", any(), any()) } returns flowOf(
            Result.Success(createMockSearchResults())
        )
        coEvery { searchHistoryDataStore.addSearch("new search") } just Runs

        viewModel = SearchViewModel(searchRepository, searchHistoryDataStore, apiService)
        viewModel.setQuery("new search")
        viewModel.submitSearch()
        testDispatcher.scheduler.advanceUntilIdle()

        coVerify { searchHistoryDataStore.addSearch("new search") }
    }

    @Test
    fun `clearRecentSearch removes specific search`() = runTest {
        coEvery { searchHistoryDataStore.removeSearch("kimchi") } just Runs

        viewModel = SearchViewModel(searchRepository, searchHistoryDataStore, apiService)
        testDispatcher.scheduler.advanceUntilIdle()

        viewModel.clearRecentSearch("kimchi")
        testDispatcher.scheduler.advanceUntilIdle()

        coVerify { searchHistoryDataStore.removeSearch("kimchi") }
    }

    @Test
    fun `clearAllRecentSearches clears all`() = runTest {
        coEvery { searchHistoryDataStore.clearAllSearches() } just Runs

        viewModel = SearchViewModel(searchRepository, searchHistoryDataStore, apiService)
        testDispatcher.scheduler.advanceUntilIdle()

        viewModel.clearAllRecentSearches()
        testDispatcher.scheduler.advanceUntilIdle()

        coVerify { searchHistoryDataStore.clearAllSearches() }
    }

    // MARK: - Helpers

    private fun createMockSearchResults() = SearchResults(
        recipes = listOf(createMockRecipeSummary()),
        logs = listOf(createMockFeedItem()),
        users = listOf(createMockUserSummary()),
        hashtags = listOf(HashtagResult(id = "1", name = "test", postCount = 10))
    )

    private fun createMockRecipeSummary(id: String = "recipe-123") = RecipeSummary(
        id = id,
        title = "Test Recipe",
        description = null,
        foodName = "Test Food",
        cookingStyle = "KR",
        userName = "testuser",
        thumbnail = null,
        variantCount = 0,
        logCount = 50,
        servings = 2,
        cookingTimeRange = "UNDER_15_MIN",
        hashtagList = emptyList(),
        isPrivate = false,
        savedStatus = false
    )

    private fun createMockFeedItem() = FeedItem(
        id = "log-123",
        title = "Test Log",
        content = "Test content",
        rating = 4,
        thumbnailUrl = null,
        creatorPublicId = "user-1",
        userName = "testuser",
        foodName = "Test Food",
        recipeTitle = "Test Recipe",
        hashtags = emptyList(),
        isVariant = false,
        isPrivate = false,
        commentCount = 2,
        cookingStyle = "KR"
    )

    private fun createMockUserSummary() = UserSummary(
        id = "user-1",
        username = "testuser",
        displayName = "Test User",
        avatarUrl = null
    )
}
