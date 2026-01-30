@file:OptIn(ExperimentalFoundationApi::class)

package com.cookstemma.app.ui.screens.logdetail

import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.pager.HorizontalPager
import androidx.compose.foundation.pager.rememberPagerState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.automirrored.filled.Send
import androidx.compose.material.icons.filled.*
import androidx.compose.material.icons.outlined.BookmarkBorder
import androidx.compose.material.icons.outlined.FavoriteBorder
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import coil.compose.AsyncImage
import com.cookstemma.app.data.repository.Comment
import com.cookstemma.app.ui.AppState
import com.cookstemma.app.ui.components.StarRating
import com.cookstemma.app.ui.theme.BrandOrange

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun LogDetailScreen(
    onNavigateBack: () -> Unit,
    onNavigateToRecipe: (String) -> Unit,
    onNavigateToProfile: (String) -> Unit,
    onNavigateToEdit: (String) -> Unit = {},
    viewModel: LogDetailViewModel = hiltViewModel(),
    appState: AppState? = null,
    isAuthenticated: Boolean = false
) {
    val uiState by viewModel.uiState.collectAsState()

    Scaffold(
        topBar = {
            TopAppBar(
                title = { },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Back")
                    }
                },
                actions = {
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
                            if (uiState.log?.isSaved == true) Icons.Filled.Bookmark
                            else Icons.Outlined.BookmarkBorder,
                            contentDescription = "Save",
                            tint = if (uiState.log?.isSaved == true) BrandOrange else Color.Gray
                        )
                    }
                    IconButton(onClick = { /* Share */ }) {
                        Icon(Icons.Default.Share, contentDescription = "Share")
                    }
                    // Edit button - show only for own logs (simplified for now)
                    uiState.log?.let { log ->
                        IconButton(onClick = { onNavigateToEdit(log.id) }) {
                            Icon(Icons.Default.Edit, contentDescription = "Edit")
                        }
                    }
                    IconButton(onClick = { /* More options */ }) {
                        Icon(Icons.Default.MoreVert, contentDescription = "More")
                    }
                }
            )
        },
        bottomBar = {
            CommentInputBar(
                text = uiState.commentText,
                onTextChange = viewModel::setCommentText,
                onSubmit = viewModel::submitComment,
                isSubmitting = uiState.isSubmittingComment,
                replyingTo = uiState.replyingTo,
                onCancelReply = { viewModel.setReplyingTo(null) }
            )
        }
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
                Box(
                    modifier = Modifier
                        .fillMaxSize()
                        .padding(padding),
                    contentAlignment = Alignment.Center
                ) {
                    Text(uiState.error ?: "Error")
                }
            }
            uiState.log != null -> {
                LazyColumn(
                    modifier = Modifier
                        .fillMaxSize()
                        .padding(padding)
                ) {
                    item {
                        LogContent(
                            log = uiState.log!!,
                            onLike = viewModel::toggleLike,
                            onNavigateToRecipe = onNavigateToRecipe,
                            onNavigateToProfile = onNavigateToProfile
                        )
                    }

                    item {
                        HorizontalDivider(modifier = Modifier.padding(vertical = 16.dp))
                        Text(
                            "Comments (${uiState.log!!.commentCount})",
                            style = MaterialTheme.typography.titleMedium,
                            fontWeight = FontWeight.SemiBold,
                            modifier = Modifier.padding(horizontal = 16.dp)
                        )
                        Spacer(modifier = Modifier.height(8.dp))
                    }

                    items(uiState.comments) { comment ->
                        CommentItem(
                            comment = comment,
                            onLike = { viewModel.toggleCommentLike(comment) },
                            onReply = { viewModel.setReplyingTo(comment) },
                            onNavigateToProfile = onNavigateToProfile
                        )
                    }

                    if (uiState.hasMoreComments) {
                        item {
                            TextButton(
                                onClick = viewModel::loadMoreComments,
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .padding(16.dp)
                            ) {
                                if (uiState.isLoadingComments) {
                                    CircularProgressIndicator(
                                        modifier = Modifier.size(20.dp),
                                        strokeWidth = 2.dp
                                    )
                                } else {
                                    Text("Load more comments")
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun LogContent(
    log: com.cookstemma.app.domain.model.CookingLogDetail,
    onLike: () -> Unit,
    onNavigateToRecipe: (String) -> Unit,
    onNavigateToProfile: (String) -> Unit
) {
    Column {
        // Author header
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .clickable { onNavigateToProfile(log.author.id) }
                .padding(horizontal = 16.dp, vertical = 12.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            AsyncImage(
                model = log.author.avatarUrl,
                contentDescription = null,
                modifier = Modifier
                    .size(40.dp)
                    .clip(CircleShape),
                contentScale = ContentScale.Crop
            )
            Spacer(modifier = Modifier.width(12.dp))
            Column {
                Text(
                    log.author.username ?: "",
                    style = MaterialTheme.typography.bodyMedium,
                    fontWeight = FontWeight.SemiBold
                )
                Text(
                    log.createdAt.toString(),
                    style = MaterialTheme.typography.bodySmall,
                    color = Color.Gray
                )
            }
        }

        // Photo carousel
        val logImages = log.images.orEmpty()
        if (logImages.isNotEmpty()) {
            val pagerState = rememberPagerState { logImages.size }
            Box {
                HorizontalPager(state = pagerState) { page ->
                    AsyncImage(
                        model = logImages[page].originalUrl ?: logImages[page].thumbnailUrl,
                        contentDescription = null,
                        modifier = Modifier
                            .fillMaxWidth()
                            .aspectRatio(1f),
                        contentScale = ContentScale.Crop
                    )
                }
                if (logImages.size > 1) {
                    Row(
                        modifier = Modifier
                            .align(Alignment.BottomCenter)
                            .padding(8.dp),
                        horizontalArrangement = Arrangement.Center
                    ) {
                        repeat(logImages.size) { index ->
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

        // Action buttons
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 8.dp, vertical = 8.dp)
        ) {
            IconButton(onClick = onLike) {
                Icon(
                    if (log.isLiked) Icons.Filled.Favorite else Icons.Outlined.FavoriteBorder,
                    contentDescription = "Like",
                    tint = if (log.isLiked) Color.Red else Color.Gray
                )
            }
            Text(
                "${log.likeCount}",
                modifier = Modifier.align(Alignment.CenterVertically),
                style = MaterialTheme.typography.bodyMedium
            )
            Spacer(modifier = Modifier.width(16.dp))
            Icon(
                Icons.Default.ChatBubbleOutline,
                contentDescription = "Comments",
                tint = Color.Gray,
                modifier = Modifier.align(Alignment.CenterVertically)
            )
            Text(
                "${log.commentCount}",
                modifier = Modifier
                    .align(Alignment.CenterVertically)
                    .padding(start = 4.dp),
                style = MaterialTheme.typography.bodyMedium
            )
        }

        // Rating
        Row(
            modifier = Modifier.padding(horizontal = 16.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            StarRating(rating = log.rating, size = 20.dp)
            Spacer(modifier = Modifier.width(8.dp))
            Text(
                "${log.rating}.0",
                style = MaterialTheme.typography.bodyMedium,
                fontWeight = FontWeight.SemiBold
            )
        }

        // Content
        if (!log.content.isNullOrBlank()) {
            Text(
                log.content,
                modifier = Modifier.padding(horizontal = 16.dp, vertical = 8.dp),
                style = MaterialTheme.typography.bodyMedium
            )
        }

        // Linked recipe
        log.recipe?.let { recipe ->
            Card(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp, vertical = 8.dp)
                    .clickable { onNavigateToRecipe(recipe.id) },
                colors = CardDefaults.cardColors(
                    containerColor = MaterialTheme.colorScheme.surfaceVariant
                )
            ) {
                Row(
                    modifier = Modifier.padding(12.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Icon(
                        Icons.Default.MenuBook,
                        contentDescription = null,
                        tint = BrandOrange,
                        modifier = Modifier.size(20.dp)
                    )
                    Spacer(modifier = Modifier.width(8.dp))
                    Column(modifier = Modifier.weight(1f)) {
                        Text(
                            recipe.title,
                            style = MaterialTheme.typography.bodyMedium,
                            fontWeight = FontWeight.SemiBold
                        )
                        Text(
                            "by @${recipe.userName}",
                            style = MaterialTheme.typography.bodySmall,
                            color = Color.Gray
                        )
                    }
                    Icon(
                        Icons.Default.ChevronRight,
                        contentDescription = "View",
                        tint = Color.Gray
                    )
                }
            }
        }

        // Hashtags
        if (!log.hashtags.isNullOrEmpty()) {
            Text(
                log.hashtags.joinToString(" ") { "#$it" },
                modifier = Modifier.padding(horizontal = 16.dp, vertical = 8.dp),
                style = MaterialTheme.typography.bodyMedium,
                color = BrandOrange
            )
        }
    }
}

@Composable
private fun CommentItem(
    comment: Comment,
    onLike: () -> Unit,
    onReply: () -> Unit,
    onNavigateToProfile: (String) -> Unit,
    isReply: Boolean = false
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(
                start = if (isReply) 48.dp else 16.dp,
                end = 16.dp,
                top = 8.dp,
                bottom = 8.dp
            )
    ) {
        AsyncImage(
            model = comment.author.avatarUrl,
            contentDescription = null,
            modifier = Modifier
                .size(if (isReply) 28.dp else 32.dp)
                .clip(CircleShape)
                .clickable { onNavigateToProfile(comment.author.id) },
            contentScale = ContentScale.Crop
        )
        Spacer(modifier = Modifier.width(8.dp))
        Column(modifier = Modifier.weight(1f)) {
            Row {
                Text(
                    comment.author.username ?: "",
                    style = MaterialTheme.typography.bodySmall,
                    fontWeight = FontWeight.SemiBold,
                    modifier = Modifier.clickable { onNavigateToProfile(comment.author.id) }
                )
                Spacer(modifier = Modifier.width(8.dp))
                Text(
                    comment.createdAt,
                    style = MaterialTheme.typography.bodySmall,
                    color = Color.Gray
                )
            }
            Text(
                comment.content ?: "",
                style = MaterialTheme.typography.bodyMedium
            )
            Row {
                TextButton(
                    onClick = onLike,
                    contentPadding = PaddingValues(0.dp)
                ) {
                    Icon(
                        if (comment.isLiked) Icons.Filled.Favorite else Icons.Outlined.FavoriteBorder,
                        contentDescription = "Like",
                        tint = if (comment.isLiked) Color.Red else Color.Gray,
                        modifier = Modifier.size(16.dp)
                    )
                    if (comment.likeCount > 0) {
                        Spacer(modifier = Modifier.width(4.dp))
                        Text(
                            "${comment.likeCount}",
                            style = MaterialTheme.typography.bodySmall,
                            color = Color.Gray
                        )
                    }
                }
                TextButton(
                    onClick = onReply,
                    contentPadding = PaddingValues(0.dp)
                ) {
                    Text(
                        "Reply",
                        style = MaterialTheme.typography.bodySmall,
                        color = Color.Gray
                    )
                }
            }

            // Show replies
            comment.replies?.forEach { reply ->
                CommentItem(
                    comment = reply,
                    onLike = { /* Toggle reply like */ },
                    onReply = onReply,
                    onNavigateToProfile = onNavigateToProfile,
                    isReply = true
                )
            }
        }
    }
}

@Composable
private fun CommentInputBar(
    text: String,
    onTextChange: (String) -> Unit,
    onSubmit: () -> Unit,
    isSubmitting: Boolean,
    replyingTo: Comment?,
    onCancelReply: () -> Unit
) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .background(MaterialTheme.colorScheme.surface)
    ) {
        if (replyingTo != null) {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .background(MaterialTheme.colorScheme.surfaceVariant)
                    .padding(horizontal = 16.dp, vertical = 8.dp),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    "Replying to @${replyingTo.author.username}",
                    style = MaterialTheme.typography.bodySmall,
                    color = Color.Gray
                )
                IconButton(onClick = onCancelReply, modifier = Modifier.size(24.dp)) {
                    Icon(
                        Icons.Default.Close,
                        contentDescription = "Cancel",
                        modifier = Modifier.size(16.dp)
                    )
                }
            }
        }
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(8.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            OutlinedTextField(
                value = text,
                onValueChange = onTextChange,
                modifier = Modifier.weight(1f),
                placeholder = { Text("Write a comment...") },
                shape = RoundedCornerShape(24.dp),
                maxLines = 3
            )
            Spacer(modifier = Modifier.width(8.dp))
            IconButton(
                onClick = onSubmit,
                enabled = text.isNotBlank() && !isSubmitting
            ) {
                if (isSubmitting) {
                    CircularProgressIndicator(
                        modifier = Modifier.size(24.dp),
                        strokeWidth = 2.dp
                    )
                } else {
                    Icon(
                        Icons.AutoMirrored.Filled.Send,
                        contentDescription = "Send",
                        tint = if (text.isNotBlank()) BrandOrange else Color.Gray
                    )
                }
            }
        }
    }
}
