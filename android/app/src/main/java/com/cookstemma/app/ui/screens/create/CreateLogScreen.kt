package com.cookstemma.app.ui.screens.create

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.net.Uri
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.animation.core.animateDpAsState
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.gestures.detectDragGesturesAfterLongPress
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
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.IntOffset
import androidx.compose.ui.unit.dp
import androidx.compose.ui.zIndex
import androidx.core.content.ContextCompat
import androidx.core.content.FileProvider
import androidx.hilt.navigation.compose.hiltViewModel
import com.cookstemma.app.R
import coil.compose.AsyncImage
import coil.compose.AsyncImagePainter
import com.cookstemma.app.domain.model.RecipeSummary
import com.cookstemma.app.ui.components.AppIcons
import com.cookstemma.app.ui.components.StarRating
import com.cookstemma.app.ui.theme.Spacing
import java.io.File
import java.io.FileOutputStream
import kotlin.math.roundToInt

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
    var showRecipeSearchSheet by remember { mutableStateOf(false) }
    var showPhotoPickerDialog by remember { mutableStateOf(false) }
    var tempCameraUri by remember { mutableStateOf<Uri?>(null) }

    // Gallery picker launcher
    val photoPickerLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.GetMultipleContents()
    ) { uris ->
        uris.take(uiState.photosRemaining).forEach { uri ->
            viewModel.addPhoto(uri)
        }
    }

    // Camera launcher
    val cameraLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.TakePicture()
    ) { success ->
        if (success && tempCameraUri != null) {
            viewModel.addPhoto(tempCameraUri!!)
        }
    }

    // Camera permission launcher
    val cameraPermissionLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.RequestPermission()
    ) { isGranted ->
        if (isGranted) {
            // Permission granted, launch camera
            tempCameraUri = createTempImageUri(context)
            tempCameraUri?.let { cameraLauncher.launch(it) }
        }
    }

    // Function to launch camera with permission check
    fun launchCamera() {
        when {
            ContextCompat.checkSelfPermission(
                context,
                Manifest.permission.CAMERA
            ) == PackageManager.PERMISSION_GRANTED -> {
                tempCameraUri = createTempImageUri(context)
                tempCameraUri?.let { cameraLauncher.launch(it) }
            }
            else -> {
                cameraPermissionLauncher.launch(Manifest.permission.CAMERA)
            }
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
                    contentDescription = stringResource(R.string.cd_close),
                    tint = MaterialTheme.colorScheme.onSurface
                )
            }

            // Title
            Text(
                text = stringResource(R.string.new_cooking_log),
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.SemiBold,
                color = MaterialTheme.colorScheme.onSurface
            )

            // Submit button
            IconButton(
                onClick = {
                    val photoFiles = uiState.photos.mapNotNull { photoItem ->
                        uriToFile(context, photoItem.uri)
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
                        contentDescription = stringResource(R.string.cd_submit),
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
                onNavigateToSearch = { showRecipeSearchSheet = true },
                onClearRecipe = viewModel::clearLinkedRecipe
            )

            HorizontalDivider()

            // Photo Section (3 fixed slots like iOS) with drag and drop
            PhotoSection(
                photos = uiState.photos,
                maxPhotos = 3,
                onAddPhoto = { showPhotoPickerDialog = true },
                onRemovePhoto = { viewModel.removePhoto(it) },
                onReorderPhotos = viewModel::reorderPhotos,
                onRetryPhoto = viewModel::retryPhoto
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
                    Text(stringResource(R.string.dismiss))
                }
            }
        ) {
            Text(error)
        }
    }

    // Recipe Search Bottom Sheet
    if (showRecipeSearchSheet) {
        RecipeSearchBottomSheet(
            onDismiss = { showRecipeSearchSheet = false },
            onSelect = { recipe ->
                viewModel.selectRecipe(recipe)
                showRecipeSearchSheet = false
            },
            searchQuery = uiState.recipeSearchQuery,
            onSearchQueryChange = viewModel::setRecipeSearchQuery,
            searchResults = uiState.recipeSearchResults,
            isSearching = uiState.isSearchingRecipes
        )
    }

    // Photo Picker Dialog (Camera or Gallery)
    if (showPhotoPickerDialog) {
        PhotoPickerDialog(
            onDismiss = { showPhotoPickerDialog = false },
            onCameraClick = {
                showPhotoPickerDialog = false
                launchCamera()
            },
            onGalleryClick = {
                showPhotoPickerDialog = false
                photoPickerLauncher.launch("image/*")
            }
        )
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
                    contentDescription = stringResource(R.string.cd_remove),
                    tint = MaterialTheme.colorScheme.onSurfaceVariant,
                    modifier = Modifier.size(12.dp)
                )
            }
        } else {
            // Show placeholder
            Text(
                text = stringResource(R.string.link_a_recipe),
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

// MARK: - Photo Section (3 Fixed Slots like iOS) with drag and drop
@Composable
private fun PhotoSection(
    photos: List<PhotoItem>,
    maxPhotos: Int,
    onAddPhoto: () -> Unit,
    onRemovePhoto: (Uri) -> Unit,
    onReorderPhotos: (Int, Int) -> Unit,
    onRetryPhoto: (Uri) -> Unit
) {
    val slotSize = 100.dp
    val slotSizePx = with(LocalDensity.current) { slotSize.toPx() }
    val spacingPx = with(LocalDensity.current) { Spacing.sm.toPx() }

    var draggedIndex by remember { mutableStateOf<Int?>(null) }
    var dragOffset by remember { mutableStateOf(0f) }

    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = Spacing.md, vertical = Spacing.lg),
        horizontalArrangement = Arrangement.spacedBy(Spacing.sm)
    ) {
        repeat(maxPhotos) { index ->
            val isDragging = draggedIndex == index
            val elevation by animateDpAsState(if (isDragging) 8.dp else 0.dp, label = "elevation")

            if (index < photos.size) {
                val photoItem = photos[index]
                // Filled slot with drag support
                Box(
                    modifier = Modifier
                        .size(slotSize)
                        .zIndex(if (isDragging) 1f else 0f)
                        .offset {
                            if (isDragging) IntOffset(dragOffset.roundToInt(), 0)
                            else IntOffset.Zero
                        }
                        .shadow(elevation, RoundedCornerShape(Spacing.sm))
                        .clip(RoundedCornerShape(Spacing.sm))
                        .background(MaterialTheme.colorScheme.surfaceVariant)
                        .then(
                            if (photoItem.state == PhotoState.SUCCESS) {
                                Modifier.pointerInput(index) {
                                    detectDragGesturesAfterLongPress(
                                        onDragStart = {
                                            draggedIndex = index
                                        },
                                        onDrag = { change, dragAmount ->
                                            change.consume()
                                            dragOffset += dragAmount.x

                                            // Calculate target index based on drag position
                                            val targetIndex = (index + (dragOffset / (slotSizePx + spacingPx)).roundToInt())
                                                .coerceIn(0, photos.size - 1)

                                            if (targetIndex != index && draggedIndex == index) {
                                                onReorderPhotos(index, targetIndex)
                                                draggedIndex = targetIndex
                                                dragOffset = 0f
                                            }
                                        },
                                        onDragEnd = {
                                            draggedIndex = null
                                            dragOffset = 0f
                                        },
                                        onDragCancel = {
                                            draggedIndex = null
                                            dragOffset = 0f
                                        }
                                    )
                                }
                            } else Modifier
                        )
                ) {
                    // Photo image with loading state from Coil
                    var imageState by remember { mutableStateOf<AsyncImagePainter.State?>(null) }

                    AsyncImage(
                        model = photoItem.uri,
                        contentDescription = null,
                        modifier = Modifier.fillMaxSize(),
                        contentScale = ContentScale.Crop,
                        onState = { state -> imageState = state }
                    )

                    // Loading/Error overlay based on PhotoItem state
                    when (photoItem.state) {
                        PhotoState.LOADING -> {
                            Box(
                                modifier = Modifier
                                    .fillMaxSize()
                                    .background(Color.Black.copy(alpha = 0.5f)),
                                contentAlignment = Alignment.Center
                            ) {
                                CircularProgressIndicator(
                                    modifier = Modifier.size(24.dp),
                                    color = Color.White,
                                    strokeWidth = 2.dp
                                )
                            }
                        }
                        PhotoState.ERROR -> {
                            Box(
                                modifier = Modifier
                                    .fillMaxSize()
                                    .background(Color.Black.copy(alpha = 0.7f))
                                    .clickable { onRetryPhoto(photoItem.uri) },
                                contentAlignment = Alignment.Center
                            ) {
                                Column(
                                    horizontalAlignment = Alignment.CenterHorizontally,
                                    verticalArrangement = Arrangement.spacedBy(4.dp)
                                ) {
                                    Icon(
                                        imageVector = Icons.Filled.Error,
                                        contentDescription = null,
                                        tint = Color.Red,
                                        modifier = Modifier.size(24.dp)
                                    )
                                    Text(
                                        text = stringResource(R.string.tap_to_retry),
                                        style = MaterialTheme.typography.labelSmall,
                                        color = Color.White
                                    )
                                }
                            }
                        }
                        PhotoState.SUCCESS -> {
                            // Success indicator (small checkmark)
                            Box(
                                modifier = Modifier
                                    .align(Alignment.BottomStart)
                                    .padding(4.dp)
                                    .size(18.dp)
                                    .background(Color(0xFF4CAF50), CircleShape),
                                contentAlignment = Alignment.Center
                            ) {
                                Icon(
                                    imageVector = Icons.Filled.Check,
                                    contentDescription = null,
                                    tint = Color.White,
                                    modifier = Modifier.size(12.dp)
                                )
                            }
                        }
                    }

                    // Remove button (top right) - always visible
                    Box(
                        modifier = Modifier
                            .align(Alignment.TopEnd)
                            .offset(x = (-4).dp, y = 4.dp)
                            .size(20.dp)
                            .background(Color.Black.copy(alpha = 0.6f), CircleShape)
                            .clickable { onRemovePhoto(photoItem.uri) },
                        contentAlignment = Alignment.Center
                    ) {
                        Icon(
                            imageVector = AppIcons.close,
                            contentDescription = stringResource(R.string.cd_remove),
                            tint = Color.White,
                            modifier = Modifier.size(10.dp)
                        )
                    }

                    // Drag hint indicator for successful photos
                    if (photoItem.state == PhotoState.SUCCESS && photos.size > 1) {
                        Box(
                            modifier = Modifier
                                .align(Alignment.TopStart)
                                .padding(4.dp)
                                .size(18.dp)
                                .background(Color.Black.copy(alpha = 0.5f), CircleShape),
                            contentAlignment = Alignment.Center
                        ) {
                            Icon(
                                imageVector = Icons.Filled.DragIndicator,
                                contentDescription = "Drag to reorder",
                                tint = Color.White,
                                modifier = Modifier.size(12.dp)
                            )
                        }
                    }
                }
            } else {
                // Empty slot
                Box(
                    modifier = Modifier
                        .size(slotSize)
                        .clip(RoundedCornerShape(Spacing.sm))
                        .background(MaterialTheme.colorScheme.surfaceVariant)
                        .border(
                            width = 1.dp,
                            color = MaterialTheme.colorScheme.outline.copy(alpha = 0.3f),
                            shape = RoundedCornerShape(Spacing.sm)
                        )
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
                            text = stringResource(R.string.tap_to_add),
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
                    text = stringResource(R.string.share_cooking_experience),
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
                                text = stringResource(R.string.add_hashtag),
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
                        contentDescription = stringResource(R.string.cd_add),
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
                                contentDescription = stringResource(R.string.cd_remove),
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
                text = if (isPrivate) stringResource(R.string.private_log) else stringResource(R.string.public_log),
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

// MARK: - Photo Picker Dialog
@Composable
private fun PhotoPickerDialog(
    onDismiss: () -> Unit,
    onCameraClick: () -> Unit,
    onGalleryClick: () -> Unit
) {
    AlertDialog(
        onDismissRequest = onDismiss,
        title = {
            Text(
                text = stringResource(R.string.add_photo),
                style = MaterialTheme.typography.titleMedium
            )
        },
        text = {
            Column(
                modifier = Modifier.fillMaxWidth(),
                verticalArrangement = Arrangement.spacedBy(Spacing.xs)
            ) {
                // Camera option
                Surface(
                    modifier = Modifier
                        .fillMaxWidth()
                        .clickable(onClick = onCameraClick),
                    shape = RoundedCornerShape(Spacing.sm),
                    color = MaterialTheme.colorScheme.surfaceVariant
                ) {
                    Row(
                        modifier = Modifier.padding(Spacing.md),
                        horizontalArrangement = Arrangement.spacedBy(Spacing.md),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Icon(
                            imageVector = Icons.Filled.CameraAlt,
                            contentDescription = null,
                            tint = MaterialTheme.colorScheme.primary
                        )
                        Text(
                            text = stringResource(R.string.take_photo),
                            style = MaterialTheme.typography.bodyLarge
                        )
                    }
                }

                // Gallery option
                Surface(
                    modifier = Modifier
                        .fillMaxWidth()
                        .clickable(onClick = onGalleryClick),
                    shape = RoundedCornerShape(Spacing.sm),
                    color = MaterialTheme.colorScheme.surfaceVariant
                ) {
                    Row(
                        modifier = Modifier.padding(Spacing.md),
                        horizontalArrangement = Arrangement.spacedBy(Spacing.md),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Icon(
                            imageVector = Icons.Filled.PhotoLibrary,
                            contentDescription = null,
                            tint = MaterialTheme.colorScheme.primary
                        )
                        Text(
                            text = stringResource(R.string.choose_from_gallery),
                            style = MaterialTheme.typography.bodyLarge
                        )
                    }
                }
            }
        },
        confirmButton = {},
        dismissButton = {
            TextButton(onClick = onDismiss) {
                Text(stringResource(R.string.cancel))
            }
        }
    )
}

// MARK: - Helper Functions
private fun createTempImageUri(context: Context): Uri? {
    return try {
        val tempFile = File.createTempFile(
            "camera_photo_${System.currentTimeMillis()}",
            ".jpg",
            context.cacheDir
        )
        FileProvider.getUriForFile(
            context,
            "${context.packageName}.fileprovider",
            tempFile
        )
    } catch (e: Exception) {
        null
    }
}

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
