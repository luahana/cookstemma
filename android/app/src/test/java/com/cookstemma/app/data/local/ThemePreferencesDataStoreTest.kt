package com.cookstemma.app.data.local

import android.content.Context
import android.content.SharedPreferences
import com.cookstemma.app.ui.screens.settings.AppTheme
import io.mockk.every
import io.mockk.mockk
import io.mockk.slot
import io.mockk.verify
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.test.runTest
import org.junit.Assert.assertEquals
import org.junit.Before
import org.junit.Test

class ThemePreferencesDataStoreTest {

    private lateinit var context: Context
    private lateinit var sharedPreferences: SharedPreferences
    private lateinit var editor: SharedPreferences.Editor
    private lateinit var sut: ThemePreferencesDataStore

    @Before
    fun setUp() {
        context = mockk()
        sharedPreferences = mockk()
        editor = mockk(relaxed = true)

        every { context.getSharedPreferences("theme_preferences", Context.MODE_PRIVATE) } returns sharedPreferences
        every { sharedPreferences.edit() } returns editor
        every { editor.putString(any(), any()) } returns editor
    }

    @Test
    fun `loads SYSTEM theme as default when no preference saved`() = runTest {
        every { sharedPreferences.getString("app_theme", AppTheme.SYSTEM.name) } returns AppTheme.SYSTEM.name

        sut = ThemePreferencesDataStore(context)

        assertEquals(AppTheme.SYSTEM, sut.currentTheme)
        assertEquals(AppTheme.SYSTEM, sut.themePreference.first())
    }

    @Test
    fun `loads saved DARK theme preference`() = runTest {
        every { sharedPreferences.getString("app_theme", AppTheme.SYSTEM.name) } returns AppTheme.DARK.name

        sut = ThemePreferencesDataStore(context)

        assertEquals(AppTheme.DARK, sut.currentTheme)
        assertEquals(AppTheme.DARK, sut.themePreference.first())
    }

    @Test
    fun `loads saved LIGHT theme preference`() = runTest {
        every { sharedPreferences.getString("app_theme", AppTheme.SYSTEM.name) } returns AppTheme.LIGHT.name

        sut = ThemePreferencesDataStore(context)

        assertEquals(AppTheme.LIGHT, sut.currentTheme)
        assertEquals(AppTheme.LIGHT, sut.themePreference.first())
    }

    @Test
    fun `setTheme saves theme to SharedPreferences`() = runTest {
        every { sharedPreferences.getString("app_theme", AppTheme.SYSTEM.name) } returns AppTheme.SYSTEM.name
        val themeSlot = slot<String>()
        every { editor.putString("app_theme", capture(themeSlot)) } returns editor

        sut = ThemePreferencesDataStore(context)
        sut.setTheme(AppTheme.DARK)

        verify { editor.putString("app_theme", "DARK") }
        verify { editor.apply() }
        assertEquals("DARK", themeSlot.captured)
    }

    @Test
    fun `setTheme updates currentTheme property`() = runTest {
        every { sharedPreferences.getString("app_theme", AppTheme.SYSTEM.name) } returns AppTheme.SYSTEM.name

        sut = ThemePreferencesDataStore(context)
        assertEquals(AppTheme.SYSTEM, sut.currentTheme)

        sut.setTheme(AppTheme.LIGHT)
        assertEquals(AppTheme.LIGHT, sut.currentTheme)
    }

    @Test
    fun `setTheme emits new value to themePreference flow`() = runTest {
        every { sharedPreferences.getString("app_theme", AppTheme.SYSTEM.name) } returns AppTheme.SYSTEM.name

        sut = ThemePreferencesDataStore(context)
        assertEquals(AppTheme.SYSTEM, sut.themePreference.first())

        sut.setTheme(AppTheme.DARK)
        assertEquals(AppTheme.DARK, sut.themePreference.first())
    }

    @Test
    fun `handles invalid theme value gracefully by defaulting to SYSTEM`() = runTest {
        every { sharedPreferences.getString("app_theme", AppTheme.SYSTEM.name) } returns "INVALID_THEME"

        sut = ThemePreferencesDataStore(context)

        assertEquals(AppTheme.SYSTEM, sut.currentTheme)
    }
}
