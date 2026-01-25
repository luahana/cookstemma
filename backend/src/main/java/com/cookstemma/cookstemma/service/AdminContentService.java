package com.cookstemma.cookstemma.service;

import com.cookstemma.cookstemma.domain.entity.comment.Comment;
import com.cookstemma.cookstemma.domain.entity.log_post.LogPost;
import com.cookstemma.cookstemma.domain.entity.recipe.Recipe;
import com.cookstemma.cookstemma.domain.entity.user.User;
import com.cookstemma.cookstemma.dto.admin.AdminCommentDto;
import com.cookstemma.cookstemma.dto.admin.AdminLogPostDto;
import com.cookstemma.cookstemma.dto.admin.AdminRecipeDto;
import com.cookstemma.cookstemma.repository.comment.CommentRepository;
import com.cookstemma.cookstemma.repository.log_post.LogPostRepository;
import com.cookstemma.cookstemma.repository.recipe.RecipeLogRepository;
import com.cookstemma.cookstemma.repository.recipe.RecipeRepository;
import com.cookstemma.cookstemma.repository.user.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.function.Function;
import java.util.stream.Collectors;

/**
 * Admin service for managing all content (recipes, logs, comments).
 * Bypasses owner checks for admin operations.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class AdminContentService {

    private final RecipeRepository recipeRepository;
    private final LogPostRepository logPostRepository;
    private final CommentRepository commentRepository;
    private final RecipeLogRepository recipeLogRepository;
    private final UserRepository userRepository;

    // ==================== RECIPES ====================

    @Transactional(readOnly = true)
    public Page<AdminRecipeDto> getRecipes(String title, String username, int page, int size) {
        Pageable pageable = PageRequest.of(page, size);

        Page<Recipe> recipes;
        boolean hasTitle = title != null && !title.isBlank();
        boolean hasUsername = username != null && !username.isBlank();

        if (hasTitle && hasUsername) {
            recipes = recipeRepository.findAllForAdminByTitleAndUsername(title, username, pageable);
        } else if (hasTitle) {
            recipes = recipeRepository.findAllForAdminByTitle(title, pageable);
        } else if (hasUsername) {
            recipes = recipeRepository.findAllForAdminByUsername(username, pageable);
        } else {
            recipes = recipeRepository.findAllForAdmin(pageable);
        }

        // Get creator usernames
        List<Long> creatorIds = recipes.getContent().stream()
                .map(Recipe::getCreatorId)
                .distinct()
                .toList();
        Map<Long, User> userMap = getUserMap(creatorIds);

        // Get variant counts
        List<Long> recipeIds = recipes.getContent().stream()
                .map(Recipe::getId)
                .toList();
        Map<Long, Long> variantCountMap = getVariantCountMap(recipeIds);
        Map<Long, Long> logCountMap = getLogCountMap(recipeIds);

        return recipes.map(recipe -> mapToRecipeDto(recipe, userMap, variantCountMap, logCountMap));
    }

    @Transactional
    public int deleteRecipes(List<UUID> publicIds) {
        List<Recipe> recipes = recipeRepository.findByPublicIdIn(publicIds);
        int deletedCount = 0;

        for (Recipe recipe : recipes) {
            recipe.softDelete();
            recipeRepository.save(recipe);
            deletedCount++;
            log.info("Admin deleted recipe: {}", recipe.getPublicId());
        }

        return deletedCount;
    }

    private AdminRecipeDto mapToRecipeDto(Recipe recipe, Map<Long, User> userMap,
                                          Map<Long, Long> variantCountMap, Map<Long, Long> logCountMap) {
        User creator = userMap.get(recipe.getCreatorId());
        return AdminRecipeDto.builder()
                .publicId(recipe.getPublicId())
                .title(recipe.getTitle())
                .cookingStyle(recipe.getCookingStyle())
                .creatorUsername(creator != null ? creator.getUsername() : "Unknown")
                .creatorPublicId(creator != null ? creator.getPublicId() : null)
                .variantCount(variantCountMap.getOrDefault(recipe.getId(), 0L).intValue())
                .logCount(logCountMap.getOrDefault(recipe.getId(), 0L).intValue())
                .viewCount(recipe.getViewCount() != null ? recipe.getViewCount() : 0)
                .saveCount(recipe.getSavedCount() != null ? recipe.getSavedCount() : 0)
                .isPrivate(recipe.getIsPrivate() != null && recipe.getIsPrivate())
                .createdAt(recipe.getCreatedAt())
                .build();
    }

    private Map<Long, Long> getVariantCountMap(List<Long> recipeIds) {
        if (recipeIds.isEmpty()) {
            return Map.of();
        }
        List<Object[]> results = recipeRepository.countVariantsByRootIds(recipeIds);
        return results.stream()
                .collect(Collectors.toMap(
                        row -> (Long) row[0],
                        row -> (Long) row[1]
                ));
    }

    private Map<Long, Long> getLogCountMap(List<Long> recipeIds) {
        if (recipeIds.isEmpty()) {
            return Map.of();
        }
        List<Object[]> results = recipeLogRepository.countLogsByRecipeIds(recipeIds);
        return results.stream()
                .collect(Collectors.toMap(
                        row -> (Long) row[0],
                        row -> (Long) row[1]
                ));
    }

    // ==================== LOG POSTS ====================

    @Transactional(readOnly = true)
    public Page<AdminLogPostDto> getLogs(String content, String username, int page, int size) {
        Pageable pageable = PageRequest.of(page, size);

        Page<LogPost> logs;
        boolean hasContent = content != null && !content.isBlank();
        boolean hasUsername = username != null && !username.isBlank();

        if (hasContent && hasUsername) {
            logs = logPostRepository.findAllForAdminByContentAndUsername(content, username, pageable);
        } else if (hasContent) {
            logs = logPostRepository.findAllForAdminByContent(content, pageable);
        } else if (hasUsername) {
            logs = logPostRepository.findAllForAdminByUsername(username, pageable);
        } else {
            logs = logPostRepository.findAllForAdmin(pageable);
        }

        // Get creator usernames
        List<Long> creatorIds = logs.getContent().stream()
                .map(LogPost::getCreatorId)
                .distinct()
                .toList();
        Map<Long, User> userMap = getUserMap(creatorIds);

        return logs.map(logPost -> mapToLogDto(logPost, userMap));
    }

    @Transactional
    public int deleteLogs(List<UUID> publicIds) {
        List<LogPost> logs = logPostRepository.findByPublicIdIn(publicIds);
        int deletedCount = 0;

        for (LogPost logPost : logs) {
            logPost.softDelete();
            logPostRepository.save(logPost);
            deletedCount++;
            log.info("Admin deleted log post: {}", logPost.getPublicId());
        }

        return deletedCount;
    }

    private AdminLogPostDto mapToLogDto(LogPost logPost, Map<Long, User> userMap) {
        User creator = userMap.get(logPost.getCreatorId());

        // Get content preview
        String contentPreview = logPost.getContent() != null
                ? (logPost.getContent().length() > 100
                        ? logPost.getContent().substring(0, 100) + "..."
                        : logPost.getContent())
                : (logPost.getTitle() != null ? logPost.getTitle() : "");

        // Get recipe info if linked
        UUID recipePublicId = null;
        String recipeTitle = null;
        if (logPost.getRecipeLog() != null && logPost.getRecipeLog().getRecipe() != null) {
            Recipe recipe = logPost.getRecipeLog().getRecipe();
            recipePublicId = recipe.getPublicId();
            recipeTitle = recipe.getTitle();
        }

        return AdminLogPostDto.builder()
                .publicId(logPost.getPublicId())
                .content(contentPreview)
                .creatorUsername(creator != null ? creator.getUsername() : "Unknown")
                .creatorPublicId(creator != null ? creator.getPublicId() : null)
                .recipePublicId(recipePublicId)
                .recipeTitle(recipeTitle)
                .commentCount(logPost.getCommentCount() != null ? logPost.getCommentCount() : 0)
                .likeCount(logPost.getSavedCount() != null ? logPost.getSavedCount() : 0)
                .isPrivate(logPost.getIsPrivate() != null && logPost.getIsPrivate())
                .createdAt(logPost.getCreatedAt())
                .build();
    }

    // ==================== COMMENTS ====================

    @Transactional(readOnly = true)
    public Page<AdminCommentDto> getComments(String content, String username, int page, int size) {
        Pageable pageable = PageRequest.of(page, size);

        Page<Comment> comments;
        boolean hasContent = content != null && !content.isBlank();
        boolean hasUsername = username != null && !username.isBlank();

        if (hasContent && hasUsername) {
            comments = commentRepository.findAllForAdminByContentAndUsername(content, username, pageable);
        } else if (hasContent) {
            comments = commentRepository.findAllForAdminByContent(content, pageable);
        } else if (hasUsername) {
            comments = commentRepository.findAllForAdminByUsername(username, pageable);
        } else {
            comments = commentRepository.findAllForAdmin(pageable);
        }

        return comments.map(this::mapToCommentDto);
    }

    @Transactional
    public int deleteComments(List<UUID> publicIds) {
        List<Comment> comments = commentRepository.findByPublicIdIn(publicIds);
        int deletedCount = 0;

        for (Comment comment : comments) {
            // Decrement parent reply count if this is a reply
            if (!comment.isTopLevel() && comment.getParent() != null) {
                Comment parent = comment.getParent();
                parent.decrementReplyCount();
                commentRepository.save(parent);
            }

            // Decrement comment count on log post
            LogPost logPost = comment.getLogPost();
            if (logPost != null) {
                logPost.setCommentCount(Math.max(0,
                        (logPost.getCommentCount() == null ? 0 : logPost.getCommentCount()) - 1));
                logPostRepository.save(logPost);
            }

            comment.softDelete();
            commentRepository.save(comment);
            deletedCount++;
            log.info("Admin deleted comment: {}", comment.getPublicId());
        }

        return deletedCount;
    }

    private AdminCommentDto mapToCommentDto(Comment comment) {
        User creator = comment.getCreator();

        return AdminCommentDto.builder()
                .publicId(comment.getPublicId())
                .content(comment.getContent())
                .creatorUsername(creator != null ? creator.getUsername() : "Unknown")
                .creatorPublicId(creator != null ? creator.getPublicId() : null)
                .logPostPublicId(comment.getLogPost() != null ? comment.getLogPost().getPublicId() : null)
                .isTopLevel(comment.isTopLevel())
                .replyCount(comment.getReplyCount() != null ? comment.getReplyCount() : 0)
                .likeCount(comment.getLikeCount() != null ? comment.getLikeCount() : 0)
                .createdAt(comment.getCreatedAt())
                .build();
    }

    // ==================== HELPERS ====================

    private Map<Long, User> getUserMap(List<Long> userIds) {
        if (userIds.isEmpty()) {
            return Map.of();
        }
        return userRepository.findAllById(userIds)
                .stream()
                .collect(Collectors.toMap(User::getId, Function.identity()));
    }
}
