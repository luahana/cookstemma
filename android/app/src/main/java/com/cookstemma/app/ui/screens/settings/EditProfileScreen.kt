package com.cookstemma.app.ui.screens.settings

import android.net.Uri
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import coil.compose.AsyncImage
import com.cookstemma.app.ui.theme.Spacing

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun EditProfileScreen(
    onNavigateBack: () -> Unit,
    onSaveSuccess: () -> Unit,
    viewModel: EditProfileViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()

    val imagePickerLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.GetContent()
    ) { uri: Uri? ->
        uri?.let { viewModel.setNewAvatar(it) }
    }

    LaunchedEffect(uiState.saveSuccess) {
        if (uiState.saveSuccess) {
            onSaveSuccess()
        }
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Edit Profile") },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Back")
                    }
                },
                actions = {
                    if (uiState.isSaving) {
                        CircularProgressIndicator(
                            modifier = Modifier
                                .padding(end = Spacing.md)
                                .size(24.dp),
                            strokeWidth = 2.dp
                        )
                    } else {
                        TextButton(
                            onClick = { viewModel.saveProfile() },
                            enabled = uiState.canSave
                        ) {
                            Text("Save")
                        }
                    }
                }
            )
        }
    ) { padding ->
        if (uiState.isLoading) {
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(padding),
                contentAlignment = Alignment.Center
            ) {
                CircularProgressIndicator()
            }
        } else {
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(padding)
                    .verticalScroll(rememberScrollState())
                    .padding(Spacing.md)
            ) {
                // Profile Photo Section
                ProfilePhotoSection(
                    currentAvatarUrl = uiState.avatarUrl,
                    newAvatarUri = uiState.newAvatarUri,
                    onChangePhoto = { imagePickerLauncher.launch("image/*") }
                )

                Spacer(modifier = Modifier.height(Spacing.lg))

                // Username Field
                UsernameField(
                    username = uiState.username,
                    onUsernameChange = viewModel::setUsername,
                    isChecking = uiState.isCheckingUsername,
                    isAvailable = uiState.usernameAvailable,
                    formatError = uiState.usernameFormatError,
                    canCheck = uiState.canCheckUsername,
                    onCheckAvailability = viewModel::checkUsernameAvailability
                )

                Spacer(modifier = Modifier.height(Spacing.md))

                // Bio Field
                OutlinedTextField(
                    value = uiState.bio,
                    onValueChange = viewModel::setBio,
                    label = { Text("Bio") },
                    placeholder = { Text("Tell us about yourself") },
                    modifier = Modifier.fillMaxWidth(),
                    minLines = 2,
                    maxLines = 4,
                    supportingText = {
                        Text("${uiState.bio.length}/${EditProfileUiState.MAX_BIO_LENGTH}")
                    }
                )

                Spacer(modifier = Modifier.height(Spacing.lg))

                // Social Links Section
                Text(
                    text = "Social Links",
                    style = MaterialTheme.typography.titleMedium,
                    color = MaterialTheme.colorScheme.primary
                )

                Spacer(modifier = Modifier.height(Spacing.sm))

                OutlinedTextField(
                    value = uiState.youtubeUrl,
                    onValueChange = viewModel::setYoutubeUrl,
                    label = { Text("YouTube") },
                    placeholder = { Text("https://youtube.com/@channel") },
                    leadingIcon = {
                        Icon(Icons.Default.PlayCircle, contentDescription = null)
                    },
                    modifier = Modifier.fillMaxWidth(),
                    singleLine = true
                )

                Spacer(modifier = Modifier.height(Spacing.sm))

                OutlinedTextField(
                    value = uiState.instagramHandle,
                    onValueChange = viewModel::setInstagramHandle,
                    label = { Text("Instagram") },
                    placeholder = { Text("username") },
                    prefix = { Text("@") },
                    leadingIcon = {
                        Icon(Icons.Default.CameraAlt, contentDescription = null)
                    },
                    modifier = Modifier.fillMaxWidth(),
                    singleLine = true
                )

                Spacer(modifier = Modifier.height(Spacing.xl))
            }
        }
    }

    // Error Snackbar
    uiState.error?.let { error ->
        LaunchedEffect(error) {
            viewModel.clearError()
        }
    }
}

@Composable
private fun ProfilePhotoSection(
    currentAvatarUrl: String?,
    newAvatarUri: Uri?,
    onChangePhoto: () -> Unit
) {
    Column(
        modifier = Modifier.fillMaxWidth(),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Box(
            modifier = Modifier
                .size(100.dp)
                .clip(CircleShape)
                .background(MaterialTheme.colorScheme.surfaceVariant)
                .clickable(onClick = onChangePhoto),
            contentAlignment = Alignment.Center
        ) {
            when {
                newAvatarUri != null -> {
                    AsyncImage(
                        model = newAvatarUri,
                        contentDescription = "New profile photo",
                        modifier = Modifier.fillMaxSize(),
                        contentScale = ContentScale.Crop
                    )
                }
                currentAvatarUrl != null -> {
                    AsyncImage(
                        model = currentAvatarUrl,
                        contentDescription = "Profile photo",
                        modifier = Modifier.fillMaxSize(),
                        contentScale = ContentScale.Crop
                    )
                }
                else -> {
                    Icon(
                        imageVector = Icons.Default.Person,
                        contentDescription = null,
                        modifier = Modifier.size(48.dp),
                        tint = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
            }

            // Camera overlay
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .background(Color.Black.copy(alpha = 0.3f)),
                contentAlignment = Alignment.Center
            ) {
                Icon(
                    imageVector = Icons.Default.CameraAlt,
                    contentDescription = "Change photo",
                    tint = Color.White,
                    modifier = Modifier.size(32.dp)
                )
            }
        }

        Spacer(modifier = Modifier.height(Spacing.sm))

        TextButton(onClick = onChangePhoto) {
            Text("Change Photo")
        }
    }
}

@Composable
private fun UsernameField(
    username: String,
    onUsernameChange: (String) -> Unit,
    isChecking: Boolean,
    isAvailable: Boolean?,
    formatError: String?,
    canCheck: Boolean,
    onCheckAvailability: () -> Unit
) {
    Column {
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(Spacing.sm),
            verticalAlignment = Alignment.Top
        ) {
            OutlinedTextField(
                value = username,
                onValueChange = onUsernameChange,
                label = { Text("Username") },
                prefix = { Text("@") },
                modifier = Modifier.weight(1f),
                singleLine = true,
                isError = formatError != null || isAvailable == false,
                supportingText = {
                    when {
                        formatError != null -> {
                            Text(formatError, color = MaterialTheme.colorScheme.error)
                        }
                        isAvailable == true -> {
                            Row(verticalAlignment = Alignment.CenterVertically) {
                                Icon(
                                    Icons.Default.CheckCircle,
                                    contentDescription = null,
                                    tint = Color(0xFF4CAF50),
                                    modifier = Modifier.size(16.dp)
                                )
                                Spacer(modifier = Modifier.width(4.dp))
                                Text("Available", color = Color(0xFF4CAF50))
                            }
                        }
                        isAvailable == false -> {
                            Row(verticalAlignment = Alignment.CenterVertically) {
                                Icon(
                                    Icons.Default.Cancel,
                                    contentDescription = null,
                                    tint = MaterialTheme.colorScheme.error,
                                    modifier = Modifier.size(16.dp)
                                )
                                Spacer(modifier = Modifier.width(4.dp))
                                Text("Already taken", color = MaterialTheme.colorScheme.error)
                            }
                        }
                    }
                }
            )

            Button(
                onClick = onCheckAvailability,
                enabled = canCheck,
                modifier = Modifier.padding(top = Spacing.sm)
            ) {
                if (isChecking) {
                    CircularProgressIndicator(
                        modifier = Modifier.size(16.dp),
                        strokeWidth = 2.dp,
                        color = MaterialTheme.colorScheme.onPrimary
                    )
                } else {
                    Text("Check")
                }
            }
        }

        Text(
            text = "Only lowercase letters, numbers, and underscores. 3-30 characters.",
            style = MaterialTheme.typography.bodySmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            modifier = Modifier.padding(start = Spacing.md, top = Spacing.xxs)
        )
    }
}
