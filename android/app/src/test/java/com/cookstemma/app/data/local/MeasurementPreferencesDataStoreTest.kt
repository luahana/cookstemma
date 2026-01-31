package com.cookstemma.app.data.local

import android.content.Context
import android.content.SharedPreferences
import com.cookstemma.app.domain.model.MeasurementPreference
import io.mockk.every
import io.mockk.mockk
import io.mockk.slot
import io.mockk.verify
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.test.runTest
import org.junit.Assert.assertEquals
import org.junit.Before
import org.junit.Test

class MeasurementPreferencesDataStoreTest {

    private lateinit var context: Context
    private lateinit var sharedPreferences: SharedPreferences
    private lateinit var editor: SharedPreferences.Editor
    private lateinit var dataStore: MeasurementPreferencesDataStore

    @Before
    fun setup() {
        context = mockk()
        sharedPreferences = mockk()
        editor = mockk(relaxed = true)

        every { context.getSharedPreferences(any(), any()) } returns sharedPreferences
        every { sharedPreferences.edit() } returns editor
        every { editor.putString(any(), any()) } returns editor
    }

    @Test
    fun `loadPreference returns ORIGINAL when no preference saved`() {
        every { sharedPreferences.getString(any(), any()) } returns null

        dataStore = MeasurementPreferencesDataStore(context)

        assertEquals(MeasurementPreference.ORIGINAL, dataStore.currentPreference)
    }

    @Test
    fun `loadPreference returns saved preference`() {
        every { sharedPreferences.getString(any(), any()) } returns "METRIC"

        dataStore = MeasurementPreferencesDataStore(context)

        assertEquals(MeasurementPreference.METRIC, dataStore.currentPreference)
    }

    @Test
    fun `loadPreference returns ORIGINAL for invalid value`() {
        every { sharedPreferences.getString(any(), any()) } returns "INVALID"

        dataStore = MeasurementPreferencesDataStore(context)

        assertEquals(MeasurementPreference.ORIGINAL, dataStore.currentPreference)
    }

    @Test
    fun `setPreference saves preference to SharedPreferences`() {
        every { sharedPreferences.getString(any(), any()) } returns null
        val keySlot = slot<String>()
        val valueSlot = slot<String>()
        every { editor.putString(capture(keySlot), capture(valueSlot)) } returns editor

        dataStore = MeasurementPreferencesDataStore(context)
        dataStore.setPreference(MeasurementPreference.US)

        assertEquals("measurement_unit", keySlot.captured)
        assertEquals("US", valueSlot.captured)
        verify { editor.apply() }
    }

    @Test
    fun `setPreference updates currentPreference`() {
        every { sharedPreferences.getString(any(), any()) } returns "ORIGINAL"

        dataStore = MeasurementPreferencesDataStore(context)
        dataStore.setPreference(MeasurementPreference.METRIC)

        assertEquals(MeasurementPreference.METRIC, dataStore.currentPreference)
    }

    @Test
    fun `measurementPreference flow emits initial value`() = runTest {
        every { sharedPreferences.getString(any(), any()) } returns "US"

        dataStore = MeasurementPreferencesDataStore(context)

        assertEquals(MeasurementPreference.US, dataStore.measurementPreference.first())
    }

    @Test
    fun `measurementPreference flow emits updated value after setPreference`() = runTest {
        every { sharedPreferences.getString(any(), any()) } returns "ORIGINAL"

        dataStore = MeasurementPreferencesDataStore(context)
        dataStore.setPreference(MeasurementPreference.METRIC)

        assertEquals(MeasurementPreference.METRIC, dataStore.measurementPreference.first())
    }
}
