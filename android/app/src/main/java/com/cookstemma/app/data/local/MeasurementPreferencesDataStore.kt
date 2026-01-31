package com.cookstemma.app.data.local

import android.content.Context
import android.content.SharedPreferences
import com.cookstemma.app.domain.model.MeasurementPreference
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class MeasurementPreferencesDataStore @Inject constructor(
    @ApplicationContext private val context: Context
) {
    companion object {
        private const val PREFS_NAME = "measurement_preferences"
        private const val KEY_MEASUREMENT_UNIT = "measurement_unit"
    }

    private val prefs: SharedPreferences =
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

    private val _measurementPreference = MutableStateFlow(loadPreference())

    val measurementPreference: Flow<MeasurementPreference> = _measurementPreference.asStateFlow()

    val currentPreference: MeasurementPreference
        get() = _measurementPreference.value

    private fun loadPreference(): MeasurementPreference {
        val prefName = prefs.getString(KEY_MEASUREMENT_UNIT, MeasurementPreference.ORIGINAL.name)
            ?: MeasurementPreference.ORIGINAL.name
        return try {
            MeasurementPreference.valueOf(prefName)
        } catch (e: IllegalArgumentException) {
            MeasurementPreference.ORIGINAL
        }
    }

    fun setPreference(preference: MeasurementPreference) {
        prefs.edit()
            .putString(KEY_MEASUREMENT_UNIT, preference.name)
            .apply()
        _measurementPreference.value = preference
    }
}
