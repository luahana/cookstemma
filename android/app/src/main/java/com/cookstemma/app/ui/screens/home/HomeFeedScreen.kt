package com.cookstemma.app.ui.screens.home

import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyListState
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.material3.pulltorefresh.PullToRefreshBox
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import coil.compose.AsyncImage
import com.cookstemma.app.R
import com.cookstemma.app.domain.model.*
import com.cookstemma.app.ui.AppState
import com.cookstemma.app.ui.components.*
import com.cookstemma.app.ui.navigation.NotificationIconButton
import com.cookstemma.app.ui.theme.Layout
import com.cookstemma.app.ui.theme.Spacing

@OptIn(ExperimentalMaterial3Api::class, ExperimentalLayoutApi::class)
@Composable
fun HomeFeedScreen(
    viewModel: HomeFeedViewModel = hiltViewModel(),
    onRecipeClick: (String) -> Unit,
    onLogClick: (String) -> Unit,
    onUserClick: (String) -> Unit,
    onHashtagClick: (String) -> Unit = {},
    onNotificationsClick: () -> Unit = {},
    notificationCount: Int = 0,
    scrollToTopTrigger: Int = 0,
    appState: AppState? = null,
    isAuthenticated: Boolean = false
) {
    val uiState by viewModel.uiState.collectAsState()
    val listState = rememberLazyListState()
    val scope = rememberCoroutineScope()
    
    // Scroll to top when trigger changes
    LaunchedEffect(scrollToTopTrigger) {
        if (scrollToTopTrigger > 0) {
            listState.animateScrollToItem(0)
        }
    }
    
    // Comments bottom sheet state
    var showCommentsForLogId by remember { mutableStateOf<String?>(null) }

    // Load more when reaching end
    LaunchedEffect(listState) {
        snapshotFlow { listState.layoutInfo.visibleItemsInfo.lastOrNull()?.index }
            .collect { lastIndex ->
                if (lastIndex != null && lastIndex >= uiState.items.size - 3) {
                    viewModel.loadMore()
                }
            }
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(MaterialTheme.colorScheme.background)
            .statusBarsPadding()
    ) {
        // Custom header like iOS
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = Spacing.md, vertical = Spacing.sm),
            verticalAlignment = Alignment.CenterVertically
        ) {
            // Logo and app name
            Row(
                horizontalArrangement = Arrangement.spacedBy(Spacing.xs),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Image(
                    painter = painterResource(id = R.drawable.ic_logo),
                    contentDescription = stringResource(R.string.cd_logo),
                    modifier = Modifier.size(36.dp)
                )
                Text(
                    text = "Cookstemma",
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.SemiBold
                )
            }

            Spacer(Modifier.weight(1f))

            // Notification bell
            NotificationIconButton(
                count = notificationCount,
                onClick = onNotificationsClick
            )
        }

        // Content
        Box(Modifier.fillMaxSize()) {
            when {
                uiState.isLoading && uiState.items.isEmpty() -> {
                    CircularProgressIndicator(Modifier.align(Alignment.Center))
                }
                uiState.error != null && uiState.items.isEmpty() -> {
                    IconEmptyState(
                        icon = AppIcons.error,
                        subtitle = uiState.error,
                        modifier = Modifier.align(Alignment.Center)
                    )
                }
                uiState.items.isEmpty() -> {
                    IconEmptyState(
                        icon = AppIcons.followers,
                        modifier = Modifier.align(Alignment.Center)
                    )
                }
                else -> {
                    PullToRefreshBox(
                        isRefreshing = uiState.isRefreshing,
                        onRefresh = { viewModel.refresh() }
                    ) {
                        LazyColumn(
                            state = listState,
                            contentPadding = PaddingValues(bottom = Spacing.md),
                            verticalArrangement = Arrangement.spacedBy(Spacing.md),
                            horizontalAlignment = Alignment.CenterHorizontally,
                            modifier = Modifier.fillMaxSize()
                        ) {
                            items(uiState.items, key = { it.id }) { item ->
                                FeedLogCard(
                                    modifier = Modifier.widthIn(max = Layout.maxContentWidth),
                                    item = item,
                                    isLiked = uiState.isLogLiked(item.id),
                                    isSaved = uiState.isLogSaved(item.id),
                                    onClick = { onLogClick(item.id) },
                                    onUserClick = { onUserClick(item.creatorPublicId) },
                                    onLikeClick = {
                                        if (appState != null) {
                                            appState.requireAuth(isAuthenticated) {
                                                viewModel.likeLog(item.id)
                                            }
                                        } else {
                                            viewModel.likeLog(item.id)
                                        }
                                    },
                                    onCommentClick = {
                                        if (appState != null) {
                                            appState.requireAuth(isAuthenticated) {
                                                showCommentsForLogId = item.id
                                            }
                                        } else {
                                            showCommentsForLogId = item.id
                                        }
                                    },
                                    onHashtagClick = onHashtagClick,
                                    onSaveClick = {
                                        if (appState != null) {
                                            appState.requireAuth(isAuthenticated) {
                                                viewModel.saveLog(item.id)
                                            }
                                        } else {
                                            viewModel.saveLog(item.id)
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
    }
    
    // Comments bottom sheet
    showCommentsForLogId?.let { logId ->
        CommentsBottomSheet(
            logId = logId,
            onDismiss = { showCommentsForLogId = null },
            onNavigateToProfile = onUserClick
        )
    }
}

// MARK: - Feed Log Card (Instagram-style, seamless white)
@OptIn(ExperimentalLayoutApi::class)
@Composable
fun FeedLogCard(
    item: FeedItem,
    modifier: Modifier = Modifier,
    isLiked: Boolean = false,
    isSaved: Boolean = false,
    onClick: () -> Unit,
    onUserClick: () -> Unit,
    onLikeClick: () -> Unit,
    onCommentClick: () -> Unit,
    onHashtagClick: (String) -> Unit,
    onSaveClick: () -> Unit
) {
    Column(
        modifier = modifier
            .fillMaxWidth()
            .clickable(onClick = onClick)
            .background(MaterialTheme.colorScheme.background)
    ) {
        // Header: User and Rating (like iOS)
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = Spacing.sm, vertical = Spacing.xs),
            verticalAlignment = Alignment.CenterVertically
        ) {
            // User avatar placeholder
            Box(
                modifier = Modifier
                    .size(32.dp)
                    .clip(CircleShape)
                    .background(MaterialTheme.colorScheme.surfaceVariant)
                    .clickable(onClick = onUserClick),
                contentAlignment = Alignment.Center
            ) {
                Text(
                    text = item.userName.take(1).uppercase(),
                    style = MaterialTheme.typography.labelSmall,
                    fontWeight = FontWeight.SemiBold,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }

            Spacer(Modifier.width(Spacing.xs))

            Text(
                text = item.userName,
                style = MaterialTheme.typography.bodyMedium,
                fontWeight = FontWeight.Medium,
                modifier = Modifier.weight(1f)
            )

            // Rating stars (like iOS - in header)
            item.rating?.let { rating ->
                Row(horizontalArrangement = Arrangement.spacedBy(2.dp)) {
                    repeat(5) { index ->
                        Icon(
                            imageVector = if (index < rating) AppIcons.star else AppIcons.starOutline,
                            contentDescription = null,
                            modifier = Modifier.size(12.dp),
                            tint = if (index < rating)
                                MaterialTheme.colorScheme.primary
                            else
                                MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.3f)
                        )
                    }
                }
            }
        }

        // Full-width image (no rounded corners, like iOS)
        item.thumbnailUrl?.let { url ->
            AsyncImage(
                model = url,
                contentDescription = null,
                contentScale = ContentScale.Crop,
                modifier = Modifier
                    .fillMaxWidth()
                    .height(220.dp)
            )
        }

        // Action buttons row (like Instagram)
        // Footer: Description, Food, Comments, Hashtags
        Column(
            modifier = Modifier.padding(horizontal = Spacing.sm).padding(bottom = Spacing.sm),
            verticalArrangement = Arrangement.spacedBy(Spacing.xs)
        ) {
            // Content preview
            item.content?.let {
                Text(
                    text = it,
                    maxLines = 2,
                    overflow = TextOverflow.Ellipsis,
                    style = MaterialTheme.typography.bodyMedium
                )
            }

            // Food name, cooking style, and comments (like iOS)
            Row(
                horizontalArrangement = Arrangement.spacedBy(Spacing.sm),
                verticalAlignment = Alignment.CenterVertically
            ) {
                // Food name
                item.foodName?.let { food ->
                    Row(
                        horizontalArrangement = Arrangement.spacedBy(4.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Icon(
                            imageVector = AppIcons.recipe,
                            contentDescription = null,
                            modifier = Modifier.size(12.dp),
                            tint = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                        Text(
                            text = food,
                            style = MaterialTheme.typography.labelSmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                }

                // Cooking style with flag
                item.cookingStyle?.let { style ->
                    Text(
                        text = "${style.toFlagEmoji()} $style",
                        style = MaterialTheme.typography.labelSmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }

                // Comment count
                item.commentCount?.let { count ->
                    if (count > 0) {
                        Row(
                            horizontalArrangement = Arrangement.spacedBy(4.dp),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Icon(
                                imageVector = AppIcons.comment,
                                contentDescription = null,
                                modifier = Modifier.size(12.dp),
                                tint = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                            Text(
                                text = "$count",
                                style = MaterialTheme.typography.labelSmall,
                                color = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                        }
                    }
                }
            }

            // Hashtags (inline text like iOS)
            if (item.hashtags.isNotEmpty()) {
                Text(
                    text = item.hashtags.take(4).joinToString(" ") { "#$it" },
                    style = MaterialTheme.typography.labelSmall,
                    color = MaterialTheme.colorScheme.primary,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis
                )
            }
        }
    }
}

// Helper extension to convert cooking style code to flag emoji
private fun String.toFlagEmoji(): String {
    return when (this.uppercase()) {
        "KR" -> "🇰🇷"
        "US" -> "🇺🇸"
        "IT" -> "🇮🇹"
        "ES" -> "🇪🇸"
        "FR" -> "🇫🇷"
        "JP" -> "🇯🇵"
        "CN" -> "🇨🇳"
        "TH" -> "🇹🇭"
        "IN" -> "🇮🇳"
        "MX" -> "🇲🇽"
        "DE" -> "🇩🇪"
        "GB", "UK" -> "🇬🇧"
        "VN" -> "🇻🇳"
        "GR" -> "🇬🇷"
        "TR" -> "🇹🇷"
        "IR" -> "🇮🇷"
        "SE" -> "🇸🇪"
        else -> "🌍"
    }
}

// MARK: - Linked Recipe Card (Icon-Focused)
@Composable
fun LinkedRecipeCard(
    recipe: RecipeSummary,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    Surface(
        modifier = modifier
            .fillMaxWidth()
            .clickable(onClick = onClick),
        color = MaterialTheme.colorScheme.surfaceVariant,
        shape = RoundedCornerShape(Spacing.sm)
    ) {
        Row(
            Modifier.padding(Spacing.sm),
            verticalAlignment = Alignment.CenterVertically
        ) {
            // Recipe icon
            Icon(
                imageVector = AppIcons.recipe,
                contentDescription = null,
                tint = MaterialTheme.colorScheme.primary,
                modifier = Modifier.size(20.dp)
            )

            Spacer(Modifier.width(Spacing.sm))

            // Recipe thumbnail
            recipe.coverImageUrl?.let {
                AsyncImage(
                    model = it,
                    contentDescription = null,
                    modifier = Modifier
                        .size(32.dp)
                        .clip(RoundedCornerShape(Spacing.xxs)),
                    contentScale = ContentScale.Crop
                )
                Spacer(Modifier.width(Spacing.sm))
            }

            // Title
            Text(
                text = recipe.title,
                style = MaterialTheme.typography.labelMedium,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis,
                modifier = Modifier.weight(1f)
            )

            // Cook count badge
            CookCountBadge(count = recipe.cookCount)

            Spacer(Modifier.width(Spacing.xs))

            // Forward icon
            Icon(
                imageVector = AppIcons.forward,
                contentDescription = null,
                tint = MaterialTheme.colorScheme.onSurfaceVariant,
                modifier = Modifier.size(16.dp)
            )
        }
    }
}

// MARK: - Recipe Card Compact (Icon-Focused)
@Composable
fun RecipeCardCompact(
    recipe: RecipeSummary,
    onClick: () -> Unit
) {
    Surface(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(onClick = onClick),
        shape = RoundedCornerShape(Spacing.md),
        color = MaterialTheme.colorScheme.surface
    ) {
        Row(Modifier.padding(Spacing.sm)) {
            // Cover image
            AsyncImage(
                model = recipe.coverImageUrl,
                contentDescription = null,
                modifier = Modifier
                    .size(80.dp)
                    .clip(RoundedCornerShape(Spacing.sm)),
                contentScale = ContentScale.Crop
            )

            Spacer(Modifier.width(Spacing.md))

            Column(Modifier.weight(1f)) {
                // Title
                Text(
                    text = recipe.title,
                    style = MaterialTheme.typography.titleSmall,
                    maxLines = 2,
                    overflow = TextOverflow.Ellipsis
                )

                Spacer(Modifier.height(Spacing.xs))

                // Stats row (icons only)
                Row(
                    horizontalArrangement = Arrangement.spacedBy(Spacing.md),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    // Time badge
                    recipe.cookingTimeRange?.let {
                        TimeBadge(text = it.cookingTimeDisplayText())
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

// MARK: - Hashtag Chip
@Composable
private fun HashtagChip(
    tag: String,
    onClick: () -> Unit
) {
    Surface(
        modifier = Modifier.clickable(onClick = onClick),
        shape = RoundedCornerShape(Spacing.sm),
        color = MaterialTheme.colorScheme.primaryContainer.copy(alpha = 0.5f)
    ) {
        Text(
            text = "#$tag",
            modifier = Modifier.padding(horizontal = Spacing.sm, vertical = Spacing.xs),
            style = MaterialTheme.typography.labelSmall,
            color = MaterialTheme.colorScheme.primary
        )
    }
}
