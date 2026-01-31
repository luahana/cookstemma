package com.cookstemma.app.data.local

import android.content.Context
import android.content.SharedPreferences
import com.cookstemma.app.ui.screens.settings.AppTheme
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class ThemePreferencesDataStore @Inject constructor(
    @ApplicationContext private val context: Context
) {
    companion object {
        private const val PREFS_NAME = "theme_preferences"
        private const val KEY_THEME = "app_theme"
    }

    private val prefs: SharedPreferences = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
    private val _themePreference = MutableStateFlow(loadTheme())

    val themePreference: Flow<AppTheme> = _themePreference.asStateFlow()

    val currentTheme: AppTheme
        get() = _themePreference.value

    private fun loadTheme(): AppTheme {
        val themeName = prefs.getString(KEY_THEME, AppTheme.SYSTEM.name) ?: AppTheme.SYSTEM.name
        return try {
            AppTheme.valueOf(themeName)
        } catch (e: IllegalArgumentException) {
            AppTheme.SYSTEM
        }
    }

    fun setTheme(theme: AppTheme) {
        prefs.edit()
            .putString(KEY_THEME, theme.name)
            .apply()
        _themePreference.value = theme
    }
}
