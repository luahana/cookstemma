package com.pairingplanet.pairing_planet.service;

import com.pairingplanet.pairing_planet.domain.entity.context.ContextTag;
import com.pairingplanet.pairing_planet.domain.entity.food.FoodMaster;
import com.pairingplanet.pairing_planet.domain.entity.food.UserSuggestedFood;
import com.pairingplanet.pairing_planet.domain.entity.image.Image;
import com.pairingplanet.pairing_planet.domain.entity.pairing.PairingMap;
import com.pairingplanet.pairing_planet.domain.entity.post.*;
import com.pairingplanet.pairing_planet.domain.entity.user.User;
import com.pairingplanet.pairing_planet.dto.food.FoodRequestDto;
import com.pairingplanet.pairing_planet.dto.post.CreatePostRequestDto;
import com.pairingplanet.pairing_planet.dto.post.PostResponseDto;
import com.pairingplanet.pairing_planet.repository.context.ContextTagRepository;
import com.pairingplanet.pairing_planet.repository.food.FoodMasterRepository;
import com.pairingplanet.pairing_planet.repository.food.UserSuggestedFoodRepository;
import com.pairingplanet.pairing_planet.repository.image.ImageRepository;
import com.pairingplanet.pairing_planet.repository.pairing.PairingMapRepository;
import com.pairingplanet.pairing_planet.repository.post.PostRepository;
import com.pairingplanet.pairing_planet.repository.user.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Map;
import java.util.UUID;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class PostService {
    private final PostRepository postRepository;
    private final PairingMapRepository pairingMapRepository;
    private final FoodMasterRepository foodMasterRepository;
    private final UserSuggestedFoodRepository userSuggestedFoodRepository;
    private final ContextTagRepository contextTagRepository;
    private final UserRepository userRepository;
    private final ImageRepository  imageRepository;
    private final ImageService imageService;

    @Value("${file.upload.url-prefix}")
    private String urlPrefix;

    // [변경] UUID 환경에서는 DB 생성 시 ID를 알 수 없으므로,
    // 클라이언트가 필수 값을 보내도록 강제하거나, DB에서 이름으로 'Default' 태그를 찾는 로직이 필요합니다.
    // 여기서는 요청에 값이 없을 경우 예외를 던지도록 처리하거나, 필요 시 이름으로 조회하는 로직을 추가해야 합니다.

    // ==========================================
    // 1. Create Methods
    // ==========================================

    @Transactional
    public PostResponseDto createDailyPost(UUID userId, CreatePostRequestDto request) {
        User user = getUser(userId);
        PairingMap pairing = processPairingLogic(user, request);

        boolean isPrivate = Boolean.TRUE.equals(request.isPrivate());
        boolean isCommentsEnabled = !isPrivate && (request.commentsEnabled() == null || request.commentsEnabled());

        DailyPost post = DailyPost.builder()
                .creator(user) // 내부는 User(Long id) 엔티티가 연결됨 (성능 OK)
                .pairing(pairing)
                .locale(user.getLocale() != null ? user.getLocale() : "en")
                .content(request.content())
                .isPrivate(isPrivate)
                .commentsEnabled(isCommentsEnabled)
                .build();

        Post savedPost = postRepository.save(post);

        imageService.activateImages(request.imageUrls());

        List<Image> images = imageRepository.findByStoredFilenameIn(
                request.imageUrls().stream().map(url -> url.replace(urlPrefix + "/", "")).toList()
        );
        for (Image image : images) image.setPost(post);

        return PostResponseDto.from(savedPost, urlPrefix);
    }

    @Transactional
    public PostResponseDto createReviewPost(UUID userId, CreatePostRequestDto request) { // [변경] Long -> UUID
        User user = getUser(userId);
        PairingMap pairing = processPairingLogic(user, request);

        boolean isPrivate = Boolean.TRUE.equals(request.isPrivate());
        boolean isVerdictEnabled = !isPrivate && (request.verdictEnabled() == null || request.verdictEnabled());
        boolean isCommentsEnabled = !isPrivate && isVerdictEnabled;

        ReviewPost post = ReviewPost.builder()
                .creator(user)
                .pairing(pairing)
                .locale(user.getLocale() != null ? user.getLocale() : "en")
                .content(request.content())
                .isPrivate(isPrivate)
                .commentsEnabled(isCommentsEnabled)
                .title(request.reviewTitle())
                .verdictEnabled(isVerdictEnabled)
                .build();

        Post savedPost = postRepository.save(post);

        imageService.activateImages(request.imageUrls());

        List<Image> images = imageRepository.findByStoredFilenameIn(
                request.imageUrls().stream().map(url -> url.replace(urlPrefix + "/", "")).toList()
        );
        for (Image image : images) image.setPost(post);

        return PostResponseDto.from(savedPost, urlPrefix);
    }

    @Transactional
    public PostResponseDto createRecipePost(UUID userId, CreatePostRequestDto request) { // [변경] Long -> UUID
        User user = getUser(userId);
        PairingMap pairing = processPairingLogic(user, request);

        boolean isPrivate = Boolean.TRUE.equals(request.isPrivate());
        boolean isCommentsEnabled = !isPrivate && (request.commentsEnabled() == null || request.commentsEnabled());

        RecipePost post = RecipePost.builder()
                .creator(user)
                .pairing(pairing)
                .locale(user.getLocale() != null ? user.getLocale() : "en")
                .content(request.content())
                .isPrivate(isPrivate)
                .commentsEnabled(isCommentsEnabled)
                .title(request.recipeTitle())
                .ingredients(request.ingredients())
                .cookingTime(request.cookingTime() != null ? request.cookingTime() : 0)
                .difficulty(request.difficulty() != null ? request.difficulty() : 1)
                .recipeData(request.recipeData())
                .build();

        Post savedPost = postRepository.save(post);

        imageService.activateImages(request.imageUrls());

        List<Image> images = imageRepository.findByStoredFilenameIn(
                request.imageUrls().stream().map(url -> url.replace(urlPrefix + "/", "")).toList()
        );
        for (Image image : images) image.setPost(post);

        imageService.activateImages(request.imageUrls());

        return PostResponseDto.from(savedPost, urlPrefix);
    }

    // ==========================================
    // 2. Update Method
    // ==========================================

    @Transactional
    public PostResponseDto updatePost(UUID userId, UUID postId, CreatePostRequestDto request) {
        Post post = postRepository.findByPublicId(postId)
                .orElseThrow(() -> new IllegalArgumentException("Post not found: " + postId));

        // 작성자 검증 (User 엔티티끼리 비교 or PublicId 비교)
        if (!post.getCreator().getPublicId().equals(userId)) {
            throw new IllegalArgumentException("Unauthorized: You are not the creator of this post.");
        }

        // 공통 필드 업데이트
        if (request.content() != null) post.updateContent(request.content());
        if (request.isPrivate() != null) post.setPrivate(request.isPrivate());

        // 타입별 필드 업데이트
        if (post instanceof ReviewPost review) {
            if (request.reviewTitle() != null) review.setTitle(request.reviewTitle());
            if (request.verdictEnabled() != null) review.setVerdictEnabled(request.verdictEnabled());
        }
        else if (post instanceof RecipePost recipe) {
            if (request.recipeTitle() != null) recipe.setTitle(request.recipeTitle());
            if (request.ingredients() != null) recipe.setIngredients(request.ingredients());
            if (request.cookingTime() != null) recipe.setCookingTime(request.cookingTime());
            if (request.difficulty() != null) recipe.setDifficulty(request.difficulty());
            if (request.recipeData() != null) recipe.setRecipeData(request.recipeData());
        }

        return PostResponseDto.from(post, urlPrefix);
    }

    // ==========================================
    // 3. Delete Method
    // ==========================================

    @Transactional
    public void deletePost(UUID userId, UUID postId) { // [변경] Long -> UUID
        // [변경] findByPublicId 사용
        Post post = postRepository.findByPublicId(postId)
                .orElseThrow(() -> new IllegalArgumentException("Post not found: " + postId));

        if (!post.getCreator().getPublicId().equals(userId)) {
            throw new IllegalArgumentException("Unauthorized");
        }

        post.softDelete();
    }

    // ==========================================
    // 4. Private Helper Methods
    // ==========================================

    private User getUser(UUID userId) {
        // [변경] findByPublicId 사용
        return userRepository.findByPublicId(userId)
                .orElseThrow(() -> new IllegalArgumentException("User not found"));
    }

    /**
     * 포스트 생성에 필요한 PairingMap을 준비하는 공통 로직
     */
    private PairingMap processPairingLogic(User user, CreatePostRequestDto request) {
        // 1. Food 처리 (UUID 기반)
        FoodMaster food1 = getOrCreateFood(request.food1(), user);
        FoodMaster food2 = (request.food2() != null && request.food2().name() != null)
                ? getOrCreateFood(request.food2(), user)
                : null;

        // 2. Context Tags 처리 (UUID 기반)
        // [변경] UUID는 DB 생성 값이므로 상수로 관리 불가 -> Request에서 받거나 DB 조회 필요
        // 여기서는 Request에 값이 필수라고 가정하거나, 없다면 예외 발생
        if (request.whenContextId() == null || request.dietaryContextId() == null) {
            throw new IllegalArgumentException("Context IDs are required.");
        }

        // [변경] findById -> findByPublicId
        ContextTag whenTag = contextTagRepository.findByPublicId(request.whenContextId())
                .orElseThrow(() -> new IllegalArgumentException("Invalid When Tag"));
        ContextTag dietaryTag = contextTagRepository.findByPublicId(request.dietaryContextId())
                .orElseThrow(() -> new IllegalArgumentException("Invalid Dietary Tag"));

        // 3. PairingMap 찾기 또는 생성
        return getOrCreatePairing(food1, food2, whenTag, dietaryTag);
    }

    private FoodMaster getOrCreateFood(FoodRequestDto foodReq, User user) {
        // [변경] id가 있다면 UUID일 것이므로 findByPublicId 사용
        if (foodReq.id() != null) {
            return foodMasterRepository.findByPublicId(foodReq.id())
                    .orElseThrow(() -> new IllegalArgumentException("Food not found: " + foodReq.id()));
        }

        String locale = foodReq.localeCode() != null ? foodReq.localeCode() : "en";

        // 1. UserSuggestedFood Queue에 저장
        UserSuggestedFood suggested = UserSuggestedFood.builder()
                .suggestedName(foodReq.name())
                .localeCode(locale)
                .user(user)
                .status(UserSuggestedFood.SuggestionStatus.PENDING)
                .build();
        userSuggestedFoodRepository.save(suggested);

        // 2. 임시 FoodMaster 생성
        // (BaseEntity의 @Builder.Default publicId 덕분에 UUID는 자동 생성됨)
        FoodMaster tempFood = FoodMaster.builder()
                .name(Map.of(locale, foodReq.name()))
                .isVerified(false)
                .build();

        return foodMasterRepository.save(tempFood);
    }

    private PairingMap getOrCreatePairing(FoodMaster f1, FoodMaster f2, ContextTag when, ContextTag dietary) {
        // Pairing 조회 로직은 내부적으로 Join이 많으므로 성능을 위해 내부 ID(Long)를 사용해도 무방
        // 이미 위에서 f1, f2, when, dietary 엔티티를 찾아왔으므로 getId() (Long) 호출 가능
        Long food2Id = (f2 != null) ? f2.getId() : null;

        return pairingMapRepository.findExistingPairing(f1.getId(), food2Id, when.getId(), dietary.getId())
                .orElseGet(() -> pairingMapRepository.save(
                        PairingMap.builder()
                                .food1(f1)
                                .food2(f2)
                                .whenContext(when)
                                .dietaryContext(dietary)
                                .build()
                ));
    }
}