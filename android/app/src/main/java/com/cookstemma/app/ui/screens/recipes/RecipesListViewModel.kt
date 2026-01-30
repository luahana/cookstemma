package com.cookstemma.app.ui.screens.recipes

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.cookstemma.app.data.repository.RecipeRepository
import com.cookstemma.app.data.repository.UserRepository
import com.cookstemma.app.domain.model.*
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import javax.inject.Inject

data class RecipesListUiState(
    val recipes: List<RecipeSummary> = emptyList(),
    val savedRecipeIds: Set<String> = emptySet(),
    val isLoading: Boolean = false,
    val isLoadingMore: Boolean = false,
    val error: String? = null,
    val hasMore: Boolean = true,
    val filters: RecipeFilters = RecipeFilters()
) {
    val hasActiveFilters: Boolean
        get() = filters.cookingTimeRange != null ||
                filters.category != null ||
                filters.servingsRange != null ||
                filters.sortBy != RecipeSortBy.TRENDING
    
    fun isRecipeSaved(recipeId: String): Boolean = savedRecipeIds.contains(recipeId)
}

@HiltViewModel
class RecipesListViewModel @Inject constructor(
    private val recipeRepository: RecipeRepository,
    private val userRepository: UserRepository
) : ViewModel() {

    private val _uiState = MutableStateFlow(RecipesListUiState())
    val uiState: StateFlow<RecipesListUiState> = _uiState.asStateFlow()

    private var nextCursor: String? = null
    private var hasFetchedSavedIds = false

    init {
        loadRecipes()
        fetchSavedRecipeIds()
    }
    
    private fun fetchSavedRecipeIds() {
        if (hasFetchedSavedIds) return
        
        viewModelScope.launch {
            val allSavedIds = mutableSetOf<String>()
            var cursor: String? = null
            
            do {
                userRepository.getSavedRecipes(cursor).collect { result ->
                    if (result is Result.Success) {
                        allSavedIds.addAll(result.data.content.map { it.id })
                        cursor = if (result.data.hasMore) result.data.nextCursor else null
                    } else {
                        cursor = null
                    }
                }
            } while (cursor != null)
            
            _uiState.update { it.copy(savedRecipeIds = allSavedIds) }
            hasFetchedSavedIds = true
        }
    }

    fun loadRecipes() {
        viewModelScope.launch {
            recipeRepository.getRecipes(null, _uiState.value.filters).collect { result ->
                when (result) {
                    is Result.Loading -> _uiState.update { it.copy(isLoading = true, error = null) }
                    is Result.Success -> {
                        nextCursor = result.data.nextCursor
                        _uiState.update {
                            it.copy(recipes = result.data.content, isLoading = false, hasMore = result.data.hasMore)
                        }
                    }
                    is Result.Error -> _uiState.update { it.copy(isLoading = false, error = result.exception.message) }
                }
            }
        }
    }

    fun loadMore() {
        if (_uiState.value.isLoadingMore || !_uiState.value.hasMore || nextCursor == null) return
        viewModelScope.launch {
            recipeRepository.getRecipes(nextCursor, _uiState.value.filters).collect { result ->
                when (result) {
                    is Result.Loading -> _uiState.update { it.copy(isLoadingMore = true) }
                    is Result.Success -> {
                        nextCursor = result.data.nextCursor
                        _uiState.update {
                            it.copy(recipes = it.recipes + result.data.content, isLoadingMore = false, hasMore = result.data.hasMore)
                        }
                    }
                    is Result.Error -> _uiState.update { it.copy(isLoadingMore = false) }
                }
            }
        }
    }

    fun updateFilters(filters: RecipeFilters) {
        _uiState.update { it.copy(filters = filters) }
        nextCursor = null
        loadRecipes()
    }

    fun updateSearchQuery(query: String?) {
        val currentFilters = _uiState.value.filters
        if (currentFilters.searchQuery != query) {
            _uiState.update { it.copy(filters = currentFilters.copy(searchQuery = query)) }
            nextCursor = null
            loadRecipes()
        }
    }

    fun saveRecipe(recipe: RecipeSummary) {
        viewModelScope.launch {
            val wasSaved = _uiState.value.isRecipeSaved(recipe.id)
            
            // Optimistic update
            _uiState.update { state ->
                val newSavedIds = if (wasSaved) {
                    state.savedRecipeIds - recipe.id
                } else {
                    state.savedRecipeIds + recipe.id
                }
                state.copy(savedRecipeIds = newSavedIds)
            }

            val result = if (wasSaved) {
                recipeRepository.unsaveRecipe(recipe.id)
            } else {
                recipeRepository.saveRecipe(recipe.id)
            }

            result.collect { res ->
                if (res is Result.Error) {
                    // Revert on failure
                    _uiState.update { state ->
                        val revertedIds = if (wasSaved) {
                            state.savedRecipeIds + recipe.id
                        } else {
                            state.savedRecipeIds - recipe.id
                        }
                        state.copy(savedRecipeIds = revertedIds)
                    }
                }
            }
        }
    }
    
    fun isRecipeSaved(recipeId: String): Boolean = _uiState.value.isRecipeSaved(recipeId)
}
