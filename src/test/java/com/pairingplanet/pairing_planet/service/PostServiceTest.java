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
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.Map;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.BDDMockito.given;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.times;

@ExtendWith(MockitoExtension.class)
class PostServiceTest {

    @InjectMocks
    private PostService postService;

    @Mock private PostRepository postRepository;
    @Mock private PairingMapRepository pairingMapRepository;
    @Mock private FoodMasterRepository foodMasterRepository;
    @Mock private UserSuggestedFoodRepository userSuggestedFoodRepository;
    @Mock private ContextTagRepository contextTagRepository;
    @Mock private UserRepository userRepository;

    @Test
    @DisplayName("FR-41: 새로운 음식을 입력하면 UserSuggestedFood 저장 및 임시 FoodMaster가 생성되어야 한다")
    void createPost_with_NewFood() {
        // given
        Long userId = 1L;
        User user = User.builder().username("tester").build();

        // Request: Food1 ID 없이 이름만 존재
        FoodRequestDto newFoodReq = new FoodRequestDto(null, "New Burger", "en");
        CreatePostRequestDto request = new CreatePostRequestDto(
                newFoodReq, null, null, null, null, "Content", true
        );

        // Mocks
        given(userRepository.findById(userId)).willReturn(Optional.of(user));
        given(contextTagRepository.findById(any())).willReturn(Optional.of(ContextTag.builder().build())); // Default Tag

        // Mock: 음식 생성 로직
        FoodMaster tempFood = FoodMaster.builder().name(Map.of("en", "New Burger")).isVerified(false).build();
        given(foodMasterRepository.save(any(FoodMaster.class))).willReturn(tempFood);

        // Mock: 페어링 생성 로직
        PairingMap newPairing = PairingMap.builder().food1(tempFood).build();
        given(pairingMapRepository.findExistingPairing(any(), any(), any(), any())).willReturn(Optional.empty()); // 기존 페어링 없음
        given(pairingMapRepository.save(any(PairingMap.class))).willReturn(newPairing);

        // Mock: 포스트 저장
        given(postRepository.save(any(Post.class))).willAnswer(invocation -> {
            Post p = invocation.getArgument(0);
            // ID가 생성된 것처럼 리턴
            return p;
        });

        // when
        postService.createPost(userId, request);

        // then
        // 1. 제안된 음식 큐에 저장되었는지 확인
        verify(userSuggestedFoodRepository, times(1)).save(any(UserSuggestedFood.class));
        // 2. 임시 FoodMaster가 저장되었는지 확인
        verify(foodMasterRepository, times(1)).save(any(FoodMaster.class));
        // 3. 포스트가 저장되었는지 확인
        verify(postRepository, times(1)).save(any(Post.class));
    }

    @Test
    @DisplayName("FR-45: Verdict을 끄면(False), 댓글 기능도 강제로 꺼져야 한다(False)")
    void createPost_disable_verdict_logic() {
        // given
        Long userId = 1L;
        User user = User.builder().username("tester").build();
        FoodRequestDto food1Req = new FoodRequestDto(10L, "Pizza", "en");

        // Request: Verdict Enabled = FALSE
        CreatePostRequestDto request = new CreatePostRequestDto(
                food1Req, null, 1L, 1L, null, "Content", false
        );

        // Mocks (단순 통과용)
        given(userRepository.findById(userId)).willReturn(Optional.of(user));
        given(foodMasterRepository.findById(10L)).willReturn(Optional.of(FoodMaster.builder().build()));
        given(contextTagRepository.findById(any())).willReturn(Optional.of(ContextTag.builder().build()));
        given(pairingMapRepository.findExistingPairing(any(), any(), any(), any())).willReturn(Optional.of(PairingMap.builder().build()));

        given(postRepository.save(any(Post.class))).willAnswer(invocation -> invocation.getArgument(0));

        // when
        PostResponseDto response = postService.createPost(userId, request);

        // then
        assertThat(response.verdictEnabled()).isFalse();
        assertThat(response.commentsEnabled()).isFalse(); // FR-45 검증
    }
}