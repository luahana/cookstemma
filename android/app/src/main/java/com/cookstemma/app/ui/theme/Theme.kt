package com.cookstemma.app.ui.theme

import android.app.Activity
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.runtime.SideEffect
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.toArgb
import androidx.compose.ui.platform.LocalView
import androidx.compose.ui.unit.dp
import androidx.core.view.WindowCompat

val PrimaryOrange = Color(0xFFFF6B35)
val PrimaryOrangeLight = Color(0xFFFF8A5C)
val SecondaryTeal = Color(0xFF00A896)
val BrandOrange = PrimaryOrange

private val LightColorScheme = lightColorScheme(
    primary = PrimaryOrange,
    onPrimary = Color.White,
    primaryContainer = PrimaryOrangeLight,
    secondary = SecondaryTeal,
    onSecondary = Color.White,
    background = Color(0xFFFFFBFE),
    surface = Color(0xFFFFFBFE),
    onBackground = Color(0xFF1C1B1F),
    onSurface = Color(0xFF1C1B1F),
)

private val DarkColorScheme = darkColorScheme(
    primary = PrimaryOrangeLight,
    onPrimary = Color(0xFF5F1500),
    secondary = Color(0xFF33BAA8),
    onSecondary = Color(0xFF003737),
    background = Color(0xFF1C1B1F),
    surface = Color(0xFF1C1B1F),
    onBackground = Color(0xFFE6E1E5),
    onSurface = Color(0xFFE6E1E5),
)

@Composable
fun CookstemmaTheme(
    darkTheme: Boolean = isSystemInDarkTheme(),
    content: @Composable () -> Unit
) {
    val colorScheme = if (darkTheme) DarkColorScheme else LightColorScheme
    val view = LocalView.current
    if (!view.isInEditMode) {
        SideEffect {
            val window = (view.context as Activity).window
            window.statusBarColor = colorScheme.primary.toArgb()
            WindowCompat.getInsetsController(window, view).isAppearanceLightStatusBars = !darkTheme
        }
    }
    MaterialTheme(colorScheme = colorScheme, content = content)
}

object Spacing {
    val xxxs = 2.dp
    val xxs = 4.dp
    val xs = 6.dp
    val sm = 8.dp
    val md = 16.dp
    val lg = 24.dp
    val xl = 32.dp
    val xxl = 48.dp
}

object CornerRadius {
    val sm = 8.dp
    val md = 12.dp
    val lg = 16.dp
}

object AvatarSize {
    val xs = 24.dp
    val sm = 32.dp
    val md = 48.dp
    val lg = 64.dp
    val xl = 96.dp
}

object Layout {
    /** Maximum content width on tablets (matches iOS) */
    val maxContentWidth = 600.dp
}
