package com.cookstemma.app.ui.screens.search

import app.cash.turbine.test
import com.cookstemma.app.data.api.ApiService
import com.cookstemma.app.data.api.HomeResponse
import com.cookstemma.app.data.local.SearchHistoryDataStore
import com.cookstemma.app.data.repository.HashtagResult
import com.cookstemma.app.data.repository.SearchRepository
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
        searchRepository = mockk(relaxed = true)
        searchHistoryDataStore = mockk(relaxed = true)
        apiService = mockk(relaxed = true)

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

    // MARK: - Recent Searches Tests

    @Test
    fun `clearRecentSearch removes specific search`() = runTest {
        viewModel = SearchViewModel(searchRepository, searchHistoryDataStore, apiService)
        testDispatcher.scheduler.advanceUntilIdle()

        viewModel.clearRecentSearch("kimchi")
        testDispatcher.scheduler.advanceUntilIdle()

        verify { searchHistoryDataStore.removeSearch("kimchi") }
    }

    @Test
    fun `clearAllRecentSearches clears all`() = runTest {
        viewModel = SearchViewModel(searchRepository, searchHistoryDataStore, apiService)
        testDispatcher.scheduler.advanceUntilIdle()

        viewModel.clearAllRecentSearches()
        testDispatcher.scheduler.advanceUntilIdle()

        verify { searchHistoryDataStore.clearAllSearches() }
    }
}
