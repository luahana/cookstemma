package com.cookstemma.app.ui.screens.create

import android.content.Context
import android.net.Uri
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import coil.compose.AsyncImage
import com.cookstemma.app.domain.model.RecipeSummary
import com.cookstemma.app.ui.components.AppIcons
import com.cookstemma.app.ui.components.StarRating
import com.cookstemma.app.ui.theme.Spacing
import java.io.File
import java.io.FileOutputStream

@OptIn(ExperimentalMaterial3Api::class, ExperimentalLayoutApi::class)
@Composable
fun CreateLogScreen(
    onDismiss: () -> Unit,
    onSuccess: () -> Unit,
    onNavigateToRecipeSearch: () -> Unit = {},
    viewModel: CreateLogViewModel = hiltViewModel()
) {
    val context = LocalContext.current
    val uiState by viewModel.uiState.collectAsState()
    var hashtagInput by remember { mutableStateOf("") }

    val photoPickerLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.GetMultipleContents()
    ) { uris ->
        uris.take(uiState.photosRemaining).forEach { uri ->
            viewModel.addPhoto(uri)
        }
    }

    LaunchedEffect(uiState.isSubmitSuccess) {
        if (uiState.isSubmitSuccess) {
            onSuccess()
        }
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(MaterialTheme.colorScheme.background)
    ) {
        // Custom Header (iOS-style)
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = Spacing.md)
                .padding(top = Spacing.lg, bottom = Spacing.sm),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            // Close button
            IconButton(
                onClick = onDismiss,
                modifier = Modifier.size(44.dp)
            ) {
                Icon(
                    imageVector = AppIcons.close,
                    contentDescription = "Close",
                    tint = MaterialTheme.colorScheme.onSurface
                )
            }

            // Title
            Text(
                text = "New Cooking Log",
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.SemiBold,
                color = MaterialTheme.colorScheme.onSurface
            )

            // Submit button
            IconButton(
                onClick = {
                    val photoFiles = uiState.photos.mapNotNull { uri ->
                        uriToFile(context, uri)
                    }
                    if (photoFiles.isNotEmpty()) {
                        viewModel.submit(photoFiles)
                    }
                },
                enabled = uiState.canSubmit && !uiState.isSubmitting,
                modifier = Modifier.size(44.dp)
            ) {
                if (uiState.isSubmitting) {
                    CircularProgressIndicator(
                        modifier = Modifier.size(24.dp),
                        strokeWidth = 2.dp
                    )
                } else {
                    Icon(
                        imageVector = Icons.Filled.ArrowCircleUp,
                        contentDescription = "Submit",
                        tint = if (uiState.canSubmit)
                            MaterialTheme.colorScheme.primary
                        else
                            MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.5f),
                        modifier = Modifier.size(28.dp)
                    )
                }
            }
        }

        // Content
        Column(
            modifier = Modifier
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
        ) {
            // Recipe Link Section (at top like iOS)
            RecipeLinkSection(
                linkedRecipe = uiState.linkedRecipe,
                onNavigateToSearch = onNavigateToRecipeSearch,
                onClearRecipe = viewModel::clearLinkedRecipe
            )

            HorizontalDivider()

            // Photo Section (3 fixed slots like iOS)
            PhotoSection(
                photos = uiState.photos,
                maxPhotos = 3,
                onAddPhoto = { photoPickerLauncher.launch("image/*") },
                onRemovePhoto = viewModel::removePhoto
            )

            HorizontalDivider()

            // Rating Section
            RatingSection(
                rating = uiState.rating,
                onRatingChange = viewModel::setRating
            )

            HorizontalDivider()

            // Description Section
            DescriptionSection(
                content = uiState.content,
                maxLength = 2000,
                onContentChange = viewModel::setContent
            )

            HorizontalDivider()

            // Hashtags Section
            HashtagsSection(
                hashtags = uiState.hashtags,
                maxHashtags = 10,
                hashtagInput = hashtagInput,
                onHashtagInputChange = { hashtagInput = it },
                onAddHashtag = {
                    viewModel.addHashtag(hashtagInput)
                    hashtagInput = ""
                },
                onRemoveHashtag = viewModel::removeHashtag
            )

            HorizontalDivider()

            // Privacy Section
            PrivacySection(
                isPrivate = uiState.isPrivate,
                onPrivateChange = viewModel::setPrivate
            )
        }
    }

    // Error Snackbar
    uiState.error?.let { error ->
        Snackbar(
            modifier = Modifier.padding(Spacing.md),
            action = {
                TextButton(onClick = viewModel::clearError) {
                    Text("Dismiss")
                }
            }
        ) {
            Text(error)
        }
    }
}

// MARK: - Recipe Link Section
@Composable
private fun RecipeLinkSection(
    linkedRecipe: RecipeSummary?,
    onNavigateToSearch: () -> Unit,
    onClearRecipe: () -> Unit
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(onClick = onNavigateToSearch)
            .padding(horizontal = Spacing.md, vertical = Spacing.md),
        horizontalArrangement = Arrangement.spacedBy(Spacing.sm),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Icon(
            imageVector = AppIcons.recipe,
            contentDescription = null,
            tint = MaterialTheme.colorScheme.primary,
            modifier = Modifier.size(24.dp)
        )

        if (linkedRecipe != null) {
            // Show selected recipe
            linkedRecipe.coverImageUrl?.let { url ->
                AsyncImage(
                    model = url,
                    contentDescription = null,
                    modifier = Modifier
                        .size(40.dp)
                        .clip(RoundedCornerShape(Spacing.xs)),
                    contentScale = ContentScale.Crop
                )
            }

            Text(
                text = linkedRecipe.title,
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurface,
                modifier = Modifier.weight(1f),
                maxLines = 1
            )

            // Clear button
            Box(
                modifier = Modifier
                    .size(24.dp)
                    .background(
                        MaterialTheme.colorScheme.surfaceVariant,
                        CircleShape
                    )
                    .clickable(onClick = onClearRecipe),
                contentAlignment = Alignment.Center
            ) {
                Icon(
                    imageVector = AppIcons.close,
                    contentDescription = "Clear",
                    tint = MaterialTheme.colorScheme.onSurfaceVariant,
                    modifier = Modifier.size(12.dp)
                )
            }
        } else {
            // Show placeholder
            Text(
                text = "Link a Recipe",
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )

            Spacer(modifier = Modifier.weight(1f))

            Icon(
                imageVector = AppIcons.forward,
                contentDescription = null,
                tint = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.5f),
                modifier = Modifier.size(20.dp)
            )
        }
    }
}

// MARK: - Photo Section (3 Fixed Slots like iOS)
@Composable
private fun PhotoSection(
    photos: List<Uri>,
    maxPhotos: Int,
    onAddPhoto: () -> Unit,
    onRemovePhoto: (Uri) -> Unit
) {
    val slotSize = 100.dp

    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = Spacing.md, vertical = Spacing.lg),
        horizontalArrangement = Arrangement.spacedBy(Spacing.sm)
    ) {
        repeat(maxPhotos) { index ->
            if (index < photos.size) {
                // Filled slot
                Box(
                    modifier = Modifier
                        .size(slotSize)
                        .clip(RoundedCornerShape(Spacing.sm))
                ) {
                    AsyncImage(
                        model = photos[index],
                        contentDescription = null,
                        modifier = Modifier.fillMaxSize(),
                        contentScale = ContentScale.Crop
                    )

                    // Remove button (top right)
                    Box(
                        modifier = Modifier
                            .align(Alignment.TopEnd)
                            .offset(x = (-4).dp, y = 4.dp)
                            .size(20.dp)
                            .background(Color.Black.copy(alpha = 0.6f), CircleShape)
                            .clickable { onRemovePhoto(photos[index]) },
                        contentAlignment = Alignment.Center
                    ) {
                        Icon(
                            imageVector = AppIcons.close,
                            contentDescription = "Remove",
                            tint = Color.White,
                            modifier = Modifier.size(10.dp)
                        )
                    }
                }
            } else {
                // Empty slot
                Box(
                    modifier = Modifier
                        .size(slotSize)
                        .clip(RoundedCornerShape(Spacing.sm))
                        .background(MaterialTheme.colorScheme.surfaceVariant)
                        .clickable(onClick = onAddPhoto),
                    contentAlignment = Alignment.Center
                ) {
                    Column(
                        horizontalAlignment = Alignment.CenterHorizontally,
                        verticalArrangement = Arrangement.spacedBy(Spacing.xs)
                    ) {
                        Icon(
                            imageVector = AppIcons.camera,
                            contentDescription = null,
                            tint = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.5f),
                            modifier = Modifier.size(24.dp)
                        )
                        Text(
                            text = "Tap to add",
                            style = MaterialTheme.typography.labelSmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.5f)
                        )
                    }
                }
            }
        }
    }
}

// MARK: - Rating Section
@Composable
private fun RatingSection(
    rating: Int,
    onRatingChange: (Int) -> Unit
) {
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = Spacing.md, vertical = Spacing.lg),
        contentAlignment = Alignment.Center
    ) {
        StarRating(
            rating = rating,
            onRatingChange = onRatingChange,
            size = 36.dp,
            interactive = true
        )
    }
}

// MARK: - Description Section
@Composable
private fun DescriptionSection(
    content: String,
    maxLength: Int,
    onContentChange: (String) -> Unit
) {
    val remaining = maxLength - content.length

    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = Spacing.md, vertical = Spacing.md)
    ) {
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .heightIn(min = 100.dp)
        ) {
            if (content.isEmpty()) {
                Text(
                    text = "Share your cooking experience...",
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.5f),
                    modifier = Modifier.padding(top = 8.dp, start = 4.dp)
                )
            }

            BasicTextField(
                value = content,
                onValueChange = { newValue ->
                    if (newValue.length <= maxLength) {
                        onContentChange(newValue)
                    }
                },
                modifier = Modifier
                    .fillMaxWidth()
                    .heightIn(min = 100.dp),
                textStyle = MaterialTheme.typography.bodyMedium.copy(
                    color = MaterialTheme.colorScheme.onSurface
                )
            )
        }

        // Character count
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.End
        ) {
            Text(
                text = "${content.length}/$maxLength",
                style = MaterialTheme.typography.labelSmall,
                color = if (remaining < 100)
                    MaterialTheme.colorScheme.error
                else
                    MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.5f)
            )
        }
    }
}

// MARK: - Hashtags Section
@OptIn(ExperimentalLayoutApi::class)
@Composable
private fun HashtagsSection(
    hashtags: List<String>,
    maxHashtags: Int,
    hashtagInput: String,
    onHashtagInputChange: (String) -> Unit,
    onAddHashtag: () -> Unit,
    onRemoveHashtag: (Int) -> Unit
) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = Spacing.md, vertical = Spacing.md),
        verticalArrangement = Arrangement.spacedBy(Spacing.sm)
    ) {
        // Input row
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(Spacing.sm),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Icon(
                imageVector = Icons.Filled.Tag,
                contentDescription = null,
                tint = MaterialTheme.colorScheme.primary,
                modifier = Modifier.size(24.dp)
            )

            BasicTextField(
                value = hashtagInput,
                onValueChange = onHashtagInputChange,
                modifier = Modifier.weight(1f),
                textStyle = MaterialTheme.typography.bodyMedium.copy(
                    color = MaterialTheme.colorScheme.onSurface
                ),
                singleLine = true,
                decorationBox = { innerTextField ->
                    Box {
                        if (hashtagInput.isEmpty()) {
                            Text(
                                text = "Add hashtag",
                                style = MaterialTheme.typography.bodyMedium,
                                color = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.5f)
                            )
                        }
                        innerTextField()
                    }
                }
            )

            if (hashtags.size < maxHashtags) {
                IconButton(
                    onClick = onAddHashtag,
                    enabled = hashtagInput.isNotEmpty(),
                    modifier = Modifier.size(32.dp)
                ) {
                    Icon(
                        imageVector = Icons.Filled.AddCircle,
                        contentDescription = "Add",
                        tint = if (hashtagInput.isEmpty())
                            MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.5f)
                        else
                            MaterialTheme.colorScheme.primary,
                        modifier = Modifier.size(24.dp)
                    )
                }
            }

            Text(
                text = "${hashtags.size}/$maxHashtags",
                style = MaterialTheme.typography.labelSmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.5f)
            )
        }

        // Hashtag chips
        if (hashtags.isNotEmpty()) {
            FlowRow(
                horizontalArrangement = Arrangement.spacedBy(Spacing.xs),
                verticalArrangement = Arrangement.spacedBy(Spacing.xs)
            ) {
                hashtags.forEachIndexed { index, tag ->
                    Surface(
                        shape = RoundedCornerShape(50),
                        color = MaterialTheme.colorScheme.primary.copy(alpha = 0.1f)
                    ) {
                        Row(
                            modifier = Modifier.padding(
                                horizontal = Spacing.sm,
                                vertical = Spacing.xs
                            ),
                            horizontalArrangement = Arrangement.spacedBy(Spacing.xxs),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Text(
                                text = "#$tag",
                                style = MaterialTheme.typography.labelMedium,
                                color = MaterialTheme.colorScheme.primary
                            )
                            Icon(
                                imageVector = AppIcons.close,
                                contentDescription = "Remove",
                                tint = MaterialTheme.colorScheme.onSurfaceVariant,
                                modifier = Modifier
                                    .size(14.dp)
                                    .clickable { onRemoveHashtag(index) }
                            )
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Privacy Section
@Composable
private fun PrivacySection(
    isPrivate: Boolean,
    onPrivateChange: (Boolean) -> Unit
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = Spacing.md, vertical = Spacing.md),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        Row(
            horizontalArrangement = Arrangement.spacedBy(Spacing.sm),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Icon(
                imageVector = if (isPrivate) Icons.Filled.Lock else Icons.Filled.LockOpen,
                contentDescription = null,
                tint = MaterialTheme.colorScheme.primary,
                modifier = Modifier.size(24.dp)
            )
            Text(
                text = if (isPrivate) "Private" else "Public",
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurface
            )
        }

        Switch(
            checked = isPrivate,
            onCheckedChange = onPrivateChange
        )
    }
}

// MARK: - Helper Functions
private fun uriToFile(context: Context, uri: Uri): File? {
    return try {
        val inputStream = context.contentResolver.openInputStream(uri) ?: return null
        val fileName = "photo_${System.currentTimeMillis()}.jpg"
        val file = File(context.cacheDir, fileName)
        FileOutputStream(file).use { outputStream ->
            inputStream.copyTo(outputStream)
        }
        inputStream.close()
        file
    } catch (e: Exception) {
        null
    }
}
