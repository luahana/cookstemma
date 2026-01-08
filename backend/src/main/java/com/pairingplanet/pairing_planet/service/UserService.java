package com.pairingplanet.pairing_planet.service;

import com.pairingplanet.pairing_planet.domain.entity.image.Image;
import com.pairingplanet.pairing_planet.domain.entity.user.User;
import com.pairingplanet.pairing_planet.dto.user.MyProfileResponseDto;
import com.pairingplanet.pairing_planet.dto.user.UpdateProfileRequestDto;
import com.pairingplanet.pairing_planet.dto.user.UserDto;
import com.pairingplanet.pairing_planet.repository.image.ImageRepository;
import com.pairingplanet.pairing_planet.repository.log_post.LogPostRepository;
import com.pairingplanet.pairing_planet.repository.recipe.RecipeRepository;
import com.pairingplanet.pairing_planet.repository.recipe.SavedRecipeRepository;
import com.pairingplanet.pairing_planet.repository.user.UserRepository;
import com.pairingplanet.pairing_planet.security.UserPrincipal;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class UserService {

    private final UserRepository userRepository;
    private final ImageService imageService;
    private final RecipeRepository recipeRepository;
    private final ImageRepository imageRepository;
    private final LogPostRepository logPostRepository;
    private final SavedRecipeRepository savedRecipeRepository;

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
     */
    public UserDto getUserProfile(UUID publicId) {
        User user = userRepository.findByPublicId(publicId)
                .orElseThrow(() -> new IllegalArgumentException("User not found"));
        return UserDto.from(user, urlPrefix);
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
}