package com.pairingplanet.pairing_planet.service;

import com.pairingplanet.pairing_planet.domain.entity.context.ContextTag;
import com.pairingplanet.pairing_planet.domain.entity.food.FoodMaster;
import com.pairingplanet.pairing_planet.domain.entity.food.UserSuggestedFood;
import com.pairingplanet.pairing_planet.domain.entity.pairing.PairingMap;
import com.pairingplanet.pairing_planet.domain.entity.post.Post;
import com.pairingplanet.pairing_planet.domain.entity.user.User;
import com.pairingplanet.pairing_planet.dto.food.FoodRequestDto;
import com.pairingplanet.pairing_planet.dto.post.CreatePostRequestDto;
import com.pairingplanet.pairing_planet.dto.post.PostResponseDto;
import com.pairingplanet.pairing_planet.repository.context.ContextTagRepository;
import com.pairingplanet.pairing_planet.repository.food.FoodMasterRepository;
import com.pairingplanet.pairing_planet.repository.food.UserSuggestedFoodRepository;
import com.pairingplanet.pairing_planet.repository.pairing.PairingMapRepository;
import com.pairingplanet.pairing_planet.repository.post.PostRepository;
import com.pairingplanet.pairing_planet.repository.user.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Map;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class PostService {

    private final PostRepository postRepository;
    private final PairingMapRepository pairingMapRepository;
    private final FoodMasterRepository foodMasterRepository;
    private final UserSuggestedFoodRepository userSuggestedFoodRepository;
    private final ContextTagRepository contextTagRepository;
    private final UserRepository userRepository; // 유저 조회를 위해 필요

    // Default IDs (DB에 미리 세팅된 Default 태그 ID)
    private static final Long DEFAULT_WHEN_ID = 1L;
    private static final Long DEFAULT_DIETARY_ID = 1L;

    @Transactional
    public PostResponseDto createPost(Long userId, CreatePostRequestDto request) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("User not found"));

        // 1. Food 처리 (FR-40, FR-41)
        FoodMaster food1 = getOrCreateFood(request.food1(), user);
        FoodMaster food2 = (request.food2() != null && request.food2().name() != null)
                ? getOrCreateFood(request.food2(), user)
                : null; // FR-40: food2는 optional

        // 2. Context Tags 처리 (FR-42)
        // 값이 없으면 Default 값 적용
        Long whenId = request.whenContextId() != null ? request.whenContextId() : DEFAULT_WHEN_ID;
        Long dietaryId = request.dietaryTagId() != null ? request.dietaryTagId() : DEFAULT_DIETARY_ID;

        ContextTag whenTag = contextTagRepository.findById(whenId)
                .orElseThrow(() -> new IllegalArgumentException("Invalid When Tag"));
        ContextTag dietaryTag = contextTagRepository.findById(dietaryId)
                .orElseThrow(() -> new IllegalArgumentException("Invalid Dietary Tag"));

        // 3. PairingMap 찾기 또는 생성
        // 기존에 등록된 페어링인지 확인하고 없으면 새로 만듭니다.
        PairingMap pairing = getOrCreatePairing(food1, food2, whenTag, dietaryTag);

        // 4. 설정 값 처리 (FR-44, FR-45)
        // Verdict Default = Enabled
        boolean isVerdictEnabled = request.verdictEnabled() != null ? request.verdictEnabled() : true;
        // FR-45: Verdict이 꺼져있으면 댓글도 강제로 꺼짐. Verdict이 켜져있으면 댓글도 켬 (기본값)
        boolean isCommentsEnabled = isVerdictEnabled;

        boolean isPrivate = request.isPrivate();
        if (isPrivate) {
            isCommentsEnabled = false;
            isVerdictEnabled = false;
        }

        // 5. Post 저장
        Post post = Post.builder()
                .pairing(pairing)
                .creator(user)
                .locale(user.getLocale() != null ? user.getLocale() : "en") // 유저 로케일 따름
                .content(request.content())
                .imageUrls(request.imageUrls()) // FR-43
                .verdictEnabled(isVerdictEnabled)
                .commentsEnabled(isCommentsEnabled)
                .isPrivate(isPrivate)
                .build();

        Post savedPost = postRepository.save(post);

        // 6. Response 변환
        return new PostResponseDto(
                savedPost.getId(),
                food1.getName().get("en"), // 다국어 처리 필요
                food2 != null ? food2.getName().get("en") : null,
                savedPost.getImageUrls(),
                savedPost.getContent(),
                savedPost.isVerdictEnabled(),
                savedPost.isCommentsEnabled(),
                savedPost.isPrivate()
        );
    }

    /**
     * FR-41: 기존 음식이면 반환, 없으면 UserSuggestedFood 등록 및 임시 FoodMaster 생성
     */
    private FoodMaster getOrCreateFood(FoodRequestDto foodReq, User user) {
        if (foodReq.id() != null) {
            return foodMasterRepository.findById(foodReq.id())
                    .orElseThrow(() -> new IllegalArgumentException("Food not found: " + foodReq.id()));
        }

        // ID가 없고 이름만 있는 경우 -> 유저 제안 음식
        String locale = foodReq.localeCode() != null ? foodReq.localeCode() : "en";

        // 1. UserSuggestedFood Queue에 저장
        UserSuggestedFood suggested = UserSuggestedFood.builder()
                .suggestedName(foodReq.name())
                .localeCode(locale)
                .user(user)
                .status(UserSuggestedFood.SuggestionStatus.PENDING)
                .build();
        userSuggestedFoodRepository.save(suggested);

        // 2. 포스팅을 위해 임시 FoodMaster 생성 (Unverified)
        // 카테고리는 '기타' 혹은 null 처리가 필요하나, FoodMaster 엔티티 제약조건에 따라 다름.
        // 여기서는 임시 빌더 패턴 사용
        FoodMaster tempFood = FoodMaster.builder()
                .name(Map.of(locale, foodReq.name())) // 다국어 맵
                .isVerified(false) // 검증되지 않음
                .build();

        return foodMasterRepository.save(tempFood);
    }

    private PairingMap getOrCreatePairing(FoodMaster f1, FoodMaster f2, ContextTag when, ContextTag dietary) {
        // PairingMapRepository에 findByFood1AndFood2AndWhenContext... 메서드가 있다고 가정
        // 순서(f1, f2)가 바뀐 경우도 고려해야 할 수 있음 (비즈니스 로직에 따라 결정)
        Long food2Id = (f2 != null) ? f2.getId() : null;

        return pairingMapRepository.findExistingPairing(f1.getId(), food2Id, when.getId(), dietary.getId())
                .orElseGet(() -> pairingMapRepository.save(
                        PairingMap.builder()
                                .food1(f1)
                                .food2(f2) // null 가능
                                .whenContext(when)
                                .dietaryContext(dietary)
                                .build()
                ));
    }
}