package com.cookstemma.app.ui.screens.create

import android.net.Uri
import androidx.lifecycle.SavedStateHandle
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.cookstemma.app.data.repository.LogRepository
import com.cookstemma.app.data.repository.RecipeRepository
import com.cookstemma.app.data.repository.SearchRepository
import com.cookstemma.app.domain.model.*
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import java.io.File
import javax.inject.Inject

enum class PhotoState {
    LOADING, SUCCESS, ERROR
}

data class PhotoItem(
    val uri: Uri,
    val state: PhotoState = PhotoState.LOADING
)

data class CreateLogUiState(
    val photos: List<PhotoItem> = emptyList(),
    val rating: Int = 0,
    val linkedRecipe: RecipeSummary? = null,
    val content: String = "",
    val hashtags: List<String> = emptyList(),
    val hashtagInput: String = "",
    val isPrivate: Boolean = false,
    val recipeSearchQuery: String = "",
    val recipeSearchResults: List<RecipeSummary> = emptyList(),
    val isSearchingRecipes: Boolean = false,
    val isSubmitting: Boolean = false,
    val error: String? = null,
    val isSubmitSuccess: Boolean = false
) {
    val canSubmit: Boolean
        get() = photos.isNotEmpty() &&
                photos.all { it.state == PhotoState.SUCCESS } &&
                rating > 0 &&
                !isSubmitting

    val photosRemaining: Int
        get() = 3 - photos.size

    val hashtagsRemaining: Int
        get() = 10 - hashtags.size
}

@HiltViewModel
class CreateLogViewModel @Inject constructor(
    savedStateHandle: SavedStateHandle,
    private val logRepository: LogRepository,
    private val searchRepository: SearchRepository,
    private val recipeRepository: RecipeRepository
) : ViewModel() {

    private val recipeId: String? = savedStateHandle.get<String>("recipeId")

    private val _uiState = MutableStateFlow(CreateLogUiState())
    val uiState: StateFlow<CreateLogUiState> = _uiState.asStateFlow()

    init {
        recipeId?.let { loadRecipeById(it) }
    }

    private fun loadRecipeById(id: String) {
        viewModelScope.launch {
            recipeRepository.getRecipe(id).collect { result ->
                if (result is Result.Success) {
                    _uiState.update {
                        it.copy(linkedRecipe = result.data.toSummary())
                    }
                }
            }
        }
    }

    fun addPhoto(uri: Uri) {
        val currentPhotos = _uiState.value.photos
        if (currentPhotos.size < 3) {
            // Add photo with loading state
            val newPhoto = PhotoItem(uri = uri, state = PhotoState.LOADING)
            _uiState.update { it.copy(photos = currentPhotos + newPhoto) }

            // Simulate loading and validate the image
            viewModelScope.launch {
                kotlinx.coroutines.delay(500) // Brief loading state
                validatePhoto(uri)
            }
        }
    }

    private fun validatePhoto(uri: Uri) {
        // Update photo state to success (in a real app, you might validate the image here)
        _uiState.update { state ->
            state.copy(
                photos = state.photos.map { photo ->
                    if (photo.uri == uri) photo.copy(state = PhotoState.SUCCESS)
                    else photo
                }
            )
        }
    }

    fun setPhotoError(uri: Uri) {
        _uiState.update { state ->
            state.copy(
                photos = state.photos.map { photo ->
                    if (photo.uri == uri) photo.copy(state = PhotoState.ERROR)
                    else photo
                }
            )
        }
    }

    fun retryPhoto(uri: Uri) {
        _uiState.update { state ->
            state.copy(
                photos = state.photos.map { photo ->
                    if (photo.uri == uri) photo.copy(state = PhotoState.LOADING)
                    else photo
                }
            )
        }
        viewModelScope.launch {
            kotlinx.coroutines.delay(500)
            validatePhoto(uri)
        }
    }

    fun removePhoto(uri: Uri) {
        _uiState.update { it.copy(photos = it.photos.filter { photo -> photo.uri != uri }) }
    }

    fun reorderPhotos(fromIndex: Int, toIndex: Int) {
        if (fromIndex == toIndex) return
        val photos = _uiState.value.photos.toMutableList()
        if (fromIndex !in photos.indices || toIndex !in photos.indices) return
        val item = photos.removeAt(fromIndex)
        photos.add(toIndex, item)
        _uiState.update { it.copy(photos = photos) }
    }

    fun setRating(rating: Int) {
        _uiState.update { it.copy(rating = rating) }
    }

    fun setContent(content: String) {
        _uiState.update { it.copy(content = content) }
    }

    fun setHashtagInput(input: String) {
        _uiState.update { it.copy(hashtagInput = input) }
    }

    fun addHashtag(tag: String) {
        val cleanedTag = tag.trim().removePrefix("#").lowercase()
        if (cleanedTag.isEmpty()) return
        
        val currentHashtags = _uiState.value.hashtags
        if (currentHashtags.size >= 10) return
        if (currentHashtags.contains(cleanedTag)) return
        
        _uiState.update { 
            it.copy(
                hashtags = currentHashtags + cleanedTag,
                hashtagInput = ""
            ) 
        }
    }

    fun removeHashtag(index: Int) {
        val currentHashtags = _uiState.value.hashtags.toMutableList()
        if (index in currentHashtags.indices) {
            currentHashtags.removeAt(index)
            _uiState.update { it.copy(hashtags = currentHashtags) }
        }
    }

    fun setPrivate(isPrivate: Boolean) {
        _uiState.update { it.copy(isPrivate = isPrivate) }
    }

    fun setRecipeSearchQuery(query: String) {
        _uiState.update { it.copy(recipeSearchQuery = query) }
        if (query.length >= 2) {
            searchRecipes(query)
        } else {
            _uiState.update { it.copy(recipeSearchResults = emptyList()) }
        }
    }

    private fun searchRecipes(query: String) {
        viewModelScope.launch {
            _uiState.update { it.copy(isSearchingRecipes = true) }
            searchRepository.searchRecipes(query)
                .collect { result ->
                    when (result) {
                        is Result.Success -> {
                            _uiState.update {
                                it.copy(
                                    recipeSearchResults = result.data.content,
                                    isSearchingRecipes = false
                                )
                            }
                        }
                        is Result.Error -> {
                            _uiState.update { it.copy(isSearchingRecipes = false) }
                        }
                        is Result.Loading -> {}
                    }
                }
        }
    }

    fun selectRecipe(recipe: RecipeSummary) {
        _uiState.update {
            it.copy(
                linkedRecipe = recipe,
                recipeSearchQuery = "",
                recipeSearchResults = emptyList()
            )
        }
    }

    fun clearLinkedRecipe() {
        _uiState.update { it.copy(linkedRecipe = null) }
    }

    fun submit(photoFiles: List<File>) {
        if (!_uiState.value.canSubmit) return

        viewModelScope.launch {
            _uiState.update { it.copy(isSubmitting = true, error = null) }

            val state = _uiState.value

            logRepository.createLog(
                photos = photoFiles,
                rating = state.rating,
                recipeId = state.linkedRecipe?.id,
                content = state.content.ifBlank { null },
                hashtags = state.hashtags.ifEmpty { null },
                isPrivate = state.isPrivate
            ).collect { result ->
                when (result) {
                    is Result.Success -> {
                        _uiState.update {
                            it.copy(isSubmitting = false, isSubmitSuccess = true)
                        }
                    }
                    is Result.Error -> {
                        _uiState.update {
                            it.copy(
                                isSubmitting = false,
                                error = result.exception.message ?: "Failed to create log"
                            )
                        }
                    }
                    is Result.Loading -> {}
                }
            }
        }
    }

    fun clearError() {
        _uiState.update { it.copy(error = null) }
    }

    fun reset() {
        _uiState.value = CreateLogUiState()
    }
}
