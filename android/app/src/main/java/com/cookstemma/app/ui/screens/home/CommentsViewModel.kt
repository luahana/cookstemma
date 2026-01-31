package com.cookstemma.app.ui.screens.home

import android.util.Log
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.cookstemma.app.data.repository.Comment
import com.cookstemma.app.data.repository.CommentRepository
import com.cookstemma.app.domain.model.Result
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import javax.inject.Inject

private const val TAG = "CommentsViewModel"

data class CommentsUiState(
    val comments: List<Comment> = emptyList(),
    val isLoading: Boolean = false,
    val isLoadingMore: Boolean = false,
    val hasMore: Boolean = true,
    val error: String? = null,
    val commentText: String = "",
    val isSubmitting: Boolean = false,
    val replyingTo: Comment? = null
)

@HiltViewModel
class CommentsViewModel @Inject constructor(
    private val commentRepository: CommentRepository
) : ViewModel() {

    private val _uiState = MutableStateFlow(CommentsUiState())
    val uiState: StateFlow<CommentsUiState> = _uiState.asStateFlow()

    private var logId: String? = null
    private var nextCursor: String? = null

    fun loadComments(logId: String) {
        Log.d(TAG, "loadComments called with logId: $logId")
        this.logId = logId
        nextCursor = null
        _uiState.update { it.copy(isLoading = true, error = null) }
        viewModelScope.launch {
            Log.d(TAG, "Starting to collect comments for logId: $logId")
            commentRepository.getComments(logId).collect { result ->
                Log.d(TAG, "Received result: $result")
                when (result) {
                    is Result.Loading -> _uiState.update { it.copy(isLoading = true, error = null) }
                    is Result.Success -> {
                        nextCursor = result.data.nextCursor
                        _uiState.update {
                            it.copy(
                                comments = result.data.content,
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

    fun loadMore() {
        val currentLogId = logId ?: return
        if (_uiState.value.isLoadingMore || !_uiState.value.hasMore || nextCursor == null) return
        
        viewModelScope.launch {
            commentRepository.getComments(currentLogId, nextCursor).collect { result ->
                when (result) {
                    is Result.Loading -> _uiState.update { it.copy(isLoadingMore = true) }
                    is Result.Success -> {
                        nextCursor = result.data.nextCursor
                        _uiState.update {
                            it.copy(
                                comments = it.comments + result.data.content,
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

    fun setCommentText(text: String) {
        _uiState.update { it.copy(commentText = text) }
    }

    fun setReplyingTo(comment: Comment?) {
        _uiState.update { it.copy(replyingTo = comment) }
    }

    fun submitComment() {
        val currentLogId = logId ?: return
        val text = _uiState.value.commentText.trim()
        if (text.isBlank()) return

        val parentId = _uiState.value.replyingTo?.id

        viewModelScope.launch {
            _uiState.update { it.copy(isSubmitting = true) }
            commentRepository.createComment(currentLogId, text, parentId).collect { result ->
                when (result) {
                    is Result.Loading -> { /* Already showing submitting state */ }
                    is Result.Success -> {
                        val newComment = result.data
                        _uiState.update { state ->
                            val updatedComments = if (parentId == null) {
                                listOf(newComment) + state.comments
                            } else {
                                state.comments.map { comment ->
                                    if (comment.id == parentId) {
                                        comment.copy(
                                            replies = (comment.replies ?: emptyList()) + newComment,
                                            replyCount = comment.replyCount + 1
                                        )
                                    } else comment
                                }
                            }
                            state.copy(
                                comments = updatedComments,
                                commentText = "",
                                isSubmitting = false,
                                replyingTo = null
                            )
                        }
                    }
                    is Result.Error -> _uiState.update {
                        it.copy(isSubmitting = false, error = result.exception.message)
                    }
                }
            }
        }
    }

    fun toggleCommentLike(comment: Comment) {
        viewModelScope.launch {
            val wasLiked = comment.isLiked
            // Optimistic update
            updateCommentInList(comment.id) {
                it.copy(
                    isLiked = !wasLiked,
                    likeCount = it.likeCount + if (wasLiked) -1 else 1
                )
            }
            
            val result = if (wasLiked) {
                commentRepository.unlikeComment(comment.id)
            } else {
                commentRepository.likeComment(comment.id)
            }
            
            result.collect { res ->
                if (res is Result.Error) {
                    // Revert on failure
                    updateCommentInList(comment.id) {
                        it.copy(
                            isLiked = wasLiked,
                            likeCount = it.likeCount + if (wasLiked) 1 else -1
                        )
                    }
                }
            }
        }
    }

    private fun updateCommentInList(commentId: String, update: (Comment) -> Comment) {
        _uiState.update { state ->
            state.copy(comments = state.comments.map { comment ->
                if (comment.id == commentId) {
                    update(comment)
                } else if (comment.replies?.any { it.id == commentId } == true) {
                    comment.copy(replies = comment.replies.map { reply ->
                        if (reply.id == commentId) update(reply) else reply
                    })
                } else comment
            })
        }
    }

    fun reset() {
        logId = null
        nextCursor = null
        _uiState.value = CommentsUiState()
    }
}
