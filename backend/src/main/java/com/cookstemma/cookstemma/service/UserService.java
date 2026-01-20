package com.cookstemma.cookstemma.service;

import com.cookstemma.cookstemma.domain.entity.hashtag.Hashtag;
import com.cookstemma.cookstemma.domain.entity.image.Image;
import com.cookstemma.cookstemma.domain.entity.log_post.LogPost;
import com.cookstemma.cookstemma.domain.entity.recipe.Recipe;
import com.cookstemma.cookstemma.domain.entity.user.User;
import com.cookstemma.cookstemma.domain.enums.AccountStatus;
import com.cookstemma.cookstemma.domain.enums.ImageType;
import com.cookstemma.cookstemma.dto.log_post.LogPostSummaryDto;
import com.cookstemma.cookstemma.dto.recipe.RecipeSummaryDto;
import com.cookstemma.cookstemma.dto.user.AcceptLegalTermsRequestDto;
import com.cookstemma.cookstemma.dto.user.MyProfileResponseDto;
import com.cookstemma.cookstemma.dto.user.UpdateProfileRequestDto;
import com.cookstemma.cookstemma.dto.user.UserDto;
import com.cookstemma.cookstemma.repository.image.ImageRepository;
import com.cookstemma.cookstemma.repository.log_post.LogPostRepository;
import com.cookstemma.cookstemma.repository.recipe.RecipeLogRepository;
import com.cookstemma.cookstemma.repository.recipe.RecipeRepository;
import com.cookstemma.cookstemma.repository.recipe.SavedRecipeRepository;
import com.cookstemma.cookstemma.repository.user.UserRepository;
import com.cookstemma.cookstemma.security.UserPrincipal;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Slice;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.Optional;
import java.time.temporal.ChronoUnit;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class UserService {

    private final UserRepository userRepository;
    private final ImageService imageService;
    private final RecipeRepository recipeRepository;
    private final RecipeLogRepository recipeLogRepository;
    private final ImageRepository imageRepository;
    private final LogPostRepository logPostRepository;
    private final SavedRecipeRepository savedRecipeRepository;
    private final CookingDnaService cookingDnaService;

    @Value("${file.upload.url-prefix}")
    private String urlPrefix;

    /**
     * [내 정보] UserPrincipal 기반 상세 조회 (기획서 7번 반영)
     */
    public MyProfileResponseDto getMyProfile(UserPrincipal principal) {
        // principal에 이미 담긴 Long ID를 사용하여 DB 부하를 줄입니다.
        User user = userRepository.findById(principal.getId())
                .orElseThrow(() -> new IllegalArgumentException("User not found"));

        Long userId = user.getId();

        // 활동 내역: 레시피, 로그, 저장 개수
        return MyProfileResponseDto.builder()
                .user(UserDto.from(user, urlPrefix))
                .recipeCount(recipeRepository.countByCreatorIdAndDeletedAtIsNull(userId))
                .logCount(logPostRepository.countByCreatorIdAndDeletedAtIsNull(userId))
                .savedCount(savedRecipeRepository.countByUserId(userId))
                .build();
    }

    /**
     * 사용자 상세 정보 조회 (공통)
     * Returns user profile with recipe and log counts, including gamification level
     */
    public UserDto getUserProfile(UUID publicId) {
        User user = userRepository.findByPublicId(publicId)
                .orElseThrow(() -> new IllegalArgumentException("User not found"));

        Long userId = user.getId();
        long recipeCount = recipeRepository.countByCreatorIdAndDeletedAtIsNull(userId);
        long logCount = logPostRepository.countByCreatorIdAndDeletedAtIsNull(userId);

        // Calculate gamification level using rating-based XP
        List<Object[]> ratingCounts = recipeLogRepository.countByRatingForUser(userId);
        int totalRatingXp = 0;
        for (Object[] row : ratingCounts) {
            Integer rating = (Integer) row[0];
            Long count = (Long) row[1];
            if (rating != null && count != null) {
                // rating * 6 XP per log (1=6, 2=12, 3=18, 4=24, 5=30)
                totalRatingXp += rating * 6 * count.intValue();
            }
        }

        int totalXp = cookingDnaService.calculateTotalXp(recipeCount, totalRatingXp);
        int level = cookingDnaService.calculateLevel(totalXp);
        String levelName = cookingDnaService.getLevelName(level);

        return UserDto.from(user, urlPrefix, recipeCount, logCount, level, levelName);
    }

    /**
     * 내 프로필 수정
     */
    @Transactional
    public UserDto updateProfile(UserPrincipal principal, UpdateProfileRequestDto request) {
        User user = userRepository.findById(principal.getId())
                .orElseThrow(() -> new IllegalArgumentException("User not found"));

        // 1. Username update with duplicate check
        if (request.username() != null && !request.username().isBlank()) {
            String newUsername = request.username().trim();
            if (!newUsername.equals(user.getUsername())) {
                // Check if username is already taken by another user
                if (userRepository.existsByUsernameIgnoreCase(newUsername)) {
                    throw new IllegalArgumentException("Username is already taken");
                }
                user.setUsername(newUsername);
            }
        }

        // 2. 프로필 이미지 업데이트 (UUID 방식 적용)
        if (request.profileImagePublicId() != null) {
            // [개선] UUID로 직접 이미지 엔티티 조회
            Image profileImage = imageRepository.findByPublicId(request.profileImagePublicId())
                    .orElseThrow(() -> new IllegalArgumentException("Image not found"));

            // 이미지 상태를 ACTIVE로 변경
            imageService.activateImages(List.of(request.profileImagePublicId()), user);

            // [개선] 문자열 파싱 없이 이미지 엔티티의 파일명을 바로 저장
            user.setProfileImageUrl(profileImage.getStoredFilename());
        }

        // 3. 성별 업데이트
        if (request.gender() != null) {
            user.setGender(request.gender());
        }

        // 4. 생년월일 업데이트
        if (request.birthDate() != null) {
            user.setBirthDate(request.birthDate());
        }

        // 5. 언어 설정 업데이트
        if (request.locale() != null) {
            user.setLocale(request.locale());
        }

        // 6. 기본 요리 스타일 업데이트
        if (request.defaultCookingStyle() != null) {
            user.setDefaultCookingStyle(request.defaultCookingStyle());
        }

        // 6b. 측정 단위 선호 업데이트
        if (request.measurementPreference() != null) {
            user.setMeasurementPreference(request.measurementPreference());
        }

        // 7. Bio update with sanitization
        if (request.bio() != null) {
            user.setBio(sanitizeBio(request.bio()));
        }

        // 8. YouTube URL update with normalization
        if (request.youtubeUrl() != null) {
            user.setYoutubeUrl(normalizeYoutubeUrl(request.youtubeUrl()));
        }

        // 9. Instagram handle update with normalization
        if (request.instagramHandle() != null) {
            user.setInstagramHandle(normalizeInstagramHandle(request.instagramHandle()));
        }

        return UserDto.from(user, urlPrefix);
    }

    /**
     * Accept legal terms (Terms of Service and Privacy Policy)
     * Records the acceptance timestamp and version for compliance tracking.
     */
    @Transactional
    public UserDto acceptLegalTerms(UserPrincipal principal, AcceptLegalTermsRequestDto request) {
        User user = userRepository.findById(principal.getId())
                .orElseThrow(() -> new IllegalArgumentException("User not found"));

        Instant now = Instant.now();

        // Record terms acceptance
        user.setTermsAcceptedAt(now);
        user.setTermsVersion(request.termsVersion());

        // Record privacy policy acceptance
        user.setPrivacyAcceptedAt(now);
        user.setPrivacyVersion(request.privacyVersion());

        // Record marketing preference
        if (request.marketingAgreed() != null) {
            user.setMarketingAgreed(request.marketingAgreed());
        }

        return UserDto.from(user, urlPrefix);
    }

    /**
     * Sanitize bio text - remove HTML tags and normalize whitespace
     */
    private String sanitizeBio(String bio) {
        if (bio == null || bio.isBlank()) return null;
        // Remove HTML tags, normalize whitespace, trim
        return bio.replaceAll("<[^>]*>", "")
                .replaceAll("\\s+", " ")
                .trim();
    }

    /**
     * Normalize YouTube URL - ensure HTTPS prefix
     */
    private String normalizeYoutubeUrl(String url) {
        if (url == null || url.isBlank()) return null;
        url = url.trim();
        // Ensure HTTPS prefix
        if (!url.startsWith("http")) {
            url = "https://" + url;
        }
        return url.replace("http://", "https://");
    }

    /**
     * Normalize Instagram handle - extract handle from URL, remove @ prefix
     */
    private String normalizeInstagramHandle(String handle) {
        if (handle == null || handle.isBlank()) return null;
        handle = handle.trim();
        // If it's a full URL, extract handle
        if (handle.contains("instagram.com/")) {
            handle = handle.replaceAll(".*instagram\\.com/", "")
                    .replaceAll("[/?].*", "");
        }
        // Remove @ prefix if present, store clean handle
        return handle.startsWith("@") ? handle.substring(1) : handle;
    }

    /**
     * 계정 삭제 (소프트 삭제)
     * 30일 유예 기간 후 실제 삭제 처리
     * 사용자의 이미지도 함께 소프트 삭제됨
     */
    @Transactional
    public void deleteAccount(UserPrincipal principal) {
        User user = userRepository.findById(principal.getId())
                .orElseThrow(() -> new IllegalArgumentException("User not found"));

        Instant now = Instant.now();
        Instant scheduledDeletion = now.plus(30, ChronoUnit.DAYS);

        // Soft-delete user
        user.setStatus(AccountStatus.DELETED);
        user.setDeletedAt(now);
        user.setDeleteScheduledAt(scheduledDeletion);
        user.setAppRefreshToken(null); // 모든 세션 무효화

        // Soft-delete user's images (same schedule as user)
        imageService.softDeleteAllByUploader(user.getId(), now, scheduledDeletion);
    }

    /**
     * 삭제된 계정 복구 (로그인 시 호출)
     * 사용자의 소프트 삭제된 이미지도 함께 복구됨
     */
    @Transactional
    public void restoreDeletedAccount(User user) {
        if (user.getStatus() == AccountStatus.DELETED && user.getDeletedAt() != null) {
            // Restore user
            user.setStatus(AccountStatus.ACTIVE);
            user.setDeletedAt(null);
            user.setDeleteScheduledAt(null);

            // Restore user's soft-deleted images
            imageService.restoreAllByUploader(user.getId());
        }
    }

    /**
     * 유예 기간이 지난 삭제된 계정 영구 삭제 (스케줄러에서 호출)
     * 30일 유예 기간이 지나면 계정 및 관련 데이터 영구 삭제
     * 이미지는 S3에서도 삭제됨
     */
    @Transactional
    public void purgeExpiredDeletedAccounts() {
        Instant now = Instant.now();
        List<User> expiredUsers = userRepository.findByStatusAndDeleteScheduledAtBefore(
                AccountStatus.DELETED, now);

        for (User user : expiredUsers) {
            // Hard-delete images from S3 and DB first
            imageService.hardDeleteAllByUploader(user.getId());

            // Then delete user (other data handled by cascade)
            userRepository.delete(user);
        }
    }

    /**
     * Get a user's public recipes
     * @param publicId user's publicId
     * @param typeFilter "original" (only root recipes), "variants" (only variants), or null (all)
     */
    public Slice<RecipeSummaryDto> getUserRecipes(UUID publicId, String typeFilter, Pageable pageable) {
        User user = userRepository.findByPublicId(publicId)
                .orElseThrow(() -> new IllegalArgumentException("User not found"));

        Long userId = user.getId();
        Slice<Recipe> recipes;

        if ("original".equalsIgnoreCase(typeFilter)) {
            recipes = recipeRepository.findByCreatorIdAndDeletedAtIsNullAndParentRecipeIsNullOrderByCreatedAtDesc(userId, pageable);
        } else if ("variants".equalsIgnoreCase(typeFilter)) {
            recipes = recipeRepository.findByCreatorIdAndDeletedAtIsNullAndParentRecipeIsNotNullOrderByCreatedAtDesc(userId, pageable);
        } else {
            recipes = recipeRepository.findByCreatorIdAndDeletedAtIsNullOrderByCreatedAtDesc(userId, pageable);
        }

        return recipes.map(this::convertToRecipeSummary);
    }

    /**
     * Get a user's public logs
     */
    public Slice<LogPostSummaryDto> getUserLogs(UUID publicId, Pageable pageable) {
        User user = userRepository.findByPublicId(publicId)
                .orElseThrow(() -> new IllegalArgumentException("User not found"));

        Long userId = user.getId();
        Slice<LogPost> logs = logPostRepository.findByCreatorIdAndDeletedAtIsNullOrderByCreatedAtDesc(userId, pageable);

        return logs.map(this::convertToLogSummary);
    }

    private RecipeSummaryDto convertToRecipeSummary(Recipe recipe) {
        User creator = userRepository.findById(recipe.getCreatorId()).orElse(null);
        UUID creatorPublicId = creator != null ? creator.getPublicId() : null;
        String userName = creator != null ? creator.getUsername() : "Unknown";

        String foodName = getFoodName(recipe);

        String thumbnail = recipe.getCoverImages().stream()
                .filter(img -> img.getType() == ImageType.COVER)
                .findFirst()
                .map(img -> urlPrefix + "/" + img.getStoredFilename())
                .orElse(null);

        int variantCount = (int) recipeRepository.countByRootRecipeIdAndDeletedAtIsNull(recipe.getId());
        int logCount = (int) recipeLogRepository.countByRecipeId(recipe.getId());
        String rootTitle = recipe.getRootRecipe() != null ? recipe.getRootRecipe().getTitle() : null;
        List<String> hashtags = recipe.getHashtags().stream()
                .map(Hashtag::getName)
                .limit(3)
                .toList();

        return new RecipeSummaryDto(
                recipe.getPublicId(),
                foodName,
                recipe.getFoodMaster().getPublicId(),
                recipe.getTitle(),
                recipe.getDescription(),
                recipe.getCookingStyle(),
                creatorPublicId,
                userName,
                thumbnail,
                variantCount,
                logCount,
                recipe.getParentRecipe() != null ? recipe.getParentRecipe().getPublicId() : null,
                recipe.getRootRecipe() != null ? recipe.getRootRecipe().getPublicId() : null,
                rootTitle,
                recipe.getServings() != null ? recipe.getServings() : 2,
                recipe.getCookingTimeRange() != null ? recipe.getCookingTimeRange().name() : "MIN_30_TO_60",
                hashtags,
                recipe.getTitleTranslations(),
                recipe.getDescriptionTranslations()
        );
    }

    private LogPostSummaryDto convertToLogSummary(LogPost log) {
        User creator = userRepository.findById(log.getCreatorId()).orElse(null);
        UUID creatorPublicId = creator != null ? creator.getPublicId() : null;
        String userName = creator != null ? creator.getUsername() : "Unknown";

        String thumbnailUrl = log.getImages().stream()
                .findFirst()
                .map(img -> urlPrefix + "/" + img.getStoredFilename())
                .orElse(null);

        // Get food name, recipe title, and variant status from linked recipe
        String foodName = null;
        String recipeTitle = null;
        Boolean isVariant = null;
        if (log.getRecipeLog() != null && log.getRecipeLog().getRecipe() != null) {
            Recipe recipe = log.getRecipeLog().getRecipe();
            foodName = recipe.getFoodMaster().getNameByLocale(recipe.getCookingStyle());
            recipeTitle = recipe.getTitle();
            isVariant = recipe.getRootRecipe() != null;
        }

        // Get hashtag names
        List<String> hashtags = log.getHashtags().stream()
                .map(Hashtag::getName)
                .toList();

        return new LogPostSummaryDto(
                log.getPublicId(),
                log.getTitle(),
                log.getContent(),
                log.getRecipeLog() != null ? log.getRecipeLog().getRating() : null,
                thumbnailUrl,
                creatorPublicId,
                userName,
                foodName,
                recipeTitle,
                hashtags,
                isVariant
        );
    }

    private String getFoodName(Recipe recipe) {
        Map<String, String> nameMap = recipe.getFoodMaster().getName();
        String locale = recipe.getCookingStyle();

        if (locale != null && nameMap.containsKey(locale)) {
            return nameMap.get(locale);
        }
        if (nameMap.containsKey("en-US")) {
            return nameMap.get("en-US");
        }
        return nameMap.values().stream().findFirst().orElse("Unknown Food");
    }

    /**
     * Get all active user public IDs for sitemap generation
     * Returns up to 1000 active users, ordered by creation date
     */
    public List<UUID> getAllUserIdsForSitemap() {
        return userRepository.findPublicIdsByStatusOrderByCreatedAtDesc(
                AccountStatus.ACTIVE,
                org.springframework.data.domain.PageRequest.of(0, 1000)
        );
    }

    /**
     * Check if a username is available for use
     * @param username the username to check
     * @param currentUserPublicId the current user's publicId (to allow keeping their own username)
     * @return true if the username is available or belongs to the current user
     */
    public boolean isUsernameAvailable(String username, UUID currentUserPublicId) {
        Optional<User> existingUser = userRepository.findByUsernameIgnoreCase(username);
        if (existingUser.isEmpty()) {
            return true;
        }
        // If it exists but belongs to current user, still "available" for them
        return existingUser.get().getPublicId().equals(currentUserPublicId);
    }
}