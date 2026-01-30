package com.cookstemma.app.ui.screens.recipes

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import coil.compose.AsyncImage
import com.cookstemma.app.domain.model.RecipeSummary
import com.cookstemma.app.domain.model.cookingStyleDisplay
import com.cookstemma.app.domain.model.cookingTimeDisplayText
import com.cookstemma.app.ui.AppState
import com.cookstemma.app.ui.components.*
import com.cookstemma.app.ui.theme.Spacing

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun RecipesListScreen(
    viewModel: RecipesListViewModel = hiltViewModel(),
    onRecipeClick: (String) -> Unit,
    scrollToTopTrigger: Int = 0,
    appState: AppState? = null,
    isAuthenticated: Boolean = false
) {
    val uiState by viewModel.uiState.collectAsState()
    val listState = rememberLazyListState()
    var showFiltersSheet by remember { mutableStateOf(false) }

    // Scroll to top when trigger changes
    LaunchedEffect(scrollToTopTrigger) {
        if (scrollToTopTrigger > 0) {
            listState.animateScrollToItem(0)
        }
    }

    // Load more when near bottom
    LaunchedEffect(listState) {
        snapshotFlow { listState.layoutInfo.visibleItemsInfo.lastOrNull()?.index }
            .collect { lastIndex ->
                if (lastIndex != null && lastIndex >= uiState.recipes.size - 3) {
                    viewModel.loadMore()
                }
            }
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .statusBarsPadding()
    ) {
        // Header with recipe icon, title, and filter button
        RecipesHeader(
            hasActiveFilters = uiState.hasActiveFilters,
            onFilterClick = { showFiltersSheet = true }
        )

        // Content
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(horizontal = Spacing.md)
        ) {
            when {
                uiState.isLoading && uiState.recipes.isEmpty() -> {
                    CircularProgressIndicator(Modifier.align(Alignment.Center))
                }
                uiState.error != null && uiState.recipes.isEmpty() -> {
                    IconEmptyState(
                        icon = AppIcons.error,
                        subtitle = uiState.error,
                        modifier = Modifier.align(Alignment.Center)
                    )
                }
                uiState.recipes.isEmpty() -> {
                    IconEmptyState(
                        icon = AppIcons.recipe,
                        modifier = Modifier.align(Alignment.Center)
                    )
                }
                else -> {
                    LazyColumn(
                        state = listState,
                        verticalArrangement = Arrangement.spacedBy(Spacing.md),
                        contentPadding = PaddingValues(bottom = Spacing.xl)
                    ) {
                        items(uiState.recipes, key = { it.id }) { recipe ->
                            RecipeCard(
                                recipe = recipe,
                                isSaved = uiState.isRecipeSaved(recipe.id),
                                onClick = { onRecipeClick(recipe.id) },
                                onSaveClick = {
                                    if (appState != null) {
                                        appState.requireAuth(isAuthenticated) {
                                            viewModel.saveRecipe(recipe)
                                        }
                                    } else {
                                        viewModel.saveRecipe(recipe)
                                    }
                                }
                            )
                        }

                        if (uiState.isLoadingMore) {
                            item {
                                Box(
                                    Modifier
                                        .fillMaxWidth()
                                        .padding(Spacing.md),
                                    contentAlignment = Alignment.Center
                                ) {
                                    CircularProgressIndicator(Modifier.size(24.dp))
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // Filters Bottom Sheet
    if (showFiltersSheet) {
        RecipeFiltersSheet(
            currentFilters = uiState.filters,
            onApplyFilters = { filters ->
                viewModel.updateFilters(filters)
            },
            onDismiss = { showFiltersSheet = false }
        )
    }
}

// MARK: - Recipes Header
@Composable
private fun RecipesHeader(
    hasActiveFilters: Boolean,
    onFilterClick: () -> Unit
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = Spacing.md, vertical = Spacing.sm),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Icon(
            imageVector = AppIcons.recipe,
            contentDescription = null,
            tint = MaterialTheme.colorScheme.primary,
            modifier = Modifier.size(28.dp)
        )

        Spacer(Modifier.width(Spacing.sm))

        Text(
            text = "Recipes",
            style = MaterialTheme.typography.headlineSmall,
            color = MaterialTheme.colorScheme.onSurface
        )

        Spacer(Modifier.weight(1f))

        IconButton(onClick = onFilterClick) {
            Icon(
                imageVector = AppIcons.filter,
                contentDescription = "Filter",
                tint = if (hasActiveFilters)
                    MaterialTheme.colorScheme.primary
                else
                    MaterialTheme.colorScheme.onSurface
            )
        }
    }
}

// MARK: - Recipe Card (matches iOS RecipeCard)
@Composable
private fun RecipeCard(
    recipe: RecipeSummary,
    isSaved: Boolean,
    onClick: () -> Unit,
    onSaveClick: () -> Unit
) {
    var isSaving by remember { mutableStateOf(false) }

    Column(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(onClick = onClick)
            .padding(Spacing.md),
        verticalArrangement = Arrangement.spacedBy(Spacing.sm)
    ) {
        // Cover image
        AsyncImage(
            model = recipe.coverImageUrl,
            contentDescription = null,
            contentScale = ContentScale.Crop,
            modifier = Modifier
                .fillMaxWidth()
                .height(180.dp)
                .clip(RoundedCornerShape(Spacing.md))
        )

        // Title
        Text(
            text = recipe.title,
            style = MaterialTheme.typography.titleMedium,
            color = MaterialTheme.colorScheme.onSurface,
            maxLines = 2,
            overflow = TextOverflow.Ellipsis
        )

        // Stats row
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(Spacing.md),
            verticalAlignment = Alignment.CenterVertically
        ) {
            // Cooking time
            recipe.cookingTimeRange?.let { time ->
                Row(
                    horizontalArrangement = Arrangement.spacedBy(Spacing.xxs),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Icon(
                        imageVector = AppIcons.timer,
                        contentDescription = null,
                        modifier = Modifier.size(14.dp),
                        tint = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                    Text(
                        text = time.cookingTimeDisplayText(),
                        style = MaterialTheme.typography.labelSmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
            }

            // Cooking style with flag
            recipe.cookingStyle?.let { style ->
                if (style.isNotEmpty()) {
                    Text(
                        text = style.cookingStyleDisplay(),
                        style = MaterialTheme.typography.labelSmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
            }

            // Cook count
            Row(
                horizontalArrangement = Arrangement.spacedBy(Spacing.xxs),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Icon(
                    imageVector = AppIcons.chef,
                    contentDescription = null,
                    modifier = Modifier.size(14.dp),
                    tint = MaterialTheme.colorScheme.onSurfaceVariant
                )
                Text(
                    text = recipe.cookCount.abbreviated(),
                    style = MaterialTheme.typography.labelSmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }

            Spacer(Modifier.weight(1f))

            // Save button
            IconButton(
                onClick = {
                    if (!isSaving) {
                        isSaving = true
                        onSaveClick()
                        isSaving = false
                    }
                },
                enabled = !isSaving,
                modifier = Modifier.size(32.dp)
            ) {
                Icon(
                    imageVector = if (isSaved) AppIcons.save else AppIcons.saveOutline,
                    contentDescription = if (isSaved) "Unsave" else "Save",
                    tint = if (isSaved)
                        MaterialTheme.colorScheme.primary
                    else
                        MaterialTheme.colorScheme.onSurfaceVariant,
                    modifier = Modifier.size(20.dp)
                )
            }
        }
    }
}

// Extension function for abbreviated numbers
private fun Int.abbreviated(): String {
    return when {
        this >= 1_000_000 -> "${this / 1_000_000}M"
        this >= 1_000 -> "${this / 1_000}K"
        else -> this.toString()
    }
}
