package com.pairingplanet.pairing_planet.service;

import com.pairingplanet.pairing_planet.domain.entity.user.User;
import com.pairingplanet.pairing_planet.dto.user.MyProfileResponseDto;
import com.pairingplanet.pairing_planet.dto.user.UpdateProfileRequestDto;
import com.pairingplanet.pairing_planet.dto.user.UserDto;
import com.pairingplanet.pairing_planet.repository.recipe.RecipeRepository;
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

    @Value("${file.upload.url-prefix}")
    private String urlPrefix;

    /**
     * [내 정보] UserPrincipal 기반 상세 조회 (기획서 7번 반영)
     */
    public MyProfileResponseDto getMyProfile(UserPrincipal principal) {
        // principal에 이미 담긴 Long ID를 사용하여 DB 부하를 줄입니다.
        User user = userRepository.findById(principal.getId())
                .orElseThrow(() -> new IllegalArgumentException("User not found"));

        // 기획서 요구사항: 내가 만든 레시피 개수 등 활동 내역 포함
        return MyProfileResponseDto.builder()
                .user(UserDto.from(user, urlPrefix))
                .recipeCount(recipeRepository.countByCreatorIdAndIsDeletedFalse(user.getId()))
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

        // 1. 사용자명 중복 체크 및 변경
        if (request.username() != null && !request.username().equals(user.getUsername())) {
            if (userRepository.existsByUsername(request.username())) {
                throw new IllegalArgumentException("Username already exists");
            }
            user.setUsername(request.username());
        }

        // 2. 프로필 이미지 활성화 및 경로 저장
        if (request.profileImageUrl() != null) {
            // [수정] 이미지 활성화 시 대상(user)을 넘겨주어 상태를 ACTIVE로 변경합니다.
            // ImageService에서 target이 User일 경우 별도의 연관관계(FK)를 맺지는 않지만,
            // status를 ACTIVE로 바꾸어 가비지 컬렉터에 의해 삭제되는 것을 방지합니다.
            imageService.activateImages(List.of(request.profileImageUrl()), user);

            // 파일명만 추출하여 DB에 저장
            String fileName = request.profileImageUrl().replace(urlPrefix + "/", "");
            user.setProfileImageUrl(fileName);
        }

        // 3. 기타 정보 업데이트
        if (request.gender() != null) user.setGender(request.gender());
        if (request.birthDate() != null) user.setBirthDate(request.birthDate());
        if (request.marketingAgreed() != null) user.setMarketingAgreed(request.marketingAgreed());

        return UserDto.from(user, urlPrefix);
    }
}