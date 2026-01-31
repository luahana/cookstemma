package com.cookstemma.app.util

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import androidx.appcompat.app.AppCompatDelegate
import androidx.core.os.LocaleListCompat
import com.cookstemma.app.MainActivity
import dagger.hilt.android.qualifiers.ApplicationContext
import java.util.Locale
import javax.inject.Inject
import javax.inject.Singleton
import kotlin.system.exitProcess

// AppCompat is required for per-app language preferences on Android < 13

enum class AppLanguage(
    val code: String,
    val displayName: String
) {
    ENGLISH("en", "English"),
    KOREAN("ko", "한국어"),
    JAPANESE("ja", "日本語"),
    CHINESE("zh-CN", "简体中文"),
    SPANISH("es", "Español"),
    FRENCH("fr", "Français"),
    GERMAN("de", "Deutsch"),
    RUSSIAN("ru", "Русский"),
    DUTCH("nl", "Nederlands");

    companion object {
        fun fromCode(code: String): AppLanguage {
            return entries.find { it.code == code } ?: ENGLISH
        }

        fun fromLocale(locale: Locale): AppLanguage {
            val languageTag = locale.toLanguageTag()
            // Handle Chinese specifically
            if (languageTag.startsWith("zh")) {
                return CHINESE
            }
            return entries.find { it.code == locale.language } ?: ENGLISH
        }
    }
}

@Singleton
class LanguageManager @Inject constructor(
    @ApplicationContext private val context: Context
) {
    fun getCurrentLanguage(): AppLanguage {
        val currentLocales = AppCompatDelegate.getApplicationLocales()
        return if (currentLocales.isEmpty) {
            // Use system locale
            AppLanguage.fromLocale(Locale.getDefault())
        } else {
            val locale = currentLocales[0] ?: Locale.getDefault()
            AppLanguage.fromLocale(locale)
        }
    }

    fun setLanguage(language: AppLanguage) {
        val localeList = LocaleListCompat.forLanguageTags(language.code)
        AppCompatDelegate.setApplicationLocales(localeList)
    }

    /**
     * Sets the language and fully restarts the app.
     * This kills the current process and starts fresh.
     */
    fun setLanguageAndRestart(language: AppLanguage) {
        // First set the language
        val localeList = LocaleListCompat.forLanguageTags(language.code)
        AppCompatDelegate.setApplicationLocales(localeList)

        // Schedule app restart
        val intent = Intent(context, MainActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK)
        }
        val pendingIntent = PendingIntent.getActivity(
            context,
            0,
            intent,
            PendingIntent.FLAG_CANCEL_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        alarmManager.setExact(
            AlarmManager.RTC,
            System.currentTimeMillis() + 100, // 100ms delay
            pendingIntent
        )

        // Kill current process
        exitProcess(0)
    }

    fun getAllLanguages(): List<AppLanguage> = AppLanguage.entries
}
