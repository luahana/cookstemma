package com.cookstemma.app.ui.screens.recipe

import androidx.lifecycle.SavedStateHandle
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.cookstemma.app.data.local.MeasurementPreferencesDataStore
import com.cookstemma.app.data.repository.RecipeRepository
import com.cookstemma.app.data.repository.SavedItemsManager
import com.cookstemma.app.domain.model.*
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import javax.inject.Inject

data class RecipeDetailUiState(
    val recipe: RecipeDetail? = null,
    val cookingLogs: List<RecipeLogItem> = emptyList(),
    val measurementPreference: MeasurementPreference = MeasurementPreference.ORIGINAL,
    val isLoading: Boolean = true,
    val isLoadingLogs: Boolean = false,
    val error: String? = null,
    val logsPage: Int = 0,
    val hasMoreLogs: Boolean = false
)

@HiltViewModel
class RecipeDetailViewModel @Inject constructor(
    savedStateHandle: SavedStateHandle,
    private val recipeRepository: RecipeRepository,
    private val savedItemsManager: SavedItemsManager,
    private val measurementPreferencesDataStore: MeasurementPreferencesDataStore
) : ViewModel() {

    private val recipeId: String = checkNotNull(savedStateHandle["recipeId"])

    private val _uiState = MutableStateFlow(RecipeDetailUiState())
    val uiState: StateFlow<RecipeDetailUiState> = _uiState.asStateFlow()

    init {
        loadRecipe()
        loadCookingLogs()
        observeSavedState()
        observeMeasurementPreference()
    }

    private fun observeMeasurementPreference() {
        viewModelScope.launch {
            measurementPreferencesDataStore.measurementPreference.collect { preference ->
                _uiState.update { it.copy(measurementPreference = preference) }
            }
        }
    }

    private fun observeSavedState() {
        viewModelScope.launch {
            savedItemsManager.savedRecipeIds.collect { savedIds ->
                _uiState.value.recipe?.let { recipe ->
                    val isSaved = savedIds.contains(recipe.id)
                    if (recipe.isSaved != isSaved) {
                        _uiState.update { it.copy(recipe = recipe.copy(uiIsSaved = isSaved)) }
                    }
                }
            }
        }
    }

    private fun loadRecipe() {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true) }
            recipeRepository.getRecipe(recipeId).collect { result ->
                when (result) {
                    is Result.Success -> {
                        _uiState.update {
                            it.copy(recipe = result.data, isLoading = false)
                        }
                    }
                    is Result.Error -> {
                        _uiState.update {
                            it.copy(
                                isLoading = false,
                                error = result.exception.message
                            )
                        }
                    }
                    is Result.Loading -> {}
                }
            }
        }
    }

    private fun loadCookingLogs(page: Int = 0) {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoadingLogs = true) }
            recipeRepository.getRecipeLogs(recipeId, page).collect { result ->
                when (result) {
                    is Result.Success -> {
                        _uiState.update {
                            it.copy(
                                cookingLogs = if (page == 0) {
                                    result.data.content
                                } else {
                                    it.cookingLogs + result.data.content
                                },
                                logsPage = page,
                                hasMoreLogs = result.data.hasMore,
                                isLoadingLogs = false
                            )
                        }
                    }
                    is Result.Error -> {
                        _uiState.update { it.copy(isLoadingLogs = false) }
                    }
                    is Result.Loading -> {}
                }
            }
        }
    }

    fun loadMoreLogs() {
        if (_uiState.value.hasMoreLogs && !_uiState.value.isLoadingLogs) {
            loadCookingLogs(_uiState.value.logsPage + 1)
        }
    }

    fun toggleSave() {
        val recipe = _uiState.value.recipe ?: return
        savedItemsManager.toggleSaveRecipe(recipe.id)
    }

    fun refresh() {
        loadRecipe()
        loadCookingLogs()
    }
}
