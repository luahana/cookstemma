@file:OptIn(ExperimentalFoundationApi::class)

package com.cookstemma.app.ui.screens.recipe

import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.pager.HorizontalPager
import androidx.compose.foundation.pager.rememberPagerState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import coil.compose.AsyncImage
import com.cookstemma.app.domain.model.MeasurementPreference
import com.cookstemma.app.domain.model.RecipeDetail
import com.cookstemma.app.domain.model.cookingTimeDisplayText
import com.cookstemma.app.ui.AppState
import com.cookstemma.app.ui.components.*
import com.cookstemma.app.ui.navigation.BackIconButton
import com.cookstemma.app.ui.navigation.MoreOptionsIconButton
import com.cookstemma.app.ui.theme.Spacing

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun RecipeDetailScreen(
    onNavigateBack: () -> Unit,
    onNavigateToLog: (String) -> Unit,
    onNavigateToProfile: (String) -> Unit,
    onCreateLog: (String) -> Unit,
    viewModel: RecipeDetailViewModel = hiltViewModel(),
    appState: AppState? = null,
    isAuthenticated: Boolean = false
) {
    val uiState by viewModel.uiState.collectAsState()

    Scaffold(
        topBar = {
            TopAppBar(
                title = { },
                navigationIcon = {
                    BackIconButton(onClick = onNavigateBack)
                },
                actions = {
                    // Save button (icon only) - requires auth
                    IconButton(onClick = {
                        if (appState != null) {
                            appState.requireAuth(isAuthenticated) {
                                viewModel.toggleSave()
                            }
                        } else {
                            viewModel.toggleSave()
                        }
                    }) {
                        Icon(
                            imageVector = if (uiState.recipe?.isSaved == true)
                                AppIcons.save else AppIcons.saveOutline,
                            contentDescription = null,
                            tint = if (uiState.recipe?.isSaved == true)
                                MaterialTheme.colorScheme.primary
                            else
                                MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                    // Share button (icon only)
                    IconButton(onClick = { /* Share */ }) {
                        Icon(
                            imageVector = AppIcons.share,
                            contentDescription = null,
                            tint = MaterialTheme.colorScheme.onSurface
                        )
                    }
                    // More options (icon only)
                    MoreOptionsIconButton(onClick = { /* More options */ })
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = MaterialTheme.colorScheme.surface
                )
            )
        },
        bottomBar = {
            uiState.recipe?.let { recipe ->
                // Start cooking button (icon prominent) - requires auth
                Surface(
                    modifier = Modifier.fillMaxWidth(),
                    shadowElevation = 8.dp,
                    color = MaterialTheme.colorScheme.surface
                ) {
                    Button(
                        onClick = {
                            if (appState != null) {
                                appState.requireAuth(isAuthenticated) {
                                    onCreateLog(recipe.id)
                                }
                            } else {
                                onCreateLog(recipe.id)
                            }
                        },
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(Spacing.md),
                        colors = ButtonDefaults.buttonColors(
                            containerColor = MaterialTheme.colorScheme.primary
                        )
                    ) {
                        Icon(
                            imageVector = AppIcons.chef,
                            contentDescription = null,
                            modifier = Modifier.size(24.dp)
                        )
                    }
                }
            }
        },
        containerColor = MaterialTheme.colorScheme.surfaceVariant
    ) { padding ->
        when {
            uiState.isLoading -> {
                Box(
                    modifier = Modifier
                        .fillMaxSize()
                        .padding(padding),
                    contentAlignment = Alignment.Center
                ) {
                    CircularProgressIndicator()
                }
            }
            uiState.error != null -> {
                IconEmptyState(
                    icon = AppIcons.error,
                    subtitle = uiState.error,
                    modifier = Modifier
                        .fillMaxSize()
                        .padding(padding)
                )
            }
            uiState.recipe != null -> {
                LazyColumn(
                    modifier = Modifier
                        .fillMaxSize()
                        .padding(padding)
                ) {
                    item {
                        RecipeHeader(
                            recipe = uiState.recipe!!,
                            onAuthorClick = { onNavigateToProfile(uiState.recipe!!.author.id) }
                        )
                    }

                    item {
                        RecipeDescription(recipe = uiState.recipe!!)
                    }

                    item {
                        IngredientsSection(
                            recipe = uiState.recipe!!,
                            measurementPreference = uiState.measurementPreference
                        )
                    }

                    item {
                        StepsSection(recipe = uiState.recipe!!)
                    }

                    item {
                        CookingLogsSection(
                            logs = uiState.cookingLogs,
                            totalCount = uiState.recipe!!.cookCount,
                            onLogClick = onNavigateToLog,
                            onCreateLogClick = { onCreateLog(uiState.recipe!!.id) }
                        )
                    }

                    // Hashtags
                    uiState.recipe?.hashtags?.let { hashtags ->
                        if (hashtags.isNotEmpty()) {
                            item {
                                LazyRow(
                                    modifier = Modifier.padding(Spacing.md),
                                    horizontalArrangement = Arrangement.spacedBy(Spacing.xs)
                                ) {
                                    items(hashtags) { tag ->
                                        Surface(
                                            shape = RoundedCornerShape(Spacing.xs),
                                            color = MaterialTheme.colorScheme.surfaceVariant
                                        ) {
                                            Text(
                                                text = "#$tag",
                                                style = MaterialTheme.typography.labelSmall,
                                                modifier = Modifier.padding(
                                                    horizontal = Spacing.sm,
                                                    vertical = Spacing.xs
                                                )
                                            )
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Bottom spacing
                    item { Spacer(modifier = Modifier.height(80.dp)) }
                }
            }
        }
    }
}

// MARK: - Recipe Header (Icon-Focused)
@Composable
private fun RecipeHeader(
    recipe: RecipeDetail,
    onAuthorClick: () -> Unit
) {
    Column {
        // Image carousel
        if (recipe.images.isNotEmpty()) {
            val pagerState = rememberPagerState { recipe.images.size }
            Box {
                HorizontalPager(state = pagerState) { page ->
                    AsyncImage(
                        model = recipe.images[page],
                        contentDescription = null,
                        modifier = Modifier
                            .fillMaxWidth()
                            .aspectRatio(4f / 3f),
                        contentScale = ContentScale.Crop
                    )
                }
                if (recipe.images.size > 1) {
                    Row(
                        modifier = Modifier
                            .align(Alignment.BottomCenter)
                            .padding(Spacing.sm),
                        horizontalArrangement = Arrangement.Center
                    ) {
                        repeat(recipe.images.size) { index ->
                            Box(
                                modifier = Modifier
                                    .padding(2.dp)
                                    .size(6.dp)
                                    .clip(CircleShape)
                                    .background(
                                        if (index == pagerState.currentPage) Color.White
                                        else Color.White.copy(alpha = 0.5f)
                                    )
                            )
                        }
                    }
                }
            }
        }

        // Content Card
        Surface(
            modifier = Modifier
                .fillMaxWidth()
                .offset(y = (-16).dp)
                .padding(horizontal = Spacing.md),
            shape = RoundedCornerShape(Spacing.lg),
            color = MaterialTheme.colorScheme.surface
        ) {
            Column(modifier = Modifier.padding(Spacing.md)) {
                // Title
                Text(
                    text = recipe.title,
                    style = MaterialTheme.typography.headlineSmall
                )

                Spacer(modifier = Modifier.height(Spacing.sm))

                // Author (avatar only)
                Row(
                    modifier = Modifier.clickable(onClick = onAuthorClick),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    AsyncImage(
                        model = recipe.author.avatarUrl,
                        contentDescription = null,
                        modifier = Modifier
                            .size(24.dp)
                            .clip(CircleShape),
                        contentScale = ContentScale.Crop
                    )
                    Spacer(modifier = Modifier.width(Spacing.xs))
                    Text(
                        text = "@${recipe.author.username}",
                        style = MaterialTheme.typography.labelSmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }

                Spacer(modifier = Modifier.height(Spacing.md))

                // Stats row (Icons with minimal text)
                Row(
                    horizontalArrangement = Arrangement.spacedBy(Spacing.lg)
                ) {
                    // Time
                    recipe.cookingTimeRange?.let {
                        TimeBadge(text = it.cookingTimeDisplayText())
                    }

                    // Servings
                    recipe.servings?.let {
                        ServingsBadge(count = it)
                    }

                    // Cook count
                    CookCountBadge(count = recipe.cookCount)

                    // Rating
                    recipe.averageRating?.let {
                        RatingBadge(rating = it)
                    }
                }
            }
        }
    }
}

// MARK: - Recipe Description
@Composable
private fun RecipeDescription(recipe: RecipeDetail) {
    if (!recipe.description.isNullOrBlank()) {
        Text(
            text = recipe.description,
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            modifier = Modifier.padding(horizontal = Spacing.md)
        )
        Spacer(modifier = Modifier.height(Spacing.md))
    }
}

// MARK: - Ingredients Section (Icon Header)
@Composable
private fun IngredientsSection(
    recipe: RecipeDetail,
    measurementPreference: MeasurementPreference
) {
    Surface(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = Spacing.md),
        shape = RoundedCornerShape(Spacing.md),
        color = MaterialTheme.colorScheme.surface
    ) {
        Column(modifier = Modifier.padding(Spacing.md)) {
            // Icon header
            Icon(
                imageVector = AppIcons.recipe,
                contentDescription = null,
                tint = MaterialTheme.colorScheme.primary,
                modifier = Modifier.size(28.dp)
            )

            Spacer(modifier = Modifier.height(Spacing.sm))

            recipe.ingredients.groupBy { it.category }.forEach { (category, ingredients) ->
                Spacer(modifier = Modifier.height(Spacing.sm))
                ingredients.forEach { ingredient ->
                    val formattedAmount = ingredient.formatAmount(measurementPreference)
                    Row(
                        modifier = Modifier.padding(vertical = Spacing.xxs),
                        verticalAlignment = Alignment.Top
                    ) {
                        Box(
                            modifier = Modifier
                                .padding(top = 6.dp)
                                .size(6.dp)
                                .background(
                                    MaterialTheme.colorScheme.primary,
                                    CircleShape
                                )
                        )
                        Spacer(modifier = Modifier.width(Spacing.sm))
                        Text(
                            text = if (formattedAmount.isNotEmpty()) {
                                "${ingredient.name} $formattedAmount"
                            } else {
                                ingredient.name
                            },
                            style = MaterialTheme.typography.bodyMedium,
                            modifier = Modifier.weight(1f)
                        )
                    }
                }
            }
        }
    }
    Spacer(modifier = Modifier.height(Spacing.sm))
}

// MARK: - Steps Section (Icon Header)
@Composable
private fun StepsSection(recipe: RecipeDetail) {
    Surface(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = Spacing.md),
        shape = RoundedCornerShape(Spacing.md),
        color = MaterialTheme.colorScheme.surface
    ) {
        Column(modifier = Modifier.padding(Spacing.md)) {
            // Icon header
            Icon(
                imageVector = Icons.Filled.FormatListNumbered,
                contentDescription = null,
                tint = MaterialTheme.colorScheme.primary,
                modifier = Modifier.size(28.dp)
            )

            Spacer(modifier = Modifier.height(Spacing.sm))

            recipe.steps.forEachIndexed { index, step ->
                Row(
                    modifier = Modifier.padding(vertical = Spacing.sm),
                    verticalAlignment = Alignment.Top
                ) {
                    // Step number badge
                    Box(
                        modifier = Modifier
                            .size(24.dp)
                            .clip(CircleShape)
                            .background(MaterialTheme.colorScheme.primary),
                        contentAlignment = Alignment.Center
                    ) {
                        Text(
                            text = "${index + 1}",
                            color = MaterialTheme.colorScheme.onPrimary,
                            style = MaterialTheme.typography.labelSmall
                        )
                    }
                    Spacer(modifier = Modifier.width(Spacing.sm))
                    Column {
                        Text(
                            text = step.instruction,
                            style = MaterialTheme.typography.bodyMedium
                        )
                        step.imageUrl?.let { imageUrl ->
                            Spacer(modifier = Modifier.height(Spacing.sm))
                            AsyncImage(
                                model = imageUrl,
                                contentDescription = null,
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .clip(RoundedCornerShape(Spacing.sm)),
                                contentScale = ContentScale.FillWidth
                            )
                        }
                    }
                }
            }
        }
    }
    Spacer(modifier = Modifier.height(Spacing.sm))
}

// MARK: - Cooking Logs Section (Icon Header)
@Composable
private fun CookingLogsSection(
    logs: List<com.cookstemma.app.domain.model.RecipeLogItem>,
    totalCount: Int,
    onLogClick: (String) -> Unit,
    onCreateLogClick: () -> Unit
) {
    Surface(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = Spacing.md),
        shape = RoundedCornerShape(Spacing.md),
        color = MaterialTheme.colorScheme.surface
    ) {
        Column(modifier = Modifier.padding(Spacing.md)) {
            // Header with icon and count
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Icon(
                    imageVector = AppIcons.log,
                    contentDescription = null,
                    tint = MaterialTheme.colorScheme.primary,
                    modifier = Modifier.size(28.dp)
                )
                Text(
                    text = "$totalCount",
                    style = MaterialTheme.typography.labelSmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }

            Spacer(modifier = Modifier.height(Spacing.sm))

            if (logs.isEmpty()) {
                // Empty state (icon only)
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(80.dp)
                        .clickable(onClick = onCreateLogClick),
                    contentAlignment = Alignment.Center
                ) {
                    Column(horizontalAlignment = Alignment.CenterHorizontally) {
                        Icon(
                            imageVector = AppIcons.addPhoto,
                            contentDescription = null,
                            modifier = Modifier.size(40.dp),
                            tint = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.5f)
                        )
                        Text(
                            text = "+",
                            style = MaterialTheme.typography.labelSmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.5f)
                        )
                    }
                }
            } else {
                LazyRow(
                    horizontalArrangement = Arrangement.spacedBy(Spacing.sm)
                ) {
                    items(logs.take(5)) { log ->
                        Box(
                            modifier = Modifier
                                .size(80.dp)
                                .clip(RoundedCornerShape(Spacing.sm))
                                .clickable { onLogClick(log.id) }
                        ) {
                            AsyncImage(
                                model = log.thumbnailUrl,
                                contentDescription = null,
                                modifier = Modifier.fillMaxSize(),
                                contentScale = ContentScale.Crop
                            )
                            // Rating stars overlay
                            Row(
                                modifier = Modifier
                                    .align(Alignment.BottomStart)
                                    .background(Color.Black.copy(alpha = 0.6f))
                                    .padding(4.dp)
                            ) {
                                repeat(log.rating ?: 0) {
                                    Icon(
                                        imageVector = AppIcons.star,
                                        contentDescription = null,
                                        modifier = Modifier.size(10.dp),
                                        tint = Color(0xFFFFD700)
                                    )
                                }
                            }
                        }
                    }

                    // Add log button
                    item {
                        Box(
                            modifier = Modifier
                                .size(80.dp)
                                .clip(RoundedCornerShape(Spacing.sm))
                                .background(MaterialTheme.colorScheme.surfaceVariant)
                                .clickable(onClick = onCreateLogClick),
                            contentAlignment = Alignment.Center
                        ) {
                            Icon(
                                imageVector = Icons.Filled.Add,
                                contentDescription = null,
                                tint = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                        }
                    }
                }
            }
        }
    }
    Spacer(modifier = Modifier.height(Spacing.sm))
}
