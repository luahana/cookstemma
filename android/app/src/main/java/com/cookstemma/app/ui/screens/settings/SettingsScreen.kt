package com.cookstemma.app.ui.screens.settings

import android.content.Intent
import android.net.Uri
import androidx.compose.foundation.clickable
import com.cookstemma.app.util.AppLanguage
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.automirrored.filled.ExitToApp
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.cookstemma.app.R
import com.cookstemma.app.ui.theme.Spacing

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SettingsScreen(
    onNavigateBack: () -> Unit,
    onNavigateToEditProfile: () -> Unit,
    onNavigateToNotificationSettings: () -> Unit,
    onNavigateToBlockedUsers: () -> Unit,
    onNavigateToMeasurementUnits: () -> Unit,
    onLogoutSuccess: () -> Unit,
    viewModel: SettingsViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()
    val context = LocalContext.current

    var showLogoutDialog by remember { mutableStateOf(false) }
    var showDeleteDialog by remember { mutableStateOf(false) }
    var showThemeDialog by remember { mutableStateOf(false) }
    var showLanguageDialog by remember { mutableStateOf(false) }
    var showRestartConfirmDialog by remember { mutableStateOf(false) }
    var pendingLanguage by remember { mutableStateOf<AppLanguage?>(null) }

    LaunchedEffect(uiState.logoutSuccess, uiState.deleteSuccess) {
        if (uiState.logoutSuccess || uiState.deleteSuccess) {
            onLogoutSuccess()
        }
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text(stringResource(R.string.settings)) },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = stringResource(R.string.cd_back))
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
            // Account Section
            SettingsSectionHeader(stringResource(R.string.account))
            SettingsItem(
                icon = Icons.Default.Person,
                title = stringResource(R.string.edit_profile),
                onClick = onNavigateToEditProfile
            )
            SettingsItem(
                icon = Icons.Default.Notifications,
                title = stringResource(R.string.notifications),
                onClick = onNavigateToNotificationSettings
            )
            SettingsItem(
                icon = Icons.Default.Lock,
                title = stringResource(R.string.privacy),
                subtitle = stringResource(R.string.manage_blocked_users),
                onClick = onNavigateToBlockedUsers
            )

            HorizontalDivider(modifier = Modifier.padding(vertical = Spacing.sm))

            // Preferences Section
            SettingsSectionHeader(stringResource(R.string.preferences))
            SettingsItem(
                icon = Icons.Default.Palette,
                title = stringResource(R.string.theme),
                subtitle = uiState.appTheme.displayName,
                onClick = { showThemeDialog = true }
            )
            SettingsItem(
                icon = Icons.Default.Language,
                title = stringResource(R.string.language),
                subtitle = uiState.currentLanguage.displayName,
                onClick = { showLanguageDialog = true }
            )
            SettingsItem(
                icon = Icons.Default.Straighten,
                title = stringResource(R.string.measurement_units),
                subtitle = stringResource(uiState.measurementPreference.displayNameRes),
                onClick = onNavigateToMeasurementUnits
            )

            HorizontalDivider(modifier = Modifier.padding(vertical = Spacing.sm))

            // Support Section
            SettingsSectionHeader(stringResource(R.string.support))
            SettingsItem(
                icon = Icons.Default.Email,
                title = stringResource(R.string.send_feedback),
                onClick = {
                    val intent = Intent(Intent.ACTION_SENDTO).apply {
                        data = Uri.parse("mailto:contact@cookstemma.com?subject=Cookstemma%20Feedback")
                    }
                    context.startActivity(intent)
                }
            )
            SettingsItem(
                icon = Icons.Default.Info,
                title = stringResource(R.string.about),
                onClick = { /* TODO: About screen */ }
            )

            HorizontalDivider(modifier = Modifier.padding(vertical = Spacing.sm))

            // Legal Section
            SettingsSectionHeader(stringResource(R.string.legal))
            SettingsItem(
                icon = Icons.Default.Description,
                title = stringResource(R.string.terms_of_service),
                onClick = {
                    val intent = Intent(Intent.ACTION_VIEW, Uri.parse("https://cookstemma.com/terms"))
                    context.startActivity(intent)
                }
            )
            SettingsItem(
                icon = Icons.Default.PrivacyTip,
                title = stringResource(R.string.privacy_policy),
                onClick = {
                    val intent = Intent(Intent.ACTION_VIEW, Uri.parse("https://cookstemma.com/privacy"))
                    context.startActivity(intent)
                }
            )

            HorizontalDivider(modifier = Modifier.padding(vertical = Spacing.sm))

            // Account Actions
            SettingsItem(
                icon = Icons.AutoMirrored.Filled.ExitToApp,
                title = stringResource(R.string.log_out),
                titleColor = MaterialTheme.colorScheme.error,
                onClick = { showLogoutDialog = true }
            )
            SettingsItem(
                icon = Icons.Default.DeleteForever,
                title = stringResource(R.string.delete_account),
                titleColor = MaterialTheme.colorScheme.error,
                onClick = { showDeleteDialog = true }
            )

            // Version Info
            Spacer(modifier = Modifier.height(Spacing.lg))
            Text(
                text = stringResource(R.string.version, uiState.appVersion),
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = Spacing.md)
            )
            Spacer(modifier = Modifier.height(Spacing.xl))
        }
    }

    // Logout Confirmation Dialog
    if (showLogoutDialog) {
        AlertDialog(
            onDismissRequest = { showLogoutDialog = false },
            title = { Text(stringResource(R.string.log_out)) },
            text = { Text(stringResource(R.string.log_out_confirm)) },
            confirmButton = {
                TextButton(
                    onClick = {
                        showLogoutDialog = false
                        viewModel.logout()
                    },
                    enabled = !uiState.isLoggingOut
                ) {
                    if (uiState.isLoggingOut) {
                        CircularProgressIndicator(modifier = Modifier.size(16.dp), strokeWidth = 2.dp)
                    } else {
                        Text(stringResource(R.string.log_out), color = MaterialTheme.colorScheme.error)
                    }
                }
            },
            dismissButton = {
                TextButton(onClick = { showLogoutDialog = false }) {
                    Text(stringResource(R.string.cancel))
                }
            }
        )
    }

    // Delete Account Confirmation Dialog
    if (showDeleteDialog) {
        AlertDialog(
            onDismissRequest = { showDeleteDialog = false },
            title = { Text(stringResource(R.string.delete_account)) },
            text = { Text(stringResource(R.string.delete_account_confirm)) },
            confirmButton = {
                TextButton(
                    onClick = {
                        showDeleteDialog = false
                        viewModel.deleteAccount()
                    },
                    enabled = !uiState.isDeletingAccount
                ) {
                    if (uiState.isDeletingAccount) {
                        CircularProgressIndicator(modifier = Modifier.size(16.dp), strokeWidth = 2.dp)
                    } else {
                        Text(stringResource(R.string.delete), color = MaterialTheme.colorScheme.error)
                    }
                }
            },
            dismissButton = {
                TextButton(onClick = { showDeleteDialog = false }) {
                    Text(stringResource(R.string.cancel))
                }
            }
        )
    }

    // Theme Selection Dialog
    if (showThemeDialog) {
        AlertDialog(
            onDismissRequest = { showThemeDialog = false },
            title = { Text(stringResource(R.string.choose_theme)) },
            text = {
                Column {
                    AppTheme.entries.forEach { theme ->
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .clickable {
                                    viewModel.setTheme(theme)
                                    showThemeDialog = false
                                }
                                .padding(vertical = Spacing.sm),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            RadioButton(
                                selected = uiState.appTheme == theme,
                                onClick = {
                                    viewModel.setTheme(theme)
                                    showThemeDialog = false
                                }
                            )
                            Spacer(modifier = Modifier.width(Spacing.sm))
                            Text(theme.displayName)
                        }
                    }
                }
            },
            confirmButton = { }
        )
    }

    // Language Selection Dialog
    if (showLanguageDialog) {
        AlertDialog(
            onDismissRequest = { showLanguageDialog = false },
            title = { Text(stringResource(R.string.choose_language)) },
            text = {
                Column {
                    viewModel.getAllLanguages().forEach { language ->
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .clickable {
                                    if (language != uiState.currentLanguage) {
                                        pendingLanguage = language
                                        showLanguageDialog = false
                                        showRestartConfirmDialog = true
                                    } else {
                                        showLanguageDialog = false
                                    }
                                }
                                .padding(vertical = Spacing.sm),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            RadioButton(
                                selected = uiState.currentLanguage == language,
                                onClick = {
                                    if (language != uiState.currentLanguage) {
                                        pendingLanguage = language
                                        showLanguageDialog = false
                                        showRestartConfirmDialog = true
                                    } else {
                                        showLanguageDialog = false
                                    }
                                }
                            )
                            Spacer(modifier = Modifier.width(Spacing.sm))
                            Text(language.displayName)
                        }
                    }
                }
            },
            confirmButton = { }
        )
    }

    // Language Change Confirmation Dialog
    if (showRestartConfirmDialog && pendingLanguage != null) {
        AlertDialog(
            onDismissRequest = {
                showRestartConfirmDialog = false
                pendingLanguage = null
            },
            title = { Text(stringResource(R.string.change_language)) },
            text = { Text(stringResource(R.string.restart_confirm)) },
            confirmButton = {
                TextButton(
                    onClick = {
                        pendingLanguage?.let { language ->
                            showRestartConfirmDialog = false
                            pendingLanguage = null
                            // Set language - this will automatically trigger activity recreation
                            viewModel.setLanguage(language)
                        }
                    }
                ) {
                    Text(stringResource(R.string.restart))
                }
            },
            dismissButton = {
                TextButton(
                    onClick = {
                        showRestartConfirmDialog = false
                        pendingLanguage = null
                    }
                ) {
                    Text(stringResource(R.string.cancel))
                }
            }
        )
    }

    // Error Snackbar
    uiState.error?.let { error ->
        LaunchedEffect(error) {
            // Show error - could use SnackbarHost
            viewModel.clearError()
        }
    }
}

@Composable
private fun SettingsSectionHeader(title: String) {
    Text(
        text = title,
        style = MaterialTheme.typography.titleSmall,
        color = MaterialTheme.colorScheme.primary,
        modifier = Modifier.padding(horizontal = Spacing.md, vertical = Spacing.sm)
    )
}

@Composable
private fun SettingsItem(
    icon: ImageVector,
    title: String,
    subtitle: String? = null,
    titleColor: androidx.compose.ui.graphics.Color = MaterialTheme.colorScheme.onSurface,
    onClick: () -> Unit
) {
    Surface(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(onClick = onClick),
        color = MaterialTheme.colorScheme.surface
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = Spacing.md, vertical = Spacing.md),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Icon(
                imageVector = icon,
                contentDescription = null,
                tint = if (titleColor == MaterialTheme.colorScheme.error)
                    MaterialTheme.colorScheme.error
                else
                    MaterialTheme.colorScheme.onSurfaceVariant,
                modifier = Modifier.size(24.dp)
            )
            Spacer(modifier = Modifier.width(Spacing.md))
            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = title,
                    style = MaterialTheme.typography.bodyLarge,
                    color = titleColor
                )
                subtitle?.let {
                    Text(
                        text = it,
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
            }
            Icon(
                imageVector = Icons.Default.ChevronRight,
                contentDescription = null,
                tint = MaterialTheme.colorScheme.onSurfaceVariant,
                modifier = Modifier.size(20.dp)
            )
        }
    }
}
