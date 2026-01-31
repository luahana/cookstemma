package com.cookstemma.app.ui.screens.settings

import android.net.Uri
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.cookstemma.app.data.repository.UserRepository
import com.cookstemma.app.domain.model.MyProfile
import com.cookstemma.app.domain.model.Result
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import javax.inject.Inject

data class EditProfileUiState(
    val isLoading: Boolean = false,
    val isSaving: Boolean = false,
    val isCheckingUsername: Boolean = false,
    val saveSuccess: Boolean = false,
    val error: String? = null,
    val avatarUrl: String? = null,
    val newAvatarUri: Uri? = null,
    val username: String = "",
    val originalUsername: String = "",
    val bio: String = "",
    val youtubeUrl: String = "",
    val instagramHandle: String = "",
    val usernameAvailable: Boolean? = null,
    val usernameFormatError: String? = null
) {
    val canSave: Boolean
        get() {
            val result = !isSaving && usernameFormatError == null &&
                (usernameAvailable == true || username == originalUsername) &&
                username.isNotBlank()
            android.util.Log.d("EditProfile", "canSave=$result isSaving=$isSaving usernameFormatError=$usernameFormatError usernameAvailable=$usernameAvailable username=$username originalUsername=$originalUsername")
            return result
        }

    val canCheckUsername: Boolean
        get() = !isCheckingUsername && username != originalUsername &&
                username.length >= 3 && usernameFormatError == null

    val hasChanges: Boolean
        get() = newAvatarUri != null ||
                username != originalUsername ||
                bio.isNotBlank() ||
                youtubeUrl.isNotBlank() ||
                instagramHandle.isNotBlank()

    companion object {
        const val MAX_USERNAME_LENGTH = 30
        const val MAX_BIO_LENGTH = 150
        const val MIN_USERNAME_LENGTH = 3
    }
}

@HiltViewModel
class EditProfileViewModel @Inject constructor(
    private val userRepository: UserRepository
) : ViewModel() {

    private val _uiState = MutableStateFlow(EditProfileUiState())
    val uiState: StateFlow<EditProfileUiState> = _uiState.asStateFlow()

    init {
        loadProfile()
    }

    private fun loadProfile() {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true) }
            userRepository.getMyProfile().collect { result ->
                when (result) {
                    is Result.Loading -> { }
                    is Result.Success -> {
                        val profile = result.data
                        _uiState.update {
                            it.copy(
                                isLoading = false,
                                avatarUrl = profile.avatarUrl,
                                username = profile.username ?: "",
                                originalUsername = profile.username ?: "",
                                usernameAvailable = true,
                                bio = profile.bio ?: "",
                                youtubeUrl = profile.youtubeUrl ?: "",
                                instagramHandle = profile.instagramHandle ?: ""
                            )
                        }
                    }
                    is Result.Error -> {
                        _uiState.update { it.copy(isLoading = false, error = result.exception.message) }
                    }
                }
            }
        }
    }

    fun setUsername(username: String) {
        val trimmed = username.take(EditProfileUiState.MAX_USERNAME_LENGTH).lowercase()
        val formatError = validateUsernameFormat(trimmed)
        _uiState.update {
            it.copy(
                username = trimmed,
                usernameAvailable = if (trimmed == it.originalUsername) true else null,
                usernameFormatError = formatError
            )
        }
    }

    fun setBio(bio: String) {
        val trimmed = bio.take(EditProfileUiState.MAX_BIO_LENGTH)
        _uiState.update { it.copy(bio = trimmed) }
    }

    fun setYoutubeUrl(url: String) {
        _uiState.update { it.copy(youtubeUrl = url) }
    }

    fun setInstagramHandle(handle: String) {
        _uiState.update { it.copy(instagramHandle = handle.removePrefix("@")) }
    }

    fun setNewAvatar(uri: Uri?) {
        _uiState.update { it.copy(newAvatarUri = uri) }
    }

    fun checkUsernameAvailability() {
        val username = _uiState.value.username
        if (username == _uiState.value.originalUsername) {
            _uiState.update { it.copy(usernameAvailable = true) }
            return
        }

        viewModelScope.launch {
            _uiState.update { it.copy(isCheckingUsername = true) }
            when (val result = userRepository.checkUsernameAvailability(username)) {
                is Result.Success -> {
                    _uiState.update { it.copy(isCheckingUsername = false, usernameAvailable = result.data) }
                }
                is Result.Error -> {
                    _uiState.update { it.copy(isCheckingUsername = false, error = result.exception.message) }
                }
                is Result.Loading -> { }
            }
        }
    }

    fun saveProfile() {
        viewModelScope.launch {
            android.util.Log.d("EditProfile", "saveProfile called, canSave=${_uiState.value.canSave}")
            _uiState.update { it.copy(isSaving = true, error = null) }

            val state = _uiState.value
            val usernameToSend = if (state.username != state.originalUsername) state.username else null
            val bioToSend = state.bio.ifBlank { null }
            val youtubeToSend = state.youtubeUrl.ifBlank { null }
            val instagramToSend = state.instagramHandle.ifBlank { null }

            android.util.Log.d("EditProfile", "Calling updateProfile: username=$usernameToSend bio=$bioToSend youtube=$youtubeToSend instagram=$instagramToSend")

            // TODO: Handle avatar upload with MultipartBody.Part if newAvatarUri is set

            val result = userRepository.updateProfile(
                username = usernameToSend,
                bio = bioToSend,
                youtubeUrl = youtubeToSend,
                instagramHandle = instagramToSend
            )

            android.util.Log.d("EditProfile", "updateProfile result: $result")

            when (result) {
                is Result.Success -> {
                    android.util.Log.d("EditProfile", "updateProfile SUCCESS, setting saveSuccess=true")
                    _uiState.update { it.copy(isSaving = false, saveSuccess = true) }
                }
                is Result.Error -> {
                    android.util.Log.e("EditProfile", "updateProfile ERROR: ${result.exception.message}", result.exception)
                    _uiState.update { it.copy(isSaving = false, error = result.exception.message) }
                }
                is Result.Loading -> { }
            }
        }
    }

    fun clearError() {
        _uiState.update { it.copy(error = null) }
    }

    private fun validateUsernameFormat(username: String): String? {
        if (username.length < EditProfileUiState.MIN_USERNAME_LENGTH) {
            return "Username must be at least ${EditProfileUiState.MIN_USERNAME_LENGTH} characters"
        }
        if (!username.matches(Regex("^[a-z0-9_]+$"))) {
            return "Only lowercase letters, numbers, and underscores allowed"
        }
        if (username.startsWith("_") || username.endsWith("_")) {
            return "Username cannot start or end with underscore"
        }
        return null
    }
}
