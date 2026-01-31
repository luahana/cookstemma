package com.cookstemma.app.ui.screens.settings

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.cookstemma.app.ui.theme.Spacing

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun NotificationSettingsScreen(
    onNavigateBack: () -> Unit
) {
    // Local state matching iOS (not persisted)
    var commentsEnabled by remember { mutableStateOf(true) }
    var followersEnabled by remember { mutableStateOf(true) }
    var newSavedEnabled by remember { mutableStateOf(true) }
    var newCookingLogsEnabled by remember { mutableStateOf(true) }
    var newVariantRecipesEnabled by remember { mutableStateOf(true) }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Notifications") },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Back")
                    }
                }
            )
        }
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .verticalScroll(rememberScrollState())
        ) {
            // Push Notifications Section
            NotificationSectionHeader("Push Notifications")

            NotificationToggleItem(
                title = "Comments & Replies",
                checked = commentsEnabled,
                onCheckedChange = { commentsEnabled = it }
            )
            NotificationToggleItem(
                title = "New Followers",
                checked = followersEnabled,
                onCheckedChange = { followersEnabled = it }
            )
            NotificationToggleItem(
                title = "New Saved Recipes",
                checked = newSavedEnabled,
                onCheckedChange = { newSavedEnabled = it }
            )
            NotificationToggleItem(
                title = "New Cooking Logs",
                checked = newCookingLogsEnabled,
                onCheckedChange = { newCookingLogsEnabled = it }
            )
            NotificationToggleItem(
                title = "New Variant Recipes",
                checked = newVariantRecipesEnabled,
                onCheckedChange = { newVariantRecipesEnabled = it }
            )

            Spacer(modifier = Modifier.height(Spacing.xl))
        }
    }
}

@Composable
private fun NotificationSectionHeader(title: String) {
    Text(
        text = title,
        style = MaterialTheme.typography.titleSmall,
        color = MaterialTheme.colorScheme.primary,
        modifier = Modifier.padding(horizontal = Spacing.md, vertical = Spacing.sm)
    )
}

@Composable
private fun NotificationToggleItem(
    title: String,
    checked: Boolean,
    onCheckedChange: (Boolean) -> Unit
) {
    Surface(
        modifier = Modifier.fillMaxWidth(),
        color = MaterialTheme.colorScheme.surface
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = Spacing.md, vertical = Spacing.sm),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(
                text = title,
                style = MaterialTheme.typography.bodyLarge,
                color = MaterialTheme.colorScheme.onSurface,
                modifier = Modifier.weight(1f)
            )
            Switch(
                checked = checked,
                onCheckedChange = onCheckedChange
            )
        }
    }
}
