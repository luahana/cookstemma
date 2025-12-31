package com.pairingplanet.pairing_planet.service;

import com.pairingplanet.pairing_planet.domain.entity.context.ContextTag;
import com.pairingplanet.pairing_planet.domain.entity.post.Post;
import com.pairingplanet.pairing_planet.domain.entity.user.User;
import com.pairingplanet.pairing_planet.dto.post.CursorResponse;
import com.pairingplanet.pairing_planet.dto.post.MyPostResponseDto;
import com.pairingplanet.pairing_planet.dto.user.UpdateProfileRequestDto;
import com.pairingplanet.pairing_planet.dto.user.UserDto;
import com.pairingplanet.pairing_planet.repository.context.ContextTagRepository;
import com.pairingplanet.pairing_planet.repository.post.PostRepository;
import com.pairingplanet.pairing_planet.repository.user.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Slice;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

import static com.pairingplanet.pairing_planet.dto.search.SearchCursorDto.SAFE_MIN_DATE;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class UserService {

    private final UserRepository userRepository;
    private final PostRepository postRepository;
    private final ImageService imageService;
    private final ContextTagRepository contextTagRepository;

    @Value("${file.upload.url-prefix}")
    private String urlPrefix;

    /**
     * 사용자 상세 정보 조회 (공통)
     * @param userId 조회 대상의 Public ID
     */
    public UserDto getUserProfile(UUID userId) {
        User user = userRepository.findByPublicId(userId)
                .orElseThrow(() -> new IllegalArgumentException("User not found"));

        // 1. 유저의 preferredDietaryId(Long)를 이용해 ContextTag의 UUID 조회
        UUID dietaryUuid = null;
        if (user.getPreferredDietaryId() != null) {
            dietaryUuid = contextTagRepository.findById(user.getPreferredDietaryId())
                    .map(ContextTag::getPublicId)
                    .orElse(null);
        }

        // 2. 조회된 UUID를 포함하여 UserDto 생성
        return UserDto.from(user, urlPrefix, dietaryUuid); //를 통해 이미지 URL 및 이니셜 처리
    }

    /**
     * 내 프로필 수정
     */
    @Transactional
    public UserDto updateProfile(UUID userId, UpdateProfileRequestDto request) {
        User user = userRepository.findByPublicId(userId)
                .orElseThrow(() -> new IllegalArgumentException("User not found"));

        if (request.username() != null && !request.username().equals(user.getUsername())) {
            if (userRepository.existsByUsername(request.username())) {
                throw new IllegalArgumentException("Username already exists");
            }
            user.setUsername(request.username());
        }

        if (request.profileImageUrl() != null) {
            String fileName = request.profileImageUrl().replace(urlPrefix + "/", "");
            imageService.activateImages(List.of(request.profileImageUrl()));
            user.setProfileImageUrl(fileName);
        }

        if (request.preferredDietaryId() != null) {
            // ContextTagRepository를 통해 해당 UUID를 가진 태그의 내부 Long ID를 가져옴
            Long internalId = contextTagRepository.findByPublicId(request.preferredDietaryId())
                    .map(ContextTag::getId)
                    .orElseThrow(() -> new IllegalArgumentException("Invalid Dietary ID"));

            user.setPreferredDietaryId(internalId); //
        }

        if (request.gender() != null) user.setGender(request.gender());
        if (request.birthDate() != null) user.setBirthDate(request.birthDate());
        if (request.marketingAgreed() != null) user.setMarketingAgreed(request.marketingAgreed());

        // [수정] 반환 시에도 식이 취향 UUID를 조회하여 전달해야 합니다.
        UUID dietaryUuid = null;
        if (user.getPreferredDietaryId() != null) {
            dietaryUuid = contextTagRepository.findById(user.getPreferredDietaryId())
                    .map(ContextTag::getPublicId)
                    .orElse(null);
        }

        return UserDto.from(user, urlPrefix, dietaryUuid);
    }

    /**
     * 특정 사용자의 게시글 조회 (커서 기반 페이징)
     */
    public CursorResponse<MyPostResponseDto> getUserPosts(UUID targetUserId, String cursor, int size) {
        User targetUser = userRepository.findByPublicId(targetUserId)
                .orElseThrow(() -> new IllegalArgumentException("User not found"));

        PageRequest pageRequest = PageRequest.of(0, size);
        Slice<Post> slice;

        if (cursor == null || cursor.isBlank()) {
            slice = postRepository.findPublicPostsByCreatorFirstPage(targetUser.getId(), pageRequest);
        } else {
            String[] parts = cursor.split("_");
            Instant cursorTime;
            try {
                cursorTime = Instant.parse(parts[0]);
                if (cursorTime.isBefore(SAFE_MIN_DATE)) cursorTime = SAFE_MIN_DATE;
            } catch (Exception e) {
                cursorTime = SAFE_MIN_DATE;
            }
            UUID cursorPublicId = UUID.fromString(parts[1]);
            Long cursorInternalId = postRepository.findByPublicId(cursorPublicId)
                    .map(Post::getId).orElse(0L);

            slice = postRepository.findPublicPostsByCreatorWithCursor(targetUser.getId(), cursorTime, cursorInternalId, pageRequest);
        }

        List<MyPostResponseDto> dtos = slice.getContent().stream()
                .map(post -> {
                    String nextCursor = post.getCreatedAt().toString() + "_" + post.getPublicId();
                    return MyPostResponseDto.from(post, nextCursor, urlPrefix);
                }).toList();

        String nextCursor = dtos.isEmpty() ? null : dtos.get(dtos.size() - 1).cursor();
        return new CursorResponse<>(dtos, nextCursor, slice.hasNext());
    }
}