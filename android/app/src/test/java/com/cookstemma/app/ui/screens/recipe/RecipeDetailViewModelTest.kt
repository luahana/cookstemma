package com.cookstemma.app.ui.screens.recipe

import app.cash.turbine.test
import com.cookstemma.app.data.local.MeasurementPreferencesDataStore
import com.cookstemma.app.data.repository.RecipeRepository
import com.cookstemma.app.data.repository.SavedItemsManager
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
import kotlin.test.assertTrue

@OptIn(ExperimentalCoroutinesApi::class)
class RecipeDetailViewModelTest {

    private lateinit var recipeRepository: RecipeRepository
    private lateinit var savedItemsManager: SavedItemsManager
    private lateinit var measurementPreferencesDataStore: MeasurementPreferencesDataStore
    private lateinit var savedStateHandle: androidx.lifecycle.SavedStateHandle
    private lateinit var viewModel: RecipeDetailViewModel
    private val testDispatcher = StandardTestDispatcher()
    private val savedRecipeIdsFlow = MutableStateFlow<Set<String>>(emptySet())

    @Before
    fun setup() {
        Dispatchers.setMain(testDispatcher)
        recipeRepository = mockk()
        savedItemsManager = mockk(relaxed = true)
        measurementPreferencesDataStore = mockk(relaxed = true)
        savedStateHandle = mockk()
        every { savedStateHandle.get<String>("recipeId") } returns "recipe-123"
        every { savedItemsManager.savedRecipeIds } returns savedRecipeIdsFlow
    }

    @After
    fun tearDown() {
        Dispatchers.resetMain()
    }

    // MARK: - Initial Load Tests

    @Test
    fun `initial state is loading`() = runTest {
        coEvery { recipeRepository.getRecipe("recipe-123") } returns flowOf(Result.Loading)
        coEvery { recipeRepository.getRecipeLogs("recipe-123", 0) } returns flowOf(Result.Loading)

        viewModel = RecipeDetailViewModel(savedStateHandle, recipeRepository, savedItemsManager, measurementPreferencesDataStore)

        viewModel.uiState.test {
            val state = awaitItem()
            assertTrue(state.isLoading)
        }
    }

    @Test
    fun `loadRecipe success updates state with recipe`() = runTest {
        val mockRecipe = createMockRecipeDetail()
        coEvery { recipeRepository.getRecipe("recipe-123") } returns flowOf(Result.Success(mockRecipe))
        coEvery { recipeRepository.getRecipeLogs("recipe-123", any()) } returns flowOf(
            Result.Success(PaginatedResponse(emptyList<RecipeLogItem>(), null, false))
        )

        viewModel = RecipeDetailViewModel(savedStateHandle, recipeRepository, savedItemsManager, measurementPreferencesDataStore)
        testDispatcher.scheduler.advanceUntilIdle()

        viewModel.uiState.test {
            val state = awaitItem()
            assertEquals("recipe-123", state.recipe?.id)
            assertEquals("Test Recipe", state.recipe?.title)
            assertFalse(state.isLoading)
        }
    }

    @Test
    fun `loadRecipe error updates state with error message`() = runTest {
        val error = Exception("Recipe not found")
        coEvery { recipeRepository.getRecipe("recipe-123") } returns flowOf(Result.Error(error))
        coEvery { recipeRepository.getRecipeLogs("recipe-123", any()) } returns flowOf(Result.Loading)

        viewModel = RecipeDetailViewModel(savedStateHandle, recipeRepository, savedItemsManager, measurementPreferencesDataStore)
        testDispatcher.scheduler.advanceUntilIdle()

        viewModel.uiState.test {
            val state = awaitItem()
            assertEquals("Recipe not found", state.error)
            assertFalse(state.isLoading)
        }
    }

    // MARK: - Cooking Logs Tests

    @Test
    fun `loadCookingLogs success updates state with logs`() = runTest {
        val mockRecipe = createMockRecipeDetail()
        val mockLogs = listOf(createMockRecipeLogItem("log-1"), createMockRecipeLogItem("log-2"))
        coEvery { recipeRepository.getRecipe("recipe-123") } returns flowOf(Result.Success(mockRecipe))
        coEvery { recipeRepository.getRecipeLogs("recipe-123", 0) } returns flowOf(
            Result.Success(PaginatedResponse(mockLogs, "cursor-1", true))
        )

        viewModel = RecipeDetailViewModel(savedStateHandle, recipeRepository, savedItemsManager, measurementPreferencesDataStore)
        testDispatcher.scheduler.advanceUntilIdle()

        viewModel.uiState.test {
            val state = awaitItem()
            assertEquals(2, state.cookingLogs.size)
            assertTrue(state.hasMoreLogs)
        }
    }

    @Test
    fun `loadMoreLogs appends to existing logs`() = runTest {
        val mockRecipe = createMockRecipeDetail()
        val initialLogs = listOf(createMockRecipeLogItem("log-1"))
        val moreLogs = listOf(createMockRecipeLogItem("log-2"))

        coEvery { recipeRepository.getRecipe("recipe-123") } returns flowOf(Result.Success(mockRecipe))
        coEvery { recipeRepository.getRecipeLogs("recipe-123", 0) } returns flowOf(
            Result.Success(PaginatedResponse(initialLogs, "cursor-1", true))
        )
        coEvery { recipeRepository.getRecipeLogs("recipe-123", 1) } returns flowOf(
            Result.Success(PaginatedResponse(moreLogs, null, false))
        )

        viewModel = RecipeDetailViewModel(savedStateHandle, recipeRepository, savedItemsManager, measurementPreferencesDataStore)
        testDispatcher.scheduler.advanceUntilIdle()

        viewModel.loadMoreLogs()
        testDispatcher.scheduler.advanceUntilIdle()

        viewModel.uiState.test {
            val state = awaitItem()
            assertEquals(2, state.cookingLogs.size)
            assertFalse(state.hasMoreLogs)
        }
    }

    @Test
    fun `loadMoreLogs does nothing when no more logs`() = runTest {
        val mockRecipe = createMockRecipeDetail()
        coEvery { recipeRepository.getRecipe("recipe-123") } returns flowOf(Result.Success(mockRecipe))
        coEvery { recipeRepository.getRecipeLogs("recipe-123", 0) } returns flowOf(
            Result.Success(PaginatedResponse(emptyList<RecipeLogItem>(), null, false))
        )

        viewModel = RecipeDetailViewModel(savedStateHandle, recipeRepository, savedItemsManager, measurementPreferencesDataStore)
        testDispatcher.scheduler.advanceUntilIdle()

        viewModel.loadMoreLogs()
        testDispatcher.scheduler.advanceUntilIdle()

        // Should not throw or cause issues
        coVerify(exactly = 1) { recipeRepository.getRecipeLogs("recipe-123", 0) }
    }

    // MARK: - Toggle Save Tests

    @Test
    fun `toggleSave calls savedItemsManager`() = runTest {
        val mockRecipe = createMockRecipeDetail(isSaved = false)
        coEvery { recipeRepository.getRecipe("recipe-123") } returns flowOf(Result.Success(mockRecipe))
        coEvery { recipeRepository.getRecipeLogs("recipe-123", any()) } returns flowOf(
            Result.Success(PaginatedResponse(emptyList<RecipeLogItem>(), null, false))
        )

        viewModel = RecipeDetailViewModel(savedStateHandle, recipeRepository, savedItemsManager, measurementPreferencesDataStore)
        testDispatcher.scheduler.advanceUntilIdle()

        viewModel.toggleSave()
        testDispatcher.scheduler.advanceUntilIdle()

        verify { savedItemsManager.toggleSaveRecipe("recipe-123", any()) }
    }

    @Test
    fun `observes savedRecipeIds from manager`() = runTest {
        val mockRecipe = createMockRecipeDetail(isSaved = false)
        coEvery { recipeRepository.getRecipe("recipe-123") } returns flowOf(Result.Success(mockRecipe))
        coEvery { recipeRepository.getRecipeLogs("recipe-123", any()) } returns flowOf(
            Result.Success(PaginatedResponse(emptyList<RecipeLogItem>(), null, false))
        )

        viewModel = RecipeDetailViewModel(savedStateHandle, recipeRepository, savedItemsManager, measurementPreferencesDataStore)
        testDispatcher.scheduler.advanceUntilIdle()

        // Simulate manager updating saved state
        savedRecipeIdsFlow.value = setOf("recipe-123")
        testDispatcher.scheduler.advanceUntilIdle()

        viewModel.uiState.test {
            val state = awaitItem()
            assertTrue(state.recipe?.isSaved ?: false)
        }
    }

    @Test
    fun `observes unsave from manager`() = runTest {
        val mockRecipe = createMockRecipeDetail(isSaved = true)
        savedRecipeIdsFlow.value = setOf("recipe-123")
        coEvery { recipeRepository.getRecipe("recipe-123") } returns flowOf(Result.Success(mockRecipe))
        coEvery { recipeRepository.getRecipeLogs("recipe-123", any()) } returns flowOf(
            Result.Success(PaginatedResponse(emptyList<RecipeLogItem>(), null, false))
        )

        viewModel = RecipeDetailViewModel(savedStateHandle, recipeRepository, savedItemsManager, measurementPreferencesDataStore)
        testDispatcher.scheduler.advanceUntilIdle()

        // Simulate manager removing saved state
        savedRecipeIdsFlow.value = emptySet()
        testDispatcher.scheduler.advanceUntilIdle()

        viewModel.uiState.test {
            val state = awaitItem()
            assertFalse(state.recipe?.isSaved ?: true)
        }
    }

    // MARK: - Refresh Tests

    @Test
    fun `refresh reloads recipe and logs`() = runTest {
        val mockRecipe = createMockRecipeDetail()
        coEvery { recipeRepository.getRecipe("recipe-123") } returns flowOf(Result.Success(mockRecipe))
        coEvery { recipeRepository.getRecipeLogs("recipe-123", 0) } returns flowOf(
            Result.Success(PaginatedResponse(emptyList<RecipeLogItem>(), null, false))
        )

        viewModel = RecipeDetailViewModel(savedStateHandle, recipeRepository, savedItemsManager, measurementPreferencesDataStore)
        testDispatcher.scheduler.advanceUntilIdle()

        viewModel.refresh()
        testDispatcher.scheduler.advanceUntilIdle()

        coVerify(exactly = 2) { recipeRepository.getRecipe("recipe-123") }
        coVerify(exactly = 2) { recipeRepository.getRecipeLogs("recipe-123", 0) }
    }

    // MARK: - Helpers

    private fun createMockRecipeDetail(isSaved: Boolean = false) = RecipeDetail(
        id = "recipe-123",
        title = "Test Recipe",
        description = "Test description",
        foodName = "Test Food",
        cookingStyle = "KR",
        userName = "testuser",
        creatorPublicId = "user-123",
        ingredientList = emptyList(),
        stepList = emptyList(),
        hashtagObjects = emptyList(),
        servings = 2,
        cookingTimeRange = "UNDER_15_MIN",
        recipeImages = emptyList(),
        isSavedByCurrentUser = isSaved,
        uiIsSaved = isSaved
    )

    private fun createMockRecipeLogItem(id: String) = FeedItem(
        id = id,
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
}
