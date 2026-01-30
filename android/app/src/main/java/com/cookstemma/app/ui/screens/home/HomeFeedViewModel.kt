package com.cookstemma.app.ui.screens.home

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.cookstemma.app.data.repository.FeedRepository
import com.cookstemma.app.data.repository.UserRepository
import com.cookstemma.app.domain.model.*
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import javax.inject.Inject

data class HomeFeedUiState(
    val items: List<FeedItem> = emptyList(),
    val savedLogIds: Set<String> = emptySet(),
    val likedLogIds: Set<String> = emptySet(),
    val isLoading: Boolean = false,
    val isRefreshing: Boolean = false,
    val isLoadingMore: Boolean = false,
    val error: String? = null,
    val hasMore: Boolean = true
) {
    fun isLogSaved(logId: String): Boolean = savedLogIds.contains(logId)
    fun isLogLiked(logId: String): Boolean = likedLogIds.contains(logId)
}

@HiltViewModel
class HomeFeedViewModel @Inject constructor(
    private val feedRepository: FeedRepository,
    private val userRepository: UserRepository
) : ViewModel() {

    private val _uiState = MutableStateFlow(HomeFeedUiState())
    val uiState: StateFlow<HomeFeedUiState> = _uiState.asStateFlow()

    private var nextCursor: String? = null
    private var hasFetchedSavedIds = false

    init {
        loadFeed()
        fetchSavedLogIds()
    }
    
    private fun fetchSavedLogIds() {
        if (hasFetchedSavedIds) return
        
        viewModelScope.launch {
            val allSavedIds = mutableSetOf<String>()
            var cursor: String? = null
            
            do {
                userRepository.getSavedLogs(cursor).collect { result ->
                    if (result is Result.Success) {
                        allSavedIds.addAll(result.data.content.map { it.id })
                        cursor = if (result.data.hasMore) result.data.nextCursor else null
                    } else {
                        cursor = null
                    }
                }
            } while (cursor != null)
            
            _uiState.update { it.copy(savedLogIds = allSavedIds) }
            hasFetchedSavedIds = true
        }
    }

    fun loadFeed() {
        viewModelScope.launch {
            feedRepository.getFeed(null).collect { result ->
                when (result) {
                    is Result.Loading -> _uiState.update { it.copy(isLoading = true, error = null) }
                    is Result.Success -> {
                        nextCursor = result.data.nextCursor
                        _uiState.update {
                            it.copy(
                                items = result.data.content,
                                isLoading = false,
                                hasMore = result.data.hasMore
                            )
                        }
                    }
                    is Result.Error -> _uiState.update {
                        it.copy(isLoading = false, error = result.exception.message)
                    }
                }
            }
        }
    }

    fun refresh() {
        viewModelScope.launch {
            _uiState.update { it.copy(isRefreshing = true, error = null) }
            feedRepository.getFeed(null).collect { result ->
                when (result) {
                    is Result.Loading -> { /* Already showing refresh indicator */ }
                    is Result.Success -> {
                        nextCursor = result.data.nextCursor
                        _uiState.update {
                            it.copy(
                                items = result.data.content,
                                isRefreshing = false,
                                hasMore = result.data.hasMore
                            )
                        }
                    }
                    is Result.Error -> _uiState.update {
                        it.copy(isRefreshing = false, error = result.exception.message)
                    }
                }
            }
        }
    }

    fun loadMore() {
        if (_uiState.value.isLoadingMore || !_uiState.value.hasMore || nextCursor == null) return
        viewModelScope.launch {
            feedRepository.getFeed(nextCursor).collect { result ->
                when (result) {
                    is Result.Loading -> _uiState.update { it.copy(isLoadingMore = true) }
                    is Result.Success -> {
                        nextCursor = result.data.nextCursor
                        _uiState.update {
                            it.copy(
                                items = it.items + result.data.content,
                                isLoadingMore = false,
                                hasMore = result.data.hasMore
                            )
                        }
                    }
                    is Result.Error -> _uiState.update { it.copy(isLoadingMore = false) }
                }
            }
        }
    }

    fun likeLog(logId: String) {
        viewModelScope.launch {
            val wasLiked = _uiState.value.isLogLiked(logId)
            
            // Optimistic update
            _uiState.update { state ->
                val newLikedIds = if (wasLiked) {
                    state.likedLogIds - logId
                } else {
                    state.likedLogIds + logId
                }
                state.copy(likedLogIds = newLikedIds)
            }
            
            val result = if (wasLiked) {
                feedRepository.unlikeLog(logId)
            } else {
                feedRepository.likeLog(logId)
            }
            
            if (result is Result.Error) {
                // Revert on failure
                _uiState.update { state ->
                    val revertedIds = if (wasLiked) {
                        state.likedLogIds + logId
                    } else {
                        state.likedLogIds - logId
                    }
                    state.copy(likedLogIds = revertedIds)
                }
            }
        }
    }

    fun saveLog(logId: String) {
        viewModelScope.launch {
            val wasSaved = _uiState.value.isLogSaved(logId)
            
            // Optimistic update
            _uiState.update { state ->
                val newSavedIds = if (wasSaved) {
                    state.savedLogIds - logId
                } else {
                    state.savedLogIds + logId
                }
                state.copy(savedLogIds = newSavedIds)
            }
            
            val result = if (wasSaved) {
                feedRepository.unsaveLog(logId)
            } else {
                feedRepository.saveLog(logId)
            }
            
            if (result is Result.Error) {
                // Revert on failure
                _uiState.update { state ->
                    val revertedIds = if (wasSaved) {
                        state.savedLogIds + logId
                    } else {
                        state.savedLogIds - logId
                    }
                    state.copy(savedLogIds = revertedIds)
                }
            }
        }
    }
    
    fun isLogSaved(logId: String): Boolean = _uiState.value.isLogSaved(logId)
    fun isLogLiked(logId: String): Boolean = _uiState.value.isLogLiked(logId)
}
