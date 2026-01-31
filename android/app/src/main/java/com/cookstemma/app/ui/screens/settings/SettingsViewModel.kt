package com.cookstemma.app.ui.screens.settings

import android.content.Context
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.cookstemma.app.data.auth.TokenManager
import com.cookstemma.app.data.local.MeasurementPreferencesDataStore
import com.cookstemma.app.data.local.ThemePreferencesDataStore
import com.cookstemma.app.data.repository.AuthRepository
import com.cookstemma.app.data.repository.UserRepository
import com.cookstemma.app.domain.model.MeasurementPreference
import com.cookstemma.app.domain.model.Result
import com.cookstemma.app.util.AppLanguage
import com.cookstemma.app.util.LanguageManager
import dagger.hilt.android.lifecycle.HiltViewModel
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import javax.inject.Inject

enum class AppTheme(val displayName: String) {
    SYSTEM("System"),
    LIGHT("Light"),
    DARK("Dark")
}

data class SettingsUiState(
    val appTheme: AppTheme = AppTheme.SYSTEM,
    val currentLanguage: AppLanguage = AppLanguage.ENGLISH,
    val measurementPreference: MeasurementPreference = MeasurementPreference.ORIGINAL,
    val appVersion: String = "1.0.0",
    val isLoggingOut: Boolean = false,
    val isDeletingAccount: Boolean = false,
    val logoutSuccess: Boolean = false,
    val deleteSuccess: Boolean = false,
    val error: String? = null
)

@HiltViewModel
class SettingsViewModel @Inject constructor(
    private val userRepository: UserRepository,
    private val authRepository: AuthRepository,
    private val tokenManager: TokenManager,
    private val languageManager: LanguageManager,
    private val themePreferencesDataStore: ThemePreferencesDataStore,
    private val measurementPreferencesDataStore: MeasurementPreferencesDataStore,
    @ApplicationContext private val context: Context
) : ViewModel() {

    private val _uiState = MutableStateFlow(SettingsUiState())
    val uiState: StateFlow<SettingsUiState> = _uiState.asStateFlow()

    init {
        loadSettings()
        observeThemeChanges()
        observeMeasurementChanges()
    }

    private fun loadSettings() {
        val packageInfo = context.packageManager.getPackageInfo(context.packageName, 0)
        val currentLanguage = languageManager.getCurrentLanguage()
        val savedTheme = themePreferencesDataStore.currentTheme
        val savedMeasurement = measurementPreferencesDataStore.currentPreference
        _uiState.update {
            it.copy(
                appVersion = packageInfo.versionName ?: "1.0.0",
                currentLanguage = currentLanguage,
                appTheme = savedTheme,
                measurementPreference = savedMeasurement
            )
        }
    }

    private fun observeThemeChanges() {
        viewModelScope.launch {
            themePreferencesDataStore.themePreference.collect { theme ->
                _uiState.update { it.copy(appTheme = theme) }
            }
        }
    }

    private fun observeMeasurementChanges() {
        viewModelScope.launch {
            measurementPreferencesDataStore.measurementPreference.collect { preference ->
                _uiState.update { it.copy(measurementPreference = preference) }
            }
        }
    }

    fun setTheme(theme: AppTheme) {
        themePreferencesDataStore.setTheme(theme)
    }

    fun setMeasurementPreference(preference: MeasurementPreference) {
        measurementPreferencesDataStore.setPreference(preference)
    }

    fun setLanguage(language: AppLanguage) {
        // This will fully restart the app after setting the language
        languageManager.setLanguageAndRestart(language)
    }

    fun getAllLanguages(): List<AppLanguage> = languageManager.getAllLanguages()

    fun logout() {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoggingOut = true, error = null) }
            authRepository.logout().collect { result ->
                when (result) {
                    is Result.Success -> {
                        _uiState.update { it.copy(isLoggingOut = false, logoutSuccess = true) }
                    }
                    is Result.Error -> {
                        _uiState.update { it.copy(isLoggingOut = false, error = result.exception.message) }
                    }
                    is Result.Loading -> {}
                }
            }
        }
    }

    fun deleteAccount() {
        viewModelScope.launch {
            _uiState.update { it.copy(isDeletingAccount = true, error = null) }
            when (val result = userRepository.deleteAccount()) {
                is Result.Success -> {
                    tokenManager.clearTokens()
                    _uiState.update { it.copy(isDeletingAccount = false, deleteSuccess = true) }
                }
                is Result.Error -> {
                    _uiState.update { it.copy(isDeletingAccount = false, error = result.exception.message) }
                }
                is Result.Loading -> { }
            }
        }
    }

    fun clearError() {
        _uiState.update { it.copy(error = null) }
    }
}
