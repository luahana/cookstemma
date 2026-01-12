package com.pairingplanet.pairing_planet.service;

import com.pairingplanet.pairing_planet.domain.entity.image.Image;
import com.pairingplanet.pairing_planet.domain.entity.log_post.LogPost;
import com.pairingplanet.pairing_planet.domain.entity.recipe.Recipe;
import com.pairingplanet.pairing_planet.domain.entity.user.User;
import com.pairingplanet.pairing_planet.domain.enums.AccountStatus;
import com.pairingplanet.pairing_planet.domain.enums.ImageType;
import com.pairingplanet.pairing_planet.dto.log_post.LogPostSummaryDto;
import com.pairingplanet.pairing_planet.dto.recipe.RecipeSummaryDto;
import com.pairingplanet.pairing_planet.dto.user.MyProfileResponseDto;
import com.pairingplanet.pairing_planet.dto.user.UpdateProfileRequestDto;
import com.pairingplanet.pairing_planet.dto.user.UserDto;
import com.pairingplanet.pairing_planet.repository.image.ImageRepository;
import com.pairingplanet.pairing_planet.repository.log_post.LogPostRepository;
import com.pairingplanet.pairing_planet.repository.recipe.RecipeLogRepository;
import com.pairingplanet.pairing_planet.repository.recipe.RecipeRepository;
import com.pairingplanet.pairing_planet.repository.recipe.SavedRecipeRepository;
import com.pairingplanet.pairing_planet.repository.user.UserRepository;
import com.pairingplanet.pairing_planet.security.UserPrincipal;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Slice;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
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
                .recipeCount(recipeRepository.countByCreatorIdAndIsDeletedFalse(userId))
                .logCount(logPostRepository.countByCreatorIdAndIsDeletedFalse(userId))
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
        long recipeCount = recipeRepository.countByCreatorIdAndIsDeletedFalse(userId);
        long logCount = logPostRepository.countByCreatorIdAndIsDeletedFalse(userId);

        // Calculate gamification level
        List<Object[]> outcomeCounts = recipeLogRepository.countByOutcomeForUser(userId);
        int successCount = 0, partialCount = 0, failedCount = 0;
        for (Object[] row : outcomeCounts) {
            String outcome = (String) row[0];
            int count = ((Number) row[1]).intValue();
            if ("SUCCESS".equals(outcome)) successCount = count;
            else if ("PARTIAL".equals(outcome)) partialCount = count;
            else if ("FAILED".equals(outcome)) failedCount = count;
        }

        int totalXp = cookingDnaService.calculateTotalXp(recipeCount, successCount, partialCount, failedCount);
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

        // 1. 사용자명 중복 체크 및 변경 로직 동일

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

        return UserDto.from(user, urlPrefix);
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
            recipes = recipeRepository.findByCreatorIdAndIsDeletedFalseAndParentRecipeIsNullOrderByCreatedAtDesc(userId, pageable);
        } else if ("variants".equalsIgnoreCase(typeFilter)) {
            recipes = recipeRepository.findByCreatorIdAndIsDeletedFalseAndParentRecipeIsNotNullOrderByCreatedAtDesc(userId, pageable);
        } else {
            recipes = recipeRepository.findByCreatorIdAndIsDeletedFalseOrderByCreatedAtDesc(userId, pageable);
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
        Slice<LogPost> logs = logPostRepository.findByCreatorIdAndIsDeletedFalseOrderByCreatedAtDesc(userId, pageable);

        return logs.map(this::convertToLogSummary);
    }

    private RecipeSummaryDto convertToRecipeSummary(Recipe recipe) {
        User creator = userRepository.findById(recipe.getCreatorId()).orElse(null);
        UUID creatorPublicId = creator != null ? creator.getPublicId() : null;
        String creatorName = creator != null ? creator.getUsername() : "Unknown";

        String foodName = getFoodName(recipe);

        String thumbnail = recipe.getImages().stream()
                .filter(img -> img.getType() == ImageType.THUMBNAIL)
                .findFirst()
                .map(img -> urlPrefix + "/" + img.getStoredFilename())
                .orElse(null);

        int variantCount = (int) recipeRepository.countByRootRecipeIdAndIsDeletedFalse(recipe.getId());
        int logCount = (int) recipeLogRepository.countByRecipeId(recipe.getId());
        String rootTitle = recipe.getRootRecipe() != null ? recipe.getRootRecipe().getTitle() : null;

        return new RecipeSummaryDto(
                recipe.getPublicId(),
                foodName,
                recipe.getFoodMaster().getPublicId(),
                recipe.getTitle(),
                recipe.getDescription(),
                recipe.getCulinaryLocale(),
                creatorPublicId,
                creatorName,
                thumbnail,
                variantCount,
                logCount,
                recipe.getParentRecipe() != null ? recipe.getParentRecipe().getPublicId() : null,
                recipe.getRootRecipe() != null ? recipe.getRootRecipe().getPublicId() : null,
                rootTitle
        );
    }

    private LogPostSummaryDto convertToLogSummary(LogPost log) {
        User creator = userRepository.findById(log.getCreatorId()).orElse(null);
        UUID creatorPublicId = creator != null ? creator.getPublicId() : null;
        String creatorName = creator != null ? creator.getUsername() : "Unknown";

        String thumbnailUrl = log.getImages().stream()
                .findFirst()
                .map(img -> urlPrefix + "/" + img.getStoredFilename())
                .orElse(null);

        return new LogPostSummaryDto(
                log.getPublicId(),
                log.getTitle(),
                log.getRecipeLog() != null ? log.getRecipeLog().getOutcome() : null,
                thumbnailUrl,
                creatorPublicId,
                creatorName
        );
    }

    private String getFoodName(Recipe recipe) {
        Map<String, String> nameMap = recipe.getFoodMaster().getName();
        String locale = recipe.getCulinaryLocale();

        if (locale != null && nameMap.containsKey(locale)) {
            return nameMap.get(locale);
        }
        if (nameMap.containsKey("en-US")) {
            return nameMap.get("en-US");
        }
        return nameMap.values().stream().findFirst().orElse("Unknown Food");
    }
}